# Firebase Production Deployment Guide

## Prerequisites

1. **Firebase CLI**: Install the latest version
   ```bash
   npm install -g firebase-tools
   ```

2. **Flutter**: Ensure Flutter is updated to stable channel
   ```bash
   flutter channel stable
   flutter upgrade
   ```

3. **Production Firebase Project**: Create separate Firebase projects for development and production

## Production Setup Steps

### 1. Firebase Project Configuration

1. **Create Production Project**
   ```bash
   # Login to Firebase
   firebase login
   
   # Create new project or select existing production project
   firebase projects:list
   firebase use your-production-project-id
   ```

2. **Configure Authentication Providers**
   - Enable Email/Password authentication
   - Configure Google Sign-In with production OAuth consent screen
   - Set up authorized domains for production

3. **Set up Firestore Database**
   ```bash
   # Deploy Firestore rules
   firebase deploy --only firestore:rules
   
   # Create composite indexes (if needed)
   firebase deploy --only firestore:indexes
   ```

4. **Configure Storage**
   ```bash
   # Deploy Storage rules
   firebase deploy --only storage
   ```

### 2. Environment Configuration

1. **Create Production Environment File**
   ```bash
   cp .env.production.example .env.production
   # Edit .env.production with your production values
   ```

2. **Configure Build Environment Variables**
   ```bash
   # For Web deployment
   flutter build web --dart-define=PRODUCTION=true \
     --dart-define=FIREBASE_API_KEY_PROD=your_api_key \
     --dart-define=FIREBASE_PROJECT_ID_PROD=your_project_id
   
   # For Android APK
   flutter build apk --release --dart-define=PRODUCTION=true
   
   # For Android App Bundle
   flutter build appbundle --release --dart-define=PRODUCTION=true
   
   # For iOS
   flutter build ios --release --dart-define=PRODUCTION=true
   ```

### 3. Security Configuration

1. **Firestore Security Rules**
   - Rules are already configured in `firestore.rules`
   - Deploy with: `firebase deploy --only firestore:rules`

2. **Storage Security Rules**
   - Rules are already configured in `storage.rules`
   - Deploy with: `firebase deploy --only storage`

3. **Authentication Security**
   - Configure authorized domains in Firebase Console
   - Set up email templates for password reset, verification
   - Enable account enumeration protection

### 4. Performance Optimization

1. **Enable Performance Monitoring**
   ```dart
   // Already configured in FirebaseConfig
   // Will be enabled automatically in production builds
   ```

2. **Configure Analytics**
   ```dart
   // Analytics automatically enabled in production
   // Configure custom events in auth_service.dart
   ```

3. **Set up Crashlytics** (Optional)
   ```bash
   # Add to pubspec.yaml
   firebase_crashlytics: ^3.4.0
   
   # Configure in main.dart
   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
   ```

### 5. API Server Production Setup

1. **Production API Deployment**
   ```bash
   # Deploy to cloud service (AWS, GCP, Azure)
   # Recommended: Use Docker container
   
   # Example Dockerfile for Python API
   FROM python:3.9-slim
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["gunicorn", "--bind", "0.0.0.0:5000", "braille_api:app"]
   ```

2. **Environment Variables for API**
   ```bash
   export FLASK_ENV=production
   export DATABASE_URL=your_production_db_url
   export REDIS_URL=your_redis_url
   export SECRET_KEY=your_secret_key
   ```

3. **Configure Load Balancer and SSL**
   - Set up HTTPS with SSL certificate
   - Configure load balancer for high availability
   - Set up health checks

### 6. Monitoring and Logging

1. **Set up Logging**
   ```dart
   // Configure production logging
   import 'package:logging/logging.dart';
   
   Logger.root.level = Level.WARNING; // Production log level
   ```

2. **Monitor Performance**
   - Firebase Performance Monitoring (auto-enabled)
   - Custom performance tracking for critical operations
   - Set up alerts for response time degradation

3. **Error Tracking**
   - Firebase Crashlytics for crash reporting
   - Custom error logging for business logic errors
   - Set up alerting for critical errors

### 7. CI/CD Pipeline Configuration

1. **GitHub Actions Example**
   ```yaml
   name: Deploy to Production
   on:
     push:
       branches: [main]
   
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - uses: subosito/flutter-action@v2
         - name: Build Web App
           run: |
             flutter build web --release --dart-define=PRODUCTION=true
         - name: Deploy to Firebase Hosting
           uses: FirebaseExtended/action-hosting-deploy@v0
           with:
             repoToken: '${{ secrets.GITHUB_TOKEN }}'
             firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
             projectId: your-production-project-id
   ```

### 8. Pre-deployment Checklist

- [ ] Production Firebase project created and configured
- [ ] Environment variables set correctly
- [ ] Security rules deployed and tested
- [ ] Authentication providers configured
- [ ] API server deployed and accessible
- [ ] SSL certificates configured
- [ ] Monitoring and alerting set up
- [ ] Performance optimization applied
- [ ] Error tracking configured
- [ ] Backup and recovery procedures in place

### 9. Deployment Commands

```bash
# Web deployment
flutter build web --release --dart-define=PRODUCTION=true
firebase deploy --only hosting

# Android Play Store
flutter build appbundle --release --dart-define=PRODUCTION=true

# iOS App Store
flutter build ios --release --dart-define=PRODUCTION=true

# Deploy Firebase Functions (if using)
firebase deploy --only functions

# Deploy all Firebase services
firebase deploy
```

### 10. Post-deployment Verification

1. **Functionality Testing**
   - Test user registration and login
   - Verify Braille translation functionality
   - Test data synchronization
   - Verify export functionality

2. **Performance Testing**
   - Monitor response times
   - Check memory usage
   - Verify database query performance

3. **Security Testing**
   - Test authentication flows
   - Verify data access restrictions
   - Check for unauthorized access

4. **Monitoring Setup**
   - Verify error tracking is working
   - Check performance monitoring
   - Test alerting systems

## Production Environment Variables Template

```bash
# Copy to .env.production and fill with actual values
FIREBASE_API_KEY_PROD=
FIREBASE_AUTH_DOMAIN_PROD=
FIREBASE_PROJECT_ID_PROD=
FIREBASE_STORAGE_BUCKET_PROD=
FIREBASE_MESSAGING_SENDER_ID_PROD=
FIREBASE_APP_ID_PROD=
FIREBASE_MEASUREMENT_ID_PROD=
BRAILLE_API_URL_PROD=
```

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Ensure all environment variables are set
   - Check Flutter and Dart SDK versions
   - Verify Firebase configuration

2. **Authentication Issues**
   - Check authorized domains in Firebase Console
   - Verify OAuth consent screen configuration
   - Ensure API keys are correct

3. **Database Access Issues**
   - Verify Firestore rules are deployed
   - Check user permissions
   - Ensure indexes are created

4. **Performance Issues**
   - Monitor Firebase Performance console
   - Check network latency
   - Optimize database queries

### Support

- Firebase Console: https://console.firebase.google.com
- Firebase Documentation: https://firebase.google.com/docs
- Flutter Documentation: https://flutter.dev/docs
