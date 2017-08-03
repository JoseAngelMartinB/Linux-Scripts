#!/bin/bash
# Allows to automatically turn on/off the keyboard light on Asus Zeenbok
# It must be run with sudo
#
# Script created by jacob-vlijm
# Improved by José Ángel Martín

let "div = 1000"
let "limit = $1"
let "bight = 2"
dimmed=false
cmd=/sys/class/leds/asus::kbd_backlight/brightness
let "bight = $(cat $cmd)"

while true
do
  sleep 2
  let "idle = $(xprintidle)"
  if [ $(($idle / $div)) -gt $limit ] && [ $dimmed == false ]; then
    let "bight = $(cat $cmd)"
    echo 0 | tee $cmd 
    dimmed=true
  elif [ $(($idle / $div)) -le $limit ] && [ $dimmed == true ]; then
    echo $bight | tee $cmd 
    dimmed=false
  fi
done
