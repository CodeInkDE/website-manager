#!/bin/bash

echo "Insert domain e.g. nevondo.com"
read basedomain

echo "Extending $basedomain ... "
echo "Insert subdomain e.g. www.nevondo.com"
read subdomain

/usr/bin/certbot certonly --expand --webroot -w /var/www/letsencrypt/ -d "$basedomain" -d "$subdomain"

echo "If everything worked, you can now edit your /etc/nginx/sites-enabled/$basedomain configuration"

