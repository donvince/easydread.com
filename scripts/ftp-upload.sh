#!/bin/bash
# Upload local changes to easydread.com FTP site
# Uses 1Password CLI for credentials
# Only uploads changed files (lftp compares timestamps/sizes)

set -e

FTP_HOST="easydread.com"
FTP_USER="easydread"
FTP_PASS=$(op read --account my 'op://Private/easydread.com/password')
SOURCE_DIR="${1:-site}"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' not found"
    exit 1
fi

# Directories to skip (space-separated)
SKIP_DIRS="${SKIP_DIRS:-video}"

# Build exclude arguments for lftp
EXCLUDE_ARGS=""
for dir in $SKIP_DIRS; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude $dir/"
done

echo "Uploading from $SOURCE_DIR/ to ftp://$FTP_HOST/"
echo "Skipping: ${SKIP_DIRS:-none}"
echo ""

# Use lftp mirror --reverse for smart uploads
# --reverse: upload (local -> remote) instead of download
# --only-newer: only upload if local file is newer
# --verbose: show what's being uploaded
# --no-perms: don't try to set permissions (avoids 550 errors)
# --no-symlinks: skip symbolic links
# --ignore-time: use size comparison only (more reliable for some servers)
lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" <<EOF
set ftp:ssl-allow no
set ftp:passive-mode on
lcd $SOURCE_DIR
mirror --reverse --only-newer --verbose --no-perms --no-symlinks $EXCLUDE_ARGS . .
bye
EOF

echo ""
echo "Upload complete!"
