# Gnos Braille System - Automated Publishing Setup

This directory contains configuration files for automated publishing to various platforms.

## Google Play Store

### Setup Requirements

1. **Google Play Console Service Account**:
   - Create a service account in Google Cloud Console
   - Grant "Service Account User" role
   - Download the JSON key file
   - Add the JSON content to GitHub Secrets as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

2. **Required GitHub Secrets**:
   ```
   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON - Service account JSON key
   ANDROID_KEYSTORE_BASE64 - Base64 encoded keystore file
   ANDROID_KEYSTORE_PASSWORD - Keystore password
   ANDROID_KEY_PASSWORD - Key password
   ANDROID_KEY_ALIAS - Key alias
   ```

### Publishing Process

The automated publishing workflow supports:
- **Production releases**: Full rollout to Google Play Store
- **Pre-releases**: Alpha/Beta tracks for testing
- **Gradual rollout**: 10% initial rollout, can be increased manually

## Web Deployment

Automatically deploys to Firebase Hosting with:
- Production environment for release tags
- Staging environment for manual triggers
- Firebase rules deployment

## Release Management

### Triggering Releases

1. **Automatic**: Push a version tag (e.g., `v1.0.0`)
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Manual**: Use GitHub Actions workflow_dispatch
   - Go to Actions tab in GitHub
   - Select "Automated Publishing" workflow
   - Click "Run workflow"
   - Specify version and environment

### Version Naming Convention

- **Production**: `v1.0.0`, `v1.1.0`, `v2.0.0`
- **Pre-release**: `v1.0.0-alpha.1`, `v1.0.0-beta.1`, `v1.0.0-rc.1`

### Release Artifacts

Each release creates:
- Android App Bundle (.aab) for Google Play Store
- Android APK (.apk) for direct installation
- Web application bundle (.zip) for hosting
- Source code archive (.zip)

## Testing Before Publishing

Always test releases using:
1. Internal testing track on Google Play
2. Firebase Hosting preview channels
3. Manual QA on staging environment

## Rollback Procedures

If issues are discovered:
1. **Google Play**: Use console to halt rollout or rollback
2. **Web**: Deploy previous version or hotfix
3. **GitHub**: Create hotfix release with incremented version
