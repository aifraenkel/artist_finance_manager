# Budget Planning Feature

## Overview

The Budget Planning feature helps artists set financial goals and track progress against those goals using AI-powered analysis. This feature integrates with OpenAI's GPT models to provide personalized insights based on your actual financial data.

## Features

### 1. Setting a Budget Goal

Users can set a financial goal in natural language through the Profile & Settings screen:

- Navigate to **Profile & Settings** (tap your profile icon)
- Scroll to the **Budget Goal** section
- Click **Set Budget Goal** or **Edit Budget Goal**
- Enter your goal in plain language, for example:
  - "I want to have a positive balance of 200€ per month"
  - "Save at least €500 per month from my art projects"
  - "Maintain a 60% profit margin across all projects"
- Toggle **Goal Active** to enable/disable goal tracking
- Click **Save Goal**

### 2. OpenAI API Configuration

To use the budget analysis feature, you need an OpenAI API key:

1. Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. In **Profile & Settings**, scroll to **OpenAI Configuration**
3. Enter your API key (it's stored locally and securely)
4. The key is saved automatically as you type

**Security Note**: Your API key is stored only on your device and is never shared or transmitted to any server except OpenAI's API.

### 3. Viewing Goal Analysis

Once your goal is active and you have configured your OpenAI API key:

1. Open the **Analytics Dashboard** from the project drawer
2. If your goal is active, you'll see a **Budget Goal Analysis** section at the top
3. The analysis includes:
   - Your stated goal (displayed in a highlighted box)
   - AI-generated assessment of your progress
   - Key metrics relevant to your goal
   - Actionable suggestions if you're not meeting your goal

### 4. Analysis Process

When you open the Analytics Dashboard with an active goal:

1. **Data Export**: The app exports all your project data (income, expenses, transactions)
2. **Prompt Building**: A structured prompt is created with:
   - Your financial goal
   - Overall financial summary (total income, expenses, balance)
   - Per-project breakdown
   - Monthly averages (if applicable)
3. **AI Analysis**: The prompt is sent to OpenAI's GPT-3.5-turbo model
4. **Result Display**: The analysis is shown in the dashboard

The analysis typically takes 2-5 seconds and shows a loading animation while processing.

## Error Handling

The feature includes comprehensive error handling:

- **No API Key**: Shows "OpenAI API key not set" message
- **Invalid API Key**: Shows "Invalid OpenAI API key" error
- **Rate Limiting**: Shows "API rate limit exceeded" message with retry suggestion
- **Network Errors**: Shows descriptive network error messages
- **No Data**: If you have no projects or transactions, suggests adding data first

All errors are logged for debugging purposes.

## Privacy & Security

### Data Privacy

- Your financial data (transaction amounts and descriptions) is **only** sent to OpenAI's API for analysis
- OpenAI's data usage policy: https://openai.com/policies/api-data-usage-policies
- As of March 2023, OpenAI does not use API data to train their models
- Your data is not stored on any intermediate servers

### API Key Security

- API keys are stored in local device storage only
- Keys are never transmitted to any server except OpenAI
- Keys are stored in encrypted SharedPreferences (on mobile) or localStorage (on web)
- You can clear your API key at any time from Profile & Settings

## Cost Considerations

- The feature uses OpenAI's GPT-3.5-turbo model
- Each analysis costs approximately $0.001-0.003 (less than a penny)
- Analysis is only performed when you open the Analytics Dashboard
- You can disable the goal to prevent automatic analysis
- Monitor your OpenAI usage at https://platform.openai.com/usage

## Technical Details

### Architecture

The budget planning feature follows SOLID principles and TDD:

- **BudgetGoal** model: Stores goal text, active status, and timestamps
- **UserPreferences** service: Manages goal and API key storage
- **OpenAIService**: Handles API communication with error handling
- **BudgetAnalysisService**: Exports data, builds prompts, and orchestrates analysis
- **Dashboard/Profile UI**: Clean separation of concerns with loading states

### Testing

Comprehensive test coverage includes:

- Unit tests for BudgetGoal model
- Unit tests for OpenAIService
- Unit tests for BudgetAnalysisService with mock data
- Integration tests for UserPreferences
- All tests follow existing patterns in the codebase

### Prompt Structure

The AI analysis prompt includes:

1. **System Message**: Sets context as a financial advisor for artists
2. **User Message** containing:
   - User's stated goal
   - Overall financial summary
   - Per-project breakdown
   - Monthly averages (when applicable)
3. **Instructions**: Asks for 3-5 sentence analysis with actionable suggestions

### API Configuration

- **Model**: GPT-3.5-turbo (fast and cost-effective)
- **Max Tokens**: 500 (sufficient for concise analysis)
- **Temperature**: 0.7 (balanced creativity and consistency)
- **Timeout**: Standard HTTP timeout with error handling

## Usage Examples

### Example 1: Monthly Savings Goal

**Goal**: "I want to save at least €200 per month"

**Sample Analysis**:
> Based on your current financial data, you are meeting your monthly savings goal. Your average monthly balance is €245, which exceeds your target of €200. Your income from Event tickets and Book sales is consistent, while expenses remain controlled. Continue tracking your largest expense categories to maintain this positive trend.

### Example 2: Profit Margin Goal

**Goal**: "Maintain a 50% profit margin on all art projects"

**Sample Analysis**:
> Your overall profit margin is currently 42%, slightly below your 50% target. The "Art Show" project has a strong 58% margin, but "Book Project" is at 35% due to high printing costs. Consider reviewing your pricing for book sales or exploring more cost-effective printing options to improve your overall margin.

### Example 3: Break-Even Goal

**Goal**: "I want to break even across all projects by end of quarter"

**Sample Analysis**:
> You are making excellent progress toward breaking even. Your current balance is €-150, a significant improvement from earlier in the quarter. With two active projects showing positive cash flow, you are on track to reach your goal. Focus on completing pending income from the "Art Show" project to close the gap.

## Troubleshooting

### Analysis not showing

- Verify your goal is set to **Active** in Profile & Settings
- Ensure you have entered a valid OpenAI API key
- Check that you have at least one project with transactions
- Try refreshing the dashboard by reopening it

### "OpenAI API key not set" error

- Go to Profile & Settings > OpenAI Configuration
- Enter your API key from https://platform.openai.com/api-keys
- The key should start with "sk-"

### "Invalid OpenAI API key" error

- Verify your API key is correct
- Check that your OpenAI account has API access enabled
- Ensure you have sufficient credits/billing set up in your OpenAI account

### Rate limit errors

- Wait a few moments and try again
- OpenAI has rate limits based on your account tier
- Consider upgrading your OpenAI account if you use the feature frequently

## Best Practices

1. **Set Specific Goals**: Be clear and measurable
   - ✓ "Save €200 per month"
   - ✗ "Make more money"

2. **Review Regularly**: Check your progress weekly or bi-weekly

3. **Update Goals**: Adjust your goal as your business evolves

4. **Protect Your API Key**: Never share your key publicly

5. **Monitor Costs**: Keep an eye on your OpenAI usage

## Future Enhancements

Potential improvements being considered:

- Historical goal tracking and progress charts
- Multiple goals with different time horizons
- Goal templates for common scenarios
- Automated email reports on goal progress
- Integration with additional AI models
- Offline analysis mode using local models

## Support

If you encounter issues:

1. Check the error message displayed in the dashboard
2. Verify your OpenAI API key is valid
3. Review the troubleshooting section above
4. Check GitHub issues for known problems
5. File a new issue with details about the error

---

Built with ❤️ for artists everywhere
