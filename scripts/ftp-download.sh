#!/bin/bash
# Download easydread.com FTP site contents
# Uses 1Password CLI for credentials

set -e

FTP_HOST="ftp://easydread.com"
FTP_USER="easydread"
FTP_PASS=$(op read --account my 'op://Private/easydread.com/password')
DEST_DIR="${1:-site}"

mkdir -p "$DEST_DIR"

echo "Downloading from $FTP_HOST to $DEST_DIR/"

# Recursive download using curl
# -r = recursive
# -l 0 = unlimited recursion depth
SKIP_DIRS="${SKIP_DIRS:-}"

download_recursive() {
    local remote_path="$1"
    local local_path="$2"

    # List directory contents
    local listing=$(curl -s --list-only -u "$FTP_USER:$FTP_PASS" "${FTP_HOST}${remote_path}")

    for item in $listing; do
        # Skip empty lines
        [[ -z "$item" ]] && continue

        # Try to list it as directory
        local sublist=$(curl -s --list-only -u "$FTP_USER:$FTP_PASS" "${FTP_HOST}${remote_path}${item}/" 2>/dev/null)

        if [[ -n "$sublist" ]]; then
            # It's a directory - check if we should skip it
            if [[ " $SKIP_DIRS " =~ " $item " ]]; then
                echo "  [SKIP] ${remote_path}${item}/"
                continue
            fi
            echo "  [DIR] ${remote_path}${item}/"
            mkdir -p "${local_path}${item}"
            download_recursive "${remote_path}${item}/" "${local_path}${item}/"
        else
            # It's a file
            echo "  [FILE] ${remote_path}${item}"
            curl -s -u "$FTP_USER:$FTP_PASS" "${FTP_HOST}${remote_path}${item}" -o "${local_path}${item}"
        fi
    done
}

download_recursive "/" "$DEST_DIR/"

echo "Download complete!"
