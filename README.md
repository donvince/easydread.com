# easydread.com
easydread are an seven piece Conscious-Rock-Reggae band from Bedfordshire

They combine sounds drawn from a wide range of influences, from Ska to Rap, soul to Punk.
As they seamlessly blend powerful political imagery with sweet harmonies and heavy grooves easydread will get you thinking as well as skanking.

Have a listen and find out more here: [easydread.com](https://easydread.com/)

## Hosting and deployment

The static site in `docs/` is stored in a private S3 bucket and served over HTTPS by
CloudFront. AWS resources are defined in `infra/hosting.yaml` and `infra/dns.yaml`.

Pushes to `main` that change the site, infrastructure, or deployment workflow run
`.github/workflows/deploy.yml`. The workflow provisions the hosting infrastructure, syncs
`docs/` to S3, and invalidates CloudFront. It does not change public DNS.

GitHub Actions authenticates through the `easydread-ci` OIDC role managed in the adjacent
`don-personal-iam` repository; no static AWS secrets are required. Deploy those IAM changes
before the first hosting deployment. The hosting stack is deployed in `us-east-1` because
CloudFront requires ACM certificates there; the DNS stack remains in `eu-west-1`.

The first deployment can take several minutes while ACM validates the domain and CloudFront
creates the distribution. After verifying the uploaded site, manually run the **Cut over DNS**
workflow to point the apex and `www` records at CloudFront. Disable GitHub Pages only after
`https://easydread.com` and `https://www.easydread.com` have been verified after cutover.

## Audio files

Audio under `https://easydread.com/audio/` is served from a separate private media bucket.
The site deployment never syncs or deletes objects in that bucket. Upload an MP3 with the
local operator profile:

```bash
aws s3 cp "song-name.mp3" \
  "s3://easydread-com-media-015311074066/audio/song-name.mp3" \
  --content-type audio/mpeg \
  --cache-control "public,max-age=31536000,immutable" \
  --profile don-easydread
```

Use a new filename when replacing released audio because CloudFront caches these immutable
URLs. Only the operator role can manage media objects; the site CI role can provision the
bucket but cannot upload or delete audio.

To perform the DNS cutover locally with the `don-easydread` AWS profile after hosting has
been deployed and verified:

```bash
./scripts/cf-deploy-dns.sh
```

## Generate the EPK PDF

Docker Desktop is the only local dependency. Generate a preview at
`output/pdf/easydread-epk.pdf` with:

```bash
make pdf
```

The first run downloads the pinned Chromium image. Docker reuses that image and the small
generator layer on later runs, so no local Node or npm registry access is required.

To write the PDF alongside the deployed web page, run:

```bash
make pdf-site
```
