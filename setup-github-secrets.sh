#!/bin/bash

# GitHub Secrets Setup Helper Script
# This script helps you configure GitHub repository secrets for CI/CD

set -e

echo "🚀 GitHub Secrets Setup Helper for Gnos Braille System"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not installed.${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  You are not authenticated with GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is ready!${NC}"
echo ""

# Get repository information
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo -e "${BLUE}📁 Repository: ${REPO}${NC}"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local description=$2
    local example=$3
    
    echo -e "${YELLOW}🔐 Setting up: ${secret_name}${NC}"
    echo "Description: $description"
    if [ -n "$example" ]; then
        echo "Example: $example"
    fi
    
    read -p "Enter value (or press Enter to skip): " secret_value
    
    if [ -n "$secret_value" ]; then
        gh secret set "$secret_name" --body "$secret_value"
        echo -e "${GREEN}✅ $secret_name set successfully${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipped $secret_name${NC}"
    fi
    echo ""
}

# Function to set secret from file
set_secret_from_file() {
    local secret_name=$1
    local description=$2
    local file_path=$3
    
    echo -e "${YELLOW}🔐 Setting up: ${secret_name}${NC}"
    echo "Description: $description"
    
    read -p "Enter file path (or press Enter to skip): " input_file
    
    if [ -n "$input_file" ] && [ -f "$input_file" ]; then
        secret_value=$(cat "$input_file")
        gh secret set "$secret_name" --body "$secret_value"
        echo -e "${GREEN}✅ $secret_name set from file successfully${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipped $secret_name${NC}"
    fi
    echo ""
}

echo -e "${BLUE}🔥 Firebase Development Configuration${NC}"
echo "=================================================="
set_secret "FIREBASE_API_KEY_DEV" "Firebase Web API Key (Development)" "AIzaSyC9k8B7X..."
set_secret "FIREBASE_AUTH_DOMAIN_DEV" "Firebase Auth Domain (Development)" "your-project-dev.firebaseapp.com"
set_secret "FIREBASE_PROJECT_ID_DEV" "Firebase Project ID (Development)" "your-project-dev"
set_secret "FIREBASE_STORAGE_BUCKET_DEV" "Firebase Storage Bucket (Development)" "your-project-dev.appspot.com"
set_secret "FIREBASE_MESSAGING_SENDER_ID_DEV" "Firebase Messaging Sender ID (Development)" "123456789012"
set_secret "FIREBASE_APP_ID_DEV" "Firebase App ID (Development)" "1:123456789012:web:abcdef123456"
set_secret "FIREBASE_MEASUREMENT_ID_DEV" "Firebase Analytics Measurement ID (Development)" "G-ABCDEF1234"

echo -e "${BLUE}🔥 Firebase Production Configuration${NC}"
echo "=================================================="
set_secret "FIREBASE_API_KEY_PROD" "Firebase Web API Key (Production)" "AIzaSyD1k8C7Y..."
set_secret "FIREBASE_AUTH_DOMAIN_PROD" "Firebase Auth Domain (Production)" "your-project-prod.firebaseapp.com"
set_secret "FIREBASE_PROJECT_ID_PROD" "Firebase Project ID (Production)" "your-project-prod"
set_secret "FIREBASE_STORAGE_BUCKET_PROD" "Firebase Storage Bucket (Production)" "your-project-prod.appspot.com"
set_secret "FIREBASE_MESSAGING_SENDER_ID_PROD" "Firebase Messaging Sender ID (Production)" "987654321098"
set_secret "FIREBASE_APP_ID_PROD" "Firebase App ID (Production)" "1:987654321098:web:fedcba654321"
set_secret "FIREBASE_MEASUREMENT_ID_PROD" "Firebase Analytics Measurement ID (Production)" "G-FEDCBA9876"

echo -e "${BLUE}🔧 API Configuration${NC}"
echo "=================================================="
set_secret "BRAILLE_API_URL_DEV" "Braille API Base URL (Development)" "http://localhost:5000"
set_secret "BRAILLE_API_URL_PROD" "Braille API Base URL (Production)" "https://api.your-domain.com"

echo -e "${BLUE}🔑 Firebase CLI Authentication${NC}"
echo "=================================================="
echo "To get Firebase CI token, run: firebase login:ci"
set_secret "FIREBASE_TOKEN" "Firebase CI Token" "1//0abc123def456..."

echo -e "${BLUE}📱 Android App Signing${NC}"
echo "=================================================="
echo "For Android keystore setup, see GITHUB_SECRETS_SETUP.md"
set_secret_from_file "ANDROID_KEYSTORE_BASE64" "Base64 encoded keystore file" "keystore.base64"
set_secret "ANDROID_KEYSTORE_PASSWORD" "Keystore password" ""
set_secret "ANDROID_KEY_ALIAS" "Key alias name" "release"
set_secret "ANDROID_KEY_PASSWORD" "Key password" ""

echo -e "${BLUE}🛡️ Optional Security Tools${NC}"
echo "=================================================="
set_secret "SEMGREP_APP_TOKEN" "Semgrep security scanning token (optional)" ""
set_secret "CODECOV_TOKEN" "Codecov upload token (optional)" ""

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Verify all secrets are set: gh secret list"
echo "2. Test the CI/CD pipeline by pushing a commit"
echo "3. Check GitHub Actions tab for workflow execution"
echo ""
echo "For detailed setup instructions, see GITHUB_SECRETS_SETUP.md"
