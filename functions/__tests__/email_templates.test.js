/**
 * Unit tests for email_templates.js
 *
 * Tests email template generation without external dependencies.
 */

import { describe, it, expect } from '@jest/globals';
import {
  generateRegistrationEmail,
  generateSignInEmail
} from '../email_templates.js';

describe('Email Templates', () => {
  describe('generateRegistrationEmail', () => {
    it('should generate registration email with correct structure', () => {
      const name = 'John Doe';
      const verificationUrl = 'https://app.example.com?registrationToken=abc123';

      const result = generateRegistrationEmail(name, verificationUrl);

      expect(result).toHaveProperty('html');
      expect(result).toHaveProperty('text');
      expect(typeof result.html).toBe('string');
      expect(typeof result.text).toBe('string');
    });

    it('should include user name in email', () => {
      const name = 'Jane Smith';
      const verificationUrl = 'https://app.example.com?registrationToken=xyz789';

      const result = generateRegistrationEmail(name, verificationUrl);

      expect(result.html).toContain(name);
      expect(result.text).toContain(name);
    });

    it('should include verification URL in email', () => {
      const name = 'Test User';
      const verificationUrl = 'https://app.example.com?registrationToken=test123';

      const result = generateRegistrationEmail(name, verificationUrl);

      expect(result.html).toContain(verificationUrl);
      expect(result.text).toContain(verificationUrl);
    });

    it('should include "Complete Registration" button text in HTML', () => {
      const name = 'Test User';
      const verificationUrl = 'https://app.example.com?registrationToken=test123';

      const result = generateRegistrationEmail(name, verificationUrl);

      expect(result.html).toContain('Complete Registration');
    });

    it('should include important security message', () => {
      const name = 'Test User';
      const verificationUrl = 'https://app.example.com?registrationToken=test123';

      const result = generateRegistrationEmail(name, verificationUrl);

      expect(result.html).toContain('24 hours');
      expect(result.text).toContain('24 hours');
    });

    it('should handle special characters in name', () => {
      const name = "O'Brien & Co.";
      const verificationUrl = 'https://app.example.com?registrationToken=test123';

      const result = generateRegistrationEmail(name, verificationUrl);

      // Should not throw error
      expect(result.html).toContain(name);
      expect(result.text).toContain(name);
    });

    it('should handle URLs with query parameters', () => {
      const name = 'Test User';
      const verificationUrl = 'https://app.example.com?foo=bar&registrationToken=test123';

      const result = generateRegistrationEmail(name, verificationUrl);

      expect(result.html).toContain(verificationUrl);
      expect(result.text).toContain(verificationUrl);
    });
  });

  describe('generateSignInEmail', () => {
    it('should generate sign-in email with correct structure', () => {
      const name = 'Alice Cooper';
      const signInUrl = 'https://app.example.com?signInToken=def456';

      const result = generateSignInEmail(name, signInUrl);

      expect(result).toHaveProperty('html');
      expect(result).toHaveProperty('text');
      expect(typeof result.html).toBe('string');
      expect(typeof result.text).toBe('string');
    });

    it('should include user name in email', () => {
      const name = 'Bob Dylan';
      const signInUrl = 'https://app.example.com?signInToken=ghi789';

      const result = generateSignInEmail(name, signInUrl);

      expect(result.html).toContain(name);
      expect(result.text).toContain(name);
    });

    it('should include sign-in URL in email', () => {
      const name = 'Test User';
      const signInUrl = 'https://app.example.com?signInToken=test456';

      const result = generateSignInEmail(name, signInUrl);

      expect(result.html).toContain(signInUrl);
      expect(result.text).toContain(signInUrl);
    });

    it('should include "Sign In" button text in HTML', () => {
      const name = 'Test User';
      const signInUrl = 'https://app.example.com?signInToken=test456';

      const result = generateSignInEmail(name, signInUrl);

      expect(result.html).toContain('Sign In');
    });

    it('should include security expiration message', () => {
      const name = 'Test User';
      const signInUrl = 'https://app.example.com?signInToken=test456';

      const result = generateSignInEmail(name, signInUrl);

      expect(result.html).toContain('24 hours');
      expect(result.text).toContain('24 hours');
    });

    it('should have different content than registration email', () => {
      const name = 'Test User';
      const url = 'https://app.example.com?token=test';

      const registrationEmail = generateRegistrationEmail(name, url);
      const signInEmail = generateSignInEmail(name, url);

      // Sign-in should say "Sign In", registration should say "Complete Registration"
      expect(signInEmail.html).toContain('Sign In');
      expect(registrationEmail.html).toContain('Complete Registration');

      // Sign-in should say "sign in", registration should say "registration"
      expect(signInEmail.html.toLowerCase()).toContain('sign in');
      expect(registrationEmail.html.toLowerCase()).toContain('registration');
    });
  });

  describe('Email Format Validation', () => {
    it('registration email HTML should be valid HTML structure', () => {
      const name = 'Test User';
      const url = 'https://app.example.com?token=test';

      const result = generateRegistrationEmail(name, url);

      // Check for basic HTML structure
      expect(result.html).toContain('<!DOCTYPE html>');
      expect(result.html).toContain('<html>');
      expect(result.html).toContain('</html>');
      expect(result.html).toContain('<body');
      expect(result.html).toContain('</body>');
    });

    it('sign-in email HTML should be valid HTML structure', () => {
      const name = 'Test User';
      const url = 'https://app.example.com?token=test';

      const result = generateSignInEmail(name, url);

      // Check for basic HTML structure
      expect(result.html).toContain('<!DOCTYPE html>');
      expect(result.html).toContain('<html>');
      expect(result.html).toContain('</html>');
      expect(result.html).toContain('<body');
      expect(result.html).toContain('</body>');
    });

    it('text emails should not contain HTML tags', () => {
      const name = 'Test User';
      const url = 'https://app.example.com?token=test';

      const registrationResult = generateRegistrationEmail(name, url);
      const signInResult = generateSignInEmail(name, url);

      // Text version should not have HTML tags
      expect(registrationResult.text).not.toContain('<html>');
      expect(registrationResult.text).not.toContain('<body>');
      expect(signInResult.text).not.toContain('<html>');
      expect(signInResult.text).not.toContain('<body>');
    });

    it('text emails should be readable without HTML', () => {
      const name = 'Test User';
      const url = 'https://app.example.com?token=test';

      const registrationResult = generateRegistrationEmail(name, url);
      const signInResult = generateSignInEmail(name, url);

      // Text should have name and URL clearly visible
      expect(registrationResult.text).toContain(name);
      expect(registrationResult.text).toContain(url);
      expect(signInResult.text).toContain(name);
      expect(signInResult.text).toContain(url);

      // Text should have some structure (newlines)
      expect(registrationResult.text.split('\n').length).toBeGreaterThan(5);
      expect(signInResult.text.split('\n').length).toBeGreaterThan(5);
    });
  });
});
