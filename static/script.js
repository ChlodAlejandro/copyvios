function copyvio_toggle_details() {
    link = document.getElementById("cv-chain-link");
    table = document.getElementById("cv-chain-table");

    if (link.innerHTML == "Hide comparison:") {
        table.style.display = "none";
        link.innerHTML = "Show comparison:";
        set_cookie("CopyviosHideComparison", "True", 1095);
    } else {
        table.style.display = "table";
        link.innerHTML = "Hide comparison:";
        if (get_cookie("CopyviosHideComparison"))
            delete_cookie("CopyviosHideComparison");
    }
}

function update_screen_size() {
    var cache = cache_cookie();
    var data = {
        "width": window.screen.availWidth,
        "height": window.screen.availHeight
    }
    if (!cache || cache["width"] != data["width"] || cache["height"] != data["height"]) {
        set_cookie("CopyviosScreenCache", JSON.stringify(data), 1095);
    }
}

function cache_cookie() {
    var cookie = get_cookie("CopyviosScreenCache");
    if (cookie) {
        try {
            data = JSON.parse(cookie);
            var width = data.width;
            var height = data.height;
            if (width && height) {
                return {"width": width, "height": height};
            }
        }
        catch (SyntaxError) {}
    }
    return false;
}

// Cookie code partially based on http://www.quirksmode.org/js/cookies.html

function get_cookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(";");
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == " ") {
            c = c.substring(1, c.length);
        }
        if (c.indexOf(nameEQ) == 0) {
            var value = window.atob(c.substring(nameEQ.length, c.length));
            if (value.indexOf("--cpv2") == 0) {
                return value.substring("--cpv2".length, value.length);
            }
        }
    }
    return null;
}

function set_cookie_with_date(name, value, date) {
    value = window.btoa("--cpv2" + value);
    var path = window.location.pathname.split("/", 2)[1];
    if (date) {
        var expires = "; expires=" + date.toUTCString();
    }
    else {
        var expires = "";
    }
    document.cookie = name + "=" + value + expires + "; path=/" + path;
}

function set_cookie(name, value, days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        set_cookie_with_date(name, value, date);
    }
    else {
        set_cookie_with_date(name, value);
    }
}

function delete_cookie(name) {
    set_cookie(name, "", -1);
}

$(document).ready(function() {
    $("#action-search").change(function() {
        $("#cv-cb-engine").prop("disabled", false);
        $("#cv-cb-links").prop("disabled", false);
        $("#url-box").prop("disabled", true);
    });
    $("#action-compare").change(function() {
        $("#cv-cb-engine").prop("disabled", true);
        $("#cv-cb-links").prop("disabled", true);
        $("#url-box").prop("disabled", false);
    });
    if ($("#action-search" ).is(":checked")) $("#action-search" ).change();
    if ($("#action-compare").is(":checked")) $("#action-compare").change();
});
