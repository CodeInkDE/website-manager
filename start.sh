#!/bin/bash

VER='1.0.0'
_tmp="/tmp/answer.$$"

##
#
# Functions
#
##

function greenMessage {
    echo -e "\\033[32;1m${@}\033[0m"
}

function magentaMessage {
    echo -e "\\033[35;1m${@}\033[0m"
}

function cyanMessage {
    echo -e "\\033[36;1m${@}\033[0m"
}

function redMessage {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellowMessage {
	echo -e "\\033[33;1m${@}\033[0m"
}

function errorExit {
    redMessage ${@}
    exit 0
}

function installdialog {

checkdialog=$(command -v dialog)

if [[ $checkdialog = "" ]]; then
    greenMessage "Das Paket Dialog wird für dieses Skript benötigt und wird in 10 Sekunden installiert."
    sleep 1
    redMessage "Möchtest du das Paket nicht installieren, breche die Installation mit CTRL + C ab."
    sleep 10
    trap '' 2 # CTRL + C Block start
    apt-get update # 2>&1 > /dev/null
    apt-get install dialog -y # 2>&1 > /dev/null
fi

}

function checkroot {

if [ "`id -u`" != "0" ]; then
    redMessage "Wechsle zu dem Root Benutzer!"
    su root
	fi
if [ "`id -u`" != "0" ]; then
    errorExit "Nicht als Rootbenutzer ausgeführt, Abgebrochen!"
    exit
	fi

}

function manageWebsites {

liste="$(ls -G /var/www/vhost)"
leer="-->"

for d in $liste
do
  domains="$domains $d $leer "
done

dialog  --backtitle "Test" --title " Test " --menu "Test" 17 60 10 $domains

}

function main_menu {
    dialog --backtitle "Hosted4u - Manager" --title " Main Menu - v$VER"\
        --cancel-label "Quit" \
        --menu "Move using [UP] [Down], [Enter] to select" 17 60 10\
        manageWebsites "Manage Websites"
        quit "Exit Manager" 2>$_tmp

    opt=${?}
    if [ $opt != 0 ]; then rm $_tmp; exit; fi;
    menuitem=`cat $_tmp`
    echo "menu=$menuitem"
    case $menuitem in
        manageWebsites) manageWebsites;;
        quit) rm $_tmp; exit;;
    esac
}



##
#
# Programm
#
##
checkroot
installdialog

while true; do
    main_menu
done
