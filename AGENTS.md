# easydread.com Agent Instructions

## Hosting

- The static site in `docs/` is deployed to the private site bucket and served through
  CloudFront.
- `.github/workflows/deploy.yml` runs `aws s3 sync docs/ ... --delete`. Treat `docs/` as the
  authoritative contents of the site bucket.
- Audio is stored in the separate private bucket
  `easydread-com-media-015311074066` and served at `https://easydread.com/audio/`.
- Never sync the site deployment to the media bucket or add a command that deletes media
  objects. The separate bucket is the safety boundary for files that are not stored in Git.
- Hosting resources are managed by `infra/hosting.yaml` in `us-east-1`. Route 53 resources are
  managed by `infra/dns.yaml` in `eu-west-1`.
- GitHub Actions assumes the `easydread-ci` OIDC role. Its permissions are managed in the
  adjacent `../don-personal-iam` repository and must be deployed before dependent site changes.

## Audio

The local `don-easydread` profile assumes the `easydread-operator` role. If the profile is not
configured, run:

```bash
../don-personal-iam/scripts/install-aws-role-profiles.sh
aws login --profile don-cli
```

Upload an MP3 with:

```bash
aws s3 cp "song-name.mp3" \
  "s3://easydread-com-media-015311074066/audio/song-name.mp3" \
  --content-type audio/mpeg \
  --cache-control "public,max-age=31536000,immutable" \
  --profile don-easydread
```

The resulting URL is `https://easydread.com/audio/song-name.mp3`. Prefer a new filename when
replacing released audio because CloudFront caches these URLs as immutable.

Do not add MP3 files to Git unless explicitly requested. Do not upload, overwrite, or delete
media objects without explicit user instruction.

## Verification

Validate infrastructure and workflows before committing changes:

```bash
cfn-lint infra/hosting.yaml infra/dns.yaml
actionlint .github/workflows/deploy.yml .github/workflows/deploy-dns.yml
git diff --check
```

Serve the site locally with `make serve`.
