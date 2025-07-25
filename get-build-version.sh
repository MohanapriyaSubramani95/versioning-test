#!/bin/bash
set -e

component_name="frontend"
branch_name=$(git rev-parse --abbrev-ref HEAD)

# Determine environment from branch name
if [[ $branch_name == *"dev"* ]]; then
  current_environment="dev"
  bump_type="patch"
elif [[ $branch_name == *"uat"* ]]; then
  current_environment="uat"
  bump_type="minor"
elif [[ $branch_name == *"main"* || $branch_name == *"prod"* ]]; then
  current_environment="prod"
  bump_type="major"
else
  echo "Unsupported branch/environment"
  exit 1
fi

# Fetch all tags related to the component across all envs
tag_pattern="$component_name-*-*"
last_tag=$(git tag --list "$tag_pattern" | sort -V | tail -n 1)

# Extract version from last tag
if [[ $last_tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
else
  major=0
  minor=0
  patch=0
fi

# Bump version
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

# Final tag
commit_hash=$(git rev-parse --short HEAD)
next_tag="$component_name-$current_environment-$major.$minor.$patch-$commit_hash"

echo "$next_tag"
