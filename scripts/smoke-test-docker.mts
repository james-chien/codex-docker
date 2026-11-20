import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { generateDockerfile } from './generate-dockerfile.mts';

const root = fileURLToPath(new URL('../', import.meta.url));

function docker(...args: string[]) {
    const result = spawnSync('docker', args, { cwd: root, stdio: 'inherit' });
    if (result.error) throw result.error;
    if (result.status !== 0) {
        throw new Error('docker ' + args[0] + ' failed (' + (result.signal ?? result.status) + ').');
    }
}

function smokeTest() {
    docker('info', '--format', '{{.ServerVersion}}');
    const directory = mkdtempSync(join(tmpdir(), 'codex-docker-smoke-'));
    try {
        const minimal = join(directory, 'Dockerfile.minimal');
        writeFileSync(minimal, generateDockerfile({ runtimes: [] }));
        for (const [name, dockerfile] of [['default', join(root, 'Dockerfile')], ['minimal', minimal]]) {
            console.log('Building and starting the ' + name + ' image');
            const imageIdFile = join(directory, name + '.iid');
            docker('build', '--iidfile', imageIdFile, '--file', dockerfile, root);
            const imageId = readFileSync(imageIdFile, 'utf8').trim();
            docker('run', '--rm', imageId, '/bin/bash', '-c',
                'source /etc/profile.d/codex-shell.sh && cdxcheck');
        }
    } finally {
        rmSync(directory, { recursive: true, force: true });
    }
}

try {
    smokeTest();
} catch (error) {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
}
