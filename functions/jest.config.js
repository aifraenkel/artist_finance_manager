export default {
  testEnvironment: 'node',
  transform: {},
  testMatch: ['**/__tests__/**/*.test.js'],
  collectCoverageFrom: [
    '*.js',
    '!index.js', // Skip main entry point as it's tested via integration
    '!email_service.js', // External service wrapper - tested via integration
    '!email_service_smtp.js', // External service wrapper - tested via integration
    '!email_service_sendgrid.js', // External service wrapper - tested via integration
    '!check_user.js', // Utility script - not part of production code
    '!delete_test_user.js', // Utility script - not part of production code
    '!test_registration.js', // Utility script - not part of production code
    '!jest.config.js',
    '!coverage/**',
    '!deploy.sh'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 90,
      lines: 90,
      statements: 90
    }
  }
};
