#!/bin/bash

# Gnos Braille System - Manual Publishing Script
# Usage: ./scripts/publish.sh [version] [environment]

set -e

VERSION=${1:-"v1.0.0"}
ENVIRONMENT=${2:-"production"}

echo "🚀 Publishing Gnos Braille System $VERSION to $ENVIRONMENT"

# Validate inputs
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo "❌ Invalid version format. Use format: v1.0.0 or v1.0.0-beta.1"
    exit 1
fi

if [[ ! $ENVIRONMENT =~ ^(production|staging)$ ]]; then
    echo "❌ Invalid environment. Use 'production' or 'staging'"
    exit 1
fi

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "❌ Tag $VERSION already exists!"
    echo "Existing tags:"
    git tag -l | tail -5
    exit 1
fi

# Ensure we're on main branch for production
if [ "$ENVIRONMENT" = "production" ]; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        echo "❌ Production releases must be from main branch (currently on $CURRENT_BRANCH)"
        exit 1
    fi
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Working directory is not clean. Commit or stash changes first."
    git status --short
    exit 1
fi

# Update version in pubspec.yaml
echo "📝 Updating version in pubspec.yaml..."
sed -i.bak "s/^version: .*/version: ${VERSION#v}+$(date +%s)/" pubspec.yaml
rm pubspec.yaml.bak

# Commit version update
git add pubspec.yaml
git commit -m "Bump version to $VERSION"

# Create and push tag
echo "🏷️  Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION

Environment: $ENVIRONMENT
Date: $(date)
Commit: $(git rev-parse HEAD)"

echo "⬆️  Pushing to remote..."
git push origin main
git push origin "$VERSION"

echo "✅ Release $VERSION initiated!"
echo ""
echo "🔗 Monitor progress at:"
echo "   https://github.com/Kabbalist-sys/gnos-braille-system/actions"
echo ""
echo "📦 Release will be available at:"
echo "   https://github.com/Kabbalist-sys/gnos-braille-system/releases/tag/$VERSION"

if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    echo "🤖 Google Play Store publishing will begin automatically"
    echo "🌐 Web app will be deployed to production"
fi
