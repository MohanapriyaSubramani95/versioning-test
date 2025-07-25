#!/bin/bash

ENVIRONMENT=$1       # dev / uat / prod
COMPONENT=$2         # e.g., frontend
POSTFIX=$3           # commit short hash

# Get latest prod tag version (major.minor.patch)
LATEST_PROD_TAG=$(git tag --list "${COMPONENT}-prod-*" --sort=-v:refname | head -n 1)
if [ -z "$LATEST_PROD_TAG" ]; then
  PROD_MAJOR=0
  PROD_MINOR=0
  PROD_PATCH=0
else
  PROD_VERSION=$(echo "$LATEST_PROD_TAG" | sed -E "s/^${COMPONENT}-prod-([0-9]+\.[0-9]+\.[0-9]+).*/\1/")
  IFS='.' read -r PROD_MAJOR PROD_MINOR PROD_PATCH <<< "$PROD_VERSION"
fi

# Get latest tag for current environment
LATEST_ENV_TAG=$(git tag --list "${COMPONENT}-${ENVIRONMENT}-*" --sort=-v:refname | head -n 1)
if [ -z "$LATEST_ENV_TAG" ]; then
  ENV_MAJOR=0
  ENV_MINOR=0
  ENV_PATCH=0
else
  ENV_VERSION=$(echo "$LATEST_ENV_TAG" | sed -E "s/^${COMPONENT}-${ENVIRONMENT}-([0-9]+\.[0-9]+\.[0-9]+).*/\1/")
  IFS='.' read -r ENV_MAJOR ENV_MINOR ENV_PATCH <<< "$ENV_VERSION"
fi

if [[ "$ENVIRONMENT" == "prod" ]]; then
  # Prod: increment major, reset minor and patch
  MAJOR=$((PROD_MAJOR + 1))
  MINOR=0
  PATCH=0

elif [[ "$ENVIRONMENT" == "uat" ]]; then
  # UAT: keep prod major, increment minor, reset patch
  MAJOR=$PROD_MAJOR
  MINOR=$((PROD_MINOR + 1))
  PATCH=0

elif [[ "$ENVIRONMENT" == "dev" ]]; then
  # Dev: keep prod major & minor
  MAJOR=$PROD_MAJOR
  MINOR=$PROD_MINOR

  # Reset patch if last dev major/minor differ from prod
  if [[ $ENV_MAJOR != $PROD_MAJOR ]] || [[ $ENV_MINOR != $PROD_MINOR ]]; then
    PATCH=0
  else
    PATCH=$((ENV_PATCH + 1))
  fi

else
  echo "Unknown environment: $ENVIRONMENT"
  exit 1
fi

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_TAG="${COMPONENT}-${ENVIRONMENT}-${NEW_VERSION}-${POSTFIX}"

echo "$NEW_TAG"
