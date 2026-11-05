#!/usr/bin/env bash
# Công cụ điều khiển máy ảo: source file này rồi dùng các hàm.
export MSYS_NO_PATHCONV=1
A="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
S="C:/Users/Lenovo/AppData/Local/Temp/claude/5ea0f9c3a2726979/faba158c-8e80-4e70-9dcd-aaf3bce6c727/scratchpad"
PKG=vn.edu.fpt.book_marketplace

dump() { "$A" shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; "$A" shell cat /sdcard/u.xml | sed 's/>/>\n/g'; }
# in danh sách phần tử có chữ (content-desc/text/hint) + toạ độ
ls_ui() { dump | grep -E 'content-desc="[^"]+"|text="[^"]+"' | sed -E 's/.*(content-desc|text)="([^"]*)".*bounds="(\[[0-9,]+\]\[[0-9,]+\])".*/\2 \3/' | sed 's/&#10;/ \/ /g' | cut -c1-${1:-110}; }
# bấm phần tử đầu tiên có chứa chuỗi
tap() { local pat="$1"; local b; b=$(dump | grep -E "(content-desc|text)=\"[^\"]*$pat[^\"]*\"" | head -1 | grep -oE 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"'); [ -z "$b" ] && { echo "NOT FOUND: $pat"; return 1; }; local xy; xy=$(echo "$b" | sed -E 's/.*\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\].*/\1 \2 \3 \4/' | awk '{print int(($1+$3)/2), int(($2+$4)/2)}'); "$A" shell input tap $xy; echo "tapped $pat @ $xy"; }
tapxy() { "$A" shell input tap "$1" "$2"; }
txt() { "$A" shell input text "$1"; }
back() { "$A" shell input keyevent 4; }
wait_s() { "$A" shell "sleep $1"; }
shot() { "$A" exec-out screencap -p > "$S/$1.png"; echo "$S/$1.png"; }
swipe_up() { "$A" shell input swipe 540 1700 540 700 300; }
swipe_down() { "$A" shell input swipe 540 700 540 1700 300; }
# nhập vào ô edit thứ n (1-based) theo thứ tự trên màn hình
edit() { local n="$1" val="$2"; local b; b=$(dump | grep 'android.widget.EditText' | sed -n "${n}p" | grep -oE 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"'); local xy; xy=$(echo "$b" | sed -E 's/.*\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\].*/\1 \2 \3 \4/' | awk '{print int(($1+$3)/2), int(($2+$4)/2)}'); "$A" shell input tap $xy; "$A" shell input keyevent KEYCODE_MOVE_END; for i in $(seq 1 40); do "$A" shell input keyevent KEYCODE_DEL; done; "$A" shell input text "$val"; }
restart() { "$A" shell am force-stop $PKG; "$A" shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; wait_s 7; }
clear_app() { "$A" shell pm clear $PKG >/dev/null; }
login_as() { clear_app; "$A" shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; wait_s 8; tap "Bỏ qua" >/dev/null; wait_s 3; tapxy 540 1320; wait_s 3; edit 1 "$1"; edit 2 "${2:-Rebook@123}"; back; wait_s 1; tapxy 540 1683; wait_s 6; }
# ẩn bàn phím nếu đang hiện (tránh bấm Back hai lần làm thoát màn)
hide_kb() { if "$A" shell dumpsys input_method | grep -q "mInputShown=true"; then "$A" shell input keyevent 4; wait_s 1; fi; }
