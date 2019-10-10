#!/usr/bin/env bash

set -e -x
HOMEDIR="/home/graham"

usage() {
	echo "Usage: $0 <profile-name|profile-number>"
	echo "Existing profiles:"
	echo "  0: laptop-only (Default)"
	echo "  1: asus-dell-laptop"
	echo "  2: asus-dell"
	echo "  3: acer-acer-laptop"
	echo "  4: acer-acer"
	exit 1
}

set_displays() {
	case "$1" in
	1*)
		profilename="asus-dell-laptop"
		dpi="109"
		screenlayout="$HOMEDIR/.screenlayout/asus-dell-laptop.sh"
		;;
	2*)
		profilename="asus-dell"
		dpi="109"
		screenlayout="$HOMEDIR/.screenlayout/asus-dell.sh"
		;;
	3*)
		profilename="acer-acer-laptop"
		dpi="96"
		screenlayout="$HOMEDIR/.screenlayout/acer-acer-laptop.sh"
		;;
	4*)
		profilename="acer-acer"
		dpi="96"
		screenlayout="$HOMEDIR/.screenlayout/acer-acer.sh"
		;;
	5*)
		profilename="laptop-benq"
		dpi="96"
		screenlayout="$HOMEDIR/.screenlayout/laptop-benq.sh"
		;;
	0*|*)
		profilename="laptop-only"
		dpi="192"
		screenlayout="$HOMEDIR/.screenlayout/default.sh"
		;;
	esac

	echo "Activating profile $profilename"
	echo " --> Setting DPI to $dpi"
	echo " --> Setting Screen Layout according to $screenlayout"

	# set desired DPI
	sed -i -r "s/Xft.dpi:.+/Xft.dpi: $dpi/g" ~/.Xresources
	# run the arandr screenlayout script
	$($screenlayout)

	echo " --> Reloading ~/.Xresources"
	xrdb ~/.Xresources
	echo " --> Restarting i3"
	i3 restart
}

if [ $# -eq 0 ]; then usage; fi

set_displays $1
echo $?
