#!/usr/bin/env bash
# Rambola LoginHook script, sets up ramdisk, spawns timely if configured

APP_HOME=$(dirname $0)
source $APP_HOME/helper.sh $1
SELF=Rambola:$(/usr/bin/basename $0)

# Startup
create_ramdisk
lock_ramdisk 
restore_contents_from_snapshot

if [ "$TIMELY_BACKUP" == "yes" ]; then
  log "Spawning timely.sh for extra safety"
  $APP_HOME/timely.sh $1 &
fi

log "Rambola LoginHook finished."