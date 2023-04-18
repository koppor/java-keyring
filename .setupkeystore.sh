#!/bin/bash

keyring="$1"

set -x
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ] && [ "$keyring" == "gnome" ]; then 
  export $(dbus-launch)
  eval "$(echo '\n' | gnome-keyring-daemon --unlock)"
  echo xxx@gmail.com | secret-tool store --label="main" email address
  PASS=$(secret-tool lookup email address)

  echo Checking the secret can be retrieved.
  if  [ "$PASS" != "xxx@gmail.com" ]; then
    echo FAIL: the secret could not be retrieved.
    exit 1;
  fi
  echo SUCCESS: the secret could be retrieved.
fi 

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ] && [ "$keyring" == "kde" ]; then
  # install pre-filled wallet (because there is no way to interactively create key store without password)
  # created with empty password
  # entry added with `kwalletcli -f . -e address -p xxx@gmail.com`
  mkdir -p ~/.local/share/kwalletd
  cp $GITHUB_WORKSPACE/.setupkeystore/* ~/.local/share/kwalletd
  chmod 600 ~/.local/share/kwalletd/*
  dbus-uuidgen --ensure
  export $(dbus-launch)
  password=$(kwalletcli -f . -e address)
  echo Checking the secret can be retrieved.
  if  [ "$password" != "xxx@gmail.com" ]; then
    echo FAIL: the secret could not be retrieved.
    exit 1;
  fi
  echo SUCCESS: the secret could be retrieved.
fi

if [ "$(uname -s)" == "Darwin" ]; then 
  ls -la ~/Library/Keychains/
  #rm -rf ~/Library/Keychains/login.keychain
fi
