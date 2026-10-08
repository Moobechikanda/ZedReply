// Builds the dashboard/widget/portal bundles into public/vite on the host.
//
// The Docker image builds these during `assets:precompile`, but a Docker build
// needs network access to Alpine, RubyGems and the npm registry. This script is
// the host-side equivalent for the `dev:mount` workflow, which serves the
// working tree straight out of the cached chatwoot image.
//
// Vite needs a large heap to bundle the dashboard. Override with NODE_OPTIONS if
// the default is too small or too large for the machine.
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const root = path.join(__dirname, '..');
const vite = path.join(root, 'node_modules', 'vite', 'bin', 'vite.js');

const result = spawnSync(process.execPath, [vite, 'build', '--mode', 'production'], {
  cwd: root,
  stdio: 'inherit',
  env: {
    ...process.env,
    NODE_ENV: 'production',
    RAILS_ENV: 'production',
    // vite-plugin-ruby reads VITE_RUBY_MODE, not Vite's --mode, to pick the
    // output directory (public/vite instead of public/vite-dev).
    VITE_RUBY_MODE: 'production',
    NODE_OPTIONS: process.env.NODE_OPTIONS || '--max-old-space-size=4096',
  },
});

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);