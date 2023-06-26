import requests, re

class LoginIntoCqnu:
    PC = 0
    PHONE = 1

    def __init__(self, user:str, passwd:str, device:int=PC, old:bool=False) -> None:
        self.__dev__ = device
        self.__old__ = False
        self.__user__ = user
        self.__passwd__ = passwd

        self.__url_old__ = "http://10.0.251.18:801/eportal/"
        self.__url_new_login__ = "http://10.0.254.125:801/eportal/portal/login"
        self.__url_new_logout__ = "http://10.0.254.125:801/eportal/portal/mac/unbind"

        self.__ua_pc__ = "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"
        self.__ua_ph__ = "5.0 (Linux; Android 9.0; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/81.0.4044.117 Mobile Safari/537.36"

        self.__data_old__ = {
            "R1":"0",
            "R2": "",
            "R6": "0",
            "para": "00",
            "0MKKey": "123456"
        }

        self.__data_new_login__ = {
            "callback": "dr1011",
            "login_method": "1",
            "wlan_user_mac": "000000000000",
            "ua_name": "Netscape",
            "ua_code": "Mozilla",
        }

        self.__data_new_logout__ = {
            "callback": "dr1003",
            "user_account": "",
            "wlan_user_mac": "000000000000",
            "wlan_user_ip": "",
            "jsVersion": "4.1.3",
            "lang": "zh"
        }

        header_desktop = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,zh;q=0.9",
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
            "Content-Length": "87",
            "Content-Type": "application/x-www-form-urlencoded",
            "Host": "10.0.251.18:801",
            "Origin": "http://10.0.251.18",
            "Referer": "http://10.0.251.18/",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"
        }

        header_desktop_new = {
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
            "Connection": "keep-alive",
            "DNT": "1",
            "Host": "10.0.254.125:801",
            "Referer": "http://10.0.254.125",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36 Edg/94.0.992.31"
        }

        header_phone = {
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,zh;q=0.9",
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
            "Content-Type": "application/x-www-form-urlencoded",
            "Host": "10.0.251.18:801",
            "Origin": "http://10.0.251.18",
            "Referer": "http://10.0.251.18/",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": "Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
        }

        header_phone_new = {
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,zh;q=0.9",
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
            "Content-Type": "application/x-www-form-urlencoded",
            "Host": "10.0.254.125:801",
            "Origin": "http://10.0.254.125",
            "Referer": "http://10.0.254.125/",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": "Mozilla/5.0 (Linux; Android 10; HuaWei Mate Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/98.0.1108.62"
        }

        self.__headers_list__ = [[header_desktop_new, header_phone_new],[header_desktop, header_phone]]

    def __process__(self) -> None:
        self.__data_old__["DDDDD"] = ",0," + self.__user__ + "@telecom"
        self.__data_old__["upass"] = self.__passwd__

        self.__data_new_login__["user_account"] = "," + str(self.__dev__) +"," +  self.__user__ + "@telecom"
        self.__data_new_login__["user_password"] = self.__passwd__
        self.__data_new_login__["terminal_type"] = self.__dev__

        if self.__dev__ == self.PC:
            self.__data_new_login__["ua_version"] = self.__ua_pc__
            self.__data_new_login__["ua_agent"] = "Mozilla/" + self.__ua_pc__
        else:
            self.__data_new_login__["ua_version"] = self.__ua_ph__
            self.__data_new_login__["ua_agent"] = "Mozilla/" + self.__ua_ph__

        self.__data_new_logout__["user_account"] = self.__user__ + "@telecom"


    def login(self, **kwargs) -> requests.Response:
        """
        This function is used to send login massage to center login authorization server.
        :param device: Device Type
        :param old: Old Autentication mode
        """
        if "device" in kwargs:
            self.__dev__ = kwargs["device"]
        if "old" in kwargs:
            self.__old__ = kwargs["old"]

        self.__process__()

        if self.__old__:
            r = requests.post(url=self.__url_old__, data=self.__data_old__, headers=self.__headers_list__[self.__old__][self.__dev__])
        else:
            r = requests.get(url=self.__url_new_login__, params=self.__data_new_login__, headers=self.__headers_list__[self.__old__][self.__dev__])
        return r


    def logout(self) -> requests.Response:
        """
        This function is used to send logout message to center server. 
        """
        r = requests.get(url=self.__url_new_logout__, params=self.__url_new_logout__, headers=self.__headers_list__[self.__old__][self.__dev__])
        return r
    
if __name__ == "__main__":
    p_res_code = re.compile(r'"result":(\d),')
    p_res_msg = re.compile(r'"msg":"(.*?)",')

    lq = LoginIntoCqnu("20xxxxxxxxxxx","xxxxxx")
    # r = lq.logout()
    r = lq.login(device=lq.PHONE)

    res_code = p_res_code.findall(r.text)[0]
    res_msg = p_res_msg.findall(r.text)[0]

    if res_code == '0':
        print(f"\033[31m", end="")
    else:
        print(f"\033[32m", end="")
    print(f"{res_msg}\033[0m")
