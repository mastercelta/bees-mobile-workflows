# Bees Mobile Workflows

Reusable, versioned release workflows for Bees Flutter applications.

## v1 contract

- Candidate AAB and Store publication are separate manual approval boundaries.
- Application source is always an immutable SHA validated against an allowed branch.
- Android and iOS share one monotonic build-number stream using annotated `build-N` tags.
- Signing identities remain on BeesMac and are referenced by path; Store runs never create or rotate keys.
- Candidate AABs use conventional Flutter builds and never publish to Stores.
- Store Android and iOS run independently so one platform result cannot hide the other.
- Shorebird is optional per repository and per deployment, and is rejected outside `production`.

## Repository variables

Each caller repository defines:

```text
STORE_APP_NAME
STORE_SOURCE_REF
STORE_BUNDLE_ID
STORE_CATALOG_CLIENT
PUBLISH_STORES=android|ios|both
BUILD_NUMBER_FLOOR
ANDROID_SIGNING_REF
IOS_SIGNING_REF
SHOREBIRD_ENABLED=true|false
```

Recommended pilot defaults:

```text
CosmoAgro      SHOREBIRD_ENABLED=true
Rútalink       SHOREBIRD_ENABLED=false
AppClubby      SHOREBIRD_ENABLED=false
Restaurante    SHOREBIRD_ENABLED=false
GoLocal        SHOREBIRD_ENABLED=false
```

## Shorebird selection

The Store wrapper exposes `shorebird_mode`:

```text
default  Use repository variable SHOREBIRD_ENABLED
true     Enable for this deployment
false    Disable for this deployment
```

Even when the repository default is `true`, the central workflow rejects Shorebird for `internal`, `alpha`, or `beta`. It is available only when `play_track=production`, `api_environment=prod`, and the source is `master` or `release/*`.

## Caller wrapper: Generate AAB

```yaml
name: Generar AAB

on:
  workflow_dispatch:
    inputs:
      source_branch:
        description: Rama
        type: choice
        options: [work, develop, qa]
        default: work
        required: true
      source_ref:
        description: SHA inmutable inyectado por Tracker
        type: string
        required: true
      ambiente:
        description: API
        type: choice
        options: [dev, qa]
        default: dev
        required: true

jobs:
  candidate:
    uses: mastercelta/bees-mobile-workflows/.github/workflows/candidate-aab.yml@v1
    with:
      app_name: ${{ vars.STORE_APP_NAME }}
      bundle_id: ${{ vars.STORE_BUNDLE_ID }}
      catalog_client: ${{ vars.STORE_CATALOG_CLIENT }}
      source_branch: ${{ inputs.source_branch }}
      source_sha: ${{ inputs.source_ref }}
      api_environment: ${{ inputs.ambiente }}
      build_number_floor: ${{ fromJSON(vars.BUILD_NUMBER_FLOOR || '99') }}
      android_signing_ref: ${{ vars.ANDROID_SIGNING_REF }}
    secrets: inherit
```

## Caller wrapper: Publish to Stores

```yaml
name: Subir a tiendas

on:
  workflow_dispatch:
    inputs:
      source_ref:
        description: SHA inmutable inyectado por Tracker
        type: string
        required: true
      ambiente:
        description: API
        type: choice
        options: [dev, qa, staging, prod]
        default: qa
        required: true
      track:
        description: Canal Google Play
        type: choice
        options: [internal, alpha, beta, production]
        default: internal
        required: true
      shorebird_mode:
        description: Shorebird para este deploy
        type: choice
        options: [default, 'true', 'false']
        default: default
        required: true

jobs:
  publish:
    uses: mastercelta/bees-mobile-workflows/.github/workflows/store-publish.yml@v1
    with:
      app_name: ${{ vars.STORE_APP_NAME }}
      bundle_id: ${{ vars.STORE_BUNDLE_ID }}
      catalog_client: ${{ vars.STORE_CATALOG_CLIENT }}
      source_branch: ${{ vars.STORE_SOURCE_REF }}
      source_sha: ${{ inputs.source_ref }}
      api_environment: ${{ inputs.ambiente }}
      play_track: ${{ inputs.track }}
      platforms: ${{ vars.PUBLISH_STORES }}
      build_number_floor: ${{ fromJSON(vars.BUILD_NUMBER_FLOOR || '99') }}
      android_signing_ref: ${{ vars.ANDROID_SIGNING_REF }}
      ios_signing_ref: ${{ vars.IOS_SIGNING_REF }}
      shorebird_default: ${{ vars.SHOREBIRD_ENABLED == 'true' }}
      shorebird_mode: ${{ inputs.shorebird_mode }}
    secrets: inherit
```

## Versioning

- Immutable releases: `v1.0.0`, `v1.1.0`, etc.
- Stable compatible channel: `v1`.
- Breaking changes use a new major tag.

Pilot callers: Rútalink, AppClubby, Restaurante, and GoLocal. Creation Basketball and ViaRentaCar are intentionally out of scope until the pilot is accepted.
