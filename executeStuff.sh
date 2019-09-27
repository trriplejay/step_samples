#!/bin/bash -e

echo "executing this script!"
echo "will cause a single command to have multiple children"
wc -l "$STEP_JSON_PATH"
cat "$STEP_JSON_PATH" | jq '.step'
cat badfile
echo "hello, we shouldn't make it this far."
