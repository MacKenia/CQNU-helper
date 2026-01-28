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

# ePortal 主机 IP 或域名
EPORTAL_HOST="10.0.254.125:801"

# 默认的 Referer URL，通常是认证页面的根路径
DEFAULT_REFERER="http://$EPORTAL_HOST/"

# --- URL 配置 ---
url_new_login="http://$EPORTAL_HOST/eportal/portal/login"
url_new_logout="http://$EPORTAL_HOST/eportal/portal/mac/unbind"
url_online_list_status="http://$EPORTAL_HOST/eportal/portal/online_list" # 用于检查状态和获取已登录IP/MAC

# --- User-Agent 配置 (用于 HTTP 头，非 URL 参数) ---
HEADER_USER_AGENT_PHONE="Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
HEADER_USER_AGENT_DESKTOP="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"

# --- 公共请求头 ---
HEADER_ACCEPT="*/*"
HEADER_ACCEPT_ENCODING="gzip, deflate"
HEADER_ACCEPT_LANGUAGE="zh-CN,zh;q=0.9"
HEADER_CONNECTION="keep-alive"
HEADER_HOST="$EPORTAL_HOST"

# --- 全局变量用于存储获取到的 IP/MAC/AC IP ---
WLAN_USER_IP="0.0.0.0" # 初始默认值
WLAN_USER_MAC="000000000000" # 初始默认值
WLAN_AC_IP="0.0.0.0" # 初始默认值
WLAN_USER_IPV6="" # 你的curl命令有这个参数
USER="" # 声明用户全局变量
PASSWD="" # 声明密码全局变量

# --- JSONP 回调计数器 (模拟 JS 行为) ---
JSONP_COUNTER=1000
generate_callback_name() { JSONP_COUNTER=$((JSONP_COUNTER + 1)); echo "dr${JSONP_COUNTER}"; }
ip_to_parse_int() {
    local ip_str="$1"; if [[ -z "$ip_str" || "$ip_str" == "0.0.0.0" ]]; then echo 0; return; fi
    if [[ "$ip_str" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local p1="${BASH_REMATCH[1]}"; local p2="${BASH_REMATCH[2]}"; local p3="${BASH_REMATCH[3]}"; local p4="${BASH_REMATCH[4]}"; printf "%d\n" "$(( p1 << 24 | p2 << 16 | p3 << 8 | p4 ))"; else echo 0; fi
}
bash_urldecode() { local url_encoded="$1"; local decoded_string="${url_encoded//+/ }"; printf '%b' "${decoded_string//%/\\x}"; }
remove_newlines() { local string="$1"; string=${string//$'\n'/}; string=${string//$'\r'/}; echo "$string"; }

# 辅助函数，用于将值安全地赋给全局变量
set_global_var() {
    local var_name="$1"
    local value="$2"
    printf -v "$var_name" "%s" "$value"
}

# `preload_term_info` 函数：参数提取逻辑直接内联
preload_term_info() {
    # 调试信息到 stderr
    echo "--- 预加载终端信息 ---" >&2
    local initial_access_url="http://neverssl.com"
    echo "尝试访问：$initial_access_url 获取重定向 URL..." >&2

    local eportal_login_target_url_raw=$(curl -L -s --max-time 10 -o /dev/null -w "%{url_effective}" "$initial_access_url")
    local eportal_login_target_url=$(remove_newlines "$eportal_login_target_url_raw")
    echo "DEBUG_PRELOAD: Captured URL (after remove_newlines): '${eportal_login_target_url}'" >&2

    if [[ -z "$eportal_login_target_url" || "$eportal_login_target_url" == "$initial_access_url" ]]; then
        echo "警告: 无法自动获取到 ePortal 登录初始 URL 或未发生重定向。" >&2
        echo "请务必确保网络处于 '未认证' 状态，否则将无法正确获取IP/MAC进行认证。" >&2
        
        while true; do
            read -p "请输入 ePortal 认证页面的完整 URL (例如: 从浏览器F12获取，必须提供有效IP/MAC): " MANUAL_AUTH_URL_RAW >/dev/null # 提示信息用户可见，输入重定向到/dev/null
            local MANUAL_AUTH_URL=$(remove_newlines "$MANUAL_AUTH_URL_RAW")
            if [[ -n "$MANUAL_AUTH_URL" ]]; then
                if [[ "$MANUAL_AUTH_URL" == *"ip1="* || "$MANUAL_AUTH_URL" == *"wlan_user_ip="* ]] && \
                   [[ "$MANUAL_AUTH_URL" == *"mac="* || "$MANUAL_AUTH_URL" == *"usermac="* ]]; then
                    eportal_login_target_url="$MANUAL_AUTH_URL"
                    break
                else
                    echo "错误: 您提供的 URL 似乎没有包含 IP 或 MAC 参数。请提供完整的认证页面 URL。" >&2
                fi
            else
                echo "错误: 必须提供 ePortal 认证页面的完整 URL 以获取 IP/MAC。" >&2
            fi
        done
         echo "DEBUG_PRELOAD: Using manually entered URL: '${eportal_login_target_url}'" >&2
    fi

    echo "从 URL: $eportal_login_target_url 提取参数 (内联逻辑直接处理)..." >&2
    
    local query_string_raw=$(echo "$eportal_login_target_url" | sed -n 's/^[^?]*\?\([^#]*\).*$/\1/p')
    local query_string_cleaned_start=$(echo "$query_string_raw" | sed -E 's/^[^a-zA-Z0-9]*//')
    local query_string=$(remove_newlines "$query_string_cleaned_start")
    echo "DEBUG_PRELOAD: Final cleaned query_string for direct parsing: '${query_string}'" >&2

    local current_extracted_val=""
    
    # --- IP ---
    local ip_aliases=( 'ip1' 'ip' 'wlanuserip' 'userip' 'user-ip' 'client_ip' 'UserIP' 'uip' 'station_ip' )
    current_extracted_val=""
    for alias in "${ip_aliases[@]}"; do
        if [[ "$query_string" == *"${alias}="* ]]; then
            local remainder="${query_string#*${alias}=}"
            current_extracted_val="${remainder%%&*}"
            break
        fi
    done
    current_extracted_val=$(bash_urldecode "$current_extracted_val")
    set_global_var WLAN_USER_IP "${current_extracted_val:-0.0.0.0}"
    echo "DEBUG_PRELOAD: WLAN_USER_IP after direct parsing: '${WLAN_USER_IP}'" >&2

    # --- MAC ---
    local mac_aliases=( 'mac' 'usermac' 'wlanusermac' 'umac' 'client_mac' 'station_mac' ) # 修正：移除了 client_mac 重复
    current_extracted_val=""
    for alias in "${mac_aliases[@]}"; do
        if [[ "$query_string" == *"${alias}="* ]]; then
            local remainder="${query_string#*${alias}=}"
            current_extracted_val="${remainder%%&*}"
            break
        fi
    done
    current_extracted_val=$(bash_urldecode "$current_extracted_val" | tr -d ':-')
    set_global_var WLAN_USER_MAC "${current_extracted_val:-000000000000}"
    echo "DEBUG_PRELOAD: WLAN_USER_MAC after direct parsing: '${WLAN_USER_MAC}'" >&2

    # --- AC IP ---
    local ac_ip_aliases=( 'wlanacip' 'acip' 'switchip' 'nasip' 'nas-ip' )
    current_extracted_val=""
    for alias in "${ac_ip_aliases[@]}"; do
        if [[ "$query_string" == *"${alias}="* ]]; then
            local remainder="${query_string#*${alias}=}"
            current_extracted_val="${remainder%%&*}"
            break
        fi
    done
    current_extracted_val=$(bash_urldecode "$current_extracted_val")
    set_global_var WLAN_AC_IP "${current_extracted_val:-0.0.0.0}"
    echo "DEBUG_PRELOAD: WLAN_AC_IP after direct parsing: '${WLAN_AC_IP}'" >&2

    # --- IPv6 ---
    local ipv6_aliases=( 'wlan_user_ipv6' 'UserV6IP' 'ipv6' )
    current_extracted_val=""
    for alias in "${ipv6_aliases[@]}"; do
        if [[ "$query_string" == *"${alias}="* ]]; then
            local remainder="${query_string#*${alias}=}"
            current_extracted_val="${remainder%%&*}"
            break
        fi
    done
    current_extracted_val=$(bash_urldecode "$current_extracted_val")
    set_global_var WLAN_USER_IPV6 "${current_extracted_val}"
    echo "DEBUG_PRELOAD: WLAN_USER_IPV6 after direct parsing: '${WLAN_USER_IPV6}'" >&2

    echo "获取到的 IP: ${WLAN_USER_IP}" >&2
    echo "获取到的 MAC: ${WLAN_USER_MAC}" >&2
    echo "获取到的 AC IP: ${WLAN_AC_IP}" >&2
    echo "获取到的 IPv6: ${WLAN_USER_IPV6}" >&2
    echo "--------------------------" >&2
    
    if [[ "$WLAN_USER_IP" == "0.0.0.0" || "$WLAN_USER_MAC" == "000000000000" ]]; then
        echo "严重警告: 无法从 URL 获取有效的 IP 或 MAC 地址。请确保提供的 URL 确实包含了正确的参数。" >&2
        return 1
    fi

    return 0
}

check_current_online_status() {
    echo "--- 检查当前在线状态 ---" >&2
    local callback_name=$(generate_callback_name)
    
    local check_params=(
        "callback=${callback_name}"
        "user_account="
        "user_password="
    )

    IFS="&"
    local query_string_raw="${check_params[*]}"
    local query_string=$(remove_newlines "$query_string_raw")
    unset IFS

    local FULL_CHECK_URL="${url_online_list_status}?${query_string}"

    echo "查询 URL: ${url_online_list_status}" >&2
    echo "完整请求: ${FULL_CHECK_URL}" >&2
    echo "User-Agent: ${HEADER_USER_AGENT_DESKTOP}" >&2

    local response_raw=$(curl --connect-timeout 5 --max-time 10 -s --compressed "$FULL_CHECK_URL" \
        -H "Accept:${HEADER_ACCEPT}" \
        -H "Accept-Encoding:${HEADER_ACCEPT_ENCODING}" \
        -H "Accept-Language:${HEADER_ACCEPT_LANGUAGE}" \
        -H "Connection:${HEADER_CONNECTION}" \
        -H "Referer:${DEFAULT_REFERER}" \
        -H "Host:${HEADER_HOST}" \
        -H "User-Agent:${HEADER_USER_AGENT_DESKTOP}")
    
    local response=$(remove_newlines "$response_raw")
    echo "DEBUG_ONLINE_STATUS: Raw response from curl for online_list: '${response}'" >&2

    local json_part=""
    if [[ "$response" =~ ^"${callback_name}"\((.*?)\)\;?$ ]]; then
        json_part="${BASH_REMATCH[1]}"
    else
        echo "DEBUG_ONLINE_STATUS: 无法从响应解析 JSONP 结构。响应不以 ${callback_name}(...); 形式开始。" >&2
        echo "DEBUG_ONLINE_STATUS: 原始响应是: '${response}'" >&2
        return 2
    fi

    local result_code=""
    if [[ "$json_part" =~ \"result\":([0-9]+) ]]; then
        result_code="${BASH_REMATCH[1]}"
    fi

    local online_ip_from_resp=""
    if [[ "$json_part" =~ \"online_ip\":\"([0-9\.]*)\" ]]; then
        online_ip_from_resp="${BASH_REMATCH[1]}"
    fi

    local online_mac_from_resp=""
    if [[ "$json_part" =~ \"online_mac\":\"([^\"]*)\" ]]; then
        online_mac_from_resp="${BASH_REMATCH[1]}"
        online_mac_from_resp=$(echo "$online_mac_from_resp" | tr -d ':-')
    fi

    if [[ "$result_code" == "1" ]]; then
        echo "DEBUG_ONLINE_STATUS: Status is ONLINE. Updating global IP/MAC from response." >&2
        set_global_var WLAN_USER_IP "${online_ip_from_resp:-0.0.0.0}"
        set_global_var WLAN_USER_MAC "${online_mac_from_resp:-000000000000}"
        echo "当前获取到的 IP (from 在线状态): '${WLAN_USER_IP}'" >&2
        echo "当前获取到的 MAC (from 在线状态): '${WLAN_USER_MAC}'" >&2
        return 0
    elif [[ "$result_code" == "0" ]]; then
        echo "DEBUG_ONLINE_STATUS: Status is OFFLINE." >&2
        return 1
    else
        echo "DEBUG_ONLINE_STATUS: Unknown result_code: '${result_code}'." >&2
        return 2
    fi
}

process() {
    if [ "$device" -eq 1 ]; then
        header_user_agent=${HEADER_USER_AGENT_PHONE}
    else
        header_user_agent=${HEADER_USER_AGENT_DESKTOP}
    fi
}

login() {
    process

    local callback_name=$(generate_callback_name)
    echo "DEBUG_LOGIN: Generated callback_name: '${callback_name}'" >&2

    # 根据设备类型动态设置 user_account 中的数字标识
    local user_account_id=""
    if [[ "$device" -eq 0 ]]; then # PC
        user_account_id="0"
    elif [[ "$device" -eq 1 ]]; then # 手机
        user_account_id="1"
    else # 默认或未知，用PC的，防止报错
        user_account_id="0" 
    fi

    local login_params=(
        "callback=${callback_name}"
        "login_method=1"
        "user_account=,${user_account_id},${USER}@telecom" # 动态设置
        "user_password=$PASSWD"
        "wlan_user_ip=$WLAN_USER_IP"
        "wlan_user_ipv6=$WLAN_USER_IPV6"
        "wlan_user_mac=$WLAN_USER_MAC"
        "wlan_ac_ip=$WLAN_AC_IP"
    )

    IFS="&"
    local params_new_login_raw="${login_params[*]}"
    unset IFS

    local params_new_login=$(remove_newlines "$params_new_login_raw")

    local FULL_LOGIN_URL="$url_new_login?$params_new_login"

    echo "--- 准备登录 ---" >&2
    echo "登录 URL: ${url_new_login}" >&2
    echo "完整请求 (部分参数掩码): $(echo "$FULL_LOGIN_URL" | sed "s/user_password=[^&]*/user_password=********/")" >&2
    echo "User-Agent: ${header_user_agent}" >&2

    local response_raw=$(curl --connect-timeout 5 --max-time 15 -s --compressed "$FULL_LOGIN_URL" \
        -H "Accept:${HEADER_ACCEPT}" \
        -H "Accept-Encoding:${HEADER_ACCEPT_ENCODING}" \
        -H "Accept-Language:${HEADER_ACCEPT_LANGUAGE}" \
        -H "Connection:${HEADER_CONNECTION}" \
        -H "Referer:${DEFAULT_REFERER}" \
        -H "Host:${HEADER_HOST}" \
        -H "User-Agent:${header_user_agent}")
    
    local response=$(remove_newlines "$response_raw")
    echo "DEBUG_LOGIN: Raw response from curl for login: '${response}'" >&2

    local json_result_part=""
    if [[ "$response" =~ ^"${callback_name}"\((.*?)\)\;?$ ]]; then
        json_part="${BASH_REMATCH[1]}"
    else
        echo "DEBUG_LOGIN: 无法从登录响应解析 JSONP 结构。响应不以 ${callback_name}(...); 形式开始。" >&2
        echo "DEBUG_LOGIN: 原始响应是: '${response}'" >&2
        json_part="$response"
    fi

    local login_result=""
    if [[ "$json_part" =~ \"result\":([0-9]+) ]]; then
        login_result="${BASH_REMATCH[1]}"
    fi

    local login_msg=""
    if [[ "$json_part" =~ \"msg\":\"([^\"]*)\" ]]; then
        login_msg="${BASH_REMATCH[1]}"
    fi

    echo "$login_result $login_msg" # 只输出最终结果到 stdout
    exit 0 # 成功执行并返回结果
}

logout() {
    process

    local callback_name=$(generate_callback_name)
    echo "DEBUG_LOGOUT: Generated callback_name: '${callback_name}'" >&2

    # 根据设备类型动态设置 user_account 中的数字标识
    local user_account_id="0" # 0 代表 PC
    if [[ "$device" -eq 1 ]]; then # 如果是手机
        user_account_id="1" # 1 代表手机
    fi

    local logout_params=(
        "callback=${callback_name}"
        "user_account=,${user_account_id},${USER}@telecom" # 动态设置
        "wlan_user_ip=$WLAN_USER_IP"
        "wlan_user_ipv6=$WLAN_USER_IPV6"
        "wlan_user_mac=$WLAN_USER_MAC"
        "wlan_ac_ip=$WLAN_AC_IP"
        "login_method=1"
    )

    IFS="&"
    local params_new_logout_raw="${logout_params[*]}"
    unset IFS

    local params_new_logout=$(remove_newlines "$params_new_logout_raw")

    local FULL_LOGOUT_URL="$url_new_logout?$params_new_logout"

    echo "--- 准备注销 ---" >&2
    echo "注销 URL: ${url_new_logout}" >&2
    echo "完整请求: $FULL_LOGOUT_URL" >&2
    echo "User-Agent: ${header_user_agent}" >&2

    local response_raw=$(curl --connect-timeout 5 --max-time 15 -s --compressed "$FULL_LOGOUT_URL" \
        -H "Accept:${HEADER_ACCEPT}" \
        -H "Accept-Encoding:${HEADER_ACCEPT_ENCODING}" \
        -H "Accept-Language:${HEADER_ACCEPT_LANGUAGE}" \
        -H "Connection:${HEADER_CONNECTION}" \
        -H "Referer:${DEFAULT_REFERER}" \
        -H "Host:${HEADER_HOST}" \
        -H "User-Agent:${header_user_agent}")
    
    local response=$(remove_newlines "$response_raw")
    echo "DEBUG_LOGOUT: Raw response from curl for logout: '${response}'" >&2

    local json_result_part=""
    if [[ "$response" =~ ^"${callback_name}"\((.*?)\)\;?$ ]]; then
        json_part="${BASH_REMATCH[1]}"
    else
        echo "DEBUG_LOGOUT: 无法从注销响应解析 JSONP 结构。响应不以 ${callback_name}(...); 的形式开始。" >&2
        echo "DEBUG_LOGOUT: 原始响应是: '${response}'" >&2
        json_part="$response"
    fi

    local logout_result=""
    if [[ "$json_part" =~ \"result\":([0-9]+) ]]; then
        logout_result="${BASH_REMATCH[1]}"
    fi

    local logout_msg=""
    if [[ "$json_part" =~ \"msg\":\"([^\"]*)\" ]]; then
        logout_msg="${BASH_REMATCH[1]}"
    fi

    echo "$logout_result $logout_msg" # 只输出最终结果到 stdout
    exit 0 # 成功执行并返回结果
}

show_help() {
echo "Usage: $0 action account password \[device]"
echo "Use curl to login/logout to the campus network."
echo "Options:"
echo -e "  -h, --help\t\tShow this help message and exit"
echo "Arguments:"
echo -e "  action\t\tLog in or log out: login, logout"
echo -e "  account\t\tThe account for logging in (e.g., 2023210516034)"
echo -e "  password\t\t(Required for login) The password for logging in"
echo -e "  device\t\t(Optional, default: pc) The device type for logging in: pc, phone"
}

# --- 命令行参数处理 ---
ACTION=""
ACCOUNT=""
PASSWORD=""
DEVICE_TYPE="pc" # 默认值

ACTION="$1"; shift
ACCOUNT="$1"; shift
PASSWORD="$1"; shift
if [[ -n "$1" ]]; then DEVICE_TYPE="$1"; shift; fi

if [[ "$ACTION" == "-h" || "$ACTION" == "--help" ]]; then show_help; exit 0; fi
if [[ -z "$ACTION" ]]; then echo -e "\033[31m错误: 必须指定 'login' 或 'logout' 动作。\033[0m" >&2; show_help; exit 3; fi

USER="${ACCOUNT}"; PASSWD="${PASSWORD}"

if [[ -z "$USER" ]]; then 
    if [[ -n "$EPORTAL_USERNAME" ]]; then USER="$EPORTAL_USERNAME"; else read -p "请输入账号 (例如: 2023210516034): " USER_INPUT; USER=$(remove_newlines "$USER_INPUT"); fi
fi
if [[ "$ACTION" == "login" && -z "$PASSWD" ]]; then 
    if [[ -n "$EPORTAL_PASSWORD" ]]; then PASSWD="$EPORTAL_PASSWORD"; else read -s -p "请输入密码: " PASSWD_INPUT; echo; PASSWD=$(remove_newlines "$PASSWD_INPUT"); fi
fi

if [[ -z "$USER" ]]; then echo -e "\033[31m错误: 必须提供账号。\033[0m" >&2; show_help; exit 1; fi
if [[ "$ACTION" == "login" && -z "$PASSWD" ]]; then echo -e "\033[31m错误: 登录操作需要提供密码。\033[0m" >&2; show_help; exit 1; fi

device_numeric=0; if [[ "$DEVICE_TYPE" == "pc" ]]; then device_numeric=0; elif [[ "$DEVICE_TYPE" == "phone" ]]; then device_numeric=1; else echo -e "\033[31m设备类型错误:须为 'pc' 或 'phone'。\033[0m" >&2; show_help; exit 2; fi
device="$device_numeric"

# --- 主逻辑流程 ---
# current_status_return_code 声明为全局变量
current_status_return_code_val=2 

echo "--- 执行前状态检查 ---" >&2
# 尝试检查当前在线状态，并获取 IP/MAC
check_current_online_status
current_status_return_code_val=$? # 0在线，1不在线，2无法判断

if [[ "$current_status_return_code_val" -eq 0 ]]; then
    echo -e "\n\033[32m当前已在线。获取到的 IP/MAC 将用于后续操作（如刷新会话或注销）。\033[0m" >&2
    echo "当前获取到的 IP: ${WLAN_USER_IP}" >&2
    echo "当前获取到的 MAC: ${WLAN_USER_MAC}" >&2
    
    if [[ "$ACTION" == "login" ]]; then
        echo -e "\n\033[33m您已登录，无需重复登录。如果需要刷新会话，可以尝试重新运行登录命令。如需注销，请使用 'logout' 动作。\033[0m" >&2
        result=1 # 模拟成功状态，但提示无需重登
        msg="已在线，无需重复登录。"
        # 注意：此处返回 result msg，并exit 0
        echo "$result $msg"
        exit 0
    fi
else # 如果不在线 ($current_status_return_code_val -eq 1) 或无法判断 (-eq 2)
    echo "DEBUG: 当前不在线或无法判断，尝试从重定向 URL 预加载 IP/MAC/AC_IP。" >&2
    if ! preload_term_info; then
        echo -e "\033[31m错误: 无法获取有效的 IP/MAC 地址。请确保网络处于未认证状态并提供有效的 URL，否则无法执行认证操作。程序退出。\033[0m" >&2
        # 注意：此处返回 result msg
        result=0 # 预加载失败被视为登录失败
        msg="IP/MAC预加载失败"
        echo "$result $msg"
        exit 4
    fi
fi

# --- 执行登录/注销动作 ---
if [[ "$ACTION" == "login" ]]; then
    login
elif [[ "$ACTION" == "logout" ]]; then
    logout
fi

# 最终确保，无论任何情况，LoginIntoCqnu.sh 都只输出 result msg 到 stdout
# 实际的 echo 在 login() 和 logout() 内部，这里不再重复
exit 0
