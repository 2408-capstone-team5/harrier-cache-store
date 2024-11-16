#!/bin/bash

# Define directory paths
CACHE_KEY_DIR="../../../s3bucket/node_modules_cache_key"
CACHE_TAR_DIR="../../../s3bucket/node_modules_cached_tar"

# Ensure the required directories exist
mkdir -p "$CACHE_KEY_DIR"
mkdir -p "$CACHE_TAR_DIR"

# Check if cache key exists
if ls "$CACHE_KEY_DIR/${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}"*.txt 1> /dev/null 2>&1; then
    echo "Cache key file exists."
    echo "KEY_EXISTS=true" >> $GITHUB_ENV
else
    echo "Cache key file does not exist."
    echo "KEY_EXISTS=false" >> $GITHUB_ENV
fi

# Source updated environment variables
source $GITHUB_ENV

# Get latest cache key if it exists
if [ "$KEY_EXISTS" == "true" ]; then
    latest_key_file=$(ls "$CACHE_KEY_DIR/${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}"*.txt | sort -t'_' -k2,2 -r | head -n 1)
    echo "Latest file: $latest_key_file"
    echo "LATEST_KEY=$latest_key_file" >> $GITHUB_ENV
fi

# Source updated environment variables again
source $GITHUB_ENV

# Check if cache key matches
if [ "$KEY_EXISTS" == "true" ]; then
    if [ "$(cat "$LATEST_KEY")" == "$HASH_FILES_PACKAGE_JSON" ]; then
        echo "Cache key matches - it has not changed."
        echo "CACHE_MATCH=true" >> $GITHUB_ENV
    else
        echo "Cache key does not match - it has changed."
        echo "CACHE_MATCH=false" >> $GITHUB_ENV
    fi
else
    echo "No cache key exists to match."
    echo "CACHE_MATCH=false" >> $GITHUB_ENV
fi

# Source updated environment variables again
source $GITHUB_ENV

# Cache current node_modules directory if no cache key exists or if cache key does not match
if [ "$KEY_EXISTS" == "false" ] || ([ "$KEY_EXISTS" == "true" ] && [ "$CACHE_MATCH" == "false" ]); then
    echo "Creating new cached tar file."
    tar -czvf "${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}.tar.gz" node_modules
    mv "${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}.tar.gz" "$CACHE_TAR_DIR/"

    # Create new cache key
    TIMESTAMP=$(date +'%Y-%m-%d-%H-%M-%S')
    echo "Creating new cache key with timestamp: $TIMESTAMP"
    echo "$HASH_FILES_PACKAGE_JSON" > "$CACHE_KEY_DIR/${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}_${TIMESTAMP}.txt"
fi
