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

# --- 用户配置 ---
EPORTAL_HOST="10.0.254.125:801" # ePortal 主机 IP 或域名
DEFAULT_REFERER="http://$EPORTAL_HOST/" # 默认的 Referer URL

# --- URL 配置 ---
url_new_login="http://$EPORTAL_HOST/eportal/portal/login"
url_new_logout="http://$EPORTAL_HOST/eportal/portal/mac/unbind"

# --- 公共请求头 (User-Agent 随device类型动态设置) ---
HEADER_USER_AGENT_PHONE="Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
HEADER_USER_AGENT_DESKTOP="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"

HEADER_ACCEPT="*/*"
HEADER_ACCEPT_ENCODING="gzip, deflate"
HEADER_ACCEPT_LANGUAGE="zh-CN,zh;q=0.9"
HEADER_CONNECTION="keep-alive"
HEADER_HOST="$EPORTAL_HOST"

# --- 全局变量用于存储获取到的 IP/MAC/AC IP ---
WLAN_USER_IP="0.0.0.0" # 黄金请求中IP是动态获取的IPv4
WLAN_USER_MAC="000000000000" # 黄金请求中MAC是全0
WLAN_AC_IP="" # 黄金请求中AC IP是空的
WLAN_USER_IPV6="" # 黄金请求中IPv6是空的
USER="" # 账号
PASSWD="" # 密码

# --- 辅助函数 ---
remove_newlines() { local string="$1"; string=${string//$'\n'/}; string=${string//$'\r'/}; echo "$string"; }
set_global_var() { local var_name="$1"; local value="$2"; printf -v "$var_name" "%s" "$value"; }

# `preload_term_info` 函数：只获取 IPv4，其他固定值
preload_term_info() {

    local target_eportal_ip="10.0.254.125"
    if [[ "$EPORTAL_HOST" =~ ^([0-9.]+):([0-9]+)$ ]]; then target_eportal_ip="${BASH_REMATCH[1]}"; elif [[ "$EPORTAL_HOST" =~ ^([a-zA-Z0-9\.-]+):([0-9]+)$ ]]; then target_eportal_ip="${BASH_REMATCH[1]}"; fi
    local target_url="http://${target_eportal_ip}"

    current_ip=$(curl --connect-timeout 1 -s http://10.0.254.125 \
      | grep -Eo '10(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')

    readarray -t ips < <(tr ' ' '\n' <<<"$current_ip")

    declare -A seen=()
    unique_ips=()

    for ip in "${ips[@]}"; do
      [[ "$ip" == "10.0.254.125" ]] && continue
      [[ -n "${seen[$ip]}" ]] && continue
      seen[$ip]=1
      unique_ips+=("$ip")
    done

    # echo "unique: ${unique_ips[@]}"

    if ((${#unique_ips[@]})); then
      last_ip="${unique_ips[-1]}"
    #   echo "last: $last_ip"
    else
    #   echo "没有筛选到可用 IP"
    fi

    set_global_var WLAN_USER_IP "$last_ip"

    # 固定其他参数
    set_global_var WLAN_USER_MAC "000000000000"
    set_global_var WLAN_AC_IP ""
    set_global_var WLAN_USER_IPV6 ""

    return 0
}

login_func() { # 登录函数
    
    # Bug修复：移除所有 callback 生成和传递逻辑
    
    # 根据设备类型动态设置 user_account 中的数字标识 (0 for PC, 1 for Phone)
    local user_account_id=""
    if [[ "$device" -eq 0 ]]; then user_account_id="0"; elif [[ "$device" -eq 1 ]]; then user_account_id="1"; else user_account_id="0"; fi

    local login_params=(
        "login_method=1"
        "user_account=,${user_account_id},${USER}@telecom"
        "user_password=$PASSWD"
        "wlan_user_ip=$WLAN_USER_IP"
        "wlan_user_ipv6=$WLAN_USER_IPV6"
        "wlan_user_mac=$WLAN_USER_MAC"
        "wlan_ac_ip=$WLAN_AC_IP"
    )

    IFS="&"
    local params_new_login_raw="${login_params[*]}"; unset IFS
    local params_new_login=$(remove_newlines "$params_new_login_raw")

    local FULL_LOGIN_URL="$url_new_login?$params_new_login"

    # echo "--- 准备登录，请求URL截取如下 ---" >&2
    echo "$(echo "$FULL_LOGIN_URL")" >&2
    
    local response_raw=$(curl --connect-timeout 5 --max-time 15 -s --compressed "$FULL_LOGIN_URL")
    
    local response=$(remove_newlines "$response_raw")

    # Bug修复：移除 callback 相关的 JSONP 解析，直接匹配 result 和 msg
    local login_result=""
    if [[ "$response" =~ \"result\":([0-9]+) ]]; then login_result="${BASH_REMATCH[1]}"; fi
    local login_msg=""
    if [[ "$response" =~ \"msg\":\"([^\"]*)\" ]]; then login_msg="${BASH_REMATCH[1]}"; fi

    echo "$login_result $login_msg" # 只输出最终结果到 stdout
}

logout_func() { # 注销函数
    local user_account_id=""
    if [[ "$device" -eq 0 ]]; then user_account_id="0"; elif [[ "$device" -eq 1 ]]; then user_account_id="1"; else user_account_id="0"; fi

    local logout_params=(
        "user_account=,${user_account_id},${USER}@telecom"
        "wlan_user_ip=$WLAN_USER_IP"
        "wlan_user_ipv6=$WLAN_USER_IPV6"
        "wlan_user_mac=$WLAN_USER_MAC"
        "wlan_ac_ip=$WLAN_AC_IP"
        "login_method=1"
    )

    IFS="&"
    local params_new_logout_raw="${logout_params[*]}"; unset IFS
    local params_new_logout=$(remove_newlines "$params_new_logout_raw")

    local FULL_LOGOUT_URL="$url_new_logout?$params_new_logout"

    echo "--- 准备注销，请求URL截取如下 ---" >&2
    echo "$FULL_LOGOUT_URL" >&2
    
    local response_raw=$(curl --connect-timeout 5 --max-time 15 -s --compressed "$FULL_LOGOUT_URL")
    local response=$(remove_newlines "$response_raw")
    debug_log "Raw response from curl for logout: '${response}'"

    # Bug修复: 移除 callback 相关的 JSONP 解析
    local logout_result=""
    if [[ "$response" =~ \"result\":([0-9]+) ]]; then logout_result="${BASH_REMATCH[1]}"; fi
    local logout_msg=""
    if [[ "$response" =~ \"msg\":\"([^\"]*)\" ]]; then logout_msg="${BASH_REMATCH[1]}"; fi

    echo "$logout_result $logout_msg" # 只输出最终结果到 stdout
}

show_help() {
echo "Usage: $0 action account password \[device]"
echo "Use curl to login/logout to the campus network."
echo "Arguments:"
echo -e "  action\t\tLog in or log out: login, logout"
echo -e "  account\t\tThe account for logging in (e.g., 2023210516034)"
echo -e "  password\t\t(Required for login) The password for logging in"
echo -e "  device\t\t(Optional, default: pc) The device type for logging in: pc, phone"
}

# --- 脚本主入口 ---
ACTION="$1"; shift
ACCOUNT="$1"; shift
PASSWORD="$1"; shift
if [[ -n "$1" ]]; then DEVICE_TYPE="$1"; shift; fi

if [[ "$ACTION" == "-h" || "$ACTION" == "--help" ]]; then show_help; exit 0; fi
if [[ -z "$ACTION" ]]; then echo "0 错误: 必须指定 'login' 或 'logout' 动作。" >&2; show_help; exit 3; fi

USER="${ACCOUNT}"; PASSWD="${PASSWORD}"

if [[ -z "$USER" ]]; then 
    if [[ -n "$EPORTAL_USERNAME" ]]; then USER="$EPORTAL_USERNAME"; else read -p "请输入账号 (例如: 2023210516034): " USER_INPUT; USER=$(remove_newlines "$USER_INPUT"); fi
fi
if [[ "$ACTION" == "login" && -z "$PASSWD" ]]; then 
    if [[ -n "$EPORTAL_PASSWORD" ]]; then PASSWD="$EPORTAL_PASSWORD"; else read -s -p "请输入密码: " PASSWD_INPUT; echo; PASSWD=$(remove_newlines "$PASSWD_INPUT"); fi
fi

if [[ -z "$USER" ]]; then echo "0 错误: 必须提供账号。" >&2; show_help; exit 1; fi
if [[ "$ACTION" == "login" && -z "$PASSWD" ]]; then echo "0 错误: 登录操作需要提供密码。" >&2; show_help; exit 1; fi

device_numeric=0; if [[ "$DEVICE_TYPE" == "pc" ]]; then device_numeric=0; elif [[ "$DEVICE_TYPE" == "phone" ]]; then device_numeric=1; else echo "0 错误: 设备类型错误。" >&2; show_help; exit 2; fi
device="$device_numeric"

# --- 核心流程：获取 IP 并执行动作 ---
if ! preload_term_info; then
    # preload_term_info 已经在内部打印错误信息，并以 "0 IP/MAC预加载失败" 退出
    exit 4
fi

# 执行登录/注销动作
if [[ "$ACTION" == "login" ]]; then
    login_func
elif [[ "$ACTION" == "logout" ]]; then
    logout_func
fi
