import re
import requests
import json

class uBills:

    def __init__(self) -> None:
        self.tsm = "http://202.202.209.1:8030/web/Common/Tsm.html"

        self.cheat_sheet_pro = {
            "嘉风": {
                "head": "01",
                "building_id": "39",
                "aid": "0030000000002503",
                "area": "大学城校区",
                "building": "01嘉风苑"
            },
            "朗风": {
                "head": "02",
                "building_id": "26",
                "aid": "0030000000002503",
                "area": "大学城校区",
                "building": "02朗风苑"
            },
             "留学生": {
                "head": "03",
                "building_id": "1",
                "aid": "0030000000002503",
                "area": "大学城校区",
                "building": "03留学生"
            },
            "培训楼": {
                "head": "04",
                "building_id": "65",
                "aid": "0030000000002503",
                "area": "大学城校区",
                "building": "04培训楼"
            },
            "畅风": {
                "head": "05",
                "building_id": "52",
                "aid": "0030000000002503",
                "area": "大学城校区",
                "building": "05畅风苑"
            },
            "硕博楼": {
                "head": "",
                "building_id": "16",
                "aid": "0030000000006701",
                "area": "",
                "building": "硕博楼"
            },
            "和风B": {
                "head": "",
                "building_id": "12",
                "aid": "0030000000006701",
                "area": "",
                "building": "和风苑B"
            },
            "和风C": {
                "head": "",
                "building_id": "13",
                "aid": "0030000000006701",
                "area": "",
                "building": "和风苑C"
            },
            "和风D": {
                "head": "",
                "building_id": "14",
                "aid": "0030000000006701",
                "area": "",
                "building": "和风苑D"
            },
            "和风E": {
                "head": "",
                "building_id": "15",
                "aid": "0030000000006701",
                "area": "",
                "building": "和风苑E"
            },
            "惠风A": {
                "head": "",
                "building_id": "5",
                "aid": "0030000000006701",
                "area": "",
                "building": "惠风苑A"
            },
            "惠风B": {
                "head": "",
                "building_id": "6",
                "aid": "0030000000006701",
                "area": "",
                "building": "惠风苑B"
            },
            "惠风C": {
                "head": "",
                "building_id": "8",
                "aid": "0030000000006701",
                "area": "",
                "building": "惠风苑C"
            },
            "雅风A": {
                "head": "",
                "building_id": "9",
                "aid": "0030000000006701",
                "area": "",
                "building": "雅风苑A"
            },
            "雅风B": {
                "head": "",
                "building_id": "10",
                "aid": "0030000000006701",
                "area": "",
                "building": "雅风苑B"
            },
            "雅风C": {
                "head": "",
                "building_id": "11",
                "aid": "0030000000006701",
                "area": "",
                "building": "雅风苑C"
            },
            "清风A": {
                "head": "00100",
                "building_id": "001",
                "aid": "0030000000007801",
                "area": "",
                "building": "清风苑A栋"
            },
            "清风B": {
                "head": "00200",
                "building_id": "002",
                "aid": "0030000000007801",
                "area": "",
                "building": "清风苑B栋"
            },
            "清风C": {
                "head": "00300",
                "building_id": "003",
                "aid": "0030000000007801",
                "area": "",
                "building": "清风苑C栋"
            },
            "嘉风B": {
                "head": "00400",
                "building_id": "004",
                "aid": "0030000000007801",
                "area": "",
                "building": "嘉风苑二期"
            }
        }

    def ac(self, building: str, room: str) -> (str, float, float, float):
        floor_id = ""
        floor = ""

        if self.cheat_sheet_pro[building]['head']:
            floor_id = self.cheat_sheet_pro[building]['head'] + room[:2]
            floor = room[1] + "层"
        
        data = {
            "query_elec_roominfo": {
                "aid": self.cheat_sheet_pro[building]['aid'],
                "account": "000001",
                "room": {
                    "roomid": self.cheat_sheet_pro[building]['head'] + room,
                    "room": room
                },
                "floor": {
                    "floorid": floor_id,
                    "floor": floor
                },
                "area": {
                    "area": self.cheat_sheet_pro[building]['area'],
                    "areaname": self.cheat_sheet_pro[building]['area']
                },
                "building": {
                    "buildingid": self.cheat_sheet_pro[building]['building_id'],
                    "building": self.cheat_sheet_pro[building]['building']
                }
            }
        }

        p1 = re.compile("\d+.房间剩余量(-?\d+.\d+)房间名称\(.*\)")
        p2 = re.compile("账号id:i\d+-剩余金额:(-?\d+\.\d+)-剩余电补:(-?\d+\.\d+)-剩余水补:(-?\d+\.\d+)")
        p3 = re.compile("账号余额:(-?\d+\.\d+)")

        if self.cheat_sheet_pro[building]["aid"] == "0030000000002503":
            data["query_elec_roominfo"]["room"]["roomid"] = self.cheat_sheet_pro[building]['head'] + room + "S"
            data["query_elec_roominfo"]["room"]["room"] = room + "S"
            res_S = requests.post(self.tsm, data={"jsondata": json.dumps(data), "funname": "synjones.onecard.query.elec.roominfo"})

            data["query_elec_roominfo"]["room"]["roomid"] = self.cheat_sheet_pro[building]['head'] + room + "D"
            data["query_elec_roominfo"]["room"]["room"] = room + "D"
            res_D = requests.post(self.tsm, data={"jsondata": json.dumps(data), "funname": "synjones.onecard.query.elec.roominfo"})
            p1_res_S = p1.findall(res_S.text)[0]
            p1_res_D = p1.findall(res_D.text)[0]
            print(p1_res_S, p1_res_D)
            return f"电费剩余: {p1_res_D}, 水费剩余: {p1_res_S}", float(p1_res_D) + float(p1_res_S), float(p1_res_D), float(p1_res_S)

        res = requests.post(self.tsm, data={"jsondata": json.dumps(data), "funname": "synjones.onecard.query.elec.roominfo"})
        try:
            p2_res = p2.findall(res.text)[0]
            return f"水电剩余: {p2_res[0]}, 电补剩余: {p2_res[1]}, 水补剩余: {p2_res[2]}", float(p2_res[0]), float(p2_res[1]), float(p2_res[2])
        except:
            p3_res = p3.findall(res.text)
            return f"水电费剩余: {p3_res[0]}", float(p3_res[0]), float(p3_res[0]), float(p3_res[0])
        

if __name__ == "__main__":
    ub = uBills()
    print(ub.ac("朗风", "1001"))
    print(ub.ac("和风B", "4070"))
    print(ub.ac("嘉风B", "3014"))
