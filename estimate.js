function doBc() {
    //组织参数对象
    var dataMap = buildRequestMap.call(this) || {};
    dataMap["tjzt"] = "0";
    jQuery.ajax({
        url: _path + "/xspjgl/xspj_bcXspj.html",
        type: "post",
        dataType: "json",
        data: dataMap,
        async: false,
        beforeSend: function () {
            console.log("填写完成")
        },
        success: function (responseText) {
            console.log("bcks");
            if ($.type(responseText) == "string") {
                if (responseText.indexOf("成功") > -1) {
                    console.log("bccg");
                    $.success(responseText, function () {
                        // 刷新评价情况
                        // refTab();
                    });
                } else if (responseText.indexOf("失败") > -1) {
                    $.error(responseText, function () {
                    });
                } else {
                    $.alert(responseText, function () {
                    });
                }
            }
        },
        error: function () {
            console.log("保存成功");
        }
    });
}

function check() {
    var radios = document.querySelectorAll("input.radio-pjf");
    radios.forEach((radio) => {
        if (radio.attributes["data-dyf"].value == 94) radio.checked = true;
    });
    radios[1].checked = true;
}

function comment() {
    document.querySelector("textarea").value =
        "老师在这一学期已经付出了很多时间和热情，此次课程对他来说可能充满了许多困难，但是他始终能够保持良好的教学状态，不断为学生讲解、感染、鼓励、并探究新的教学理念, 并将这些要求传递给学生。在这一学期中，老师不仅教会了我们重要的课程内容，也让我们明白了一门课程背后所代表的核心思想。在此，我站出来向老师衷心的感谢和真心的敬佩。";
}

var counter = 0;

function estimate() {
    var cls = document.querySelectorAll("tr.ui-widget-content");
    var i = 0;
    cls.forEach((cl) => {
        setTimeout(() => {
            console.log("正在评价第("+(++counter)+"/"+cls.length+")门课程")
            cl.click();
        }, i * 5000);
        setTimeout(() => {
            try {
                check();
                comment();
                console.log("评价完成")
            } catch {
                console.log("此课程已评价")
            }
        }, i * 5000 + 800)
        setTimeout(() => {
            try {
                doBc()
                console.log("保存成功")
            } catch {
                console.log("此课程已保存")
            }
        }, i * 5000 + 1000);
        setTimeout(() => {
            try {
                document.querySelector("#btn_ok").click();
                console.log("切换下一门")
            } catch {
                console.log("此课程已保存")
            }
        }, i++ * 5000 + 1200);
    });

    setTimeout(()=>{
        console.log("评价完成，请自行检查后提交！");
        console.log("评价完成，请自行检查后提交！");
        console.log("评价完成，请自行检查后提交！");
        refTab();
    }, cls.length * 5000)
}
