# 🚀 Automated Publishing Guide

This guide covers the complete automated publishing setup for Gnos Braille System.

## 📋 Prerequisites

### 1. GitHub Secrets Configuration

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

#### Android Publishing
```
ANDROID_KEYSTORE_BASE64        # Base64 encoded keystore file
ANDROID_KEYSTORE_PASSWORD      # Keystore password
ANDROID_KEY_PASSWORD           # Key password
ANDROID_KEY_ALIAS              # Key alias (usually "upload" or "release")
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON # Google Play Console service account JSON
```

#### Firebase Deployment
```
FIREBASE_TOKEN                 # Firebase CI token
FIREBASE_PROJECT_ID_PROD       # Production Firebase project ID
FIREBASE_PROJECT_ID_DEV        # Development Firebase project ID
FIREBASE_API_KEY_PROD          # Production Firebase API key
FIREBASE_AUTH_DOMAIN_PROD      # Production Firebase auth domain
FIREBASE_STORAGE_BUCKET_PROD   # Production Firebase storage bucket
FIREBASE_MESSAGING_SENDER_ID_PROD # Production Firebase messaging sender ID
FIREBASE_APP_ID_PROD           # Production Firebase app ID
FIREBASE_MEASUREMENT_ID_PROD   # Production Firebase measurement ID
BRAILLE_API_URL_PROD           # Production Braille API URL
```

### 2. Google Play Console Setup

1. **Create a Service Account**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new service account
   - Download the JSON key file
   - Add the JSON content to GitHub Secrets as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

2. **Grant Permissions**:
   - In Google Play Console, go to Settings → API access
   - Link the service account
   - Grant "Release Manager" permissions

3. **Initial App Setup**:
   - Upload an initial APK/AAB manually to create the app listing
   - Set up store listing, privacy policy, etc.

## 🎯 Publishing Methods

### Method 1: Automatic (Recommended)

Push a version tag to trigger automatic publishing:

```bash
# Create and push a release tag
git tag v1.0.0
git push origin v1.0.0
```

### Method 2: Manual via Scripts

Use the provided scripts for manual publishing:

```bash
# Linux/macOS
./scripts/publish.sh v1.0.0 production

# Windows PowerShell
.\scripts\publish.ps1 v1.0.0 production
```

### Method 3: Manual via GitHub Actions

1. Go to GitHub Actions tab
2. Select "Automated Publishing" workflow
3. Click "Run workflow"
4. Specify version and environment

## 📊 Release Types

### Production Releases
- **Format**: `v1.0.0`, `v1.1.0`, `v2.0.0`
- **Trigger**: Version tags matching `v*.*.*`
- **Deployment**: Google Play Store (production track) + Firebase Hosting
- **Rollout**: 10% initial rollout on Google Play

### Pre-releases
- **Format**: `v1.0.0-alpha.1`, `v1.0.0-beta.1`, `v1.0.0-rc.1`
- **Trigger**: Version tags containing `alpha`, `beta`, or `rc`
- **Deployment**: Google Play Store (internal/alpha track) + Firebase Hosting
- **Rollout**: Internal testing only

### Staging
- **Trigger**: Manual workflow dispatch with "staging" environment
- **Deployment**: Firebase Hosting (staging project only)
- **Purpose**: Testing before production

## 🔄 Publishing Workflow

### Automatic Process
1. **Tag Creation**: Version tag is pushed to repository
2. **Build Assets**: Android AAB, APK, and Web builds are created
3. **Google Play**: AAB is uploaded to appropriate track
4. **Web Deployment**: Web app is deployed to Firebase Hosting
5. **GitHub Release**: Release page is created with downloadable assets
6. **Notifications**: Build status is reported in GitHub Actions

### Build Artifacts
Each release creates:
- **Android App Bundle (.aab)**: For Google Play Store
- **Android APK (.apk)**: For direct installation
- **Web Application (.zip)**: For self-hosting
- **Source Code (.zip)**: Complete source code archive

## 🛡️ Quality Gates

### Pre-Publishing Checks
- ✅ All CI/CD tests must pass
- ✅ Code quality checks must pass
- ✅ Security scans must pass
- ✅ Android signing must be successful

### Post-Publishing Verification
- ✅ Google Play Console shows successful upload
- ✅ Firebase Hosting deployment is live
- ✅ GitHub Release is created with assets

## 🔧 Troubleshooting

### Common Issues

#### Android Publishing Fails
```
Error: The Android App Bundle was not signed
```
**Solution**: Check that all Android signing secrets are correctly set

#### Firebase Deployment Fails
```
Error: Permission denied (Firebase authentication failed)
```
**Solution**: Verify `FIREBASE_TOKEN` is valid and project IDs are correct

#### Google Play Upload Fails
```
Error: You cannot rollout this release because it does not allow any existing users to upgrade
```
**Solution**: Increment version code in pubspec.yaml

### Getting Help

1. **Check Workflow Logs**: GitHub Actions tab shows detailed logs
2. **Verify Secrets**: Ensure all required secrets are set correctly
3. **Test Locally**: Use staging environment to test changes
4. **Contact Support**: Create an issue in the repository

## 📈 Monitoring Releases

### Google Play Console
- Monitor rollout percentage
- Check crash reports and ANRs
- Review user feedback and ratings

### Firebase Console
- Monitor web app performance
- Check analytics and user behavior
- Review error reports

### GitHub
- Track download statistics
- Monitor issues and discussions
- Review release feedback

## 🔄 Rollback Procedures

### Emergency Rollback

#### Google Play Store
1. Go to Google Play Console
2. Navigate to Release Management → App Releases
3. Halt rollout or rollback to previous version

#### Firebase Hosting
```bash
# Deploy previous version
firebase hosting:clone SOURCE_SITE_ID:SOURCE_VERSION_ID TARGET_SITE_ID
```

#### Quick Hotfix
1. Create hotfix branch from main
2. Apply minimal fix
3. Create new patch version (e.g., v1.0.1)
4. Follow normal release process

## 🎯 Best Practices

### Version Management
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Create release branches for major versions
- Tag releases consistently
- Write meaningful commit messages

### Testing Strategy
- Test on staging environment first
- Use internal testing track on Google Play
- Monitor initial rollout carefully
- Have rollback plan ready

### Release Cadence
- **Major releases**: Quarterly (new features)
- **Minor releases**: Monthly (improvements)
- **Patch releases**: As needed (bug fixes)
- **Hotfixes**: Emergency only

### Communication
- Update changelog for each release
- Notify stakeholders of major changes
- Document breaking changes clearly
- Provide migration guides when needed

## 📞 Support

For issues with the publishing setup:
1. Check this documentation first
2. Review GitHub Actions logs
3. Create an issue with detailed error information
4. Tag relevant team members for urgent issues
