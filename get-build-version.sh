#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

echo "Current environment: $current_environment"
echo "Component name: $component_name"
echo "Version postfix: $version_postfix"

git fetch --tags

last_tag_pattern="$component_name-*"
echo "Initial last_tag_pattern: $last_tag_pattern"

is_patch=false

if [ "$current_environment" == "uat" ] || [ "$current_environment" == "prod" ]; then
  current_commit=$(git rev-parse HEAD)
  echo "Current commit: $current_commit"

  number_of_branches_with_commit=$(git branch -a --contains "$current_commit" | grep -c "remotes/origin/[dev|uat|prod]")
  echo "Number of branches containing current commit: $number_of_branches_with_commit"

  if [ "$number_of_branches_with_commit" == "1" ]; then
    is_patch=true
    echo "is_patch set to true"
  else
    echo "is_patch remains false"
  fi
fi

if [ "$is_patch" == true ]; then
  last_tag_pattern="$component_name-$current_environment-*"
  echo "Updated last_tag_pattern for patch: $last_tag_pattern"
fi

number_of_existing_tags=$(git tag --list "$last_tag_pattern" | wc -l)
echo "Number of existing tags matching pattern: $number_of_existing_tags"

if [ "$number_of_existing_tags" != "0" ]; then
  last_tag=$(git describe --match "$last_tag_pattern" --abbrev=0 --tags "$(git rev-list --tags --max-count=1)")
  echo "Last tag found: $last_tag"
fi

major=0
minor=0
patch=0

if [[ $last_tag ]]; then
  version_number=$(echo "$last_tag" | cut -d- -f3)
  echo "Extracted version number from last tag: $version_number"

  major=$(echo "$version_number" | cut -d. -f1)
  minor=$(echo "$version_number" | cut -d. -f2)
  patch=$(echo "$version_number" | cut -d. -f3)
  echo "Parsed version - major: $major, minor: $minor, patch: $patch"
fi

echo "is_patch before version bump logic: $is_patch"

if [ "$current_environment" == "prod" ] && [ "$is_patch" == false ]; then
  major=$((major + 1))
  minor=0
  patch=0
  echo "Prod environment detected, bumped major version"
elif [ "$current_environment" == "uat" ] && [ "$is_patch" == false ]; then
  minor=$((minor + 1))
  patch=0
  echo "Uat environment detected, bumped minor version"
else
  patch=$((patch + 1))
  echo "Patch incremented"
fi

echo "New version to output: $component_name-$current_environment-$major.$minor.$patch-$version_postfix"

echo "$component_name-$current_environment-$major.$minor.$patch-$version_postfix"
