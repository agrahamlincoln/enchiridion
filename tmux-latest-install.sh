#!/usr/bin/env bash

# Install the latest tmux and dependencies from source

if [ ! rpm -q libevent ]; then
  # libevent is not installed
  echo "Installing libevent 2.0.21 from source"
  curl -LO https://github.com/downloads/libevent/libevent/libevent-2.0.21-stable.tar.gz
  tar xzf libevent-2.0.21-stable.tar.gz
  cd libevent-2.0.21-stable
  ./configure && make
  sudo make install
  cd ..
  rm -rf libevent-2.0.21-stable
  rm libevent-2.0.21-stable.tar.gz
fi

if [ ! rpm -q tmux ]; then
  # tmux is not installed!
  echo "Installing latest tmux from source"
  cd ~/projects
  git clone https://github.com/tmux/tmux.git
  cd tmux
  sh autogen.sh
  ./configure && make
else
  echo "Tmux is already installed."
  echo "Please uninstall and try again"
  exit 1
fi
