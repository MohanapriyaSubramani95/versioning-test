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

  number_of_branches_with_commit=$(git branch -a --contains "$current_commit" | grep -c "remotes/origin/[dev|uat|prod]")
  echo "Debug: Number of branches containing current commit: $number_of_branches_with_commit" >&2

  if [ "$number_of_branches_with_commit" == "1" ]; then
    is_patch=true
    echo "Debug: is_patch set to true" >&2
  else
    echo "Debug: is_patch remains false" >&2
  fi
fi

if [ "$is_patch" == true ]; then
  last_tag_pattern="$component_name-$current_environment-*"
  echo "Debug: Updated last_tag_pattern for patch: $last_tag_pattern" >&2
fi

number_of_existing_tags=$(git tag --list "$last_tag_pattern" | wc -l)
echo "Debug: Number of existing tags matching pattern: $number_of_existing_tags" >&2

if [ "$number_of_existing_tags" != "0" ]; then
  last_tag=$(git describe --match "$last_tag_pattern" --abbrev=0 --tags "$(git rev-list --tags --max-count=1)")
  echo "Debug: Last tag found: $last_tag" >&2
fi

major=0
minor=0
patch=0

if [[ $last_tag ]]; then
  version_number=$(echo "$last_tag" | cut -d- -f3)
  echo "Debug: Extracted version number from last tag: $version_number" >&2

  major=$(echo "$version_number" | cut -d. -f1)
  minor=$(echo "$version_number" | cut -d. -f2)
  patch=$(echo "$version_number" | cut -d. -f3)
  echo "Debug: Parsed version - major: $major, minor: $minor, patch: $patch" >&2
fi

echo "Debug: is_patch before version bump logic: $is_patch" >&2

if [ "$current_environment" == "prod" ] && [ "$is_patch" == false ]; then
  major=$((major + 1))
  minor=0
  patch=0
  echo "Debug: Prod environment detected, bumped major version" >&2
elif [ "$current_environment" == "uat" ] && [ "$is_patch" == false ]; then
  minor=$((minor + 1))
  patch=0
  echo "Debug: Uat environment detected, bumped minor version" >&2
else
  patch=$((patch + 1))
  echo "Debug: Patch incremented" >&2
fi

echo "Debug: New version to output: $component_name-$current_environment-$major.$minor.$patch-$version_postfix" >&2

# Final output for GitHub Actions
echo "$component_name-$current_environment-$major.$minor.$patch-$version_postfix"
