# GitHub Pages Migration Plan

## Goal

Move easydread.com from FTP-hosted static site to GitHub Pages to gain HTTPS.

## Repo

`donvince/easydread.com` — site lives in `site/` (will become `docs/`)

---

## Phase 1 — Prepare repo (this branch)

### 1.1 Rename `site/` → `docs/`

GitHub Pages can serve from a `docs/` folder on the main branch. Rename the folder and
GitHub Pages will be configured to use it. No CI/CD needed — just push and GH Pages
serves it.

### 1.2 Fix HTTP URLs in the site

All internal `http://www.easydread.com/` references must become `https://`:

**index.html:**
- `og:url` meta tag
- `og:image` meta tag
- Facebook img src
- Instagram img src
- Bandcamp links (external but use http)

**videos.html:**
- Facebook img src
- Instagram img src

**robots.txt:**
- Sitemap URL (also wrong extension: `.txt` → `.xml`)

**sitemap.xml:**
- Both `<loc>` entries

### 1.3 Add CNAME file

`docs/CNAME` must contain the custom domain:
```
easydread.com
```
(no www prefix — apex domain, since GH Pages will handle both)

### 1.4 Add .nojekyll

`docs/.nojekyll` — empty file, prevents Jekyll from processing the site.
Required because the site has no Jekyll config and Jekyll would mangle some files.

---

## Phase 2 — Enable GitHub Pages

In GitHub repo settings → Pages:
- Source: `main` branch, `/docs` folder
- Custom domain: `easydread.com`
- Enforce HTTPS: ✓ (enable after DNS is pointing)

URL while testing (before DNS change): `https://donvince.github.io/easydread.com/`

---

## Phase 3 — DNS migration (AWS Route 53)

### Current DNS (to be confirmed)

Run to retrieve:
```bash
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>
```

### Target DNS records

**For apex domain (easydread.com) — A records pointing to GitHub Pages:**
```
easydread.com  A  185.199.108.153
easydread.com  A  185.199.109.153
easydread.com  A  185.199.110.153
easydread.com  A  185.199.111.153
```

**For www subdomain — CNAME:**
```
www.easydread.com  CNAME  donvince.github.io
```

**Leave untouched:** MX records (email), any other TXT/SPF records.

### Migration sequence

1. Complete Phase 1 + 2 and verify site works at `donvince.github.io/easydread.com/`
2. Update Route 53 A records to GitHub Pages IPs
3. Update/add www CNAME to `donvince.github.io`
4. Wait for DNS propagation (TTL-dependent, typically 5–60 min)
5. Verify `https://easydread.com` loads correctly
6. Enable "Enforce HTTPS" in GitHub Pages settings (if not already on)

---

## Phase 4 — Cleanup

- Remove `scripts/ftp-upload.sh` and `scripts/ftp-download.sh` (or keep for archive)
- Update `CLAUDE.md` to reflect new hosting
- Update `robots.txt` sitemap URL to use `https://`

---

## Status

- [ ] Phase 1: Site prep (this branch)
- [ ] Phase 2: Enable GH Pages in repo settings
- [ ] Phase 3: DNS cutover
- [ ] Phase 4: Cleanup

---

## AWS Route 53 Findings

Zone ID: `Z05099481R278MSYRMTGJ`

| Name | Type | Current value | Action |
|------|------|---------------|--------|
| `easydread.com.` | A | `178.79.166.99` (friend's server) | **Replace** with 4 GH Pages IPs |
| `www.easydread.com.` | CNAME | `easydread.com.` | **Update** to `donvince.github.io.` |
| `ftp.easydread.com.` | CNAME | `easydread.com.` | **Remove** (FTP hosting retired) |
| `easydread.com.` | MX | `mx1/mx2.improvmx.com.` | Keep (email forwarding) |
| `easydread.com.` | TXT | SPF for ImprovMX | Keep |
| `easydread.com.` | NS/SOA | AWS nameservers | Keep |

DNS changes are codified in `infra/easydread.yaml` (CloudFormation).

### Deploying the CF stack

```bash
# First deploy (creates IAM user + updates DNS)
aws cloudformation deploy \
  --template-file infra/easydread.yaml \
  --stack-name easydread \
  --capabilities CAPABILITY_NAMED_IAM \
  --profile don-root

# Generate access key for the new IAM user (do once after stack creates)
aws iam create-access-key --user-name easydread-cli --profile don-root

# Add the new profile locally
aws configure --profile easydread
# Use the key/secret from above; region = eu-west-1
```
