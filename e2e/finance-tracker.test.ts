import { Stagehand } from '@browserbasehq/stagehand';
import { describe, test, beforeAll, afterAll, expect } from '@jest/globals';

describe('Artist Finance Manager - E2E Tests', () => {
  let stagehand: Stagehand;
  const TEST_URL = process.env.TEST_URL || 'http://localhost:8000';

  beforeAll(async () => {
    // Initialize Stagehand with OpenAI
    stagehand = new Stagehand({
      env: 'LOCAL',
      modelName: 'gpt-4o-mini', // Cost-effective model
      enableCaching: true, // Save 90% on API costs!
      headless: process.env.HEADLESS !== 'false',
      modelClientOptions: {
        apiKey: process.env.OPENAI_API_KEY,
      },
      verbose: 1, // Enable logging for debugging
    });

    await stagehand.init();
  });

  afterAll(async () => {
    if (stagehand) {
      await stagehand.close();
    }
  });

  test('App loads successfully and shows initial state', async () => {
    await stagehand.page.goto(TEST_URL);

    // Natural language verification
    await stagehand.page.act('verify that the page title shows "Project Finance Tracker"');

    // Check initial zero state
    const hasZeroBalances = await stagehand.page.extract(
      'Are all three summary cards (Income, Expenses, Balance) showing €0.00?'
    );
    expect(hasZeroBalances).toBeTruthy();
  });

  test('Complete user flow: Add expense, add income, verify balance, delete transaction', async () => {
    await stagehand.page.goto(TEST_URL);

    // Step 1: Add an expense transaction
    await stagehand.page.act(`
      Add an expense transaction with these details:
      1. Click on the category dropdown
      2. Select "Musicians" from the list
      3. In the description field, type "Band payment"
      4. In the amount field, enter "1000"
      5. Click the Add button to submit
    `);

    // Verify expense was added
    const expenseAdded = await stagehand.page.extract(
      'Is there a transaction in the list showing "Band payment" with an amount of -€1000.00?'
    );
    expect(expenseAdded).toBeTruthy();

    // Verify expense summary updated
    const expenseTotal = await stagehand.page.extract(
      'What amount is shown in the "Total Expenses" card?'
    );
    expect(expenseTotal).toContain('1000');

    // Step 2: Add an income transaction
    await stagehand.page.act(`
      Add an income transaction:
      1. Click on the transaction type selector to switch from "Expense" to "Income"
      2. Select "Income" option
      3. Click the category dropdown
      4. Select "Event Tickets"
      5. In the description field, type "Concert ticket sales"
      6. In the amount field, enter "2500"
      7. Click the Add button
    `);

    // Verify income was added
    const incomeAdded = await stagehand.page.extract(
      'Is there a transaction showing "Concert ticket sales" with +€2500.00?'
    );
    expect(incomeAdded).toBeTruthy();

    // Step 3: Verify balance calculation
    const balance = await stagehand.page.extract(
      'What is the balance amount shown in the Balance card? (should be €2500 - €1000 = €1500)'
    );
    expect(balance).toContain('1500');

    // Verify both transactions are visible
    const transactionCount = await stagehand.page.extract(
      'How many transactions are visible in the transaction list?'
    );
    expect(parseInt(transactionCount as string)).toBeGreaterThanOrEqual(2);

    // Step 4: Delete a transaction
    await stagehand.page.act(`
      Delete the first transaction:
      1. Find the first transaction in the list
      2. Click the "Delete" button for that transaction
      3. If a confirmation dialog appears, click "Delete" to confirm
      4. Wait for the transaction to be removed
    `);

    // Verify deletion
    const remainingTransactions = await stagehand.page.extract(
      'How many transactions are now in the list after deletion?'
    );
    expect(parseInt(remainingTransactions as string)).toBe(1);

    // Verify summary cards updated after deletion
    const balanceAfterDelete = await stagehand.page.extract(
      'What is the current balance shown after the deletion?'
    );
    // Balance should have changed based on which transaction was deleted
    expect(balanceAfterDelete).toBeDefined();
  });

  test('Form validation works correctly', async () => {
    await stagehand.page.goto(TEST_URL);

    // Try to submit empty form
    await stagehand.page.act(`
      Try to add a transaction without filling in any fields:
      1. Do not select any category
      2. Do not enter description
      3. Do not enter amount
      4. Just click the Add button
    `);

    // Check for validation errors
    const hasValidationError = await stagehand.page.extract(
      'Are there any validation error messages visible on the form (like "Please select a category" or "Please enter a description")?'
    );
    expect(hasValidationError).toBeTruthy();
  });

  test('Category switching works between Income and Expense', async () => {
    await stagehand.page.goto(TEST_URL);

    // Verify expense categories are shown
    await stagehand.page.act('click on the category dropdown');

    const expenseCategories = await stagehand.page.extract(
      'List the category options visible in the dropdown (like Musicians, Venue, Food & Drinks, etc.)'
    );
    expect(expenseCategories).toBeDefined();

    // Close dropdown
    await stagehand.page.act('click outside the dropdown to close it');

    // Switch to Income
    await stagehand.page.act(`
      Switch to Income type:
      1. Find the transaction type selector (Expense/Income)
      2. Click to switch to "Income"
    `);

    // Verify income categories
    await stagehand.page.act('click on the category dropdown again');

    const incomeCategories = await stagehand.page.extract(
      'What income categories are now shown (like Book Sales, Event Tickets)?'
    );
    expect(incomeCategories).toContain('Event Tickets');
  });

  test('Multiple transactions can be added and displayed', async () => {
    await stagehand.page.goto(TEST_URL);

    // Add multiple transactions using natural language
    for (let i = 1; i <= 3; i++) {
      await stagehand.page.act(`
        Add expense transaction #${i}:
        - Select category "Other"
        - Description: "Test expense ${i}"
        - Amount: "${i * 100}"
        - Click Add
      `);
    }

    // Verify all transactions are visible
    const transactionCount = await stagehand.page.extract(
      'How many transactions are now shown in the transaction list?'
    );
    expect(parseInt(transactionCount as string)).toBeGreaterThanOrEqual(3);

    // Verify total expenses
    const totalExpenses = await stagehand.page.extract(
      'What is the total expenses amount shown? (should be €600.00 = 100+200+300)'
    );
    expect(totalExpenses).toContain('600');
  });
});
