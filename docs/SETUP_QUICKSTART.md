# Firebase Authentication Setup - Quick Start

## 🚀 One-Command Setup (Automated)

Run this single command to set up everything automatically:

```bash
./scripts/setup_all.sh
```

This script will:
- ✅ Enable all required Firebase APIs
- ✅ Create and configure Firestore database
- ✅ Deploy Firestore security rules
- ✅ Create Firebase web app
- ✅ Fetch and configure Firebase credentials
- ✅ Enable email authentication
- ✅ Install Flutter dependencies
- ✅ Optionally deploy Cloud Functions
- ✅ Run tests and analysis

**Estimated time:** 5-10 minutes

---

## 📋 What Gets Automated

### Fully Automated (No Manual Steps)
1. ✅ **Firebase APIs** - Automatically enabled
2. ✅ **Firestore Database** - Automatically created
3. ✅ **Firestore Rules** - Automatically deployed
4. ✅ **Firestore Indexes** - Automatically configured
5. ✅ **Firebase Web App** - Automatically created
6. ✅ **Firebase Configuration** - Automatically fetched and updated in code
7. ✅ **Email Authentication** - Automatically enabled
8. ✅ **Cloud Functions** - Optionally deployed
9. ✅ **Flutter Dependencies** - Automatically installed

### Requires Manual Verification (Quick Check)
1. 🔍 **Firebase Console** - Verify email link authentication is enabled
2. 🔍 **Authorized Domains** - Add your Cloud Run URL (if not automatically added)
3. 🔍 **Email Service** - Optional: Configure SendGrid/Mailgun for production emails

---

## 🛠️ Manual Setup (Step-by-Step)

If you prefer to run each step individually:

### 1. Firebase Infrastructure Setup
```bash
./scripts/setup_firebase_complete.sh
```
**What it does:** Creates Firebase project infrastructure, configures Firestore, and sets up authentication.

### 2. Deploy Cloud Functions (Optional)
```bash
./scripts/deploy_functions.sh
```
**What it does:** Deploys email notification functions and cleanup scheduler.

### 3. Install Flutter Dependencies
```bash
flutter pub get
```

### 4. Verify Configuration
```bash
cat lib/firebase_options.dart
```
Ensure all values are populated (not placeholders).

---

## ✅ Post-Setup Verification Checklist

After running the automated setup, verify these settings in Firebase Console:

### Firebase Console Checks
Visit: https://console.firebase.google.com/project/artist-manager-479514

1. **Authentication > Sign-in method**
   - [ ] Email/Password: Enabled ✓
   - [ ] Email link (passwordless sign-in): Enabled ✓

2. **Authentication > Settings**
   - [ ] Authorized domains includes:
     - `localhost` ✓
     - Your Cloud Run domain ✓
     - `artist-manager-479514.firebaseapp.com` ✓

3. **Firestore Database**
   - [ ] Database created in us-central1 ✓
   - [ ] Security rules deployed ✓

---

## 🧪 Testing Your Setup

### Local Testing
```bash
# Run the app locally
flutter run -d chrome

# Try the following:
# 1. Click "Create Account"
# 2. Enter name and email
# 3. Check your email for the sign-in link
# 4. Click the link to complete registration
# 5. Test profile settings and logout
```

### Deploy and Test Production
```bash
# Deploy to Cloud Run
./scripts/deploy.sh

# Visit your deployed app
# URL will be shown after deployment
```

---

## 🔧 Troubleshooting

### Issue: "Firebase configuration not found"
**Solution:**
```bash
# Re-fetch Firebase config
./scripts/get_firebase_config.sh

# Or manually update lib/firebase_options.dart from Firebase Console
```

### Issue: "Email links not working"
**Solution:**
1. Check authorized domains in Firebase Console
2. Ensure your domain is added to: Authentication > Settings > Authorized domains
3. Clear browser cache and try again

### Issue: "Firestore permission denied"
**Solution:**
```bash
# Redeploy Firestore rules
firebase deploy --only firestore:rules --project=artist-manager-479514
```

### Issue: "Cloud Functions not deploying"
**Solution:**
```bash
# Check if APIs are enabled
gcloud services list --enabled --project=artist-manager-479514 | grep functions

# Enable if needed
gcloud services enable cloudfunctions.googleapis.com --project=artist-manager-479514
```

---

## 📚 Additional Resources

- **Full Setup Guide:** [AUTH_SETUP.md](AUTH_SETUP.md)
- **Firebase Console:** https://console.firebase.google.com/project/artist-manager-479514
- **GCP Console:** https://console.cloud.google.com/home/dashboard?project=artist-manager-479514

---

## 🎯 Quick Commands Reference

```bash
# Complete automated setup
./scripts/setup_all.sh

# Individual setup scripts
./scripts/setup_firebase_complete.sh  # Firebase infrastructure
./scripts/deploy_functions.sh         # Cloud Functions
./scripts/get_firebase_config.sh      # Fetch Firebase config

# Development
flutter run -d chrome                 # Run locally
flutter test                          # Run tests
flutter analyze                       # Check for issues

# Deployment
./scripts/deploy.sh                   # Deploy to Cloud Run

# Firebase CLI commands (if needed)
firebase login                        # Login to Firebase
firebase deploy --only firestore      # Deploy rules only
firebase deploy --only functions      # Deploy functions only
```

---

## 💡 What Happens Behind the Scenes

When you run `./scripts/setup_all.sh`:

1. **Checks prerequisites** - Verifies gcloud, flutter, npm are installed
2. **Enables Firebase APIs** - Activates 6+ required Google Cloud APIs
3. **Creates Firestore database** - Sets up database in us-central1
4. **Generates security rules** - Creates firestore.rules with user-level access control
5. **Creates Firebase web app** - Registers your app with Firebase
6. **Fetches configuration** - Gets API keys and config via REST API
7. **Updates code** - Writes configuration to lib/firebase_options.dart
8. **Enables authentication** - Activates email/password and email link auth
9. **Sets up Cloud Functions** - Deploys notification and cleanup functions
10. **Creates Cloud Scheduler** - Sets up daily cleanup job
11. **Installs dependencies** - Runs flutter pub get
12. **Runs tests** - Verifies everything works

---

## ⚠️ Important Notes

### Security
- The `.grafana_settings` file contains credentials and is gitignored
- Firebase API keys in `firebase_options.dart` are safe to commit (they're restricted by authorized domains)
- Firestore security rules protect all user data at the database level

### Costs
- Firebase free tier covers most development needs
- Cloud Functions: First 2M invocations/month free
- Firestore: 50K reads, 20K writes/day free
- Authentication: 10K verifications/month free

### Production Readiness
Before going to production:
1. Configure a real email service (SendGrid/Mailgun/SES)
2. Set up monitoring and alerts
3. Review and test security rules
4. Set up backup and recovery procedures
5. Configure custom domain for email links

---

## 🎉 You're Done!

Once setup is complete, you'll have:
- ✅ Fully functional email link authentication
- ✅ User registration and profile management
- ✅ Secure Firestore database with rules
- ✅ Cloud Functions for notifications
- ✅ Automated account cleanup
- ✅ Production-ready authentication system

**Happy coding! 🚀**
