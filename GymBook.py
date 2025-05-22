import random
import time, json, requests, logging, threading, argparse

from LoginSession import LoginSession
from time import struct_time
from StaticVars import TTime, Venue, Court

# 配置日志记录，指定编码为utf-8
logging.basicConfig(
    filename='error.log', 
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s',
    encoding='utf-8'
)

def push_log(message: str, sub: str=None) -> None:
    requests.post("https://ntfy.sh/36d1053c-c2da-42d8-bcfd-871d2a4c645c-027", data=message)
    if message.find("成功") > 0:
        requests.post(f"https://ntfy.sh/36d1053c-c2da-42d8-bcfd-871d2a4c645c-{sub}", data=message)


class GymBook:
    def __init__(self):
        self.index_url = "https://gym.cqnu.edu.cn/app/index.html"
        self.findOkArea = "https://gym.cqnu.edu.cn/app/product/findOkArea.html"
        self.toBook = "https://gym.cqnu.edu.cn/app/order/tobook.html"

        self.ls = LoginSession(self.index_url)

    def login(self, user: str, passwd: str) -> bool:
        self.user = user
        logging.info(f"[GymBook][{self.user}] 尝试登录")
        self.ls.set_account(user, passwd)
        if self.ls.login():
            logging.info(f"[GymBook][{self.user}] 登录成功")

    def available_courts(self, date:struct_time, venue_id:str) -> dict|None:
        self.ls.check_login()
        try:
            response = self.ls.main_se.get(self.findOkArea, params={"s_date": time.strftime("%Y-%m-%d", date), "serviceid": venue_id})
            response.raise_for_status()  # 检查请求是否成功
            return response.json()
        except requests.exceptions.RequestException as e:
            logging.error(f"[GymBook][{self.user}] 请求失败: {e}")
            return None
        except json.JSONDecodeError as e:
            logging.error(f"[GymBook][{self.user}] JSON解析失败: {e}")
            return None
        
    def find_court(self, date: struct_time, venue: Venue, times: TTime, court: Court) -> dict|None:
        self.ls.check_login()
        try:
            available_court_list = self.available_courts(date, venue.value.id)
            if available_court_list and "object" in available_court_list:
                for court_info in available_court_list["object"]:
                    if (court_info["stock"]["time_no"] == times.value and
                        court_info["stock"]["s_date"] == time.strftime("%Y-%m-%d", date) and
                        court_info["sname"] == court.value):
                        return {"time_no": court_info['stock']['time_no'], "s_date": court_info['stock']['s_date'], "stock_id": court_info["stockid"], "id": court_info["id"], "service_id": venue.value.id, "sname": court_info['sname']}
                        # return {"stock_id": court_info["stockid"], "id": court_info["id"], "service_id": venue.value.id, "sname": court_info['sname']}
            return None
        except Exception as e:
            logging.error(f"[GymBook][{self.user}] 查找场地时出错: {e}")
            return None
    
    def find_courts(self, date: struct_time, venue: Venue, times: TTime=None, court: Court = None) -> list|None:
        self.ls.check_login()
        try:
            available_court_list = self.available_courts(date, venue.value.id)
            if available_court_list and "object" in available_court_list and available_court_list["object"]:
                result = []
                for court_info in available_court_list["object"]:
                    if (times is None or court_info["stock"]["time_no"] == times.value) and \
                       (court is None or court_info["sname"] == court.value) and \
                       court_info["stock"]["s_date"] == time.strftime("%Y-%m-%d", date):
                        result.append({"time_no": court_info['stock']['time_no'], "s_date": court_info['stock']['s_date'], "stock_id": court_info["stockid"], "id": court_info["id"], "service_id": venue.value.id, "sname": court_info['sname']})
                return result if result else []
            return []
        except Exception as e:
            logging.error(f"[GymBook][{self.user}] 查找场地时出错: {e}")
            return []
        
    def to_book(self, stock_id:str, id:str, service_id: str) -> dict|None:
        self.ls.check_login()
        data = {
            "param": json.dumps({
                "stockdetail": {
                    f"{stock_id}": str(id)
                },
                "service_id": str(service_id),
                "stock_id": str(stock_id),
                "remark": ""
            }),
            "num": "1",
            "json": "true"
        }
        logging.info(f"[GymBook][{self.user}] 预订请求数据: {data}")
        try:
            response = self.ls.main_se.post(self.toBook, data=data)
            response.raise_for_status()  # 检查请求是否成功
            return response.json()["message"]
        except requests.exceptions.RequestException as e:
            logging.error(f"[GymBook][{self.user}] 请求失败: {e}")
            return None
        except json.JSONDecodeError as e:
            logging.error(f"[GymBook][{self.user}] JSON解析失败: {e}")
            return None

def book_with_notify(GymBook: GymBook, acc, court, venue):
    message = ""
    while True:
        message = GymBook.to_book(court["stock_id"], court["id"], court["service_id"])
        if message is None:
            message = "网络错误"
        logging.info(f"[GymBook][{acc}] 预订{court['s_date']} {court['time_no']} {venue.value.name} {court['sname']}服务器返回: {message}")
        if message.find("预订成功") != -1 or message.find("预订失败") != -1 or message.find("数据有误") != -1:
            break
        time.sleep(random.randrange(100, 300) * 0.001)

    push_log(f"[GymBook][{acc}] 预订{court['s_date']} {court['time_no']} {venue.value.name} {court['sname']}服务器返回: {message}", sub=acc)
    logging.info(f"[GymBook][{acc}] 预订{court['s_date']} {court['time_no']} {venue.value.name} {court['sname']}服务器返回: {message}")
    

def book_a_court(**kwargs):
    # 传入的参数为:acc, pwd, venue, court

    user = kwargs.get('user', None)
    passwd = kwargs.get('passwd', None)
    
    venue = kwargs.get('venue', Venue.YMQ)  # default to YMQ if not specified
    if venue is None:
        venue = Venue.YMQ
    court = kwargs.get('court', None)
    
    gb = GymBook()
    if user is None or passwd is None:
        with open("login.info","r") as f:
            login_info = json.load(f)
            user = login_info["ID"]
            passwd = login_info["passwd"]
            gb.login(user, passwd)
    else:
        gb.login(user, passwd)
    
    days_later = time.localtime(time.time() + 2 * 24 * 60 * 60)
    book_date = time.localtime(time.mktime(days_later) - 24 * 60 * 60)

    print("启动...")

    if True:
        current_time = time.localtime()
        logging.info(f"[GymBook][{user}] 等待直到{time.strftime('%Y-%m-%d', book_date)}...")
        while current_time.tm_mday != book_date.tm_mday or current_time.tm_hour != 7:
            time.sleep(60*60)
            current_time = time.localtime()

        logging.info(f"[GymBook][{user}] 等待直到早上八点...")
        current_time = time.localtime()
        while current_time.tm_hour != 7 or current_time.tm_min < 59:
            time.sleep(60)
            current_time = time.localtime()

    logging.info(f"[GymBook][{user}] 查询场地中...")
    
    selected_courts = []
    logging.info(f"[GymBook][{user}] {venue.value.name}空闲的场地信息:")
    time_list = [i.value for i in TTime.get_all_times()[6:]]
    avilable_courts = gb.find_courts(days_later, venue, court=court)

    while len(avilable_courts) == 0:
        logging.info(f"[GymBook][{user}] 没有找到空闲的场地，等待中...")
        time.sleep(60)
        avilable_courts = gb.find_courts(days_later, venue, court=court)
        
    for ci in avilable_courts:
        if ci['time_no'] in time_list:
            selected_courts.append(ci)
            logging.info(f"[GymBook][{user}] 选中的场地为: {ci['s_date']} {ci['time_no']} {venue.value.name} {ci['sname']} 场地id: {ci['id']}")
            push_log(f"[GymBook][{user}] 选中的场地为: {ci['s_date']} {ci['time_no']} {venue.value.name} {ci['sname']} 场地id: {ci['id']}", sub=user)
            time_list.remove(ci['time_no'])
            
    if len(avilable_courts) > 0:
        avilable_courts = gb.find_courts(days_later, venue)
        for ci in avilable_courts:
            if ci['time_no'] in time_list:
                selected_courts.append(ci)
                logging.info(f"[GymBook][{user}] 选中的代场地为: {ci['s_date']} {ci['time_no']} {venue.value.name} {ci['sname']} 场地id: {ci['id']}")
                push_log(f"[GymBook][{user}] 选中的代场地为: {ci['s_date']} {ci['time_no']} {venue.value.name} {ci['sname']} 场地id: {ci['id']}", sub=user)
                time_list.remove(ci['time_no'])
            
    logging.info(f"[GymBook][{user}] 选中的场地数量: {len(selected_courts)}")
    logging.info(f"[GymBook][{user}] 重新登录，准备预定！...")
    gb.ls.check_login()

    current_time = time.localtime()
    while current_time.tm_sec < 59:
        time.sleep(1)
        current_time = time.localtime()
    logging.info(f"[GymBook][{user}] 到点行动！...")
        
    threads = []
    for court in selected_courts:
        # thread = threading.Thread(target=gb.to_book, args=(court["stock_id"], court["id"], court["service_id"]))
        thread = threading.Thread(target=book_with_notify, args=(gb, user, court, venue))
        threads.append(thread)
        thread.start()
        logging.info(f"[GymBook][{user}] 已发送预定{court['id']}的请求")

    for thread in threads:
        thread.join()

def test_find():
    gb = GymBook()
    two_days_later = time.localtime(time.time() + 2 * 24 * 60 * 60)
    venue = Venue.YMQ

    days_later = two_days_later
    for court in Court.get_all_courts():
        for ttime in TTime.get_all_times()[6:10]:
            ci = gb.find_court(days_later, venue, ttime, court)
            if ci:
                logging.info(f"[GymBook] {time.strftime('%Y-%m-%d', days_later)} {ttime.value} {venue.value.name} {court.value} 场地id: {ci['stock_id']}")

def test():
    gb = GymBook()

    two_days_later = time.localtime(time.time() + 2 * 24 * 60 * 60)
    one_day_later = time.localtime(time.time() + 1 * 24 * 60 * 60)

    days_later = two_days_later
    for court in Court.get_all_courts():
        for ttime in TTime.get_all_times()[6:10]:
            ci = gb.find_court(days_later, venue, ttime, court)
            if ci:
                logging.info(f"[GymBook] {time.strftime('%Y-%m-%d', days_later)} {ttime.value} {venue.value.name} {court.value} 场地id: {ci['stock_id']}")
    date = two_days_later
    print(f"预定的日期: {time.strftime('%Y-%m-%d', date)}")
    venue = Venue.YMQ
    ttime = TTime.T8
    court = Court.F1
    c1 = gb.find_courts(date, venue, ttime, court)
    print(f"场馆为：{venue.value}，时间为：{time.strftime('%Y-%m-%d', date)} {ttime.value}，场地为：{court.value}")

    for i in range(2):
        for i in ci:
            thread = threading.Thread(target=gb.to_book, args=(i["stock_id"], i["id"], i["service_id"]))
            thread.start()

        # for thread in threads:
        #     thread.join()
        logging.info(f"[GymBook] 已发送第{i+1}次请求")
        time.sleep(1)
    if c1:
        print(c1)
        pass
        # print(gb.to_book(c1["stock_id"], c1["id"], c1["service_id"]))
    else:
        print("没有找到场地")

if __name__ == "__main__":
    # Define the venue and court dictionaries
    venue_dict = {
        '1': Venue.YMQ,
        '2': Venue.PPQ,
        '3': Venue.WQS,
        '4': Venue.WQF
    }
    
    court_dict = {
        '1': Court.F1,
        '2': Court.F2,
        '3': Court.F3,
        '4': Court.F4,
        '5': Court.F5,
        '6': Court.F6,
        '7': Court.F7,
        '8': Court.F8
    }
    
    # Define the argument parser
    parser = argparse.ArgumentParser()
    parser.add_argument("-u", "--user", help="account to login", type=str)
    parser.add_argument("-p", "--passwd", help="password to login", type=str)
    parser.add_argument("-v", "--venue", help="venue to book", type=str, choices=list(venue_dict.keys()))
    parser.add_argument("-c", "--court", help="court to book", type=str, choices=list(court_dict.keys()))
    
    # Parse the arguments
    args = parser.parse_args()
    
    # Get the venue and court objects from the dictionaries
    if args.venue is None:
        venue = None
    else:
        venue = venue_dict[args.venue]
        
    if args.court is None:
        court = None
    else:
        court = court_dict[args.court]

    while True:
        res = book_a_court(
            user=args.user,
            passwd=args.passwd,
            venue=venue,
            court=court
        )
        # break
    # while True:
    #     book_a_court()
