import base64 as bs
import json, re, time
from PIL import Image
from io import BytesIO

import bs4 as Bss
import requests as rts
from pyDes import ECB, PAD_PKCS5, des


class LoginSession:
    def __init__(self, service_url:str, print_banner:bool=True):
        if print_banner:
            banner = r"""  ______   ______  __    __ __    __ 
 /      \ /      \|  \  |  \  \  |  \
|  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓\ | ▓▓ ▓▓  | ▓▓
| ▓▓   \▓▓ ▓▓  | ▓▓ ▓▓▓\| ▓▓ ▓▓  | ▓▓
| ▓▓     | ▓▓  | ▓▓ ▓▓▓▓\ ▓▓ ▓▓  | ▓▓
| ▓▓   __| ▓▓ _| ▓▓ ▓▓\▓▓ ▓▓ ▓▓  | ▓▓
| ▓▓__/  \ ▓▓/ \ ▓▓ ▓▓ \▓▓▓▓ ▓▓__/ ▓▓
 \▓▓    ▓▓\▓▓ ▓▓ ▓▓ ▓▓  \▓▓▓\▓▓    ▓▓
  \▓▓▓▓▓▓  \▓▓▓▓▓▓\\▓▓   \▓▓ \▓▓▓▓▓▓ 
               \▓▓▓                   .edu.cn"""
            print(banner)

        self.main_se = rts.session()

        self.ver_image = "https://csxrz.cqnu.edu.cn/cas/verCode?random=="

        self.login_url = "https://csxrz.cqnu.edu.cn/cas/login"

        self.findOkArea = "https://gym.cqnu.edu.cn/app/product/findOkArea.html"
        self.service_url = service_url

        self.normal_headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36"
        }

        self.main_se.headers.update(self.normal_headers)

        # try:
        #     with open("login.info","r") as f:
        #         login_info = json.load(f)
        #         self.user = login_info["ID"]
        #         self.passwd = login_info["passwd"]
        # except :
        #     print("请先登录")
        #     self.user = input("账号:")
        #     self.passwd = input("密码:")

        # while not self.login():
        #     print("登陆失败,重试中...")
        #     time.sleep(1)

    def deVer(self, ver):
        """
        验证码识别
        方法一:
            使用 ddddocr
            如果你安装了此依赖
        方法二:
            验证码解析接口
            https://market.aliyun.com/products/57124001/cmapi027426.html?spm=5176.2020520132.101.1.45ab72185BHAcX#sku=yuncode2142600000
            注册成功后 复制APPCODE
            粘贴到headers 中
            示例:注意空格
            "Authorization":"APPCODE 你的APPCODE" 
        方法三:
            手动识别验证码
        """

        code = False

        # 方法一:
        try:
            import ddddocr
            ocr = ddddocr.DdddOcr(show_ad=False)
            code = ocr.classification(ver)
        except:
            print("can't import ddddocr switch to another decode method")
        finally:
            if code:
                return code
            # 方法二:
            ascii_ver = bs.b64encode(ver).decode('ascii')
            headers = {
                "image": ascii_ver,
                "type": "1001",
                "Authorization": "APPCODE <your token>"
            }
            url = "https://302307.market.alicloudapi.com/ocr/gaptcha"
            res = rts.post(url, headers=headers)
            if res and res.json()["code"] == 0:
                return res.json()["data"]["gaptcha"]
            else:
                # 方法三
                print(res.headers["X-Ca-Error-Message"])
                print("can't decode through network API switch to the last decode method")
                img = Image.open(BytesIO(ver))
                img.show()
                time.sleep(1.5)
                return input("请输入验证码: ")

    def encrypt_des(self, passwd, key):
        k = des(key, ECB, key, pad=None, padmode=PAD_PKCS5)
        en = k.encrypt(passwd.encode('utf-8'), padmode=PAD_PKCS5)
        return str(bs.b64encode(en), 'utf-8')

    def set_account(self, user, passwd):
        self.user = user
        self.passwd = passwd
        
    def login(self):
        try:
            login_res = self.main_se.get(self.login_url, params={"service": self.service_url}, headers=self.normal_headers)
                
            if login_res.text.find("<title>统一身份认证及授权访问平台</title>") < 0:
                return True
        
            ping = self.main_se.get(self.login_url, params={"service": self.service_url}, headers=self.normal_headers)
            ping.raise_for_status()  # 检查请求是否成功

            pings = Bss.BeautifulSoup(ping.text, "html.parser")

            ver_img = self.main_se.get(
                self.ver_image + str(int(time.time()*100)), headers=self.normal_headers)
            ver_img.raise_for_status()  # 检查请求是否成功

            ver_code = self.deVer(ver_img.content)

            execution = pings.find("input", {"name": "execution"})
            lt = pings.find("input", {"name": "lt"})

            if not execution or not lt:
                raise ValueError("无法找到 execution 或 lt 字段")

            execution = execution.get("value")
            lt = lt.get("value")
            key = lt[:8]

            password = self.encrypt_des(self.passwd, key)

            data = {
                "username": self.user,
                "password": password,
                "cellPhoneNum": "",
                "smsValidateCode": "",
                "authCode": ver_code,
                "lt": lt,
                "execution": execution,
                "_eventId": "submit",
                "isQrSubmit": "false",
                "isMobileLogin": "false",
                "qrValue": "",
                "isMobileLogin": "false"
            }

            login_res = self.main_se.post(
                self.login_url, params={"service": self.service_url}, data=data, headers=self.normal_headers)
            login_res.raise_for_status()  # 检查请求是否成功

            if login_res.text.find("<title>统一身份认证及授权访问平台</title>") < 0:
                return True
            else:
                return False

        except rts.exceptions.RequestException as e:
            print(f"[LoginSession] 网络请求失败: {e}")
            return False
        except ValueError as e:
            print(f"[LoginSession] 解析错误: {e}")
            return False
        except Exception as e:
            print(f"[LoginSession] 未知错误: {e}")
            return False
        
    def check_login(self):
        while not self.login():
            # print("登陆失败,重试中...")
            time.sleep(1)
        