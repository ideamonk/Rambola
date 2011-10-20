# Rambola helper - configurations, helper functions

# Auto-filled variables
USER_NAME=$1
SELF=Rambola:$(basename $0)

# Constants
AS_USER="sudo -u ${USER_NAME} "
RSYNC="/usr/local/bin/rsync -aNHAXx --delete --fileflags --protect-decmpfs " 
SLEEP_DELAY=60 # re-check count every one minute
let SAFETY_BACKUP_INTERVAL=45 # backup interval in minutes

# Settings
RAMDISK_SIZE=1024 # Size in Mega Bytes.
RAMDISK_NAME="RamDisk"
SNAPSHOT_LOCATION="/Users/${USER_NAME}/Library/CachesSnapshot${RAMDISK_NAME}/"
TIMELY_BACKUP=yes

# Variables
COUNT=0

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
   $AS_USER exec 5>"/Volumes/${RAMDISK_NAME}/.lock.${USER_NAME}"
}

function unlock_ramdisk
{
   $AS_USER exec 5>&-
   $AS_USER rm "/Volumes/${RAMDISK_NAME}/.lock.${USER_NAME}"
}

function create_ramdisk 
{
  # Check if ramdisk is not already created and mounted.
  if [ ! -d "/Volumes/${RAMDISK_NAME}" ]; then
     log "Creating Ram disk (\"${RAMDISK_NAME}\") with a size of: ${RAMDISK_SIZE}MB."
     let RAMDISK_BLOCKSIZE=2048*${RAMDISK_SIZE} # Size in blocks.

     BLOCK_DEVICE=$($AS_USER hdiutil attach -nomount ram://${RAMDISK_BLOCKSIZE})
     $AS_USER diskutil eraseVolume HFS+ "$RAMDISK_NAME" $BLOCK_DEVICE
     
     # Update so every user can write to it while pertaining its own
     # user permissions.
     $AS_USER mount -u -o owners "/Volumes/${RAMDISK_NAME}"
     $AS_USER chmod g+w "/Volumes/${RAMDISK_NAME}"
     
  else
     log "Ram disk (\"${RAMDISK_NAME}\") already created."
  fi

}

function restore_contents_from_snapshot
{
  # Check if snapshot path exists
  if [ ! -d ${SNAPSHOT_LOCATION} ]; then
      log "Snapshot location missing: \"${SNAPSHOT_LOCATION}\" not found."
      log "Creating snapshot path"
      $AS_USER mkdir -p ${SNAPSHOT_LOCATION}
  fi
  
   DEST="/Volumes/${RAMDISK_NAME}/"
   log "Restoring snapshot from \"${SNAPSHOT_LOCATION}\" to \"${DEST}\"."
   $AS_USER $RSYNC "${SNAPSHOT_LOCATION}" "${DEST}"
}

function store_contents_on_snapshot
{
  SOURCE="/Volumes/${RAMDISK_NAME}/"
  if [ ! -d "$SOURCE" ]; then
   quit "Directory: \"$SOURCE\" does not exist."
  fi 
  
  log "Storing snapshot from \"${SOURCE}\" to \"${SNAPSHOT_LOCATION}\"."
  $AS_USER $RSYNC "${SOURCE}" "${SNAPSHOT_LOCATION}"
}


function store_periodically
{
   let COUNT=COUNT+1
	 if [[ $COUNT -gt $SAFETY_BACKUP_INTERVAL ]]; then
	   log "Starting power failure preventive backup."
	   store_contents_on_snapshot
	   let COUNT=0
   fi
}


function shutdown_rambola
{
  log "Shutdown request received."
  store_contents_on_snapshot
  unlock_ramdisk
  quit "Shutdown request finished."
}
