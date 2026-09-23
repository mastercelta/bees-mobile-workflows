#!/usr/bin/env bash
set -euo pipefail

SOURCE_SHA="${1:?source SHA required}"
ENVIRONMENT="${2:?environment required}"
FLOOR="${BUILD_NUMBER_FLOOR:-99}"
RETRIES="${BUILD_NUMBER_RETRIES:-100}"

[[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "source SHA must be 40 lowercase hex characters" >&2; exit 2; }
[[ "$FLOOR" =~ ^[0-9]+$ ]] || { echo "BUILD_NUMBER_FLOOR must be numeric" >&2; exit 2; }
[[ "$RETRIES" =~ ^[0-9]+$ ]] || { echo "BUILD_NUMBER_RETRIES must be numeric" >&2; exit 2; }
[[ "$ENVIRONMENT" =~ ^(dev|qa|staging|prod)$ ]] || { echo "environment must be dev, qa, staging or prod" >&2; exit 2; }

git fetch origin --tags --force
max="$FLOOR"
while IFS= read -r tag; do
  number="${tag##*-}"
  [[ "$number" =~ ^[0-9]+$ ]] || continue
  (( number > max )) && max="$number"
done < <(git tag -l 'dev-*' -l 'qa-*' -l 'staging-*' -l 'prod-*')

for ((attempt=1; attempt<=RETRIES; attempt++)); do
  next=$((max + attempt))
  tag="$ENVIRONMENT-$next"
  git tag -a "$tag" "$SOURCE_SHA" -m "Reserve $ENVIRONMENT mobile build $next for $SOURCE_SHA"
  if git push origin "refs/tags/$tag"; then
    printf '%s\n' "$next"
    exit 0
  fi
  git tag -d "$tag" >/dev/null 2>&1 || true
  git fetch origin --tags --force
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    continue
  fi
  echo "failed to reserve $tag for an unknown reason" >&2
  exit 1
done

echo "could not reserve a build number after $RETRIES attempts" >&2
exit 1
