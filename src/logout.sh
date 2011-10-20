#!/usr/bin/env bash
# Rambola LogoutHook script, backs up ramdisk on logout/restart/shutdown

APP_HOME=$(dirname $0)
source $APP_HOME/helper.sh $1
SELF=Rambola:$(/usr/bin/basename $0)

shutdown_rambola