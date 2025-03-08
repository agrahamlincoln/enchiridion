#!/bin/bash

pacman -Qu > /tmp/.package-available-upgrades
paru -Qu >> /tmp/.package-available-upgrades
