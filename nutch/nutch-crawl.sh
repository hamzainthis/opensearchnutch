#!/bin/bash

# Set environment variables for Nutch paths
NUTCH_HOME="/root/nutch_source/runtime/local/bin/nutch"
CRAWL_DB="/root/nutch_source/runtime/local/crawl/crawldb"
LINK_DB="/root/nutch_source/runtime/local/crawl/linkdb"
SEED_URLS="/root/nutch_source/runtime/local/urls/seed.txt"
SEGMENTS_DIR="/root/nutch_source/runtime/local/crawl/segments"
LOG_FILE="crawl.log"

# Inject URLs into CrawlDb
$NUTCH_HOME inject $CRAWL_DB $SEED_URLS

# Generate segments
$NUTCH_HOME generate $CRAWL_DB $SEGMENTS_DIR

# Fetch content, parse, and update CrawlDb and LinkDb
for segment in $(ls -d $SEGMENTS_DIR/*); do
    echo "Fetching segment $segment" >> $LOG_FILE
    $NUTCH_HOME fetch "$segment"
    $NUTCH_HOME parse "$segment"
    $NUTCH_HOME updatedb "$CRAWL_DB" "$segment"
done



# Generate segments
$NUTCH_HOME generate $CRAWL_DB $SEGMENTS_DIR -topN 20

LAST_SEGMENT=""

for segment in $(ls -d $SEGMENTS_DIR/*); do
    LAST_SEGMENT="$segment"
done

# Check if we found a segment
if [ -n "$LAST_SEGMENT" ]; then
    echo "Fetching segment $LAST_SEGMENT" >> $LOG_FILE
    $NUTCH_HOME fetch "$LAST_SEGMENT"
    $NUTCH_HOME parse "$LAST_SEGMENT"
    $NUTCH_HOME updatedb $CRAWL_DB "$LAST_SEGMENT"
else
    echo "No segments found in $SEGMENTS_DIR" >> $LOG_FILE
fi

$NUTCH_HOME generate $CRAWL_DB $SEGMENTS_DIR -topN 20

LAST_SEGMENT1=""

for segment in $(ls -d $SEGMENTS_DIR/*); do
    LAST_SEGMENT1="$segment"
done

# Check if we found a segment
if [ -n "$LAST_SEGMENT1" ]; then
    echo "Fetching segment $LAST_SEGMENT1" >> $LOG_FILE
    $NUTCH_HOME fetch "$LAST_SEGMENT1"
    $NUTCH_HOME parse "$LAST_SEGMENT1"
    $NUTCH_HOME updatedb $CRAWL_DB "$LAST_SEGMENT1"
else
    echo "No segments found in $SEGMENTS_DIR" >> $LOG_FILE
fi

# Invert links and update LinkDb
$NUTCH_HOME invertlinks $LINK_DB -dir $SEGMENTS_DIR

# Index the crawled data into OpenSearch (or Solr)
$NUTCH_HOME index $CRAWL_DB -linkdb $LINK_DB -dir $SEGMENTS_DIR -filter -normalize -deleteGone

# Keep the container running
tail -f /dev/null

