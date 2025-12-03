# CSV Export Feature

## Overview
Users can now export all their projects and transactions to a CSV file from the Profile screen.

## User Interface Changes

### Profile Screen - Export Button
The "Export to CSV" button has been added to the Account Actions section in the Profile screen, positioned above the "Sign Out" and "Delete Account" buttons.

**Location**: Profile & Settings → Account Actions → Export to CSV

**Button Features**:
- Icon: Download icon (⬇️)
- Label: "Export to CSV"
- Shows a progress indicator while exporting
- Disabled during export operation to prevent duplicate requests

## Functionality

### Export Process
1. User clicks "Export to CSV" button
2. Button shows loading indicator
3. System fetches all active projects
4. For each project, loads all associated transactions
5. Generates CSV file with the following columns:
   - Project name
   - Type (Income/Expense)
   - Category
   - Description
   - Amount (formatted to 2 decimal places)
   - Datetime (YYYY-MM-DD HH:MM:SS format)
6. Downloads CSV file to user's device
7. Shows success message

### File Naming
Files are named with a timestamp to avoid conflicts:
- Format: `art_finance_hub_export_YYYY-MM-DD_HHMMSS.csv`
- Example: `art_finance_hub_export_2024-12-03_143025.csv`

### Error Handling
- If export fails, user sees an error message
- Button re-enables for retry
- No partial files are created

## Technical Implementation

### New Services
1. **ExportService** (`lib/services/export_service.dart`)
   - Fetches all projects and transactions
   - Formats data as CSV
   - Uses the `csv` package for proper CSV encoding

2. **File Download Services** (platform-specific)
   - `file_download.dart` - Platform-agnostic interface
   - `file_download_web.dart` - Web implementation using browser download API
   - `file_download_stub.dart` - Stub for non-web platforms

### Dependencies Added
- `csv: ^6.0.0` - For CSV generation and proper escaping

### Tests
- Comprehensive tests in `test/services/export_service_test.dart`
- Tests cover:
  - Empty data export
  - Single project export
  - Multiple projects export
  - Data formatting (amounts, dates, types)
  - Special character handling in CSV

## Usage Instructions

Users can export their data by:
1. Opening Profile & Settings (tap profile icon)
2. Scrolling to Account Actions section
3. Clicking "Export to CSV"
4. Waiting for the progress indicator
5. CSV file downloads automatically

The exported file can be opened in Excel, Google Sheets, or any CSV-compatible application for further analysis or backup.
