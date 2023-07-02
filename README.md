# CQNU Helper

This repository consist of a series of tools that help you enjoy CQNU life better.

## LoginIntoCqnu.py

You can use this script to login to your campus network or use it to automatic jobs.

features:

- Ignore login type
- Add as automated tasks

You can add some python code and made it to connect network when your computer start up.

## LoginIntoCqnu.sh

You can use this script to login to your campus network or use it to automatic jobs.

features:

- Ignore login type
- Add as automated tasks

You can login without python in tiny linux system but you still need `curl` and `sed` in your system.

## Ms_book.py

> extend form 07's script

⚠️ Only work with Python < 3.11

This script can help you book the dream rooms located at library without limitation such as banned by the official system.

This script include these features:

- book a table after three days later
- overlook system ban
- add to you automatic system
- reserve discontinuous time periods
- generate .ics and send to your phone
- auto login in

bugs:

- Canceled orders won't show on website but it actually canceled from backend.

## estimate.js

Help you to fill all the annoying option boxes when evaluate the courses.

Usage:

1. Open Teaching evaluate website on academic affairs system.
2. Expand the courses list to show all courses you have this term
3. Open webconsole through F12
4. Paste following code

Option One:

```js
$('head').append('<script src="https://static.mackenia.co/estimate.js"></script>'); 
estimate();
```

Option Two:

1. Copy all code in `estimate.js`
2. Paste it in console
3. run `estimate()`
