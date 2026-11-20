import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

function normalizeBasePath(value: string): string {
  const segments = value.split('/').filter(Boolean);
  return segments.length ? `/${segments.join('/')}/` : '/';
}

const configuredBasePath = process.env.BIDDWORLD_BASE_PATH?.trim();
const base = configuredBasePath
  ? normalizeBasePath(configuredBasePath)
  : process.env.GITHUB_PAGES === 'true'
    ? '/biddworld/'
    : '/';

export default defineConfig({
  plugins: [react()],
  base,
});
