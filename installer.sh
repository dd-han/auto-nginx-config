#!/bin/sh

if test -d "config.pool"; then
	echo 'run installer from cloned repo'
	if which git > /dev/null 2> /dev/null; then
		echo "Check update"
		git pull
	else
		echo "no git on this system, skip pull newest config from git"
	fi
else
	if which git > /dev/null 2> /dev/null; then
		git clone https://github.com/dd-han/auto-nginx-config
		cd auto-nginx-config
	else
		echo 'need git for auto install'
		exit 1
	fi
fi

if test -d /etc/nginx/config.pool && test -d /etc/nginx/autoSite; then
	## Upgrade
	echo "upgradeing"
	cp -a config.pool/* /etc/nginx/config.pool/
else
	## new Install
	echo "new install"
	cp -a config.pool /etc/nginx
	mkdir /etc/nginx/autoSite
	HTTP_LINE=`cat /etc/nginx/nginx.conf | grep 'http' -n | sed -n '1,1p' | sed 's/:.*//g'`
	sed $HTTP_LINE' ainclude autoSite/*.site;' -i /etc/nginx/nginx.conf
fi
cp newNginx.sh /usr/sbin/

echo 'install finished, start use newNginx.sh for new Website!'
