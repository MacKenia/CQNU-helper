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

HEADER_ACCEPT="*/*"
HEADER_ACCEPT_ENCODING="gzip, deflate"
HEADER_ACCEPT_LANGUAGE="zh-CN,zh;q=0.9"
HEADER_CACHE_CONTROL="max-age=0"
HEADER_CONNECTION="keep-alive"
HEADER_DNT="1"
HEADER_REFERER="http://10.0.254.125/"
HEADER_HOST="10.0.254.125:801"
HEADER_CONTENT_TYPE="application/x-www-form-urlencoded"
HEADER_ORIGIN="http://10.0.254.125"
HEADER_UPGRADE_INSECURE_REQUESTS="1"
HEADER_USER_AGENT_PHONE="Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
HEADER_USER_AGENT_DESKTOP="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"

process() {
    data_new_login[1]="user_account=,$device,$user@telecom"
    data_new_login[2]="user_password=$passwd"
    data_new_login[3]="terminal_type=$device"
    data_new_login[4]="callback=dr1011"
    data_new_login[5]="login_method=1"
    data_new_login[6]="wlan_user_mac=000000000000"
    data_new_login[7]="ua_name=Netscape"
    data_new_login[8]="ua_code=Mozilla"

    data_new_logout[1]="user_account=$user@telecom"
    data_new_logout[2]="callback=dr1003"
    data_new_logout[3]="wlan_user_mac=000000000000"
    data_new_logout[4]="wlan_user_ip="
    data_new_logout[5]="jsVersion=4.1.3"
    data_new_logout[6]="lang=zh"

    # 设置请求头变量
    if [ $device -eq 1 ]; then
        data_new_login[9]="ua_version=$ua_ph"
        data_new_login[10]="ua_agent=Mozilla%2$ua_ph"
        data_new_logout[7]="ua_version=$ua_ph"
        data_new_logout[8]="ua_agent=Mozilla%2$ua_ph"
        header_user_agent=${HEADER_USER_AGENT_PHONE}
    else
        data_new_login[9]="ua_version=$ua_pc"
        data_new_login[10]="ua_agent=Mozilla%2$ua_pc"
        data_new_logout[7]="ua_version=$ua_pc"
        data_new_logout[8]="ua_agent=%2$ua_pc"
        header_user_agent=${HEADER_USER_AGENT_DESKTOP}
    fi
}


login() {
    process
    
    params_new_login=$(IFS="&"; echo "${data_new_login[*]}")

    read result msg <<< $(curl -s --compressed "$url_new_login?$params_new_login" \
        -H "Accept:${HEADER_ACCEPT}" \
        -H "Accept-Encoding:${HEADER_ACCEPT_ENCODING}" \
        -H "Accept-Language: ${HEADER_ACCEPT_LANGUAGE}" \
        -H "Cache-Control:${HEADER_CACHE_CONTROL}" \
        -H "Connection:${HEADER_CONNECTION}" \
        -H "DNT:${HEADER_DNT}" \
        -H "Referer:${HEADER_REFERER}" \
        -H "Host:${HEADER_HOST}" \
        -H "User-Agent:${header_user_agent}" \
        -H "Content_Type:${HEADER_CONTENT_TYPE}" \
        -H "Origin:${HEADER_ORIGIN}" \
        -H "Upgrade-Insecure-Requests:${HEADER_UPGRADE_INSECURE_REQUESTS}" \
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
