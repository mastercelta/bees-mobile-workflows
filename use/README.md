# Use in a new Flutter repository

Copy the four files under `use/.github/workflows/` into the target repository's `.github/workflows/` directory, then configure every value from `repository-variables.env.example` as a GitHub repository variable.

## Included entry points

```text
generate-aab.yml      Manual signed candidate; never publishes to Stores
store-publish.yml     Manual Play/TestFlight publication
shorebird-patch.yml   Manual Dart patch over latest prod-N release
tag-master.yml        Semantic vX.Y.Z tag when release/* reaches master
```

## Required decisions

- Set `STORE_SOURCE_REF` to the persistent Store source branch.
- Set `PUBLISH_STORES` to `android`, `ios`, or `both`.
- Set `BUILD_NUMBER_FLOOR` to the highest number already burned in Play/App Store, or `99` for a new app whose first build is 100.
- Use absolute BeesMac signing references. Never copy keystores or ASC keys into the repository.
- Set `SHOREBIRD_ENABLED=true` only for apps registered and verified in Shorebird. The patch wrapper fails closed when false.

## Tag streams

```text
dev-N / qa-N / staging-N / prod-N   One global mobile build sequence
vX.Y.Z                              Marketing version published from master
parche-X.Y.Z+N.P                    Patch P over production build N
```

## Installation check

After copying:

1. Run `actionlint` on the four wrappers.
2. Confirm the reusable repository is accessible from the private caller repository.
3. Run candidate preflight without Store publication.
4. Verify the AAB appears in Tracker and downloads with ZIP magic `PK`.
5. Test Play Internal and TestFlight separately before Production.
6. Enable Shorebird only after a conventional production release was built with Shorebird.
