# GitHub Repository Secrets Setup Guide

This guide will help you configure all the necessary secrets in your GitHub repository for the CI/CD pipeline to function properly.

## 🔐 How to Add Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add the secret name and value
6. Click **Add secret**

## 📋 Required Secrets

### 🔥 Firebase Configuration (Development Environment)

These secrets are for your development/staging Firebase project:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `FIREBASE_API_KEY_DEV` | Firebase Web API Key (Development) | `AIzaSyC9k8B7X...` |
| `FIREBASE_AUTH_DOMAIN_DEV` | Firebase Auth Domain (Development) | `your-project-dev.firebaseapp.com` |
| `FIREBASE_PROJECT_ID_DEV` | Firebase Project ID (Development) | `your-project-dev` |
| `FIREBASE_STORAGE_BUCKET_DEV` | Firebase Storage Bucket (Development) | `your-project-dev.appspot.com` |
| `FIREBASE_MESSAGING_SENDER_ID_DEV` | Firebase Messaging Sender ID (Development) | `123456789012` |
| `FIREBASE_APP_ID_DEV` | Firebase App ID (Development) | `1:123456789012:web:abcdef123456` |
| `FIREBASE_MEASUREMENT_ID_DEV` | Firebase Analytics Measurement ID (Development) | `G-ABCDEF1234` |

### 🔥 Firebase Configuration (Production Environment)

These secrets are for your production Firebase project:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `FIREBASE_API_KEY_PROD` | Firebase Web API Key (Production) | `AIzaSyD1k8C7Y...` |
| `FIREBASE_AUTH_DOMAIN_PROD` | Firebase Auth Domain (Production) | `your-project-prod.firebaseapp.com` |
| `FIREBASE_PROJECT_ID_PROD` | Firebase Project ID (Production) | `your-project-prod` |
| `FIREBASE_STORAGE_BUCKET_PROD` | Firebase Storage Bucket (Production) | `your-project-prod.appspot.com` |
| `FIREBASE_MESSAGING_SENDER_ID_PROD` | Firebase Messaging Sender ID (Production) | `987654321098` |
| `FIREBASE_APP_ID_PROD` | Firebase App ID (Production) | `1:987654321098:web:fedcba654321` |
| `FIREBASE_MEASUREMENT_ID_PROD` | Firebase Analytics Measurement ID (Production) | `G-FEDCBA9876` |

### 🔧 API Configuration

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `BRAILLE_API_URL_DEV` | Braille API Base URL (Development) | `http://localhost:5000` or `https://api-dev.example.com` |
| `BRAILLE_API_URL_PROD` | Braille API Base URL (Production) | `https://api.your-domain.com` |

### 🔑 Firebase CLI Authentication

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `FIREBASE_TOKEN` | Firebase CI Token | Run `firebase login:ci` in terminal | 1//091luka1zLQsgCgYIARAAGAkSNgF-L9Ire42HibdOv8AFqVNnWi1n9kOdaq_57EgwKtygTlxb7rwFUih6EC3cBpcnsQyNanj3Mw

### 📱 Android App Signing

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded keystore file | ✅ SET - Generated from my-release-key.keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Password you set when creating keystore |
| `ANDROID_KEY_ALIAS` | Key alias name | ✅ SET - "my-key-alias" |
| `ANDROID_KEY_PASSWORD` | Key password | Password you set for the key |

### 🛡️ Optional Security Tools

| Secret Name | Description | Purpose |
|-------------|-------------|---------|
| `SEMGREP_APP_TOKEN` | Semgrep security scanning token | Enhanced security analysis |
| `CODECOV_TOKEN` | Codecov upload token | Code coverage reporting |

## 🔥 Firebase Setup Instructions

### 1. Create Firebase Projects

You need **two separate Firebase projects**:
- One for development/staging
- One for production

### 2. Get Firebase Configuration

For each project:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon → **Project settings**
4. Scroll down to **Your apps** section
5. Click on your web app or **Add app** if none exists
6. Copy the configuration values from the Firebase SDK snippet

### 3. Generate Firebase CI Token

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login and generate CI token
firebase login:ci
```

This will output a token that you should add as `FIREBASE_TOKEN` secret.

## 📱 Android Keystore Setup

### 1. Generate Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

When prompted, enter:
- Keystore password (save this as `ANDROID_KEYSTORE_PASSWORD`)
- Key password (save this as `ANDROID_KEY_PASSWORD`) 
- Your information (name, organization, etc.)
- Use "release" as alias (save this as `ANDROID_KEY_ALIAS`)

### 2. Convert Keystore to Base64

**On Windows:**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release-key.jks")) | Out-File keystore.base64
```

**On macOS/Linux:**
```bash
base64 -i release-key.jks -o keystore.base64
```

### 3. Add Base64 Content to Secret

Copy the entire content of `keystore.base64` file and add it as `ANDROID_KEYSTORE_BASE64` secret.

## ✅ Verification Checklist

After adding all secrets, verify:

- [ ] All Firebase configuration secrets added for both dev and prod
- [ ] Firebase CLI token added and tested
- [ ] Android keystore secrets added (if building Android)
- [ ] API URL secrets configured
- [ ] All secret names match exactly (case-sensitive)
- [ ] No trailing spaces in secret values
- [ ] Production and development configs are different

## 🔍 Testing Your Configuration

### 1. Test Firebase Token

```bash
firebase projects:list --token "YOUR_FIREBASE_TOKEN"
```

### 2. Test Android Keystore

```bash
# Test keystore validity
keytool -list -v -keystore release-key.jks -alias release
```

### 3. Run CI/CD Pipeline

1. Push a commit to `main` branch
2. Check GitHub Actions tab for workflow execution
3. Review logs for any authentication or configuration issues

## 🛡️ Security Best Practices

### Secrets Security
- **Never commit secrets** to your repository
- **Rotate secrets regularly** (quarterly recommended)
- **Use least privilege principle** for service accounts
- **Monitor secret usage** in GitHub Actions logs

### Firebase Security
- **Enable App Check** for production
- **Set up security rules** properly
- **Use different projects** for dev/prod
- **Monitor Firebase Console** for suspicious activity

### Android Security
- **Store keystore safely** (encrypted backup)
- **Use strong passwords** for keystore and keys
- **Don't share keystore files** via insecure channels
- **Consider using Google Play App Signing**

## 🚨 Troubleshooting

### Common Issues

1. **"Invalid token" errors**
   - Regenerate Firebase token: `firebase login:ci`
   - Check token has proper permissions

2. **Android signing failures**
   - Verify base64 encoding doesn't have line breaks
   - Check keystore password is correct
   - Ensure alias name matches

3. **Firebase deployment failures**
   - Verify project IDs are correct
   - Check Firebase CLI has proper permissions
   - Ensure security rules are valid

4. **Environment variable not found**
   - Check secret names match exactly
   - Verify secrets are set in correct repository
   - Ensure branch protection allows secrets access

### Getting Help

If you encounter issues:
1. Check GitHub Actions logs for detailed error messages
2. Verify all secrets are properly configured
3. Test configurations locally when possible
4. Review Firebase Console for any project-level issues

## 📞 Support Commands

```bash
# Check Firebase projects
firebase projects:list

# Test Firebase authentication
firebase login:list

# Validate Android keystore
keytool -list -keystore release-key.jks

# Test Flutter build with environment variables
flutter build web --dart-define=PRODUCTION=true

# Check GitHub CLI (if available)
gh secret list
```

---

## 🔄 Next Steps

After setting up all secrets:

1. ✅ Test the CI/CD pipeline with a small commit
2. ✅ Verify deployments work correctly
3. ✅ Set up branch protection rules
4. ✅ Configure notification preferences
5. ✅ Document your specific configuration for team members

Remember to keep this information secure and only share with authorized team members!
