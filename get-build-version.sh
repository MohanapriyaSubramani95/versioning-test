#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

echo "Debug: Current environment: $current_environment" >&2
echo "Debug: Component name: $component_name" >&2
echo "Debug: Version postfix: $version_postfix" >&2

git fetch --tags

last_tag_pattern="$component_name-*"
echo "Debug: Initial last_tag_pattern: $last_tag_pattern" >&2

is_patch=false

if [ "$current_environment" == "uat" ] || [ "$current_environment" == "prod" ]; then
  current_commit=$(git rev-parse HEAD)
  echo "Debug: Current commit: $current_commit" >&2

  number_of_branches_with_commit=$(git branch --contains "$current_commit" | wc -l)
  echo "Debug: Number of branches containing current commit: $number_of_branches_with_commit" >&2

  # Detect if it was a merge from dev branch
  git log -1 --pretty=%B | grep -iq "merge.*dev"
  if [ $? -eq 0 ]; then
    is_patch=false
    echo "Debug: Detected merge from dev → $current_environment" >&2
  else
    is_patch=true
    echo "Debug: Not a merge from dev — treating as patch" >&2
  fi

  # Override: allow FORCE_MINOR flag for dev → uat tagging from outside
  if [ "$FORCE_MINOR" == "true" ]; then
    is_patch=false
    echo "Debug: FORCE_MINOR flag detected, setting is_patch=false" >&2
  fi

  echo "Debug: is_patch set to $is_patch" >&2

  # Update pattern to environment-aware version
  last_tag_pattern="$component_name-$current_environment-*"
  echo "Debug: Updated last_tag_pattern for patch: $last_tag_pattern" >&2
fi

# Extract latest tag for this component/environment
matching_tags=$(git tag --list "$last_tag_pattern" | sort -r)
tag_count=$(echo "$matching_tags" | wc -l)
echo "Debug: Number of existing tags matching pattern: $tag_count" >&2

if [ "$tag_count" -eq 0 ]; then
  last_tag=""
else
  last_tag=$(echo "$matching_tags" | head -n 1)
fi

echo "Debug: Last tag found: $last_tag" >&2

# Extract version numbers
if [[ $last_tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
else
  major=0
  minor=1
  patch=0
fi

echo "Debug: Parsed version - major: $major, minor: $minor, patch: $patch" >&2
echo "Debug: is_patch before version bump logic: $is_patch" >&2

# Increment version
if [ "$is_patch" == "true" ]; then
  patch=$((patch + 1))
  echo "Debug: Patch incremented" >&2
else
  minor=$((minor + 1))
  patch=0
  echo "Debug: Minor incremented, patch reset" >&2
fi

# Generate new tag
new_version="$major.$minor.$patch"
new_tag="$component_name-$current_environment-$new_version-$version_postfix"
echo "Debug: New version to output: $new_tag" >&2

# Output tag (only this line should go to stdout for GitHub Actions)
echo "$new_tag"
