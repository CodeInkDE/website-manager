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
	domain=$( \
		dialog  --title "Add Websites" \
				--cancel-label "Cancel" \
			    --inputbox "Type in your Domain (example: hosted4u.de)" 8 40 \
		3>&1 1>&2 2>&3 3>&- \
	)

    if [ -z "$domain" ]; then
        addWebsite
        exit 0
    fi

	if [ -d "/var/www/vhost/$domain/" ]; then
        errorExit "Domain already exits!"
    fi

    mkdir "/var/www/vhost/$domain/"
    formatted=$(echo "$domain" | sed -r 's/\.//g')

    cp configs/pool.default /etc/php/7.0/fpm/pool.d/"$formatted".conf
    sed -i "s/%DOMAIN%/$formatted/g" /etc/php/7.0/fpm/pool.d/"$formatted".conf

    pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')
    useradd www-"$formatted" --home-dir "/var/www/vhost/$domain/" --no-create-home --shell /bin/nologin --password "$pw" --groups www-data

    cp configs/nginx-sites.default /etc/nginx/sites-enabled/"$domain"
    sed -i "s/%DOMAIN%/$domain/g" /etc/nginx/sites-enabled/"$domain"
    sed -i "s/%FORMATTED%/$formatted/g" /etc/nginx/sites-enabled/"$domain"

    /root/certbot-auto certonly --webroot -w /var/www/letsencrypt/ -d  "$domain"

    service php7.0-fpm reload
    service nginx reload

    cp configs/index.html "/var/www/vhost/$domain/index.html"
    sed -i "s/%DOMAIN%/$domain/g" "/var/www/vhost/$domain/index.html"
    chown -R www-"$formatted":www-data "/var/www/vhost/$domain/"

    clear

    echo "**************************"
    echo "Domain: $domain"
    echo "User: www-$formatted"
    echo "Password: $pw"
    echo "**************************"

    exit 0
}

function deleteWebsite {
    domain=${@}

    dialog --title "Delete Website" --yesno "Remove $domain ?" 8 40
    response=$?

    if [ $response = 1 ]; then
        manageWebsites
        exit 0
    fi


    if [ -z "$domain" ]; then
        errorExit "No parameter!"
    fi

	if ! [ -d "/var/www/vhost/$domain/" ]; then
        errorExit "Website doesn't exists!"
    fi

    tar cfz backups/$domain.tar.gz "/var/www/vhost/$domain/"
    rm -R "/var/www/vhost/$domain"

    formatted=$(echo "$domain" | sed -r 's/\.//g')

    rm /etc/php/7.0/fpm/pool.d/"$formatted".conf
    rm /etc/nginx/sites-enabled/"$domain"
    rm -rf "/etc/letsencrypt/live/$domain"
    rm "/etc/letsencrypt/renewal/$domain.conf"

    service php7.0-fpm reload
    service nginx reload
    deluser www-"$formatted"

    clear

    echo "**************************"
    echo "Domain: $domain"
    echo "Status: DELETED"
    echo "Backup: backups/$domain.tar.gz"
    echo "**************************"

    exit 0
}




function manageWebsite {

    formatted=$(echo "$website" | sed -r 's/\.//g')

    if [ -f "/etc/php/7.0/fpm/pool.d/$formatted.conf" ]; then
        php="[ Activated ]"
    else
        php="[ Dectivated ]"
    fi


    dialog --backtitle "Hosted4u - Manager" --title " Manage Website - $website"\
        --cancel-label "Back" \
        --menu "Move using [UP] [Down], [Enter] to select" 17 60 10\
        php "$php"\
        changePW "Reset password" \
        delete "Delete website"\
        back "Back" 2>$_tmp

    menuitem=`cat $_tmp`
    #echo "menu=$menuitem"
    case $menuitem in
        php) manageWebsites;;
        changePW) changePW "www-$formatted";;
        delete) deleteWebsite "$website";;
        quit) rm $_tmp; exit 0;;
    esac

}

function changePW {
    user=${@}
    pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')

    echo "$user:$pw"|chpasswd

    clear

    echo "**************************"
    echo "User: $user"
    echo "Password: $pw"
    echo "**************************"

    exit 0
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
