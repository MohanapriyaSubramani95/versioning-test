#!/bin/bash

ENVIRONMENT=$1         # dev / uat / prod
COMPONENT=$2           # e.g., frontend
POSTFIX=$3             # short commit SHA

# Fetch latest tag for the given environment and component
LATEST_TAG=$(git tag --list "${COMPONENT}-${ENVIRONMENT}-*" --sort=-v:refname | head -n 1)

# Default version if no tag found
DEFAULT_VERSION="0.0.0"

if [ -z "$LATEST_TAG" ]; then
  BASE_VERSION=$DEFAULT_VERSION
else
  # Extract version part from tag: frontend-dev-0.0.1-abc123 → 0.0.1
  BASE_VERSION=$(echo "$LATEST_TAG" | sed -E "s/^${COMPONENT}-${ENVIRONMENT}-([0-9]+\.[0-9]+\.[0-9]+).*/\1/")
fi

# Split BASE_VERSION into major, minor, patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"

# Increment version based on environment
if [[ "$ENVIRONMENT" == "prod" ]]; then
  ((MAJOR++))
  MINOR=0
  PATCH=0
elif [[ "$ENVIRONMENT" == "uat" ]]; then
  ((MINOR++))
  PATCH=0
else
  ((PATCH++))
fi

# Construct new version
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Create final tag string
FINAL_TAG="${COMPONENT}-${ENVIRONMENT}-${NEW_VERSION}-${POSTFIX}"

echo "$FINAL_TAG"
