#!/bin/bash

# Number of days to look back for commits
NUM_DAYS=$1

# Output file
OUTPUT_FILE="work_history.txt"

# Initialize the output file
echo -n > $OUTPUT_FILE

# Loop through the past NUM_DAYS days
for (( i=0; i<NUM_DAYS; i++ ))
do
  # Get the date for the current day in the loop
  DATE=$(date -d "-$i days" +%Y-%m-%d)

  # Get commit messages for the current day
  COMMIT_MSGS=$(git log --since="$DATE 00:00" --until="$DATE 23:59" --reverse --pretty=format:"%an - %s")

  # If there are commit messages, add them to the output file
  if [ -n "$COMMIT_MSGS" ]; then
    echo "[$DATE]" >> $OUTPUT_FILE
    echo "$COMMIT_MSGS" | while read -r line; do
      echo "$line" >> $OUTPUT_FILE
    done
    echo "" >> $OUTPUT_FILE
  fi
done

echo "Commit history for the past $NUM_DAYS days has been saved to $OUTPUT_FILE"
