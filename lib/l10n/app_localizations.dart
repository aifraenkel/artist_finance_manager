import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Art Finance Hub'**
  String get appTitle;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @updateCurrency.
  ///
  /// In en, this message translates to:
  /// **'Update Currency'**
  String get updateCurrency;

  /// No description provided for @changeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change Currency'**
  String get changeCurrency;

  /// No description provided for @budgetGoal.
  ///
  /// In en, this message translates to:
  /// **'Budget Goal'**
  String get budgetGoal;

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileAndSettings;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Add your first one above!'**
  String get noTransactionsYet;

  /// No description provided for @viewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get viewAnalytics;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @incomeType.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeType;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venue;

  /// No description provided for @musicians.
  ///
  /// In en, this message translates to:
  /// **'Musicians'**
  String get musicians;

  /// No description provided for @foodAndDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food & Drinks'**
  String get foodAndDrinks;

  /// No description provided for @materialsClothes.
  ///
  /// In en, this message translates to:
  /// **'Materials/Clothes'**
  String get materialsClothes;

  /// No description provided for @bookPrinting.
  ///
  /// In en, this message translates to:
  /// **'Book Printing'**
  String get bookPrinting;

  /// No description provided for @podcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get podcast;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @bookSales.
  ///
  /// In en, this message translates to:
  /// **'Book Sales'**
  String get bookSales;

  /// No description provided for @eventTickets.
  ///
  /// In en, this message translates to:
  /// **'Event Tickets'**
  String get eventTickets;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get deleteTransactionConfirm;

  /// No description provided for @renameProject.
  ///
  /// In en, this message translates to:
  /// **'Rename Project'**
  String get renameProject;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project?'**
  String get deleteProjectConfirm;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @sendSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Send Sign-In Link'**
  String get sendSignInLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Are you sure you want to delete your account?'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'This will:'**
  String get deleteAccountDetails;

  /// No description provided for @deleteAccountRemoveAccess.
  ///
  /// In en, this message translates to:
  /// **'• Remove access to your account'**
  String get deleteAccountRemoveAccess;

  /// No description provided for @deleteAccountDeleteData.
  ///
  /// In en, this message translates to:
  /// **'• Permanently delete all your data'**
  String get deleteAccountDeleteData;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @analyzeGoal.
  ///
  /// In en, this message translates to:
  /// **'Analyze Goal'**
  String get analyzeGoal;

  /// No description provided for @changeCurrencyWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing currency will convert all transaction amounts.'**
  String get changeCurrencyWarning;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @essentialOnly.
  ///
  /// In en, this message translates to:
  /// **'Essential Only'**
  String get essentialOnly;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @createProjectToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a project to start\nmanaging your finances'**
  String get createProjectToStart;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @enterProjectName.
  ///
  /// In en, this message translates to:
  /// **'Enter project name'**
  String get enterProjectName;

  /// No description provided for @projectNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Project name must be at most 50 characters.'**
  String get projectNameTooLong;

  /// No description provided for @projectCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project \"\$name\" created'**
  String get projectCreatedSuccess;

  /// No description provided for @failedToCreateProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to create project: \$error'**
  String get failedToCreateProject;

  /// No description provided for @projectRenamedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project renamed to \"\$name\"'**
  String get projectRenamedSuccess;

  /// No description provided for @failedToRenameProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename project: \$error'**
  String get failedToRenameProject;

  /// No description provided for @deleteProjectWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"\$name\"?\n\nAll transactions for this project will be lost. This action cannot be undone.'**
  String get deleteProjectWarning;

  /// No description provided for @projectDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project \"\$name\" deleted'**
  String get projectDeletedSuccess;

  /// No description provided for @failedToDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete project: \$error'**
  String get failedToDeleteProject;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @addTransactionsToSeeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Add some transactions to see analytics'**
  String get addTransactionsToSeeAnalytics;

  /// No description provided for @failedToLoadUserPreferences.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user preferences'**
  String get failedToLoadUserPreferences;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @deleteAccountKeepData.
  ///
  /// In en, this message translates to:
  /// **'• Keep your data for 90 days in case you change your mind'**
  String get deleteAccountKeepData;

  /// No description provided for @recoverAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'You can recover your account within 90 days by signing in again'**
  String get recoverAccountInfo;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @projectsExportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Projects exported successfully'**
  String get projectsExportedSuccess;

  /// No description provided for @failedToExport.
  ///
  /// In en, this message translates to:
  /// **'Failed to export'**
  String get failedToExport;

  /// No description provided for @budgetGoalCleared.
  ///
  /// In en, this message translates to:
  /// **'Budget goal cleared'**
  String get budgetGoalCleared;

  /// No description provided for @budgetGoalSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Budget goal saved successfully'**
  String get budgetGoalSavedSuccess;

  /// No description provided for @openaiApiKeyCleared.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key cleared'**
  String get openaiApiKeyCleared;

  /// No description provided for @openaiApiKeySavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key saved successfully'**
  String get openaiApiKeySavedSuccess;

  /// No description provided for @failedToSaveApiKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to save API key'**
  String get failedToSaveApiKey;

  /// No description provided for @languageUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Language updated to'**
  String get languageUpdatedTo;

  /// No description provided for @failedToUpdateLanguage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update language'**
  String get failedToUpdateLanguage;

  /// No description provided for @currencyChangeDescription.
  ///
  /// In en, this message translates to:
  /// **'will update the currency symbol displayed in the app.'**
  String get currencyChangeDescription;

  /// No description provided for @currencyRateInfo.
  ///
  /// In en, this message translates to:
  /// **'The conversion rate from the European Central Bank (via Frankfurter API) will be fetched and stored for your reference.'**
  String get currencyRateInfo;

  /// No description provided for @noteNoConvertExistingAmounts.
  ///
  /// In en, this message translates to:
  /// **'Note: This does not convert existing transaction amounts'**
  String get noteNoConvertExistingAmounts;

  /// No description provided for @currencyUpdatedWithRate.
  ///
  /// In en, this message translates to:
  /// **'Currency updated to'**
  String get currencyUpdatedWithRate;

  /// No description provided for @failedToUpdateCurrency.
  ///
  /// In en, this message translates to:
  /// **'Failed to update currency'**
  String get failedToUpdateCurrency;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @nameMinimumLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinimumLength;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get lastLogin;

  /// No description provided for @loginCount.
  ///
  /// In en, this message translates to:
  /// **'Login count'**
  String get loginCount;

  /// No description provided for @privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndData;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsHelperText.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app by sharing anonymous usage data'**
  String get analyticsHelperText;

  /// No description provided for @analyticsEnabledThankYou.
  ///
  /// In en, this message translates to:
  /// **'Analytics enabled - thank you!'**
  String get analyticsEnabledThankYou;

  /// No description provided for @analyticsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Analytics disabled'**
  String get analyticsDisabled;

  /// No description provided for @whatDataDoWeCollect.
  ///
  /// In en, this message translates to:
  /// **'What data do we collect?'**
  String get whatDataDoWeCollect;

  /// No description provided for @financialGoal.
  ///
  /// In en, this message translates to:
  /// **'Financial Goal'**
  String get financialGoal;

  /// No description provided for @financialGoalHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., I want to have a positive balance of 200€ per month'**
  String get financialGoalHint;

  /// No description provided for @financialGoalHelper.
  ///
  /// In en, this message translates to:
  /// **'Describe your financial goal in natural language'**
  String get financialGoalHelper;

  /// No description provided for @goalActive.
  ///
  /// In en, this message translates to:
  /// **'Goal Active'**
  String get goalActive;

  /// No description provided for @goalActiveHelper.
  ///
  /// In en, this message translates to:
  /// **'Activate goal to see analysis in dashboard'**
  String get goalActiveHelper;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoal;

  /// No description provided for @noBudgetGoalSet.
  ///
  /// In en, this message translates to:
  /// **'No budget goal set'**
  String get noBudgetGoalSet;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @setBudgetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Budget Goal'**
  String get setBudgetGoal;

  /// No description provided for @editBudgetGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget Goal'**
  String get editBudgetGoal;

  /// No description provided for @openaiConfiguration.
  ///
  /// In en, this message translates to:
  /// **'OpenAI Configuration'**
  String get openaiConfiguration;

  /// No description provided for @openaiApiKey.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API Key'**
  String get openaiApiKey;

  /// No description provided for @openaiApiKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'sk-...'**
  String get openaiApiKeyPlaceholder;

  /// No description provided for @openaiApiKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'Required for budget goal analysis. Get your key from platform.openai.com'**
  String get openaiApiKeyHelper;

  /// No description provided for @openaiApiKeySecurityInfo.
  ///
  /// In en, this message translates to:
  /// **'Your API key is stored locally and never shared. It\'s used only for analyzing your budget goals.'**
  String get openaiApiKeySecurityInfo;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @exportToCSV.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCSV;

  /// No description provided for @changingFrom.
  ///
  /// In en, this message translates to:
  /// **'Changing from'**
  String get changingFrom;

  /// No description provided for @privacyAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Analytics'**
  String get privacyAnalyticsTitle;

  /// No description provided for @privacyAnalyticsIntro.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app by sharing anonymous analytics data.'**
  String get privacyAnalyticsIntro;

  /// No description provided for @privacyAnalyticsCollect.
  ///
  /// In en, this message translates to:
  /// **'What we collect:'**
  String get privacyAnalyticsCollect;

  /// No description provided for @privacyCollectTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transaction events (add/delete/load)'**
  String get privacyCollectTransactions;

  /// No description provided for @privacyCollectPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance metrics (load times, Web Vitals)'**
  String get privacyCollectPerformance;

  /// No description provided for @privacyCollectErrors.
  ///
  /// In en, this message translates to:
  /// **'Error tracking'**
  String get privacyCollectErrors;

  /// No description provided for @privacyCollectSessions.
  ///
  /// In en, this message translates to:
  /// **'Session analytics'**
  String get privacyCollectSessions;

  /// No description provided for @privacyAnalyticsNoCollect.
  ///
  /// In en, this message translates to:
  /// **'What we DON\'T collect:'**
  String get privacyAnalyticsNoCollect;

  /// No description provided for @privacyNoCollectAmounts.
  ///
  /// In en, this message translates to:
  /// **'Transaction amounts'**
  String get privacyNoCollectAmounts;

  /// No description provided for @privacyNoCollectDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Transaction descriptions'**
  String get privacyNoCollectDescriptions;

  /// No description provided for @privacyNoCollectPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal financial data'**
  String get privacyNoCollectPersonal;

  /// No description provided for @privacyChangeAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change this preference anytime in Settings.'**
  String get privacyChangeAnytime;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyCallout.
  ///
  /// In en, this message translates to:
  /// **'Our Privacy Policy explains how we collect, use, and protect your data.\n\nKey points:\n• Analytics are disabled by default\n• We never track transaction amounts or descriptions\n• You control your privacy settings\n• You can delete your data anytime\n\nFor the full privacy policy, please visit our GitHub repository:\ngithub.com/aifraenkel/artist_finance_manager/blob/main/PRIVACY.md'**
  String get privacyPolicyCallout;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @financialGoalWizard.
  ///
  /// In en, this message translates to:
  /// **'Financial Goal Wizard'**
  String get financialGoalWizard;

  /// No description provided for @setYourFinancialGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Your Financial Goal'**
  String get setYourFinancialGoal;

  /// No description provided for @goalDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your financial goal'**
  String get goalDescription;

  /// No description provided for @goalDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What would you like to achieve?'**
  String get goalDescriptionHint;

  /// No description provided for @goalDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Be specific about what you want to achieve, how much, and by when'**
  String get goalDescriptionHelper;

  /// No description provided for @charactersRemaining.
  ///
  /// In en, this message translates to:
  /// **'characters remaining'**
  String get charactersRemaining;

  /// No description provided for @goalTooLong.
  ///
  /// In en, this message translates to:
  /// **'Goal must be at most 2000 characters'**
  String get goalTooLong;

  /// No description provided for @goalRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe your financial goal'**
  String get goalRequired;

  /// No description provided for @inspiration.
  ///
  /// In en, this message translates to:
  /// **'Need inspiration? Here are some examples:'**
  String get inspiration;

  /// No description provided for @exampleGoal1.
  ///
  /// In en, this message translates to:
  /// **'Save \$5,000 for professional recording equipment to produce my debut album by December'**
  String get exampleGoal1;

  /// No description provided for @exampleGoal2.
  ///
  /// In en, this message translates to:
  /// **'Increase my monthly income from live performances to \$3,000 to quit my day job'**
  String get exampleGoal2;

  /// No description provided for @exampleGoal3.
  ///
  /// In en, this message translates to:
  /// **'Build an emergency fund of \$2,000 from art sales to cover 3 months of studio rent'**
  String get exampleGoal3;

  /// No description provided for @exampleGoal4.
  ///
  /// In en, this message translates to:
  /// **'Earn \$10,000 from poetry book sales and performance fees to fund a national tour'**
  String get exampleGoal4;

  /// No description provided for @exampleGoal5.
  ///
  /// In en, this message translates to:
  /// **'Generate \$1,500/month passive income from prints and merchandise to focus on new collections'**
  String get exampleGoal5;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @timelineAndNotifications.
  ///
  /// In en, this message translates to:
  /// **'Timeline & Notifications'**
  String get timelineAndNotifications;

  /// No description provided for @whenDoYouWantToAchieveThis.
  ///
  /// In en, this message translates to:
  /// **'When do you want to achieve this goal?'**
  String get whenDoYouWantToAchieveThis;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get selectDueDate;

  /// No description provided for @dueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a due date'**
  String get dueDateRequired;

  /// No description provided for @dueDateMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Due date must be in the future'**
  String get dueDateMustBeFuture;

  /// No description provided for @howOftenEmailUpdates.
  ///
  /// In en, this message translates to:
  /// **'How often would you like email updates?'**
  String get howOftenEmailUpdates;

  /// No description provided for @emailCadenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get emailCadenceDaily;

  /// No description provided for @emailCadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get emailCadenceWeekly;

  /// No description provided for @emailCadenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every two weeks'**
  String get emailCadenceBiweekly;

  /// No description provided for @emailCadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get emailCadenceMonthly;

  /// No description provided for @emailCadenceNever.
  ///
  /// In en, this message translates to:
  /// **'Never (dashboard only)'**
  String get emailCadenceNever;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @yourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your Goal'**
  String get yourGoal;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @emailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Email Updates'**
  String get emailUpdates;

  /// No description provided for @generatingAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Generating your personalized acknowledgment...'**
  String get generatingAcknowledgment;

  /// No description provided for @failedToGenerateAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate acknowledgment. Your goal has been saved.'**
  String get failedToGenerateAcknowledgment;

  /// No description provided for @goalSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Financial goal saved successfully!'**
  String get goalSavedSuccessfully;

  /// No description provided for @failedToSaveGoal.
  ///
  /// In en, this message translates to:
  /// **'Failed to save financial goal'**
  String get failedToSaveGoal;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @setFinancialGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Financial Goal'**
  String get setFinancialGoal;

  /// No description provided for @noFinancialGoalSet.
  ///
  /// In en, this message translates to:
  /// **'No financial goal set'**
  String get noFinancialGoalSet;

  /// No description provided for @setAGoalToTrackProgress.
  ///
  /// In en, this message translates to:
  /// **'Set a financial goal to track your progress and get personalized insights'**
  String get setAGoalToTrackProgress;

  /// No description provided for @openGoalWizard.
  ///
  /// In en, this message translates to:
  /// **'Set Your Goal'**
  String get openGoalWizard;

  /// No description provided for @goalBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to take control of your financial future?'**
  String get goalBannerTitle;

  /// No description provided for @goalBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a meaningful financial goal and get personalized insights to help you achieve it'**
  String get goalBannerDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
