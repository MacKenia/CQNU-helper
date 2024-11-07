# ������ - ������ڽű�����
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

# �������
$url_new_login = "http://10.0.254.125:801/eportal/portal/login"
$url_new_logout = "http://10.0.254.125:801/eportal/portal/mac/unbind"

# ��������ͷ
$headers = @{
    "Accept" = "*/*"
    "Accept-Encoding" = "gzip, deflate"
    "Accept-Language" = "zh-CN,zh;q=0.9"
    "Cache-Control" = "max-age=0"
    # "Connection" = "keep-alive"   # �Ƴ������Ա������
    "DNT" = "1"
    "Referer" = "http://10.0.254.125/"
    "Host" = "10.0.254.125:801"
    "Content-Type" = "application/x-www-form-urlencoded"
    "Origin" = "http://10.0.254.125"
    "Upgrade-Insecure-Requests" = "1"
}

# �û�����
$ua_ph = "Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
$ua_pc = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"

# ��������
function Get-RandomCredential {
    param (
        [string]$filePath
    )

    if (Test-Path $filePath) {
        # ��ȡ JSON �ļ���ת��Ϊ PowerShell ����
        $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json

        if ($jsonContent.PSObject.Properties.Count -eq 0) {
            Write-Error "JSON �ļ���û���κμ�ֵ�ԡ�"
            exit 1
        }

        # ���ѡ��һ����
        $randomKey = Get-Random -InputObject $jsonContent.PSObject.Properties.Name

        # ��ȡ��Ӧ��ֵ
        $randomValue = $jsonContent.$randomKey

        return @{ id = $randomKey; passwd = $randomValue }
    } else {
        Write-Error "JSON �ļ�δ�ҵ�������·����$filePath"
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

    # �����豸ѡ���û�����
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
        Write-Error "��¼����ʧ��: $_"
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
        Write-Error "ע������ʧ��: $_"
    }
}

if ($id -and $passwd) {
    # ʹ���ֶ�ָ����ƾ֤
    if ($action -eq "login") {
        Login -user $id -passwd $passwd -device $device
    } elseif ($action -eq "logout") {
        Logout -user $id
    }
} else {
    # ʹ�����ѡ���ƾ֤
    $credentials = Get-RandomCredential -filePath $jsonFilePath
    $id = $credentials.id
    $passwd = $credentials.passwd

    if ($action -eq "login") {
        Login -user $id -passwd $passwd -device $device
    } elseif ($action -eq "logout") {
        Logout -user $id
    }
}
