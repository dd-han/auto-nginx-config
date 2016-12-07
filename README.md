# Module Nginx config

## 起因
因為某天要開nginx site的時候覺得要打好多指令就算了，我竟然還找不到任何新一點的樣本讓我改。

## 安裝
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/dd-han/auto-nginx-config/master/installer.sh)"

## 用法
    newNginx.sh www.example.com ww2.example.com ... -R http://target | -r /target/webroot [option]

### 必要參數：
    -r /path/to/site/root
 `-r` 參數設定網站根目錄，裡面要有`index.html`之類的東西，不可與`-R`共用。

    -R http://127.0.0.1:8080
 `-R` 參數設定逆向代理，後面是真正的伺服器連線位置，不可與`-r`共用。



### 可選參數：
    -f
 `-f` 會啟用透過301強制將使用者導向https連結


    -F
 `-F` 會加入HTST的設定


    -n SiteName
 `-n` 設定Site的名稱，影響log檔名與設定檔檔名，不設定預設就是第一個Domain。

    -php 0|5|7
 `-php` 設定php的版本，必須搭配-r使用

    -try 0|1
 `-try` 設定是否當找不到檔案時，要交給index.php處理（WordPress、MediaWiki可用），搭配 `-r` 使用。

    -ssl private.key cert.crt
 `-ssl` 指定SSL私鑰與證書，並啟用網站的SSL

