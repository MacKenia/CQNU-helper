from enum import Enum

class VenueValue(object):
    def __init__(self, name, id):
      self.name = name
      self.id = id
    def __repr__(self):
       return f"VenueValue(name='{self.name}', id='{self.id}')"
    def __eq__(self, other):
      if isinstance(other, VenueValue):
        return self.name == other.name and self.id == other.id
      return NotImplemented


class Venue(Enum):
    """
    场馆枚举类，包含不同场馆的名称和ID。
    """
    YMQ = VenueValue("羽毛球馆", "301")
    """羽毛球馆，ID: 301"""
    
    PPQ = VenueValue("乒乓球馆", "322")
    """乒乓球馆，ID: 322"""
    
    WQS = VenueValue("室外网球场", "302")
    """室外网球场，ID: 302"""
    
    WQF = VenueValue("风雨球场网球场", "321")
    """风雨球场网球场，ID: 321"""
    
    @classmethod
    def get_all_venues(cls):
        """
        返回所有场馆的列表。
        """
        return [venue for venue in cls]

class TTime(Enum):
    """
    时间段枚举类，包含不同时间段的描述。
    """
    T1 = "08:30-09:30"
    """08:30-09:30"""
    T2 = "09:31-10:30"
    """09:31-10:30"""
    T3 = "10:31-11:30"
    """10:31-11:30"""
    T4 = "11:31-12:30"
    """11:31-12:30"""
    T5 = "12:31-13:30"
    """12:31-13:30"""
    T6 = "13:31-14:30"
    """13:31-14:30"""
    T7 = "14:31-15:30"
    """14:31-15:30"""
    T8 = "15:31-16:30"
    """15:31-16:30"""
    T9 = "16:31-17:30"
    """16:31-17:30"""
    T10 = "17:31-18:30"
    """17:31-18:30"""
    T11 = "18:31-19:30"
    """18:31-19:30"""
    T12 = "19:31-20:30"
    """19:31-20:30"""
    T13 = "20:31-21:30"
    """20:31-21:30"""

    @classmethod
    def get_all_times(cls):
        """
        返回所有时间段的列表。
        """
        return [time for time in cls]

class Court(Enum):
    """
    场地枚举类，包含不同场地的名称。
    """
    F1 = "场地1"
    """场地1"""
    F2 = "场地2"
    """场地2"""
    F3 = "场地3"
    """场地3"""
    F4 = "场地4"
    """场地4"""
    F5 = "场地5"
    """场地5"""
    F6 = "场地6"
    """场地6"""
    F7 = "场地7"
    """场地7"""
    F8 = "场地8"
    """场地8"""

    @classmethod
    def get_all_courts(cls):
        """
        返回所有场地的列表。
        """
        return [court for court in cls]

if __name__ == "__main__":
    # 访问名称和ID
    print(Venue.YMQ)  # 输出: Venue.YMQ
    print(Venue.YMQ.value) # 输出: VenueValue(name='羽毛球馆', id='301')
    print(Venue.YMQ.value.name)    # 输出: 羽毛球馆
    print(Venue.YMQ.value.id)       # 输出: 301


    print(Venue.PPQ.value.name)    # 输出: 乒乓球馆
    print(Venue.PPQ.value.id)       # 输出: 322

    # 遍历枚举
    print("\nVenues:")
    for venue in Venue:
        print(venue, venue.value.name, venue.value.id)

    # 枚举值的比较
    print(Venue.YMQ.value == VenueValue("羽毛球馆","301")) #输出 True
    print(Venue.PPQ.value == VenueValue("羽毛球馆", "301")) #输出 False

    print(Venue.get_all_venues()[0])