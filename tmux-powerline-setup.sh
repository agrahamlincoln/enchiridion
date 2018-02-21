#!/usr/bin/env bash

# Install Powerline-tmux

if [ -d ~/projects/tmux-powerline/ ]; then
    echo "tmux-powerline already installed!"
    echo "please uninstall and then try again"
    exit 1
fi

if [[ $OSTYPE == darwin* ]]; then
    echo "tmux-powerline: installing alternative grep via homebrew"
    brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/master/Formula/grep.rb
fi

if [ ! -d ~/projects ]; then
    echo "tmux-powerline: git projects directory not found. creating ~/projects/"
    mkdir ~/projects
fi

echo "tmux-powerline: installing fonts"
echo "Please note, you may still need to change your terminal to use these fonts"
OLDPWD=$(pwd)
# clone
git clone https://github.com/powerline/fonts.git --depth=1 /tmp/powerline-fonts 
# install
cd /tmp/powerline-fonts
./install.sh
# clean-up a bit
cd $OLDPWD
rm -rf /tmp/powerline-fonts/

echo "tmux-powerline: downloading scripts"
git clone https://github.com/agrahamlincoln/tmux-powerline.git ~/projects/tmux-powerline

echo "tmux-powerline: configuring powerline in ~/.tmux.conf"
cat >> ~/.tmux.conf <<EOF
set-option -g status on
set-option -g status-interval 2
set-option -g status-justify "centre"
set-option -g status-left-length 60
set-option -g status-right-length 90
set-option -g status-left "#(~/projects/tmux-powerline/powerline.sh left)"
set-option -g status-right "#(~/projects/tmux-powerline/powerline.sh right)"
EOF

