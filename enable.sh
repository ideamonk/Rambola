#!/usr/bin/env bash
# Rambola installer (unlike Cache2RAM this is based on Login window hooks)

APP_NAME=Rambola
APP_DEST=`pwd`

function setup()
{
  echo "Adding ${APP_NAME} to LoginHook (needs root)..."
  sudo defaults write com.apple.loginwindow LoginHook $APP_DEST/src/rambola.sh
  sudo defaults write com.apple.loginwindow LogoutHook $APP_DEST/src/logout.sh
}

echo "This will install and setup ${APP_NAME} at ${APP_DEST}"
echo
read -p "Continue (y/n) :"

if [ "$REPLY" == "y" ]; then
  setup
fi
