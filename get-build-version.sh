#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

echo "Debug: Current environment: $current_environment"
echo "Debug: Component name: $component_name"
echo "Debug: Version postfix: $version_postfix"

git fetch --tags

# Use all environment tags to find latest version so versioning is global and incremental
last_tag_pattern="$component_name-*"
echo "Debug: Using last_tag_pattern: $last_tag_pattern"

matching_tags=$(git tag --list "$last_tag_pattern" | sort -r)
tag_count=$(echo "$matching_tags" | wc -l)
echo "Debug: Number of existing tags matching pattern: $tag_count"

if [ "$tag_count" -eq 0 ]; then
  last_tag=""
else
  last_tag=$(echo "$matching_tags" | head -n 1)
fi

echo "Debug: Last tag found: $last_tag"

# Extract version numbers from last tag if it exists
if [[ $last_tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
else
  # Default version if no tag found
  major=0
  minor=0
  patch=0
fi

echo "Debug: Parsed version - major: $major, minor: $minor, patch: $patch"

# Determine whether to bump patch or minor
is_patch=false

if [ "$current_environment" == "dev" ]; then
  # Always patch bump on dev branch
  is_patch=true
  echo "Debug: Environment is dev, patch bump"
else
  # uat or prod branch
  git log -1 --pretty=%B | grep -iq "merge.*dev"
  if [ $? -eq 0 ]; then
    is_patch=false
    echo "Debug: Detected merge from dev → $current_environment, minor bump"
  else
    is_patch=true
    echo "Debug: Not a merge from dev, patch bump"
  fi

  # Override with FORCE_MINOR flag if set
  if [ "$FORCE_MINOR" == "true" ]; then
    is_patch=false
    echo "Debug: FORCE_MINOR flag detected, forcing minor bump"
  fi
fi

# Increment version based on is_patch flag
if [ "$is_patch" == "true" ]; then
  patch=$((patch + 1))
  echo "Debug: Patch incremented"
else
  minor=$((minor + 1))
  patch=0
  echo "Debug: Minor incremented, patch reset"
fi

# Compose new tag string
new_version="$major.$minor.$patch"
new_tag="$component_name-$current_environment-$new_version-$version_postfix"
echo "Debug: New version to output: $new_tag"

# Output the new tag
echo "$new_tag"
