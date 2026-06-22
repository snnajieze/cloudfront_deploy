/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['@testing-library/jest-dom'],
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
  moduleNameMapper: {
    '\\.(css|less|scss)$': '<rootDir>/src/test/styleMock.js',
    '^(\\.{1,2}/.*)lib/viteEnv\\.js$': '<rootDir>/src/test/viteEnvMock.js',
  },
  collectCoverageFrom: ['src/**/*.{js,jsx}', '!src/main.jsx'],
};
