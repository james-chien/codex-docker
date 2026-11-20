import { deepEqual, equal, match, doesNotMatch, throws } from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { generateDockerfile } from '../scripts/generate-dockerfile.mts';

const root = fileURLToPath(new URL('../', import.meta.url));

test('default config reproduces the checked-in Dockerfile', () => {
    const config = JSON.parse(readFileSync(join(root, 'docker.config.json'), 'utf8'));
    const dockerfile = generateDockerfile(config);
    equal(dockerfile, readFileSync(join(root, 'Dockerfile'), 'utf8'));
    match(dockerfile, /^FROM swift:trixie AS development$/m);
    match(dockerfile, /for script in 10-node\.sh 20-python\.sh 60-gcc\.sh 70-ruby\.sh 80-php\.sh 90-swift\.sh;/);
});

test('empty selection keeps the Codex prerequisites and omits optional installers', () => {
    const dockerfile = generateDockerfile({ runtimes: [] });
    deepEqual(dockerfile.match(/^FROM .+$/gm), [
        'FROM node:trixie-slim AS node-runtime',
        'FROM debian:trixie-slim AS development',
    ]);
    match(dockerfile, /COPY --from=node-runtime/);
    match(dockerfile, /libatomic1/);
    match(dockerfile, /ENTRYPOINT \["\/usr\/local\/bin\/entrypoint.sh"\]/);
    doesNotMatch(dockerfile, /docker\/scripts|npm-cache|javac|swift --version/);
});

test('a subset emits its stage copies, installer, and checks in stable order', () => {
    const dockerfile = generateDockerfile({ runtimes: ['python', 'go'] });
    equal(dockerfile, generateDockerfile({ runtimes: ['go', 'python'] }));
    match(dockerfile, /COPY --from=python-runtime/);
    match(dockerfile, /ENV PATH=\/usr\/local\/go\/bin:\$PATH/);
    match(dockerfile, /for script in 20-python\.sh;/);
    match(dockerfile, /python3 -m pip --version/);
    match(dockerfile, /go version/);
    doesNotMatch(dockerfile, /java-runtime|gcc-runtime|swift:trixie|10-node\.sh/);
});

test('Node tooling and Swift can be enabled independently', () => {
    const node = generateDockerfile({ runtimes: ['node'] });
    match(node, /10-node\.sh/);
    match(node, /type=cache,target=\/root\/\.npm/);
    doesNotMatch(node, /swift:trixie/);

    const swift = generateDockerfile({ runtimes: ['swift'] });
    match(swift, /FROM swift:trixie AS development/);
    match(swift, /90-swift\.sh/);
    match(swift, /swift package --version/);
    doesNotMatch(swift, /10-node\.sh|FROM gcc:/);
});

test('invalid configs fail with actionable messages', () => {
    throws(() => generateDockerfile({}), /"runtimes" array/);
    throws(() => generateDockerfile({ runtimes: [], typo: true }), /"runtimes" array/);
    throws(() => generateDockerfile({ runtimes: ['constructor'] }), /Unknown runtime/);
    throws(() => generateDockerfile({ runtimes: [42] }), /Unknown runtime/);
    throws(() => generateDockerfile({ runtimes: ['go', 'go'] }), /Duplicate runtime/);
});

test('config can pin Codex to an exact release', () => {
    match(generateDockerfile({ runtimes: [], codexVersion: '0.171.0-beta.1' }),
        /^ENV CODEX_VERSION=0\.171\.0-beta\.1$/m);
    match(generateDockerfile({ runtimes: [] }), /^ENV CODEX_VERSION=latest$/m);
    for (const codexVersion of ['^0.171.0', 'latest\nRUN false', '0.171.0\n', '', 171]) {
        throws(() => generateDockerfile({ runtimes: [], codexVersion }), /"codexVersion"/);
    }
});

test('CLI writes a Dockerfile, protects existing output, and supports regeneration', (context) => {
    const directory = mkdtempSync(join(tmpdir(), 'codex-dockerfile-tests-'));
    context.after(() => rmSync(directory, { recursive: true, force: true }));
    const config = join(directory, 'docker.config.json');
    const output = join(directory, 'Dockerfile.generated');
    function run(...args: string[]) {
        return spawnSync(process.execPath, [join(root, 'scripts/generate-dockerfile.mts'), ...args], {
            cwd: directory, encoding: 'utf8', timeout: 10_000,
        });
    }

    writeFileSync(config, '{');
    equal(run().status, 1);
    equal(existsSync(output), false);

    writeFileSync(config, '{"runtimes":["go"]}');
    const first = run();
    equal(first.status, 0, first.stderr);
    const original = readFileSync(output, 'utf8');
    match(original, /go version/);

    writeFileSync(config, '{"runtimes":["python"]}');
    equal(run().status, 1);
    equal(readFileSync(output, 'utf8'), original);
    const updated = run('--force');
    equal(updated.status, 0, updated.stderr);
    match(readFileSync(output, 'utf8'), /python3 --version/);
    doesNotMatch(readFileSync(output, 'utf8'), /go version/);

    const checkedIn = join(directory, 'Dockerfile');
    equal(run('--check').status, 1);
    equal(existsSync(checkedIn), false);
    writeFileSync(checkedIn, readFileSync(output));
    equal(run('--check').status, 0);
    writeFileSync(checkedIn, original);
    const stale = run('--check');
    equal(stale.status, 1, stale.stderr);
    match(stale.stderr, /out of date/);
    equal(readFileSync(checkedIn, 'utf8'), original);
});

test('Docker smoke command builds and starts each image through its entrypoint', (context) => {
    const directory = mkdtempSync(join(tmpdir(), 'codex-smoke-test-fixture-'));
    context.after(() => rmSync(directory, { recursive: true, force: true }));
    const log = join(directory, 'docker.log');
    writeFileSync(join(directory, 'docker'), [
        '#!/bin/sh',
        'set -eu',
        'case "$1" in',
        '  info) echo info >> "$TEST_LOG" ;;',
        '  build)',
        '    [ "$2" = --iidfile ] && [ "$4" = --file ] && [ -f "$5" ] || exit 2',
        '    case "$5" in',
        '      */Dockerfile) image=default ;;',
        '      */Dockerfile.minimal) image=minimal ;;',
        '      *) exit 2 ;;',
        '    esac',
        '    echo "build $image" >> "$TEST_LOG"',
        '    echo "$image" > "$3" ;;',
        '  run)',
        '    [ "$2" = --rm ] && [ "$4" = /bin/bash ] && [ "$5" = -c ] || exit 2',
        '    [ "$6" = "source /etc/profile.d/codex-shell.sh && cdxcheck" ] || exit 2',
        '    echo "run $3" >> "$TEST_LOG" ;;',
        '  *) exit 2 ;;',
        'esac',
    ].join('\n'), { mode: 0o755 });
    const result = spawnSync(process.execPath, [join(root, 'scripts/smoke-test-docker.mts')], {
        cwd: directory, encoding: 'utf8', timeout: 10_000,
        env: { PATH: directory, TEST_LOG: log, TMPDIR: directory },
    });
    equal(result.status, 0, result.stderr);
    equal(readFileSync(log, 'utf8'), 'info\nbuild default\nrun default\nbuild minimal\nrun minimal\n');
});
