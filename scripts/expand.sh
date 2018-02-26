#!/bin/bash

echo "Insert domain e.g. codeink.de"
read basedomain

echo "Extending $basedomain ... "
echo "Insert subdomain e.g. www.codeink.de"
read subdomain

/usr/bin/certbot certonly --expand --webroot -w /var/www/letsencrypt/ -d "$basedomain" -d "$subdomain"

echo "If everything worked, you can now edit your /etc/nginx/sites-enabled/$basedomain configuration"

