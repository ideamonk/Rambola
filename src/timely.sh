#!/usr/bin/env bash
# Rambola timely backup, syncs cache snapshots on time

APP_HOME=$(dirname $0)
source $APP_HOME/helper.sh $1
SELF=Rambola:$(basename $0)

OUR_PID=$(ps -ef | grep ${SELF} | grep -v 'grep' | awk -v uid="$USER_ID" '$1==uid {print $2; exit;}') # Only first occurence from the current user.
USER_ID=$(id | sed 's/uid=\([0-9]*\).*/\1/')

# Renice ourself to a low priority
log "Lowering priority from $OUR_PID to 19."
/usr/bin/renice 19 ${OUR_PID}

# Main loop
while [ 1 ]; do
	sleep ${SLEEP_DELAY}
	
	# Store to snapshot every hour for extra safety (power failure, etc.)
	store_periodically
done