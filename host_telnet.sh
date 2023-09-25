#!/bin/bash
# ---------------------------------
# Time: 2023/09/15
# AuthorName: lianyuxue
# Function: 健康检测telnet主机
# ---------------------------------

export LANG=zh_CN.UTF-8

# 脚本变量
LOGPATH=./
LOGFILE=${LOGPATH}/SKDATA_TelnetHostStatus.log
# 状态 0成功 1失败
STATUS=0
# 判断重复调用
fname=$(basename "$0")
cnt=$(pgrep -fu "$USER" "$fname" | wc -l)
if [[ "$cnt" -gt "2" ]]; then
    echo "$fname Running exit 1"
    exit 1
fi

# 判断日志文件路径
if [[ -d "$LOGPATH" ]]; then
    mkdir -p "$LOGPATH"
fi

hosts=$(cat ./hosts || exit)
for i in $hosts; do
    # 省份|IP地址|端口|timeout超时|启用状态
    IFS="|" read -r -a array <<<"$i"
    if [[ "${#array[@]}" == 5 && "${array[4]}" == 1 ]]; then
        if [[ "${array[3]}" -gt 60 ]]; then
            array[3]=60
        fi
        # timout_second:超时时间，秒
        # host: 域名
        # port: 端口
        timout_second="${array[3]}"
        host="${array[1]}"
        port="${array[2]}"

        if ! echo -e '\x1dclose\x0d' | timeout --signal=2 "$timout_second" telnet "$host" "$port" >/dev/null 2>&1; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") 失败 ${array[*]}" >>"$LOGFILE"
            STATUS=1
            continue
        fi
        echo "$(date "+%Y-%m-%d %H:%M:%S") 成功 ${array[*]}"
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") 跳过 ${array[*]}" >>"$LOGFILE"
    fi
done
echo $STATUS
