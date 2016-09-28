#!/bin/bash

## Config here
configNginxDIR='/etc/nginx'
configPoolDIR='config.pool'
configDestDIR=$configNginxDIR'/autoSite'
configLOGDIR='/var/log/nginx'

loadedDoamins=""
loadedType=""
loadedConfigPHP=""
loadedConfigTRY=""
loadedConfig301="0"
loadedConfigRoot=""
loadedConfigHTST="0"
loadedConfigName=""
loadedConfigSSLPK=""
loadedConfigSSLCT=""

OLD_BACKUP=""

function output() {
	cat - <<< "$@" >> "/tmp/$loadedConfigName"
}

function genDomains() {
	for i in $@;do
		output "    server_name $i;"
	done
}


function outputUsage() {
	echo '========================================================================'
    echo 'usage '$0' example.com [exp2.com] -R http://target | -r /target [option]'
	echo 'option:'
	echo '    -f           : Always 301 HTTP user to HTTPS'
	echo '    -F           : Enable HTST'
	echo '    -n SiteName  : set Site Config Name'
	echo '    -php 0|5|7   : set php version'
	echo '    -try 0|1     : set try index.php and index.html while page not found'
	echo '    -ssl key crt : set ssl key and cert'
	echo '========================================================================'
}

## check folder
if ! test -d "$configNginxDIR"; then
	echo 'nginx config Dir not exist'
	exit 1
fi

if ! test -d "$configNginxDIR/$configPoolDIR"; then
	echo 'config Pool Dir not exist'
	exit 2
fi

if ! test -d "$configDestDIR"; then
	echo 'config dest Dir not exist'
	exit 3
fi

if ! test -d "$configLOGDIR"; then
	echo 'logging Dir not exist'
	exit 4
fi

## check nginx
if ! nginx -t > /dev/null 2> /dev/null; then
	echo 'nginx with wrong config before add new site'
	exit 5
fi

## Start loading command args
loadDomainDone='0'
loadingConfigPHP='0'
loadingConfigTRY='0'
loadingConfigSSL='0'
loadingConfig301='0'
loadingConfigRoot='0'
loadingConfigHTST='0'
loadingConfigName='0'
for i in $@; do
	if [ "$loadDomainDone" == '0' ]; then
		if grep '^-' <<< $i > /dev/null; then 
			loadDomainDone='1'
		else
			loadedDoamins+="$i "
			continue
		fi
	fi
	## 連帶的參數要優先讀取
	if [ "$loadingConfigRoot" != '0' ];then
		loadedConfigRoot="$i"
		loadingConfigRoot='0'
	elif [ "$loadingConfigName" != '0' ];then
		loadedConfigName="$i"
		loadingConfigName='0'
	elif [ "$loadingConfigPHP" != '0' ]; then
		loadedConfigPHP="$i"
		loadingConfigPHP='0'
	elif [ "$loadingConfigTRY" != '0' ]; then
		loadedConfigTRY="$i"
		loadingConfigTRY='0'
	elif [ "$loadingConfigSSL" != '0' ]; then
		if [ "$loadingConfigSSL" == '1' ];then
			loadedConfigSSLPK="$i"
			loadingConfigSSL='2'
		else
			loadedConfigSSLCT="$i"
			loadingConfigSSL='0'
		fi

	## 比較簡單的參數
	elif grep '^-f$' <<< $i > /dev/null; then
		loadedConfig301='1'
	elif grep '^-F$' <<< $i > /dev/null; then
		loadedConfigHTST='1'

	## 預備讀取複雜的參數
	elif grep '^-n$' <<< $i > /dev/null; then
		loadingConfigName='1'
	elif grep '^-php$' <<< $i > /dev/null; then
		loadingConfigPHP='1'
	elif grep '^-try$' <<< $i > /dev/null; then
		loadingConfigTRY='1'
	elif grep '^-ssl$' <<< $i > /dev/null; then
		loadingConfigSSL='1'
	elif grep '^-[rR]$' <<< $i > /dev/null; then
		loadingConfigRoot='1'
		if [ "$i" == '-r' ];then
			loadedType="ROOT"
		else
			loadedType="REV"
		fi
	else
		echo "unknown_config $i"
	fi
done

## loadd default configName
if [ "$loadedConfigName" == '' ];then
	for i in $loadedDoamins; do
		loadedConfigName=$i
		break
	done
fi

## check params
if [ "$loadedDoamins" == "" ]; then
	echo "no domain!!"
	outputUsage
	exit 10
else
	loadedConfigName=`sed 's/\./-/g' <<< ${loadedConfigName}`
	loadedConfigName=`cat - <<< ${loadedConfigName}.site`
fi

if [ "$loadedType" == "" ];then
	echo "no -R (Reverse Proxy) or -r (root)"
	outputUsage
	exit 11
fi

if [ "$loadedConfigRoot" == "" ];then
	echo "no target URL or root directory"
	outputUsage
	exit 12
fi

## check config
nowDate=`date +-%Y%m%d-%H%M%S.backup`
newName=`sed 's/.site/'$nowDate'/g' <<< $loadedConfigName`
if test -e "/tmp/$loadedConfigName"; then
	if test -e "$newName"; then
		echo "cannot create tmp file"
		exit 20
	else
		mv "/tmp/$loadedConfigName" "/tmp/$newName"
	fi
fi

if test -e "$configDestDIR/$loadedConfigName"; then
	if test -e "$newName"; then
		echo "config already exist and cannot rename"
		exit 21
	else
		if mv "$configDestDIR/$loadedConfigName" "$configDestDIR/$newName"; then
			if nginx -t > /dev/null 2> /dev/null; then
				echo "old config $loadedConfigName has rename to $newName"
				OLD_BACKUP="$newName"
			else
				mv "$configDestDIR/$newName" "$configDestDIR/$loadedConfigName"
				echo "trying to renmae config, but nginx failed"
				exit 22
			fi
		else
			echo "config already exist and cannot rename"
			exit 21
		fi
	fi
fi

## process 301 red server
if [ "$loadedConfig301" == '1' ];then
	output 'server {'
	genDomains $loadedDoamins
	output '    include '$configPoolDIR'/redirectToHttps;'
	output '}'
fi

## process main server config
output 'server {'
## listen 80 or not
if [ "$loadedConfig301" == '1' ];then 
	prefix='#'
else
	prefix=''
fi
output '    '$prefix'include config.pool/listen.conf;' 

## gen domain settings
genDomains $loadedDoamins

## gen root config
output ''
if [ "$loadedType" == 'REV' ]; then
	output '    #root /some/where/if/need;'
else
	output '    root '"$loadedConfigRoot"';'
fi

## gen some basic config
output '    include '$configPoolDIR'/baseSecure.conf;'

## gen log config
output '    access_log '$configLOGDIR'/access_'$loadedConfigName'.log;'
output '    error_log '$configLOGDIR'/error_'$loadedConfigName'.log;'

## gen SSL config
output ''
output '    ## SSL Settings'
if [ "$loadedConfigSSLPK" == '' ];then 
	prefix='#'
else
	prefix=''
fi
output '    '$prefix'ssl_certificate_key '$loadedConfigSSLPK';'
output '    '$prefix'ssl_certificate     '$loadedConfigSSLCT';'
output '    '$prefix'include '$configPoolDIR'/ssl.conf;'

## gen location root
output ''
output '    location / {'
if [ "$loadedType" == "ROOT" ];then

	if [ "$loadedConfigTRY" != '0' ]; then
		if [ "loadedConfigPHP" != '0' ]; then
			output '        try_files $uri $uri/ index.html index.html index.php?$args;'
		else
			output '        try_files $uri $uri/ index.html index.html;'
		fi
	else
		output '        index index.html index.html'$extFile';'
	fi
else
	output '        proxy_pass '$loadedConfigRoot';'
	output '        include include proxy_params;'
fi
output '    }'


## output .php location
if [ "$loadedConfigPHP" != '0' ];then
	output '    location ~ \.php$ {'
	output '        include  fastcgi.conf;'
	output '        include  '$configPoolDIR'/php'$loadedConfigPHP'.backen;'
	output '    }'
fi

output '}'

cp "/tmp/$loadedConfigName" "$configDestDIR"
if nginx -t > /dev/null; then
	echo "new site ready"
else
	rm "$configDestDIR/$loadedConfigName"
	echo "new site cause nginx failed"
	echo "config create at /tmp/$loadedConfigName"
	if [ "$OLD_BACKUP" != "" ]; then
		mv "$configDestDIR/$OLD_BACKUP" "$configDestDIR/$loadedConfigName"
		echo "old config restored"
	fi
	exit 30
fi

exit 0
