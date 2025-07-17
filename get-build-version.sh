#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

echo "Debug: Current environment: $current_environment"
echo "Debug: Component name: $component_name"
echo "Debug: Version postfix: $version_postfix"

git fetch --tags

last_tag_pattern="$component_name-*"
echo "Debug: Initial last_tag_pattern: $last_tag_pattern"

# Default bump flags
is_patch=false
is_minor=false
is_major=false

if [ "$current_environment" == "dev" ]; then
  # Always patch bump on dev branch
  is_patch=true
  echo "Debug: Environment is dev - always patch bump"
elif [ "$current_environment" == "uat" ]; then
  current_commit=$(git rev-parse HEAD)
  echo "Debug: Current commit: $current_commit"
  
  # Check if this commit is a merge from dev
  git log -1 --pretty=%B | grep -iq "merge.*dev"
  if [ $? -eq 0 ]; then
    is_minor=true
    echo "Debug: Detected merge from dev → uat - minor bump"
  else
    is_patch=true
    echo "Debug: No merge from dev - patch bump"
  fi
elif [ "$current_environment" == "prod" ]; then
  current_commit=$(git rev-parse HEAD)
  echo "Debug: Current commit: $current_commit"

  # Check if this commit is a merge from uat
  git log -1 --pretty=%B | grep -iq "merge.*uat"
  if [ $? -eq 0 ]; then
    is_major=true
    echo "Debug: Detected merge from uat → prod - major bump"
  else
    is_patch=true
    echo "Debug: No merge from uat - patch bump"
  fi
fi

# Update pattern to environment-aware version
last_tag_pattern="$component_name-$current_environment-*"
echo "Debug: Updated last_tag_pattern: $last_tag_pattern"

# Get latest tag matching pattern
matching_tags=$(git tag --list "$last_tag_pattern" | sort -r)
tag_count=$(echo "$matching_tags" | wc -l)
echo "Debug: Number of existing tags matching pattern: $tag_count"

if [ "$tag_count" -eq 0 ]; then
  last_tag=""
else
  last_tag=$(echo "$matching_tags" | head -n 1)
fi

echo "Debug: Last tag found: $last_tag"

# Extract version numbers
if [[ $last_tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
else
  major=0
  minor=0
  patch=0
fi

echo "Debug: Parsed version - major: $major, minor: $minor, patch: $patch"

# Increment version based on flags
if [ "$is_major" == "true" ]; then
  major=$((major + 1))
  minor=0
  patch=0
  echo "Debug: Major incremented, minor and patch reset"
elif [ "$is_minor" == "true" ]; then
  minor=$((minor + 1))
  patch=0
  echo "Debug: Minor incremented, patch reset"
elif [ "$is_patch" == "true" ]; then
  patch=$((patch + 1))
  echo "Debug: Patch incremented"
else
  # Default to patch if none set
  patch=$((patch + 1))
  echo "Debug: No increment flag set, patch incremented by default"
fi

# Generate new tag
new_version="$major.$minor.$patch"
new_tag="$component_name-$current_environment-$new_version-$version_postfix"
echo "Debug: New version to output: $new_tag"

# Output tag
echo "$new_tag"
