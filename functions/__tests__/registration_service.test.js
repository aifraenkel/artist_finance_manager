/**
 * Unit tests for registration_service.js
 *
 * These tests run autonomously on localhost without requiring Firebase.
 * Firestore is mocked to test business logic in isolation.
 */

import { jest } from '@jest/globals';
import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';

// Mock Firestore before importing the service
const mockFirestore = {
  collection: jest.fn(),
};

const mockCollection = {
  doc: jest.fn(),
  where: jest.fn(),
  get: jest.fn(),
};

const mockDoc = {
  set: jest.fn(),
  get: jest.fn(),
  update: jest.fn(),
  exists: false,
  data: jest.fn(),
};

const mockBatch = {
  delete: jest.fn(),
  commit: jest.fn(),
};

const mockQuery = {
  get: jest.fn(),
  where: jest.fn(), // Allow chaining .where().where()
};

// Set up mock chain - where() returns itself to allow chaining
mockQuery.where.mockReturnValue(mockQuery);

// Set up mock chain
mockFirestore.collection.mockReturnValue(mockCollection);
mockCollection.doc.mockReturnValue(mockDoc);
mockCollection.where.mockReturnValue(mockQuery);
mockFirestore.batch = jest.fn().mockReturnValue(mockBatch);

// Mock the Firestore module
jest.unstable_mockModule('@google-cloud/firestore', () => ({
  Firestore: jest.fn(() => mockFirestore)
}));

// Now import the service
const {
  createPendingRegistration,
  verifyRegistrationToken,
  cleanupExpiredRegistrations,
  hasPendingRegistration,
  cancelPendingRegistration
} = await import('../registration_service.js');

describe('Registration Service', () => {
  beforeEach(() => {
    // Reset all mocks before each test
    jest.clearAllMocks();
  });

  describe('createPendingRegistration', () => {
    it('should create a pending registration with token', async () => {
      const email = 'test@example.com';
      const name = 'Test User';
      const continueUrl = 'https://app.example.com';

      const result = await createPendingRegistration(email, name, continueUrl);

      // Should return token and expiration
      expect(result).toHaveProperty('token');
      expect(result).toHaveProperty('expiresAt');
      expect(result.token).toBeTruthy();
      expect(result.expiresAt).toBeInstanceOf(Date);

      // Should call Firestore to save
      expect(mockFirestore.collection).toHaveBeenCalledWith('pendingRegistrations');
      expect(mockCollection.doc).toHaveBeenCalledWith(result.token);
      expect(mockDoc.set).toHaveBeenCalled();

      // Check saved data structure
      const savedData = mockDoc.set.mock.calls[0][0];
      expect(savedData.email).toBe(email);
      expect(savedData.name).toBe(name);
      expect(savedData.token).toBe(result.token);
      expect(savedData.continueUrl).toBe(continueUrl);
      expect(savedData.status).toBe('pending');
      expect(savedData.createdAt).toBeInstanceOf(Date);
      expect(savedData.expiresAt).toBeInstanceOf(Date);
    });

    it('should generate unique tokens for different requests', async () => {
      const result1 = await createPendingRegistration(
        'user1@example.com',
        'User 1',
        'https://app.example.com'
      );
      const result2 = await createPendingRegistration(
        'user2@example.com',
        'User 2',
        'https://app.example.com'
      );

      expect(result1.token).not.toBe(result2.token);
    });

    it('should set expiration to 24 hours in the future', async () => {
      const before = new Date();
      const result = await createPendingRegistration(
        'test@example.com',
        'Test User',
        'https://app.example.com'
      );
      const after = new Date();

      const expiresAt = result.expiresAt.getTime();
      const expectedMin = before.getTime() + (24 * 60 * 60 * 1000) - 1000; // -1s tolerance
      const expectedMax = after.getTime() + (24 * 60 * 60 * 1000) + 1000; // +1s tolerance

      expect(expiresAt).toBeGreaterThanOrEqual(expectedMin);
      expect(expiresAt).toBeLessThanOrEqual(expectedMax);
    });
  });

  describe('verifyRegistrationToken', () => {
    it('should verify a valid token and return user data', async () => {
      const token = 'valid-token';
      const mockData = {
        email: 'test@example.com',
        name: 'Test User',
        continueUrl: 'https://app.example.com',
        status: 'pending',
        expiresAt: { toDate: () => new Date(Date.now() + 60000) }, // Future date
      };

      mockDoc.exists = true;
      mockDoc.data.mockReturnValue(mockData);
      mockDoc.get.mockResolvedValue(mockDoc);

      const result = await verifyRegistrationToken(token, '1.2.3.4');

      expect(result).toEqual({
        email: mockData.email,
        name: mockData.name,
        continueUrl: mockData.continueUrl,
      });

      // Should mark as completed
      expect(mockDoc.update).toHaveBeenCalled();
      const updateData = mockDoc.update.mock.calls[0][0];
      expect(updateData.status).toBe('completed');
      expect(updateData.verifiedAt).toBeInstanceOf(Date);
      expect(updateData.ipAddress).toBe('1.2.3.4');
    });

    it('should throw error for non-existent token', async () => {
      const token = 'invalid-token';
      mockDoc.exists = false;
      mockDoc.get.mockResolvedValue(mockDoc);

      await expect(verifyRegistrationToken(token)).rejects.toThrow(
        'INVALID_TOKEN: Registration token not found'
      );
    });

    it('should throw error for already-used token', async () => {
      const token = 'used-token';
      const mockData = {
        status: 'completed',
        expiresAt: { toDate: () => new Date(Date.now() + 60000) },
      };

      mockDoc.exists = true;
      mockDoc.data.mockReturnValue(mockData);
      mockDoc.get.mockResolvedValue(mockDoc);

      await expect(verifyRegistrationToken(token)).rejects.toThrow(
        'TOKEN_ALREADY_USED'
      );
    });

    it('should throw error for expired token', async () => {
      const token = 'expired-token';
      const mockData = {
        status: 'pending',
        expiresAt: { toDate: () => new Date(Date.now() - 60000) }, // Past date
      };

      mockDoc.exists = true;
      mockDoc.data.mockReturnValue(mockData);
      mockDoc.get.mockResolvedValue(mockDoc);

      await expect(verifyRegistrationToken(token)).rejects.toThrow(
        'TOKEN_EXPIRED'
      );

      // Should mark as expired
      expect(mockDoc.update).toHaveBeenCalled();
      const updateData = mockDoc.update.mock.calls[0][0];
      expect(updateData.status).toBe('expired');
    });
  });

  describe('cleanupExpiredRegistrations', () => {
    it('should delete expired registrations', async () => {
      const mockDocs = [
        { id: 'token1', data: () => ({ email: 'user1@example.com', status: 'pending', expiresAt: { toDate: () => new Date(Date.now() - 60000) } }), ref: 'ref1' },
        { id: 'token2', data: () => ({ email: 'user2@example.com', status: 'pending', expiresAt: { toDate: () => new Date(Date.now() - 120000) } }), ref: 'ref2' },
      ];

      // Mock the status query
      mockQuery.get.mockResolvedValue({
        empty: false,
        size: 2,
        docs: mockDocs,
      });

      const result = await cleanupExpiredRegistrations();

      expect(result).toBe(2);
      expect(mockFirestore.batch).toHaveBeenCalled();
      expect(mockBatch.delete).toHaveBeenCalledTimes(2);
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should return 0 when no expired registrations exist', async () => {
      const mockDocs = [
        { id: 'token1', data: () => ({ email: 'user1@example.com', status: 'pending', expiresAt: { toDate: () => new Date(Date.now() + 60000) } }), ref: 'ref1' },
      ];

      mockQuery.get.mockResolvedValue({
        empty: false,
        size: 1,
        docs: mockDocs,
      });

      const result = await cleanupExpiredRegistrations();

      expect(result).toBe(0);
    });

    it('should return 0 when no pending registrations exist', async () => {
      mockQuery.get.mockResolvedValue({
        empty: true,
        size: 0,
        docs: [],
      });

      const result = await cleanupExpiredRegistrations();

      expect(result).toBe(0);
      expect(mockBatch.delete).not.toHaveBeenCalled();
      expect(mockBatch.commit).not.toHaveBeenCalled();
    });
  });

  describe('hasPendingRegistration', () => {
    it('should return true when pending registration exists', async () => {
      mockQuery.get.mockResolvedValue({
        empty: false,
      });

      const result = await hasPendingRegistration('test@example.com');

      expect(result).toBe(true);
      expect(mockCollection.where).toHaveBeenCalledWith('email', '==', 'test@example.com');
      // Second where() is chained on mockQuery, not mockCollection
      expect(mockQuery.where).toHaveBeenCalledWith('status', '==', 'pending');
    });

    it('should return false when no pending registration exists', async () => {
      mockQuery.get.mockResolvedValue({
        empty: true,
      });

      const result = await hasPendingRegistration('test@example.com');

      expect(result).toBe(false);
    });
  });

  describe('cancelPendingRegistration', () => {
    it('should cancel pending registrations for email', async () => {
      const mockDocs = [
        { id: 'token1', ref: 'ref1' },
      ];

      mockQuery.get.mockResolvedValue({
        empty: false,
        docs: mockDocs,
      });

      await cancelPendingRegistration('test@example.com');

      expect(mockFirestore.batch).toHaveBeenCalled();
      expect(mockBatch.delete).toHaveBeenCalledWith('ref1');
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should do nothing when no pending registrations exist', async () => {
      mockQuery.get.mockResolvedValue({
        empty: true,
        docs: [],
      });

      await cancelPendingRegistration('test@example.com');

      expect(mockBatch.delete).not.toHaveBeenCalled();
      expect(mockBatch.commit).not.toHaveBeenCalled();
    });
  });
});
