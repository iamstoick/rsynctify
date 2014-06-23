#!/usr/bin/env bash
#
# @file
#   A one directional auto-sync triggered by inotify.
#   The inotify-utils must be installed in the system
#   before using this script.
#
# @source
#   $SOURCE - A git repository. 
#
# @destination
#   $DEST - Apache's document root.
#
# @author
#   Gerald Villorente
#   2014
#
# @description
#   Auto-sync changes after Git pushed the updates to 
#   $SOURCE. Changes will be then sync to 
#   $DEST.

# The source directory.
SOURCE="/home/azureuser/repo"
# Your target directory.
DEST="/var/www"

EVENTS="CREATE,DELETE,MODIFY,MOVED_FROM,MOVED_TO"

# Check if inotofywait is installed.
hash inotifywait 2>/dev/null
if [ $? -eq 1 ]; then
  echo "Unable to execute the script. Please make sure that inotify-utils
  is installed in the system."
  exit 1
fi

inotifywait -e "$EVENTS" -m -r --format '%:e %f' $SOURCE --exclude '$SOURCE/.*cache.*' | (
WAITING="";
while true; do
  LINE="";
  read -t 1 LINE;
  if test -z "$LINE"; then
    if test ! -z "$WAITING"; then
      echo "CHANGE";
      WAITING="";
      # Merge the changes before running rsync.
      cd $GIT_REPO
      git merge master -m "Merging master to prod"
      sudo rsync --update -alvzr --exclude '*cache*' --exclude '*.git*' $SOURCE/* $DEST
    fi;
  else
    WAITING=1;
  fi;
done)
