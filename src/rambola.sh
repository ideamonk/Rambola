#!/usr/bin/env bash
:<<'_'
                   __                 _           _       
                  /__\ __ _ _ __ ___ | |__   ___ | | __ _ 
                 / \/// _` | '_ ` _ \| '_ \ / _ \| |/ _` |
                / _  \ (_| | | | | | | |_) | (_) | | (_| |
                \/ \_/\__,_|_| |_| |_|_.__/ \___/|_|\__,_|

My very own improvised RamDisk Manager.
Heavily based on QuickSander's [1] Cache2RAM script [2]

Author : Abhishek Mishra 

[1] http://hints.macworld.com/users.php?mode=profile&uid=1054078
[2] http://hints.macworld.com/article.php?story=2011010204203424
_

# Auto-filled variables
USER_NAME=$(/usr/bin/who am i | /usr/bin/awk '{print $1}')
SELF=$(/usr/bin/basename $0)
USER_ID=$(id | sed 's/uid=\([0-9]*\).*/\1/')
OUR_PID=$(ps -ef | grep ${SELF} | grep -v 'grep' | awk -v uid="$USER_ID" '$1==uid {print $2; exit;}') # Only first occurence from the current user.


# Constants
RSYNC="/usr/local/bin/rsync -aNHAXx --fileflags --protect-decmpfs " 
SLEEP_DELAY=1
let SAFETY_BACKUP_INTERVAL=(60*60*2)/SLEEP_DELAY # Create backup in case of power failure every 2 hours.

# Settings
RAMDISK_SIZE=1024 # Size in Mega Bytes.
RAMDISK_NAME="RamDisk"
SNAPSHOT_LOCATION="/Users/${USER_NAME}/Library/CachesSnapshot${RAMDISK_NAME}/"

# Variables
COUNT=

# Operational function declaration
function log
{
  echo "${SELF}: $1"
}

function quit
{
  log "Quiting: $1"
  exit 0
}

function lock_ramdisk
{
   exec 5>"/Volumes/${RAMDISK_NAME}/.lock.${USER_NAME}"
}

function unlock_ramdisk
{
   exec 5>&-
   rm "/Volumes/${RAMDISK_NAME}/.lock.${USER_NAME}"
}

function create_ramdisk 
{
  # Check if ramdisk is not already created and mounted.
  if [ ! -d "/Volumes/${RAMDISK_NAME}" ]; then
     log "Creating Ram disk (\"${RAMDISK_NAME}\") with a size of: ${RAMDISK_SIZE}MB."
     let RAMDISK_BLOCKSIZE=2048*${RAMDISK_SIZE} # Size in blocks.

     BLOCK_DEVICE=$(hdiutil attach -nomount ram://${RAMDISK_BLOCKSIZE})
     diskutil eraseVolume HFS+ "$RAMDISK_NAME" $BLOCK_DEVICE
     
     # Update so every user can write to it while pertaining its own
     # user permissions.
     mount -u -o owners "/Volumes/${RAMDISK_NAME}"
     chmod g+w "/Volumes/${RAMDISK_NAME}"
     
  else
     log "Ram disk (\"${RAMDISK_NAME}\") already created."
  fi

}

function restore_contents_from_snapshot
{
  # Check if snapshot exists
  if [ -d ${SNAPSHOT_LOCATION} ]; then
     DEST="/Volumes/${RAMDISK_NAME}/${USER_NAME}/"

     log "Restoring snapshot from \"${SNAPSHOT_LOCATION}\" to \"${DEST}\"."
     $RSYNC "${SNAPSHOT_LOCATION}" "${DEST}"
  else
     log "No restore required: \"${SNAPSHOT_LOCATION}\" not found."
  fi
}

function store_contents_on_snapshot
{
  SOURCE="/Volumes/${RAMDISK_NAME}/${USER_NAME}/"
  if [ ! -d "$SOURCE" ]; then
   quit "Directory: \"$SOURCE\" does not exist."
  fi 
  
  log "Storing snapshot from \"${SOURCE}\" to \"${SNAPSHOT_LOCATION}\"."
  $RSYNC "${SOURCE}" "${SNAPSHOT_LOCATION}"
}


function store_periodically
{
   let COUNT=COUNT+1
	if [ "0$COUNT" -gt $SAFETY_BACKUP_INTERVAL ]; then
	   log "Starting power failure preventive backup."
	   store_contents_on_snapshot
	   let COUNT=0
   fi
}


function shutdown
{
  log "Shutdown request received."
  store_contents_on_snapshot
  unlock_ramdisk
  quit "Shutdown request finished."
}


# Shutdown: Register terminate signals.
trap shutdown TERM 



# Startup
create_ramdisk
lock_ramdisk 
restore_contents_from_snapshot

# Renice ourself to a low priority
log "Lowering priority from $OUR_PID to 19."
/usr/bin/renice 19 ${OUR_PID}

# Main loop
while [ 1 ]; do
	sleep ${SLEEP_DELAY}
	
	# Store to snapshot every hour for extra safety (power failure, etc.)
	#store_periodically
done