#!/bin/bash
set -e

ENVIRONMENT=$1       # dev / uat / prod
COMPONENT=$2          # e.g., frontend
POSTFIX=$3            # short commit hash

# Define bump type based on environment
case "$ENVIRONMENT" in
  dev)
    bump_type="patch"
    ;;
  uat)
    bump_type="minor"
    ;;
  prod)
    bump_type="major"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Get latest tag matching the component and environment
tag_pattern="$COMPONENT-$ENVIRONMENT-*"
latest_tag=$(git tag --list "$tag_pattern" | sort -V | tail -n 1)

if [[ $latest_tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
else
  major=0
  minor=0
  patch=0
fi

# Bump version based on environment
if [[ $bump_type == "major" ]]; then
  ((major++))
  minor=0
  patch=0
elif [[ $bump_type == "minor" ]]; then
  ((minor++))
  patch=0
elif [[ $bump_type == "patch" ]]; then
  ((patch++))
fi

# Construct the new version tag
new_tag="$COMPONENT-$ENVIRONMENT-$major.$minor.$patch-$POSTFIX"

echo "$new_tag"
