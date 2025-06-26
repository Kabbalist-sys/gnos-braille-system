# CI/CD Pipeline Documentation

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipelines for the Gnos Braille System.

## 🚀 Pipeline Overview

The CI/CD system consists of several automated workflows that ensure code quality, security, and reliable deployments across multiple platforms.

## 📋 Workflows

### 1. Main CI/CD Pipeline (`ci-cd.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Release publications

**Jobs:**
- **Test & Analyze**: Runs Flutter analysis and tests with coverage
- **Build Web**: Creates production-ready web builds
- **Build Android**: Creates APK and App Bundle for Google Play
- **Deploy Web**: Deploys to Firebase Hosting
- **Deploy Firebase**: Updates Firestore and Storage rules
- **Notify**: Sends deployment notifications

### 2. API Deployment (`api-deploy.yml`)

**Triggers:**
- Changes to API files (`braille_api.py`, `requirements.txt`)
- Release publications

**Jobs:**
- **Test API**: Runs Python API tests with coverage
- **Deploy Staging**: Deploys API to staging environment
- **Deploy Production**: Deploys API to production on releases

### 3. Multi-Platform Tests (`multi-platform-tests.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests
- Weekly scheduled runs

**Jobs:**
- **Test Matrix**: Tests on Ubuntu, Windows, and macOS
- **Integration Tests**: End-to-end testing
- **Security Scan**: Vulnerability and secret scanning

### 4. Release Automation (`release.yml`)

**Triggers:**
- Git tags matching `v*.*.*` pattern

**Jobs:**
- **Create Release**: Generates GitHub release with notes
- **Build Assets**: Creates all platform builds for release
- **Deploy Production**: Automatically deploys production environment

### 5. Quality & Security (`quality-checks.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests

**Jobs:**
- **Code Quality**: Static analysis and formatting checks
- **Security Scan**: Vulnerability scanning with Semgrep
- **Performance Analysis**: Bundle size and performance checks
- **Documentation Check**: Ensures documentation completeness
- **Accessibility Check**: Validates accessibility implementation

## 🔧 Setup Instructions

### 1. Repository Secrets

Configure the following secrets in your GitHub repository settings:

#### Firebase Configuration (Development)
```
FIREBASE_API_KEY_DEV
FIREBASE_AUTH_DOMAIN_DEV
FIREBASE_PROJECT_ID_DEV
FIREBASE_STORAGE_BUCKET_DEV
FIREBASE_MESSAGING_SENDER_ID_DEV
FIREBASE_APP_ID_DEV
FIREBASE_MEASUREMENT_ID_DEV
```

#### Firebase Configuration (Production)
```
FIREBASE_API_KEY_PROD
FIREBASE_AUTH_DOMAIN_PROD
FIREBASE_PROJECT_ID_PROD
FIREBASE_STORAGE_BUCKET_PROD
FIREBASE_MESSAGING_SENDER_ID_PROD
FIREBASE_APP_ID_PROD
FIREBASE_MEASUREMENT_ID_PROD
```

#### API Configuration
```
BRAILLE_API_URL_DEV
BRAILLE_API_URL_PROD
```

#### Firebase CLI Token
```
FIREBASE_TOKEN  # Generate with: firebase login:ci
```

#### Android Signing
```
ANDROID_KEYSTORE_BASE64     # Base64 encoded keystore file
ANDROID_KEYSTORE_PASSWORD   # Keystore password
ANDROID_KEY_ALIAS          # Key alias
ANDROID_KEY_PASSWORD       # Key password
```

#### Optional Security Tools
```
SEMGREP_APP_TOKEN  # For enhanced security scanning
```

### 2. Android Signing Setup

1. **Generate a keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. **Encode keystore to base64**:
   ```bash
   base64 -i release-key.jks -o keystore.base64
   ```

3. **Add the base64 content** to `ANDROID_KEYSTORE_BASE64` secret

### 3. Firebase Setup

1. **Create Firebase projects** for development and production
2. **Enable services**: Authentication, Firestore, Storage, Analytics, Crashlytics
3. **Generate service account key** for Firebase CLI
4. **Get Firebase token**:
   ```bash
   firebase login:ci
   ```

### 4. Branch Protection Rules

Configure branch protection for `main`:
- Require status checks to pass
- Require branches to be up to date
- Require review from code owners
- Dismiss stale reviews
- Restrict pushes to matching branches

## 🔄 Development Workflow

### Feature Development
1. Create feature branch from `develop`
2. Make changes and commit
3. Push branch - triggers quality checks
4. Create pull request to `develop`
5. CI runs all tests and quality checks
6. After review and approval, merge to `develop`

### Release Process
1. Merge `develop` to `main` when ready for release
2. Create and push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
3. Release workflow automatically:
   - Creates GitHub release
   - Builds all platform artifacts
   - Deploys to production
   - Uploads release assets

### Hotfix Process
1. Create hotfix branch from `main`
2. Make critical fixes
3. Create pull request to `main`
4. After approval, merge and tag new version
5. Release workflow handles deployment

## 📊 Monitoring & Notifications

### Build Status
- Monitor workflow status in GitHub Actions tab
- Build status badges can be added to README
- Failed builds trigger notifications

### Deployment Monitoring
- Firebase Console for hosting and database metrics
- Google Play Console for Android app metrics
- Custom monitoring can be added for API endpoints

### Quality Metrics
- Code coverage reports uploaded to Codecov
- Security scan results in GitHub Security tab
- Performance metrics tracked in workflow summaries

## 🛠️ Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Flutter version compatibility
   - Verify all secrets are properly configured
   - Ensure dependencies are up to date

2. **Deployment Failures**
   - Verify Firebase token is valid
   - Check Firebase project permissions
   - Ensure security rules are valid

3. **Android Signing Issues**
   - Verify keystore is properly base64 encoded
   - Check that all signing secrets are configured
   - Ensure keystore password is correct

4. **Environment Variable Issues**
   - Double-check secret names match exactly
   - Verify environment-specific configurations
   - Test locally with the same environment variables

### Debug Commands

```bash
# Test Flutter build locally
flutter build web --release --dart-define=PRODUCTION=true

# Test Firebase deployment
firebase deploy --only hosting --dry-run

# Validate Android keystore
keytool -list -v -keystore release-key.jks

# Check Firebase authentication
firebase login:list
```

## 🔄 Pipeline Maintenance

### Regular Tasks
- Update Flutter version in workflows monthly
- Review and update dependencies quarterly
- Rotate secrets and tokens annually
- Monitor security vulnerability reports

### Performance Optimization
- Review build times and optimize where possible
- Cache dependencies when appropriate
- Parallelize independent jobs
- Monitor resource usage

## 📈 Analytics & Reporting

### Metrics to Track
- Build success/failure rates
- Deployment frequency
- Lead time for changes
- Mean time to recovery
- Test coverage trends

### Reporting Tools
- GitHub Actions provides basic metrics
- Third-party tools can be integrated for advanced analytics
- Custom dashboards can be created using GitHub APIs

## 🔒 Security Considerations

### Best Practices
- All secrets stored in GitHub Secrets
- Minimal permissions for service accounts
- Regular security scanning enabled
- Dependency vulnerability monitoring
- Code signing for all releases

### Compliance
- Audit logs available in GitHub
- All deployments traceable
- Automated security checks
- Environment separation enforced

---

## 📞 Support

For questions or issues with the CI/CD pipeline:
1. Check the workflow logs in GitHub Actions
2. Review this documentation
3. Create an issue in the repository
4. Contact the development team

Remember to keep this documentation updated as the pipeline evolves!
