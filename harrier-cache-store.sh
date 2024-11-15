#!/bin/bash

# Check if cache key exists
if [ ls ../../../s3bucket/node_modules_cache_key/${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}*.txt 1> /dev/null 2>&1]
then
  echo "cache key file exists."
  echo "KEY_EXISTS=true" >> $GITHUB_ENV
else
  echo "cache key file does not exist."
  echo "KEY_EXISTS=false" >> $GITHUB_ENV
fi

# Get latest cache key if it exists
if [${{ env.KEY_EXISTS == 'true' }}]
then
  latest_key_file=$(ls ../../../s3bucket/node_modules_cache_key/${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}*.txt | sort -t'_' -k2,2 -r | head -n 1)
  echo "Latest file: $latest_key_file"
  echo "LATEST_KEY=$latest_key_file" >> $GITHUB_ENV

# Check if cache key matches
if [${{ env.KEY_EXISTS == 'true' }}]
then
  if [ "${{ hashFiles('package.json') }}" == "$(cat ${{ env.LATEST_KEY }})" ]
  then
    echo "cache key matches - it has not changed."
    echo "CACHE_MATCH=true" >> $GITHUB_ENV
  else
    echo "cache key does not match - it has changed."
    echo "CACHE_MATCH=false" >> $GITHUB_ENV
  fi
        
# Cache current node_modules directory if no cache key exists or if cache key does not match
if [${{ env.KEY_EXISTS == 'false' || (env.KEY_EXISTS == 'true' && env.CACHE_MATCH == 'false') }}]
then
  echo "creating new cached tar file."
  tar -czf ${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}.tar.gz node_modules
  cp ${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}.tar.gz ../../../s3bucket/node_modules_cached_tar/

# Create new cache key
TIMESTAMP=$(date +'%Y-%m-%d-%H-%M-%S')
echo "create new cache key with timestamp: $TIMESTAMP"
echo '${{ hashFiles('package.json') }}' > ../../../s3bucket/node_modules_cache_key/${GITHUB_REPOSITORY_OWNER}-${GITHUB_REPOSITORY##*/}-${GITHUB_REF#refs/heads/}_${TIMESTAMP}.txt
