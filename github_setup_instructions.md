# GitHub Repository Setup Instructions

## Step 1: Create GitHub Repository
1. Go to https://github.com/new
2. Repository name: `gnos-braille-system`
3. Description: "Gnos Braille System - Accessible Braille translation app with Firebase integration"
4. Make it **Public**
5. **Don't initialize** with README, .gitignore, or license

## Step 2: Connect Local Repository
After creating the repository, run these commands in your terminal:

```powershell
# Replace 'YOUR_GITHUB_USERNAME' with your actual GitHub username
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/gnos-braille-system.git
git branch -M main
git push -u origin main
```

## Step 3: Set Up GitHub Secrets
After pushing to GitHub, run:
```powershell
./setup-github-secrets.bat
```

## Step 4: Validate Secrets
Go to your GitHub repository and trigger the "Validate Secrets" workflow:
- Go to Actions tab
- Click "Validate Secrets" workflow
- Click "Run workflow"

## Required Secrets for Full Functionality

### Firebase Secrets
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_WEB_API_KEY` - Firebase web API key
- `FIREBASE_MESSAGING_SENDER_ID` - Firebase messaging sender ID
- `FIREBASE_APP_ID` - Firebase app ID
- `FIREBASE_SERVICE_ACCOUNT_KEY` - Firebase service account JSON (base64 encoded)

### Android Secrets
- `ANDROID_KEYSTORE_BASE64` - Your Android keystore file (base64 encoded)
- `ANDROID_KEYSTORE_PROPERTIES` - Keystore properties content
- `ANDROID_KEY_ALIAS` - Key alias name
- `ANDROID_KEY_PASSWORD` - Key password
- `ANDROID_STORE_PASSWORD` - Keystore password

### API Secrets
- `BRAILLE_API_KEY` - API key for Braille service
- `ENCRYPTION_KEY` - Encryption key for secure data

### Optional (for enhanced features)
- `SLACK_WEBHOOK_URL` - For deployment notifications
- `TEAMS_WEBHOOK_URL` - For Microsoft Teams notifications

## Notes
- The workflow will validate all secrets are present and properly formatted
- Some secrets will be tested for connectivity (Firebase, API endpoints)
- Missing secrets will be reported with instructions on how to obtain them
