# easydread.com

Website for easydread, a seven-piece Conscious-Rock-Reggae band from Bedfordshire, UK.

## Project Structure

```
site/               # Static website files (downloaded from FTP)
  index.html        # Main page - gigs listing with Bandsintown widget
  videos.html       # Videos page - embedded YouTube videos
  images/           # Band photos, logos, social icons
  style/            # CSS (easydread.css, normalize.css)
  video/            # Video files (.mov) - large files
scripts/
  ftp-download.sh   # Downloads site from FTP using 1Password credentials
```

## FTP Access

Credentials stored in 1Password (personal account):
- Item: `easydread.com`
- Host: `ftp://easydread.com`
- Uses `op read --account my` to fetch credentials

### Download site from FTP

```bash
# Full download
./scripts/ftp-download.sh site

# Skip large video files
SKIP_DIRS="video" ./scripts/ftp-download.sh site
```

## Site Details

- Static HTML site with embedded widgets (Bandsintown for gigs, YouTube for videos, Bandcamp player)
- Uses Google Analytics (UA-71619031-1)
- Black background with green accent links (#00FF00 / LawnGreen)
- Contact: booking@easydread.com

## External Services

- Bandcamp: easydread.bandcamp.com
- YouTube: UCShZCj7av3AoLn-fC_4abDQ
- Twitter: @easydreadmusic
- Facebook: /easydread
- Instagram: @easydreadmusic
