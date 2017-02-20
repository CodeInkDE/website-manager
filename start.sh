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
    exit 1
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
domains=""
list="$(ls -G /var/www/vhost)"
leer="-->"

for d in $list
do
  domains="$domains $d $leer "
done

domains="$domains add $leer"

dialog --backtitle "Hosted4u - Manager" --title " Manage Websites " --cancel-label "Back" --menu "Move using [UP] [Down], [Enter] to select" 17 60 10 $domains 2>$_tmp
#echo "$website"
website=`cat $_tmp`
if [[ $website != "add" && $website != "Back" ]]; then
    manageWebsite
else if [[ $website == "add" ]]; then
    addWebsite
else
    manageWebsites
fi
fi
}

function addWebsite {
	domain=$(\
		dialog 	--backtitle "Hosted4u - Manager" --title " Add Websites "\
				--inputbox "Type in your Domain (example: hosted4u.de)" 8 40 \
		3>&1 1>&2 2>&3 3>&- \
	)

	if [ -d "/var/www/vhost/" domain "/" ]; then
        errorExit "Domain already exits!"
    fi

    mkdir "/var/www/vhost/$domain/"
    formatted=$(echo "$domain" | sed -r 's/\.//g')

    cp /configs/pool.default /etc/php/7.0/fpm/pool.d/"$formatted".conf
    sed -i "s/%DOMAIN%/$formatted/g" /etc/php/7.0/fpm/pool.d/"$formatted".conf

    pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')
    useradd www-"$formatted" --home-dir "/var/www/vhost/$domain/" --no-create-home --shell /bin/nologin --password "$pw" --groups www-data

    cp /configs/nginx-sites.default /etc/nginx/sites-enabled/"$domain"
    sed -i "s/%DOMAIN%/$domain/g" /etc/nginx/sites-enabled/"$domain"
    sed -i "s/%FORMATTED%/$formatted/g" /etc/nginx/sites-enabled/"$domain"

    chown -R www-"$formatted":www-data "/var/www/vhost/$domain/"

    /root/certbot-auto certonly --webroot -w /var/www/letsencrypt/ -d  "%DOMAIN%" -d "www.%DOMAIN%"

    service php7.0-fpm reload
    service nginx reload
}

function manageWebsite {
    dialog --backtitle "Hosted4u - Manager" --title " Manage Website - $website"\
        --cancel-label "Back" \
        --menu "Move using [UP] [Down], [Enter] to select" 17 60 10\
        delete "Delete Website"\
        back "Back" 2>$_tmp
}

function main_menu {
    dialog --backtitle "Hosted4u - Manager" --title " Main Menu - v$VER"\
        --cancel-label "Quit" \
        --menu "Move using [UP] [Down], [Enter] to select" 17 60 10\
        manageWebsites "Manage Websites"\
        quit "Exit Manager" 2>$_tmp

    opt=${?}
    if [ $opt != 0 ]; then rm $_tmp; exit; fi;
    menuitem=`cat $_tmp`
    #echo "menu=$menuitem"
    case $menuitem in
        manageWebsites) manageWebsites;;
        quit) rm $_tmp; exit 0;;
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
