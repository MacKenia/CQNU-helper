# CQNU Helper

This repository consists of a series of tools that help you enjoy CQNU life better.

## LoginIntoCqnu.py

You can use this script to log in to your campus network or use it for automatic jobs.

features:

- Ignore login type
- Add as automated tasks

You can add some Python code and make it to connect the network when your computer starts up.

[Binary In Rust by @mobeicanyue](https://github.com/mobeicanyue/Campus-Network-Master-Rust)

## LoginIntoCqnu.sh

You can use this script to log in to your campus network or use it for automatic jobs.

features:

- Ignore login type
- Add as automated tasks

You can log in without Python in a tiny Linux system but you still need `curl` and `sed` in your system.

## Ms_book.py

> extend form 07's script

⚠️ Only work with Python < 3.11

This script can help you book a dream hall seat located at the library without limitations such as being banned by the official system.
This script includes these features:

- Book a table after three days later
- overlook system ban
- add to your automatic system
- Reserve discontinuous time periods
- generate .ics and send it to your phone
- auto login in

bugs:

- Canceled orders won't show on the website but it actually canceled from the backend.

## uBills.py

This script is used to acquire utility bills for your dormitory.

Usage:

```python
from uBills import uBills

ub = uBills()
ub.ac("清风A", "2017")
```

## estimate.js

Help you to fill all the annoying option boxes when evaluating the courses.

Usage:

1. Open Teaching evaluate website on the academic affairs system.
2. Expand the courses list to show all courses you have this term
3. Open console through F12
4. Paste the following code

Option One:

```js
$('head').append('<script src="https://static.cqnu.asia/estimate.js"></script>'); 
estimate();
```

Option Two:

1. Copy all code in `estimate.js`
2. Paste it into the console
3. run `estimate()`

## thanks

Special thanks to Microsoft for providing [visual studio code](https://code.visualstudio.com/) and open-source projects to support.

[![My Skills](https://skillicons.dev/icons?i=vscode,neovim,bash,python,javascript)](https://code.visualstudio.com/)

## license

This project uses the Apache license 3.0 agreement, which is only for learning and communication. Please delete it within 24 hours after downloading. use should follow local laws and regulations, and do not use for illegal purposes.

```txt
                      gnu general public license
                       version 3, 29 june 2007

 copyright (c) 2007 free software foundation, inc. <https://fsf.org/>
 everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.
```
