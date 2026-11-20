import { deepEqual, equal, match, doesNotMatch } from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chmodSync, mkdtempSync, readdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test, type TestContext } from 'node:test';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const sh = '/bin/sh';
const bash = '/bin/bash';

function shellFixture(context: TestContext) {
    const directory = mkdtempSync(join(tmpdir(), 'codex-shell-tests-'));
    context.after(() => rmSync(directory, { recursive: true, force: true }));
    const log = join(directory, 'commands.log');
    writeFileSync(log, '');

    for (const tool of ['sh', 'cat', 'chmod', 'mktemp', 'rm']) {
        symlinkSync(join('/bin', tool), join(directory, tool));
    }

    function stub(name: string, body: string) {
        const path = join(directory, name);
        writeFileSync(path, '#!/bin/sh\n' + body + '\n');
        chmodSync(path, 0o755);
    }

    function run(command: string, args: string[], options: {
        input?: string;
        env?: Record<string, string>;
    } = {}) {
        const result = spawnSync(command, args, {
            cwd: root,
            encoding: 'utf8',
            timeout: 10_000,
            input: options.input,
            env: {
                PATH: directory,
                HOME: directory,
                TMPDIR: directory,
                TEST_LOG: log,
                TEST_BIN: directory,
                NPM_STATUS: '0',
                DOWNLOAD_STATUS: '0',
                ...options.env,
            },
        });
        if (result.error) throw result.error;
        return result;
    }

    function stubNpm() {
        stub('npm', [
            'echo "$*" >> "$TEST_LOG"',
            '[ "$NPM_STATUS" = 0 ] || exit "$NPM_STATUS"',
            'cat > "$TEST_BIN/codex" <<\'CODEX\'',
            '#!/bin/sh',
            '[ "$#" -eq 1 ] && [ "$1" = --version ] || exit 2',
            'echo codex fixture',
            'CODEX',
            'chmod +x "$TEST_BIN/codex"',
        ].join('\n'));
    }

    function stubUvDownload() {
        stub('curl', [
            'while [ "$#" -gt 0 ] && [ "$1" != --output ]; do shift; done',
            '[ "$#" -ge 2 ] || exit 2',
            'cat > "$2" <<\'INSTALLER\'',
            '[ "$UV_INSTALL_DIR" = /usr/local/bin ] && [ "$UV_NO_MODIFY_PATH" = 1 ] || exit 2',
            'echo installer >> "$TEST_LOG"',
            'INSTALLER',
            'exit "$DOWNLOAD_STATUS"',
        ].join('\n'));
        stub('uv', '[ "$1" = --version ] && echo uv >> "$TEST_LOG"');
    }

    return { directory, log, run, stub, stubNpm, stubUvDownload };
}

test('shell scripts pass syntax checks', (context) => {
    const { run } = shellFixture(context);
    const installers = readdirSync(join(root, 'docker/scripts'))
        .filter((name) => name.endsWith('.sh'))
        .map((name) => 'docker/scripts/' + name);
    for (const script of ['entrypoint.sh', ...installers]) {
        const result = run(sh, ['-n', script]);
        equal(result.status, 0, result.stderr);
    }
    const result = run(bash, ['-n', 'scripts/codex-shell.sh']);
    equal(result.status, 0, result.stderr);
});

test('entrypoint installs once and forwards arguments and exit status', (context) => {
    const { log, run, stubNpm } = shellFixture(context);
    stubNpm();
    for (let attempt = 0; attempt < 2; attempt++) {
        const result = run(sh, ['entrypoint.sh', sh, '-c',
            'printf "<%s>\\n" "$1"; exit 42', 'sh', 'argument with spaces']);
        equal(result.status, 42, result.stderr);
        match(result.stdout, /<argument with spaces>/);
        match(result.stdout, /codex fixture/);
    }
    equal(readFileSync(log, 'utf8'), 'install --global @openai/codex@latest\n');
});

test('entrypoint repairs a failed version check', (context) => {
    const { log, run, stub, stubNpm } = shellFixture(context);
    stubNpm();
    stub('codex', 'exit 3');
    const result = run(sh, ['entrypoint.sh', sh, '-c', 'exit 0']);
    equal(result.status, 0, result.stderr);
    match(result.stdout, /codex fixture/);
    equal(readFileSync(log, 'utf8'), 'install --global @openai/codex@latest\n');
});

test('entrypoint stops on installation failure', (context) => {
    const { run, stubNpm } = shellFixture(context);
    stubNpm();
    const result = run(sh, ['entrypoint.sh', sh, '-c', 'echo command-ran'], {
        env: { NPM_STATUS: '17' },
    });
    equal(result.status, 17, result.stderr);
    doesNotMatch(result.stdout, /command-ran/);
});

test('entrypoint defaults to Bash', (context) => {
    const { run, stub } = shellFixture(context);
    stub('codex', '[ "$1" = --version ] && echo codex fixture');
    const result = run(sh, ['entrypoint.sh'], {
        input: '[[ -n "$BASH_VERSION" ]] && echo bash\n',
    });
    equal(result.status, 0, result.stderr);
    equal(result.stdout, 'codex fixture\nbash\n');
});

test('entrypoint restores a pin and reuses it on restart', (context) => {
    const { log, run, stub } = shellFixture(context);
    stub('codex', 'echo codex-cli 9.9.9');
    stub('npm', [
        'echo "$*" >> "$TEST_LOG"',
        'printf \'%s\\n\' "#!/bin/sh" "echo codex-cli 1.2.3-beta.1" > "$TEST_BIN/codex"',
    ].join('\n'));
    const env = { CODEX_VERSION: '1.2.3-beta.1' };
    for (let attempt = 0; attempt < 2; attempt++) {
        const result = run(sh, ['entrypoint.sh', sh, '-c', 'exit 0'], { env });
        equal(result.status, 0, result.stderr);
        match(result.stdout, /codex-cli 1\.2\.3-beta\.1/);
    }
    equal(readFileSync(log, 'utf8'), 'install --global @openai/codex@1.2.3-beta.1\n');
});

test('entrypoint blocks startup if the installed version differs from the pin', (context) => {
    const { run, stub } = shellFixture(context);
    stub('codex', 'echo codex-cli 9.9.9');
    stub('npm', 'exit 0');
    const result = run(sh, ['entrypoint.sh', sh, '-c', 'echo command-ran'], {
        env: { CODEX_VERSION: '1.2.3' },
    });
    equal(result.status, 1, result.stderr);
    match(result.stderr, /Expected Codex CLI 1\.2\.3, got codex-cli 9\.9\.9/);
    doesNotMatch(result.stdout, /command-ran/);
});

test('helpers load in nested Bash sessions with errexit enabled', (context) => {
    const { run } = shellFixture(context);
    const result = run(bash, ['--noprofile', '--norc', '-euc', [
        'source scripts/codex-shell.sh',
        'source scripts/codex-shell.sh',
        'alias cw >/dev/null',
        '"$BASH" --noprofile --norc -euc \'source scripts/codex-shell.sh; alias cw >/dev/null\'',
    ].join('\n')]);
    equal(result.status, 0, result.stderr);
});

test('tool diagnostics handle missing tools, failures, and stderr versions', (context) => {
    const { run, stub } = shellFixture(context);
    stub('broken', 'exit 2');
    stub('versioned', "printf 'version 1\\nextra output\\n' >&2");
    const result = run(bash, ['--noprofile', '--norc', '-euc', [
        'source scripts/codex-shell.sh',
        'cdx_tool_version missing --version',
        'cdx_tool_version broken --version',
        'cdx_tool_version versioned --version',
    ].join('\n')]);
    equal(result.status, 0, result.stderr);
    equal(result.stdout, 'not found\nversion unavailable\nversion 1\n');
});

test('cdxcheck validates the CLI and writable directories without signing in', (context) => {
    const { directory, run, stub } = shellFixture(context);
    stub('codex', '[ "$#" -eq 1 ] && [ "$1" = --version ] && echo codex fixture');
    const result = run(bash, ['--noprofile', '--norc', '-euc',
        'source scripts/codex-shell.sh; cdxcheck'], {
        env: { CODEX_WORKSPACE: directory, CODEX_HOME: directory },
    });
    equal(result.status, 0, result.stderr);
    match(result.stdout, /checks passed/);
});

test('cdxcheck reports missing or broken Codex and invalid directories', (context) => {
    const { directory, log, run, stub } = shellFixture(context);
    const args = ['--noprofile', '--norc', '-euc', 'source scripts/codex-shell.sh; cdxcheck'];
    const options = { env: { CODEX_WORKSPACE: join(directory, 'missing'), CODEX_HOME: log } };
    const missing = run(bash, args, options);
    equal(missing.status, 1, missing.stderr);
    match(missing.stderr, /Codex CLI is missing/);
    match(missing.stderr, /Workspace is unavailable/);
    match(missing.stderr, /Codex state directory is unavailable/);

    stub('codex', 'exit 3');
    const broken = run(bash, args, options);
    equal(broken.status, 1, broken.stderr);
    match(broken.stderr, /Codex CLI version check failed/);
});

test('cdxupdate installs latest or a pinned version and reports the resulting CLI version', (context) => {
    const { log, run, stubNpm } = shellFixture(context);
    stubNpm();
    for (const update of ['cdxupdate', 'cdxupdate 1.2.3-beta.1']) {
        const result = run(bash, ['--noprofile', '--norc', '-euc',
            'source scripts/codex-shell.sh; ' + update]);
        equal(result.status, 0, result.stderr);
        equal(result.stdout, 'codex fixture\n');
    }
    deepEqual(readFileSync(log, 'utf8').trimEnd().split('\n'), [
        'install --global @openai/codex@latest',
        'install --global @openai/codex@1.2.3-beta.1',
    ]);
});

test('cdxupdate rejects invalid versions and propagates install and version failures', (context) => {
    const { log, run, stub, stubNpm } = shellFixture(context);
    stubNpm();
    const shell = ['--noprofile', '--norc', '-euc'];
    const invalid = run(bash, [...shell, 'source scripts/codex-shell.sh; cdxupdate invalid']);
    equal(invalid.status, 2, invalid.stderr);
    match(invalid.stderr, /Usage: cdxupdate/);
    equal(readFileSync(log, 'utf8'), '');

    const update = [...shell, 'source scripts/codex-shell.sh; cdxupdate'];
    stub('codex', 'echo version-checked; exit 3');
    const failed = run(bash, update, { env: { NPM_STATUS: '17' } });
    equal(failed.status, 17, failed.stderr);
    doesNotMatch(failed.stdout, /version-checked/);

    stub('npm', 'exit 0');
    const broken = run(bash, update);
    equal(broken.status, 3, broken.stderr);
    match(broken.stdout, /version-checked/);
});

test('uv installer runs and cleans up', (context) => {
    const { directory, log, run, stubUvDownload } = shellFixture(context);
    stubUvDownload();
    const before = readdirSync(directory).sort();
    const result = run(sh, ['docker/scripts/20-python.sh']);
    equal(result.status, 0, result.stderr);
    equal(readFileSync(log, 'utf8'), 'installer\nuv\n');
    deepEqual(readdirSync(directory).sort(), before);
});

test('a partial uv download is cleaned up without executing it', (context) => {
    const { directory, log, run, stubUvDownload } = shellFixture(context);
    stubUvDownload();
    const before = readdirSync(directory).sort();
    const result = run(sh, ['docker/scripts/20-python.sh'], {
        env: { DOWNLOAD_STATUS: '18' },
    });
    equal(result.status, 18, result.stderr);
    equal(readFileSync(log, 'utf8'), '');
    deepEqual(readdirSync(directory).sort(), before);
});

test('APT update failure stops installers before package installation', (context) => {
    const { log, run, stub } = shellFixture(context);
    stub('apt-get', 'echo "$*" >> "$TEST_LOG"; exit 100');
    for (const name of ['60-gcc', '70-ruby', '80-php', '90-swift']) {
        writeFileSync(log, '');
        const result = run(sh, ['docker/scripts/' + name + '.sh']);
        equal(result.status, 100, name + ': ' + result.stderr);
        equal(readFileSync(log, 'utf8'), '-o APT::Update::Error-Mode=any update\n', name);
    }
});
