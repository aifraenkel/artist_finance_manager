export default {
  testEnvironment: 'node',
  transform: {},
  testMatch: ['**/__tests__/**/*.test.js'],
  collectCoverageFrom: [
    '*.js',
    '!index.js', // Skip main entry point as it's tested via integration
    '!email_service.js', // External service wrapper - tested via integration
    '!email_service_smtp.js', // External service wrapper - tested via integration
    '!jest.config.js',
    '!coverage/**'
  ],
  coverageThreshold: {
    global: {
      branches: 90,
      functions: 100,
      lines: 100,
      statements: 100
    }
  }
};
