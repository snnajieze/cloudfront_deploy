import React, { useMemo, useState } from 'react';
import { getEnvironmentLabel } from './lib/environment.js';
import { getViteAppEnv } from './lib/viteEnv.js';

export default function App() {
  const [count, setCount] = useState(0);
  const envLabel = useMemo(() => getEnvironmentLabel(getViteAppEnv()), []);

  return (
    <main style={{ fontFamily: 'system-ui, sans-serif', padding: '2rem' }}>
      <h1>FSL DevOps Challenge</h1>
      <p data-testid="env-label">
        Running in: <strong>{envLabel}</strong>
      </p>
      <button type="button" onClick={() => setCount((c) => c + 1)}>
        Clicked {count} {count === 1 ? 'time' : 'times'}
      </button>
      <p>
        This static app is built with Vite, linted with ESLint, tested with
        Jest, and shipped to AWS S3 behind CloudFront via Terraform.
      </p>
    </main>
  );
}
