# Module Nginx config

## 起因
因為某天要開nginx site的時候覺得要打好多指令就算了，我竟然還找不到任何新一點的樣本讓我改。

## 安裝
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/dd-han/auto-nginx-config/master/installer.sh)"

## 用法
    newNginx www.example.com ww2.example.com ... -R http://target | -r /target [option]

### 必要參數：
    -r /path/to/site/root
設定網站根目錄，不可與-R共用

    -R http://127.0.0.1:8080
設定逆向代理不可與-r共用

### 可選參數：
    -f
透過301強制將使用者導向https連結

    -F
加入HTST的設定

    -n SiteName
設定Site的名稱，影響log檔的檔名與設定檔的檔名，不設定預設就是第一個Domain。

    -php 0|5|7
設定php的版本，必須搭配-r使用

    -try 0|1
設定是否當找不到檔案時，要交給index.php處理（WordPress、MediaWiki可用），僅在php Site有用。

    -ssl private.key cert.crt
指定SSL私鑰與證書，並啟用網站的SSL

