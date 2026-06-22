// Isolated in its own file because `import.meta` is a syntax Babel/Jest's
// CommonJS transform does not parse the same way Vite's native ESM does.
// Jest is configured (see jest.config.cjs moduleNameMapper) to substitute
// this module with a plain mock during tests, so App.jsx can stay simple
// and never has to special-case the test environment itself.
export function getViteAppEnv() {
  return import.meta.env.VITE_APP_ENV;
}
