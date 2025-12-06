// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Art Finance Hub';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get balance => 'Balance';

  @override
  String get projects => 'Projects';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get loading => 'Loading';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get updateCurrency => 'Update Currency';

  @override
  String get changeCurrency => 'Change Currency';

  @override
  String get budgetGoal => 'Budget Goal';

  @override
  String get profileAndSettings => 'Profile & Settings';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get noTransactionsYet =>
      'No transactions yet. Add your first one above!';

  @override
  String get viewAnalytics => 'View Analytics';

  @override
  String get createProject => 'Create Project';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select category';

  @override
  String get expense => 'Expense';

  @override
  String get incomeType => 'Income';

  @override
  String get type => 'Type';

  @override
  String get venue => 'Venue';

  @override
  String get musicians => 'Musicians';

  @override
  String get foodAndDrinks => 'Food & Drinks';

  @override
  String get materialsClothes => 'Materials/Clothes';

  @override
  String get bookPrinting => 'Book Printing';

  @override
  String get podcast => 'Podcast';

  @override
  String get other => 'Other';

  @override
  String get bookSales => 'Book Sales';

  @override
  String get eventTickets => 'Event Tickets';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get deleteTransactionConfirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String get renameProject => 'Rename Project';

  @override
  String get rename => 'Rename';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String get deleteProjectConfirm =>
      'Are you sure you want to delete this project?';

  @override
  String get create => 'Create';

  @override
  String get createAccount => 'Create Account';

  @override
  String get sendSignInLink => 'Send Sign-In Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action cannot be undone. Are you sure you want to delete your account?';

  @override
  String get deleteAccountDetails => 'This will:';

  @override
  String get deleteAccountRemoveAccess => '• Remove access to your account';

  @override
  String get deleteAccountDeleteData => '• Permanently delete all your data';

  @override
  String get analyticsDashboard => 'Analytics Dashboard';

  @override
  String get analyzeGoal => 'Analyze Goal';

  @override
  String get changeCurrencyWarning =>
      'Changing currency will convert all transaction amounts.';

  @override
  String get accept => 'Accept';

  @override
  String get essentialOnly => 'Essential Only';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get createProjectToStart =>
      'Create a project to start\nmanaging your finances';

  @override
  String get projectName => 'Project Name';

  @override
  String get enterProjectName => 'Enter project name';

  @override
  String get projectNameTooLong =>
      'Project name must be at most 50 characters.';

  @override
  String get projectCreatedSuccess => 'Project \"\$name\" created';

  @override
  String get failedToCreateProject => 'Failed to create project: \$error';

  @override
  String get projectRenamedSuccess => 'Project renamed to \"\$name\"';

  @override
  String get failedToRenameProject => 'Failed to rename project: \$error';

  @override
  String get deleteProjectWarning =>
      'Are you sure you want to delete \"\$name\"?\n\nAll transactions for this project will be lost. This action cannot be undone.';

  @override
  String get projectDeletedSuccess => 'Project \"\$name\" deleted';

  @override
  String get failedToDeleteProject => 'Failed to delete project: \$error';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get addTransactionsToSeeAnalytics =>
      'Add some transactions to see analytics';

  @override
  String get failedToLoadUserPreferences => 'Failed to load user preferences';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get deleteAccountKeepData =>
      '• Keep your data for 90 days in case you change your mind';

  @override
  String get recoverAccountInfo =>
      'You can recover your account within 90 days by signing in again';

  @override
  String get failedToDeleteAccount => 'Failed to delete account';

  @override
  String get projectsExportedSuccess => 'Projects exported successfully';

  @override
  String get failedToExport => 'Failed to export';

  @override
  String get budgetGoalCleared => 'Budget goal cleared';

  @override
  String get budgetGoalSavedSuccess => 'Budget goal saved successfully';

  @override
  String get openaiApiKeyCleared => 'OpenAI API key cleared';

  @override
  String get openaiApiKeySavedSuccess => 'OpenAI API key saved successfully';

  @override
  String get failedToSaveApiKey => 'Failed to save API key';

  @override
  String get languageUpdatedTo => 'Language updated to';

  @override
  String get failedToUpdateLanguage => 'Failed to update language';

  @override
  String get currencyChangeDescription =>
      'will update the currency symbol displayed in the app.';

  @override
  String get currencyRateInfo =>
      'The conversion rate from the European Central Bank (via Frankfurter API) will be fetched and stored for your reference.';

  @override
  String get noteNoConvertExistingAmounts =>
      'Note: This does not convert existing transaction amounts';

  @override
  String get currencyUpdatedWithRate => 'Currency updated to';

  @override
  String get failedToUpdateCurrency => 'Failed to update currency';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get nameMinimumLength => 'Name must be at least 2 characters';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get memberSince => 'Member since';

  @override
  String get lastLogin => 'Last login';

  @override
  String get loginCount => 'Login count';

  @override
  String get privacyAndData => 'Privacy & Data';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsHelperText =>
      'Help improve the app by sharing anonymous usage data';

  @override
  String get analyticsEnabledThankYou => 'Analytics enabled - thank you!';

  @override
  String get analyticsDisabled => 'Analytics disabled';

  @override
  String get whatDataDoWeCollect => 'What data do we collect?';

  @override
  String get financialGoal => 'Financial Goal';

  @override
  String get financialGoalHint =>
      'e.g., I want to have a positive balance of 200€ per month';

  @override
  String get financialGoalHelper =>
      'Describe your financial goal in natural language';

  @override
  String get goalActive => 'Goal Active';

  @override
  String get goalActiveHelper => 'Activate goal to see analysis in dashboard';

  @override
  String get saveGoal => 'Save Goal';

  @override
  String get noBudgetGoalSet => 'No budget goal set';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get setBudgetGoal => 'Set Budget Goal';

  @override
  String get editBudgetGoal => 'Edit Budget Goal';

  @override
  String get openaiConfiguration => 'OpenAI Configuration';

  @override
  String get openaiApiKey => 'OpenAI API Key';

  @override
  String get openaiApiKeyPlaceholder => 'sk-...';

  @override
  String get openaiApiKeyHelper =>
      'Required for budget goal analysis. Get your key from platform.openai.com';

  @override
  String get openaiApiKeySecurityInfo =>
      'Your API key is stored locally and never shared. It\'s used only for analyzing your budget goals.';

  @override
  String get accountActions => 'Account Actions';

  @override
  String get exportToCSV => 'Export to CSV';

  @override
  String get changingFrom => 'Changing from';

  @override
  String get privacyAnalyticsTitle => 'Privacy & Analytics';

  @override
  String get privacyAnalyticsIntro =>
      'Help us improve the app by sharing anonymous analytics data.';

  @override
  String get privacyAnalyticsCollect => 'What we collect:';

  @override
  String get privacyCollectTransactions =>
      'Transaction events (add/delete/load)';

  @override
  String get privacyCollectPerformance =>
      'Performance metrics (load times, Web Vitals)';

  @override
  String get privacyCollectErrors => 'Error tracking';

  @override
  String get privacyCollectSessions => 'Session analytics';

  @override
  String get privacyAnalyticsNoCollect => "What we DON'T collect:";

  @override
  String get privacyNoCollectAmounts => 'Transaction amounts';

  @override
  String get privacyNoCollectDescriptions => 'Transaction descriptions';

  @override
  String get privacyNoCollectPersonal => 'Personal financial data';

  @override
  String get privacyChangeAnytime =>
      'You can change this preference anytime in Settings.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyCallout =>
      'Our Privacy Policy explains how we collect, use, and protect your data.\n\nKey points:\n• Analytics are disabled by default\n• We never track transaction amounts or descriptions\n• You control your privacy settings\n• You can delete your data anytime\n\nFor the full privacy policy, please visit our GitHub repository:\ngithub.com/aifraenkel/artist_finance_manager/blob/main/PRIVACY.md';

  @override
  String get close => 'Close';
}
