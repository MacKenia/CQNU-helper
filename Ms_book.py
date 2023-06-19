"""
安装依赖(带验证码识别，依赖包较大，安装时间会比较久):
pip install requests beautifulsoup4 pyDes Pillow ddddocr

安装依赖(不带验证码识别，依赖包较小，安装时间相对较短):
pip install requests beautifulsoup4 pyDes Pillow

基于07大佬脚本改写

date 格式 yyyymmdd 示例 20220510
"""
import base64 as bs
import json, re, time, os
from PIL import Image
from io import BytesIO

import bs4 as Bss
import requests as rts
from pyDes import ECB, PAD_PKCS5, des
from datetime import datetime
from icalendar import Calendar, Event
import pyqrcode as pyqr
import socket
from http.server import HTTPServer, BaseHTTPRequestHandler
from websockets.sync.client import connect

class MyHandler(BaseHTTPRequestHandler):
    def __init__(self, file, *args) -> None:
        self.file = file
        BaseHTTPRequestHandler.__init__(self, *args)
        print("路径", file, "...")

    def do_GET(self):
        with open(self.file, 'rb') as f:
            file_contents = f.read()

        self.send_response(200)
        self.send_header('Content-type', 'text/calender')
        self.send_header('Content-Disposition', f'attachment; filename="{self.file}"')
        self.end_headers()

        self.wfile.write(file_contents)
        return

class BookYourDream:
    def __init__(self):
        self.D_ONE = 141  # 梦一厅
        self.D_TWO = 142  # 梦二厅
        self.D_THREE = 261  # 梦三厅

        self.TIME_TABLE = ["07:30-09:59", "10:00-11:59", "12:00-13:59",
                           "14:00-15:59", "16:00-17:59", "18:00-19:59", "20:00-23:30"]
        self.week_name = ["星期天", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        self.reserved = []

        self.main_se = rts.session()

        self.table_patten = re.compile(r"<dt>(\d{2}:\d{2}-\d{2}:\d{2})[^0-9]+(\d+)排(\d)座<\/dt>")

        self.index_url = "http://202.202.209.15:8081/index.html"

        self.ver_image = "https://csxrz.cqnu.edu.cn:443/cas/verCode?random=="

        self.login_url = "https://csxrz.cqnu.edu.cn/cas/login?service=https://csxmh.cqnu.edu.cn/PersonalApplications/viewPage?active_nav_num=1"
        self.login_url = "https://csxrz.cqnu.edu.cn/cas/login?service=http%3A%2F%2F202.202.209.15%3A8081%2Findex.html"

        self.inquire_url = "http://202.202.209.15:8081/product/findtime.html"

        self.double_url = "http://202.202.209.15:8081/product/doublingTimeVer.html?stockid="

        self.book_url = "http://202.202.209.15:8081/order/tobook.html"

        self.search_url = "http://202.202.209.15:8081/yyuser/searchorder.html?page=1&status=1&iscomment="

        self.cancel_url = "http://202.202.209.15:8081/order/delorder.html"

        self.cancel_detail_url = "http://202.202.209.15:8081/order/delorderdetail.html"

        self.order_url = "http://202.202.209.15:8081/order/myorder_view.html?id="
        
        self.success_page = "http://202.202.209.15:8081/order/successpage.html"

        self.normal_headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36"
        }

        self.response = None

    def yesorno(self, msg:str) -> bool:
        while True:
            c = input(msg).strip()
            if c == "y" or c == "Y" or c == "":
                return True
            elif c == "n" or c == "N":
                return False
            else:
                print("输入错误,请重新输入")

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
            ocr = ddddocr.DdddOcr()
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

    def login(self, user:str, passwd:str):
        ping = self.main_se.get(self.index_url, headers=self.normal_headers)

        pings = Bss.BeautifulSoup(ping.text, "html.parser")

        # print(type(pings))

        ping_inputs = pings.find_all("input")

        ver_img = self.main_se.get(
            self.ver_image + str(int(time.time()*100)), headers=self.normal_headers)

        ver_code = self.deVer(ver_img.content)

        print(ver_code)

        key = ping_inputs[4].get("value")[:8]
        execution = ping_inputs[5].get("value")

        password = self.encrypt_des(passwd, key)

        data = {
            "username": user,
            "password": password,
            "authCode": ver_code,
            "lt": ping_inputs[4].get("value"),
            "execution": execution,
            "_eventId": "submit",
            "isQrSubmit": "false",
            "isMobileLogin": "false",
            "qrValue": ""
        }

        login_res = self.main_se.post(
            self.login_url, data=data, headers=self.normal_headers)
        # print(login_res.text)
        if login_res.content.decode('utf-8').find("梦厅") != login_res.content.decode("utf-8").find("场地"):
            print("登录成功")
            login_res = Bss.BeautifulSoup(login_res.text, "html.parser")
            self.user_no = login_res.select("#userno")[0].get("value")
            return True
        else:
            print("登录失败")
            return False

    def parse_num(self, raw:str) -> list:
        re = []
        raw = raw.split(" ")
        for i in raw:
            if i.count("-"):
                t = i.split("-")
                for j in range(int(t[0]), int(t[1])+1):
                    re.append(j)
            else:
                for j in range(len(i)):
                    re.append(int(i[j]))
        return sorted(re)

    def just_inquire(self, room:str, date:str) -> list:
        params = {
            "type": "day",
            "s_dates": time.strftime("%Y-%m-%d", date),
            "serviceid": room
        }
        r = self.main_se.get(self.inquire_url, params=params)
        if not r.json()["object"]:
            print("网络错误")
            return []
        return r.json()["object"]


    def inquire(self, room:str, date:str, allday:str=False):
        params = {
            "type": "day",
            "s_dates": time.strftime("%Y-%m-%d", date),
            "serviceid": room
        }
        r = self.main_se.get(self.inquire_url, params=params)
        if not r.json()["object"]:
            print("网络错误")
            return
        for index, i in enumerate(r.json()["object"]):
            print(f"{index}: {i['TIME_NO']} 剩余 {i['SURPLUS']}")

        reserve = {}

        allday = self.yesorno("需要预定全天吗?(y/n):")
        if not allday:
            rs = input("请输入希望预定的时间段(示例:01 2 3-4 6-7 ): ")
            rs = self.parse_num(rs)

        for index, i in enumerate(r.json()["object"]):
            if allday or index in rs:
                reserve[str(i['ID'])] = "1"

        self.reserved.append(time.strftime("%Y-%m-%d", date))
        return reserve

    def booked(self, rows:int=3, get_expired:bool=True):
        """
        function not stable, still has some problem.
        """
        booked_list = []
        r = self.main_se.get(self.search_url, headers=self.normal_headers, params={'rows': rows})
        if not r.json():
            print("网络错误")
            return
        for i in r.json():
            if not get_expired:
                if time.strptime(i['stockDate'], "%Y-%m-%d") < time.strptime(time.strftime("%Y-%m-%d", time.localtime()), "%Y-%m-%d"):
                    continue
            booked_list.append({'stockDate': i['stockDate'],
                                'orderid': i['orderid'],
                                'servicenames': i['servicenames'],
                                'remark1': i['remark1'],
                                'remark': i['remark']
                                })
        return booked_list

    def book(self, table:dict) -> rts.Response:
        with connect('ws://202.202.209.15:8081/websocket/') as ws:
            ws.send(f"createOrder{self.user_no}")
            data = {
                "param": json.dumps({
                    "stock": table,
                    "extend": {}
                }),
                "json": True
            }
            r = self.main_se.post(self.book_url, data=data)
            if not r:
                print("网络错误")
                return
            self.ws_response = ws.recv()
            return r

    def book_time(self, room:str, date:str, times:str):
        param = {
            "type": "day",
            "s_dates": time.strftime("%Y-%m-%d", date),
            "serviceid": room
        }

        t = 1
        e = 1
        while True:
            print(f"第{t}次尝试预定", end="\r")
            r = self.main_se.get(self.inquire_url, params=param)
            if not r:
                if e == 3:
                    print("失败")
                    return
                print("出现错误，正在重试", end="\r")
                return
            for i in r.json()["object"]:
                if i["TIME_NO"] == times:
                    self.book({str(i['ID']): "1"})
                    if r.json()["message"]:
                        print("出错重试中...", end="\r")
                    else:
                        print("\n预定成功")
                        return
            t += 1
            time.sleep(1)

    def check_after_book(self,**kwargs):
        if kwargs.get("table"):
            table:str = kwargs["table"]
        if kwargs.get("times"):
            times:list = kwargs["times"]
        
        order_id = json.loads(self.ws_response)['object']['orderid']
        self.response = self.main_se.get(self.success_page, params={'id': order_id}).text
        self.re_result = self.table_patten.findall(self.response)
        print(self.re_result[0])
        if table:
            if table == f"{self.re_result[0][1]:0>2}{self.re_result[0][2]}":
                return True
        elif times:
            """
            不稳定
            """
            time_list_re = [ i[0] for i in self.re_result ]
            for i in times:
                if i not in time_list_re:
                    return False
            return True
        return False

    def book_table(self, room:str, date:str, reserve:dict, table:str):
        t = 1
        sleep_gap = 1
        while True:
            self.book(reserve)
            if self.check_after_book(table=table):
                print("预定成功!")
                return True
            else:
                p = int(table[0:2]) - int(self.re_result[0][1])
                z = int(table[-1]) - int(self.re_result[0][2])
                if z < 0:
                    z += 8
                    p -= 1
                print(f"当前预定到的座位为{self.re_result[0][1]}排{self.re_result[0][2]}座")
                print(f"与目标座位距离{p}排{z}座")

                if p < 0:
                    print(f"已经被人预定了.")
                    return False
                elif p < 1:
                    sleep_gap = 1
                    print(f"距离很近, 更改下一次预定等待时间为{sleep_gap}秒")
                elif p < 2:
                    sleep_gap = 10
                    print(f"距离较近, 更改下一次预定等待时间为{sleep_gap}秒")
                else:
                    sleep_gap = 60
                    print(f"距离较远, 更改下一次预定等待时间为{sleep_gap}秒")
                print("取消该座位中...")
                self.cancel_order(json.loads(self.ws_response)['object']['orderid'])
                print("取消完成")
            print(f"第{t}次尝试预定失败，下一次预定为{sleep_gap}秒后\n")
            t += 1
            time.sleep(sleep_gap)

    def cancel_order(self, orderid:str):
        """
        已知问题:
            后端数据库已取消，前端不同步
        """
        r = self.main_se.get(str(self.order_url + orderid))
        if not r:
            print("网络错误")
            return False
        rr = re.findall("onclick=\"cencelDetail\('(\d*)'\)\"", r.text)
        rr.append(orderid)
        for j in rr:
            data = {
                "orderid": j,
                "json": True
            }
            self.main_se.post(self.cancel_detail_url, data=data,
                            headers=self.normal_headers)
        return True

    def cancel(self, cancel_list:list):
        for index, i in enumerate(self.booked(len(cancel_list), False)):
            if index not in cancel_list:
                continue

            if not self.cancel_order(i["orderid"]):
                continue

            print(f"\n已取消:\n日期: {i['stockDate']} \n地点: {i['servicenames']} \n时间: {i['remark1']} \n座位: {i['remark']}\n")

    def ical_gen(self):
        self.reserve = []
        booked = self.booked()

        if not self.reserved:
            inp = input("您此次还没有任何预定，您给可以从曾经的订单中生成.ics文件(y/n):").strip()
            if inp == "" or inp == "y":
                for i in booked:
                    t = input(f"\n日期: {i['stockDate']} \n地点: {i['servicenames']} \n时间: {i['remark1']} \n座位: {i['remark']}\n添加到日程吗(y/n):").strip()
                    if t == "y" or not t:
                        self.reserved.append(i['stockDate'])
            else:
                return
        for i in booked:
            if i["stockDate"] in self.reserved:
                self.reserved.remove(i["stockDate"])
                remark = i["remark1"].split(",")
                for j in remark:
                    self.reserve.append({
                        "title": "梦厅预定@Ms_book",
                        "location": f"{i['servicenames']} {i['remark']}",
                        "start_time": f"{i['stockDate']} {j[:5]}",
                        "end_time": f"{i['stockDate']} {j[6:]}"
                    })

        # 创建日历对象
        cal = Calendar()

        # 遍历日程信息，创建事件对象
        for item in self.reserve:
            event = Event()
            event.add('summary', item['title'])
            event.add('location', item['location'])
            event.add('dtstart', datetime.fromisoformat(item['start_time']))
            event.add('dtend', datetime.fromisoformat(item['end_time']))
            cal.add_component(event)

        filename = f'{self.reserve[0]["start_time"][:10]}'

        # 将日历写入文件
        with open(f'{filename}_{time.localtime().tm_sec}.ics', 'wb') as f:
            f.write(cal.to_ical())
        t = input("发送到手机(y/n)?").strip()
        if t == "" or t == "y":
            self.send_to_phone(f'{filename}.ics')

    def send_to_phone(self, path):
        ip_address = self.get_host_ip()
        qr = pyqr.create(f"http://{ip_address}:8080")
        print(qr.terminal())
        print(f'http://{ip_address}:8080')
        print('请确保手机与电脑处于统一局域网,校园网亦可')
        print('按<C-c>来关闭 HTTP 服务器...')

        httpd = HTTPServer(('0.0.0.0', 8080), lambda x, y, z: MyHandler(path ,x, y, z))
        httpd.serve_forever()
        try:
            httpd.serve_forever()
        except:
            print('正在关闭 HTTP 服务器...')
            httpd.shutdown()

    def get_host_ip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(('8.8.8.8', 80))
            ip = s.getsockname()[0]
        finally:
            s.close()

        return ip

    def main(self):
        room = [self.D_ONE, self.D_TWO, self.D_THREE]
        try:
            with open("login.info","r") as f:
                login_info = json.load(f)
                user = login_info["ID"]
                passwd = login_info["passwd"]
        except :
            print("请先登录")
            user = input("账号:")
            passwd = input("密码:")

        while not self.login(user, passwd):
            print("登陆失败,重试中...")
            time.sleep(1)
        while True:
            choice = int(input("\n1.预定座位\n2.取消订单\n3.查询订单\n4.退出\n5.自动登陆开关\n6.生成.ics\n请输入:"))
            if choice == 1:
                while True:
                    choice = input("\n1.日期预定\n2.时间预定\n3.位置预定\n请输入:")
                    try:
                        choice = int(choice)
                        break
                    except:
                        print("输入错误,请重新输入\n")
                while True:
                    cRoom = input("1. 梦一厅\n2. 梦二厅\n3. 梦三厅\n场地:")
                    try:
                        cRoom = int(cRoom)
                        break
                    except:
                        print("输入错误,请重新输入\n")
                while True:
                    _date = input("日期(示例: yyyymmdd 或 一个数字表示多少天后):")
                    try:
                        if _date == "":
                            date = time.localtime()
                        elif len(_date) < 6:
                            date = time.localtime(time.time()+int(_date)*24*60*60)
                        else:
                            date = time.strptime(_date, "%Y%m%d")
                        print(f"\n你选择的日期: {time.strftime('%Y-%m-%d', date)} {self.week_name[int(time.strftime('%w', date))]}")
                        break
                    except:
                        print("输入错误,请重新输入\n")
                if choice == 1:
                    reserve = self.inquire(room[cRoom-1], date)
                    if reserve:
                        self.response = self.book(reserve)
                        self.response = self.main_se.get(self.success_page, params={"id": json.loads(self.ws_response)['object']['orderid']})
                        self.table = self.table_patten.findall(self.response.text)[0]
                        print(f"\n预定成功:\n座位号: {self.table[1]:0>2}排{self.table[2]}座\n")

                elif choice == 2:
                    for i, j in enumerate(self.TIME_TABLE):
                        print(f"{i+1}. {j}")
                    s_time = input("时间:")
                    self.book_time(room[cRoom-1], date,
                                   self.TIME_TABLE[int(s_time)-1])
                elif choice == 3:
                    reserve = self.inquire(room[cRoom-1], date)

                    while True:
                        place = input("位置(aab):").strip()
                        if len(place) == 3 and 0 < int(place[-1]) < 9:
                            break
                        else:
                            print("输入有误,请重新输入")

                    self.book_table(
                            room[cRoom-1], date, reserve, place)
                else:
                    return

            elif choice == 2:
                n = input("请先查询订单,再输入需要取消的订单序号(0 2-3),输入-1返回: ")
                if (n == "-1"):
                    continue
                cancel_list = self.parse_num(n)
                self.cancel(cancel_list)

            elif choice == 3:
                n = input("查询条数(默认3条):")
                if n == "":
                    r = self.booked()
                else:
                    r = self.booked(int(n))
                print("已预定:\n")
                for index, i in enumerate(r):
                    print(
                        f"=={index}==\n时间: {i['stockDate']} \n地点: {i['servicenames']} \n时间: {i['remark1']} \n座位: {i['remark']}\n\n")
            elif choice == 4:
                return
            elif choice == 5:
                login_info = {
                    "ID":user,
                    "passwd":passwd
                }
                if os.path.exists("login.info"):
                    os.remove("login.info")
                    print("关闭自动登陆")
                else:
                    with open("login.info", "w") as f:
                        f.write(json.dumps(login_info))
                    print("开启自动登陆")
            elif choice == 6:
                self.ical_gen()
            else:
                print("输入错误")
                continue


if __name__ == "__main__":
    y = BookYourDream()
    y.main()
    # print(y.booked(rows=3, get_expired=False))
