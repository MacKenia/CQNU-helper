#!/bin/bash

echo "\
  ______   ______  __    __ __    __ 
 /      \ /      \|  \  |  \  \  |  \\
|  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓\ | ▓▓ ▓▓  | ▓▓
| ▓▓   \▓▓ ▓▓  | ▓▓ ▓▓▓\| ▓▓ ▓▓  | ▓▓
| ▓▓     | ▓▓  | ▓▓ ▓▓▓▓\ ▓▓ ▓▓  | ▓▓
| ▓▓   __| ▓▓ _| ▓▓ ▓▓\▓▓ ▓▓ ▓▓  | ▓▓
| ▓▓__/  \ ▓▓/ \ ▓▓ ▓▓ \▓▓▓▓ ▓▓__/ ▓▓
 \▓▓    ▓▓\▓▓ ▓▓ ▓▓ ▓▓  \▓▓▓\▓▓    ▓▓
  \▓▓▓▓▓▓  \▓▓▓▓▓▓\\\\▓▓   \▓▓ \▓▓▓▓▓▓ 
               \▓▓▓                   .edu.cn"

url_new_login="http://10.0.254.125:801/eportal/portal/login"
url_new_logout="http://10.0.254.125:801/eportal/portal/mac/unbind"

ua_ph="F5.0+%28Linux%3B+Android+9.0%3B+HuaWei+Mate+Pro%29+AppleWebKit%2F537.36+%28KHTML%2C+like+Gecko%29+Version%2F4.0+Chrome%2F81.0.4044.117+Mobile+Safari%2F537.36"
ua_pc="F5.0+%28Windows+NT+10.0%3B+Win64%3B+x64%29+AppleWebKit%2F537.36+%28KHTML%2C+like+Gecko%29+Chrome%2F94.0.4606.61+Safari%2F537.36+Edg%2F94.0.992.31"

data_new_login=(
"callback=dr1011"
"login_method=1"
"wlan_user_mac=000000000000"
"ua_name=Netscape"
"ua_code=Mozilla"
)

data_new_logout=(
"callback=dr1003"
"user_account="
"wlan_user_mac=000000000000"
"wlan_user_ip="
"jsVersion=4.1.3"
"lang=zh"
)

HEADER_PHONE_ACCEPT="*/*"
HEADER_PHONE_ACCEPT_ENCODING="gzip, deflate"
HEADER_PHONE_ACCEPT_LANGUAGE="zh-CN,zh;q=0.9"
HEADER_PHONE_CACHE_CONTROL="max-age=0"
HEADER_PHONE_CONNECTION="keep-alive"
HEADER_PHONE_CONTENT_TYPE="application/x-www-form-urlencoded"
HEADER_PHONE_HOST="10.0.254.125:801"
HEADER_PHONE_ORIGIN="http://10.0.254.125"
HEADER_PHONE_REFERER="http://10.0.254.125/"
HEADER_PHONE_UPGRADE_INSECURE_REQUESTS="1"
HEADER_PHONE_USER_AGENT="Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"

HEADER_DESKTOP_ACCEPT="*/*"
HEADER_DESKTOP_ACCEPT_ENCODING="gzip, deflate"
HEADER_DESKTOP_ACCEPT_LANGUAGE="zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
HEADER_DESKTOP_CONNECTION="keep-alive"
HEADER_DESKTOP_DNT="1"
HEADER_DESKTOP_HOST="10.0.254.125:801"
HEADER_DESKTOP_REFERER="http://10.0.254.125"
HEADER_DESKTOP_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"


process() {
    data_new_login[1]="user_account=,$device,$user@telecom"
    data_new_login[2]="user_password=$passwd"
    data_new_login[3]="terminal_type=$device"
    data_new_login[6]="callback=dr1011"
    data_new_login[7]="login_method=1"
    data_new_login[8]="wlan_user_mac=000000000000"
    data_new_login[9]="ua_name=Netscape"
    data_new_login[9]="ua_code=Mozilla"

    
    data_new_logout[1]="user_account=$user@telecom"
    data_new_logout[4]="callback=dr1003"
    data_new_logout[5]="wlan_user_mac=000000000000"
    data_new_logout[6]="wlan_user_ip="
    data_new_logout[7]="jsVersion=4.1.3"
    data_new_logout[8]="lang=zh"

    # 设置请求头变量
    if [ $device -eq 1 ]; then
        data_new_login[4]="ua_version=$ua_ph"
        data_new_login[5]="ua_agent=Mozilla%2$ua_ph"
        data_new_logout[2]="ua_version=$ua_ph"
        data_new_logout[3]="ua_agent=Mozilla%2$ua_ph"
        header_accept=${HEADER_PHONE_ACCEPT}
        header_accept_encoding=${HEADER_PHONE_ACCEPT_ENCODING}
        header_accept_language=${HEADER_PHONE_ACCEPT_LANGUAGE}
        header_cache_control=${HEADER_PHONE_CACHE_CONTROL}
        header_connection=${HEADER_PHONE_CONNECTION}
        header_content_type=${HEADER_PHONE_CONTENT_TYPE}
        header_host=${HEADER_PHONE_HOST}
        header_origin=${HEADER_PHONE_ORIGIN}
        header_referer=${HEADER_PHONE_REFERER}
        header_upgrade_insecure_requests=${HEADER_PHONE_UPGRADE_INSECURE_REQUESTS}
        header_user_agent=${HEADER_PHONE_USER_AGENT}
    else
        data_new_login[4]="ua_version=$ua_pc"
        data_new_login[5]="ua_agent=Mozilla%2$ua_pc"
        data_new_logout[2]="ua_version=$ua_pc"
        data_new_logout[3]="ua_agent=%2$ua_pc"
        header_accept=${HEADER_DESKTOP_ACCEPT}
        header_accept_encoding=${HEADER_DESKTOP_ACCEPT_ENCODING}
        header_accept_language=${HEADER_DESKTOP_ACCEPT_LANGUAGE}
        header_connection=${HEADER_DESKTOP_CONNECTION}
        header_dnt=${HEADER_DESKTOP_DNT}
        header_host=${HEADER_DESKTOP_HOST}
        header_referer=${HEADER_DESKTOP_REFERER}
        header_user_agent=${HEADER_DESKTOP_USER_AGENT}
    fi
}

login() {
    process
    
    params_new_login=$(IFS="&"; echo "${data_new_login[*]}")

    read result msg <<< $(curl -s --compressed "$url_new_login?$params_new_login" \
        -H "Accept:${header_accept}" \
        -H "Accept-Encoding:${header_accept_encoding}" \
        -H "Accept-Language: ${header_accept_language}" \
        -H "Cache-Control:${header_cache_control}" \
        -H "Connection:${header_connection}" \
        -H "DNT:${header_dnt}" \
        -H "Referer:${header_referer}" \
        -H "User-Agent:${header_user_agent}" \
        -H "Host:${header_host}" \
        --output - | sed 's/dr1011(//;s/);$//;s/.*"result":\([^,]*\),.*"msg":"\([^"]*\)".*/\1 \2/')
}

logout() {
    params_new_logout=$(IFS="&"; echo "${data_new_logout[*]}")
    
    read result msg <<< $(curl -s --compressed "$url_new_logout?$params_new_logout" \
    --output - | sed 's/dr1011(//;s/);$//;s/.*"result":\([^,]*\),.*"msg":"\([^"]*\)".*/\1 \2/')
}


show_help() {
  echo "Usage: $0 action account <password> [device]"
  echo "Use curl to login to the campus network."
  echo "Options:"
  echo -e "  -h, --help\t\tShow this help message and exit"
  echo "Arguments:"
  echo -e "  action\t\tLog in or log out: login, logout"
  echo -e "  account\t\tThe account for logging in"
  echo -e "  password\t\t(Optional when logout) The password for logging in"
  echo -e "  device\t\t(Optional, default: pc) The device type for logging in: pc, phone"
}


if [[ $1 == "-h" || $1 == "--help" ]]; then
  show_help
  exit 0
fi


action=$1
user=$2
passwd=$3
device=$4

if [[ -z $device ]]; then
  device="pc"
fi

if [[ $device == "pc" ]]; then
  device=0
elif [[ $device == "phone" ]]; then
  device=1
else
  echo -e "\033[31mDevice type error: pc, phone.\033[0m"
  show_help
  exit 2
fi

if [[ $action == "login" ]]; then
  if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo -e "\033[31mAccount and password is required.\033[0m"
    show_help
    exit 1
  fi
  login
elif [[ $action == "logout" ]]; then
  if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo -e "\033[31mAccount is required.\033[0m"
    show_help
    exit 1
  fi
  logout
else
  echo -e "\033[31mAction type error: login, logout.\033[0m"
  show_help
  exit 3
fi

if [ "$result" = "0" ]; then
  echo -ne "\033[31m"
else
  echo -ne "\033[32m"
fi
echo -e "$msg\033[0m"
