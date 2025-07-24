#!/bin/bash

set -e

current_environment=$1      # dev, uat, prod
component_name=$2           # e.g. "mycomponent"
version_postfix=$3          # optional (e.g., build id, date)

if [[ -z "$current_environment" || -z "$component_name" ]]; then
  echo "Usage: $0 <env: dev|uat|prod> <component_name> [version_postfix]"
  exit 1
fi

# Fetch all tags
git fetch --tags

# Path to version file
version_file="version.json"

# Read existing version.json or initialize empty JSON
if [[ -f "$version_file" ]]; then
  versions_json=$(cat "$version_file")
else
  versions_json='{}'
fi

# Get latest prod tag and parse major, minor, patch
latest_prod_tag=$(git tag --list "$component_name-prod-*" | sort -V | tail -n1)

major=0
minor=0
patch=0

if [[ $latest_prod_tag ]]; then
  version_number=$(echo "$latest_prod_tag" | cut -d- -f3)
  major=$(echo "$version_number" | cut -d. -f1)
  minor=$(echo "$version_number" | cut -d. -f2)
  patch=$(echo "$version_number" | cut -d. -f3)
fi

# Get last tag for current environment
last_env_tag=$(git tag --list "$component_name-$current_environment-*" | sort -V | tail -n1)

env_major=0
env_minor=0
env_patch=0

if [[ $last_env_tag ]]; then
  env_version=$(echo "$last_env_tag" | cut -d- -f3)
  env_major=$(echo "$env_version" | cut -d. -f1)
  env_minor=$(echo "$env_version" | cut -d. -f2)
  env_patch=$(echo "$env_version" | cut -d. -f3)
fi

# Calculate new version based on environment
case "$current_environment" in
  "dev")
    # dev: keep prod major, minor; patch = last dev patch +1
    major=$major
    minor=$minor
    patch=$((env_patch + 1))
    ;;
  "uat")
    # uat: prod major; minor +1; patch=0
    major=$major
    minor=$((minor + 1))
    patch=0
    ;;
  "prod")
    # prod: major+1; minor=0; patch=0
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  *)
    echo "Error: Unknown environment '$current_environment'. Use dev, uat or prod."
    exit 1
    ;;
esac

# Compose new version string
version="$component_name-$current_environment-$major.$minor.$patch"
if [[ -n "$version_postfix" ]]; then
  version="$version-$version_postfix"
fi

echo "New version: $version"

# Create and push git tag
git tag -a "$version" -m "Release $version"
git push origin "$version"

# Update version.json file with jq (or fallback)
if command -v jq >/dev/null 2>&1; then
  # Update JSON with new version for current environment
  updated_json=$(echo "$versions_json" | jq --arg env "$current_environment" --arg ver "$version" '.[$env] = $ver')
  echo "$updated_json" > "$version_file"
else
  # Simple fallback (overwrite whole file with current env/version only)
  echo "{\"$current_environment\": \"$version\"}" > "$version_file"
  echo "Warning: 'jq' not found, overwriting $version_file with current env only."
fi

# Commit and push version.json changes if any
if git diff --quiet "$version_file"; then
  echo "No changes in $version_file to commit."
else
  git add "$version_file"
  git commit -m "Update version file: $version"
  git push origin HEAD
fi
