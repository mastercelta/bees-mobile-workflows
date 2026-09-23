#!/usr/bin/env bash
set -euo pipefail

required=(APP_NAME BUNDLE_ID CATALOG_CLIENT SOURCE_SHA SOURCE_BRANCH API_ENV PLATFORMS)
for name in "${required[@]}"; do
  [[ -n "${!name:-}" ]] || { echo "$name is required" >&2; exit 2; }
done
[[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "SOURCE_SHA must be immutable 40-char SHA" >&2; exit 2; }
[[ "$SOURCE_BRANCH" =~ ^(work|develop|qa|master|release/[A-Za-z0-9._/-]+)$ ]] || { echo "unsupported source branch" >&2; exit 2; }
[[ "$API_ENV" =~ ^(dev|qa|staging|prod)$ ]] || { echo "unsupported API environment" >&2; exit 2; }
[[ "$PLATFORMS" =~ ^(android|ios|both)$ ]] || { echo "PLATFORMS must be android, ios or both" >&2; exit 2; }
[[ "$BUNDLE_ID" =~ ^[A-Za-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)+$ ]] || { echo "invalid bundle id" >&2; exit 2; }

git fetch origin "$SOURCE_BRANCH" --no-tags
git cat-file -e "$SOURCE_SHA^{commit}"
git merge-base --is-ancestor "$SOURCE_SHA" FETCH_HEAD || { echo "$SOURCE_SHA does not belong to $SOURCE_BRANCH" >&2; exit 2; }

if [[ -n "${PLAY_TRACK:-}" ]]; then
  [[ "$PLAY_TRACK" =~ ^(internal|alpha|beta|production)$ ]] || { echo "unsupported Play track" >&2; exit 2; }
  if [[ "$PLAY_TRACK" == production ]]; then
    [[ "$API_ENV" == prod ]] || { echo "production track requires API_ENV=prod" >&2; exit 2; }
    [[ "$SOURCE_BRANCH" == master || "$SOURCE_BRANCH" == release/* ]] || { echo "production requires master or release/* source" >&2; exit 2; }
  fi
fi

if [[ "${SHOREBIRD_ENABLED:-false}" == true ]]; then
  [[ "${PLAY_TRACK:-}" == production ]] || { echo "Shorebird is allowed only for production publication" >&2; exit 2; }
fi
