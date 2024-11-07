# 参数块 - 将其放在脚本顶部
# keep.ps1 -action login -device 1
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("login", "logout")]
    [string]$action,

    [string]$jsonFilePath = "credentials.json",

    [string]$device = "pc",

    [string]$id = $null,

    [string]$passwd = $null
)

# 定义变量
$url_new_login = "http://10.0.254.125:801/eportal/portal/login"
$url_new_logout = "http://10.0.254.125:801/eportal/portal/mac/unbind"

# 定义请求头
$headers = @{
    "Accept" = "*/*"
    "Accept-Encoding" = "gzip, deflate"
    "Accept-Language" = "zh-CN,zh;q=0.9"
    "Cache-Control" = "max-age=0"
    # "Connection" = "keep-alive"   # 移除此行以避免错误
    "DNT" = "1"
    "Referer" = "http://10.0.254.125/"
    "Host" = "10.0.254.125:801"
    "Content-Type" = "application/x-www-form-urlencoded"
    "Origin" = "http://10.0.254.125"
    "Upgrade-Insecure-Requests" = "1"
}

# 用户代理
$ua_ph = "Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
$ua_pc = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"

# 函数定义
function Get-RandomCredential {
    param (
        [string]$filePath
    )

    if (Test-Path $filePath) {
        # 读取 JSON 文件并转换为 PowerShell 对象
        $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json

        if ($jsonContent.PSObject.Properties.Count -eq 0) {
            Write-Error "JSON 文件中没有任何键值对。"
            exit 1
        }

        # 随机选择一个键
        $randomKey = Get-Random -InputObject $jsonContent.PSObject.Properties.Name

        # 获取对应的值
        $randomValue = $jsonContent.$randomKey

        return @{ id = $randomKey; passwd = $randomValue }
    } else {
        Write-Error "JSON 文件未找到，请检查路径：$filePath"
        exit 1
    }
}

function ProcessData {
    param (
        [string]$device,
        [string]$user,
        [string]$passwd
    )

    $data_new_login = @{
        "callback" = "dr1011"
        "login_method" = "1"
        "wlan_user_mac" = "000000000000"
        "ua_name" = "Netscape"
        "ua_code" = "Mozilla"
        "user_account" = "$device,$user@telecom"
        "user_password" = $passwd
    }

    # 根据设备选择用户代理
    if ($device -eq "1") {
        $headers["User-Agent"] = $ua_ph
    } else {
        $headers["User-Agent"] = $ua_pc
    }

    return $data_new_login
}

function Login {
    param (
        [string]$user,
        [string]$passwd,
        [string]$device
    )

    $data = ProcessData -device $device -user $user -passwd $passwd
    try {
        $response = Invoke-RestMethod -Uri $url_new_login -Method Get -Body $data -Headers $headers -ContentType "application/x-www-form-urlencoded"
        Write-Output $response
    }
    catch {
        Write-Error "登录请求失败: $_"
    }
}

function Logout {
    param (
        [string]$user
    )

    $data_new_logout = @{
        "callback" = "dr1003"
        "user_account" = "$user@telecom"
        "wlan_user_mac" = "000000000000"
        "jsVersion" = "4.1.3"
        "lang" = "zh"
    }
    try {
        $response = Invoke-RestMethod -Uri $url_new_logout -Method Get -Body $data_new_logout -Headers $headers -ContentType "application/x-www-form-urlencoded"
        Write-Output $response
    }
    catch {
        Write-Error "注销请求失败: $_"
    }
}

if ($id -and $passwd) {
    # 使用手动指定的凭证
    if ($action -eq "login") {
        Login -user $id -passwd $passwd -device $device
    } elseif ($action -eq "logout") {
        Logout -user $id
    }
} else {
    # 使用随机选择的凭证
    $credentials = Get-RandomCredential -filePath $jsonFilePath
    $id = $credentials.id
    $passwd = $credentials.passwd

    if ($action -eq "login") {
        Login -user $id -passwd $passwd -device $device
    } elseif ($action -eq "logout") {
        Logout -user $id
    }
}
