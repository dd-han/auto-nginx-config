#!/bin/bash

## Config here
configPoolDIR='config.pool'
configDestDIR='/etc/nginx/autoSite'
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


function genDomains() {
	for i in $@;do
		echo "    server_name $i;"
	done
}

function output() {
	echo "$@"
}

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

echo =========configs==========
echo loadedDoamins:
echo $loadedDoamins
echo -n loadedType=
echo $loadedType
echo -n loadedConfigRoot=
echo $loadedConfigRoot
echo -n loadedConfigPHP=
echo $loadedConfigPHP
echo -n loadedConfigTRY=
echo $loadedConfigTRY
echo loadedConfigSSL:
echo $loadedConfigSSLPK
echo $loadedConfigSSLCT
echo -n loadedConfig301=
echo $loadedConfig301
echo -n loadedConfigHTST=
echo $loadedConfigHTST
echo -n loadedConfigName=
echo $loadedConfigName
echo =========================

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
output '    '$prefix'listen 80;' 

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
output '    access_log access_'$loadedConfigName'.log;'
output '    error_log error_'$loadedConfigName'.log;'

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
			output '        try $uri $uri/ index.html index.html index.php?$args;'
		else
			output '        try $uri $uri/ index.html index.html;'
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
