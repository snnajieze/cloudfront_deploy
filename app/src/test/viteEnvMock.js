// Jest substitute for src/lib/viteEnv.js (see jest.config.cjs
// moduleNameMapper). Returns "test" so getEnvironmentLabel() has a
// deterministic, environment-agnostic value to assert against.
module.exports = {
  getViteAppEnv: () => 'test',
};
