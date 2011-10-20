#!/usr/bin/env bash
# removes loginwindow hooks for Rambola

APP_NAME=Rambola
APP_DEST=`pwd`

sudo defaults delete com.apple.loginwindow LoginHook
sudo defaults delete com.apple.loginwindow LogoutHook
