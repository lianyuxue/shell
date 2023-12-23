#!/bin/bash
# shellcheck disable=SC2034
# ---------------------------------
# Time: 2023/09/21
# AuthorName: lianyuxue
# Function: 正则匹配日志关键字输出
# ---------------------------------

# 多个目录下相同文件
# dir1,dir2
dirs=''

# 多个文件
# file1,file2
files=''

# 单个文件
# logback_luna_info-2023-09-05.0.log
file=''

# 正则匹配条件
# 根据申请单号
re_1='1.completeTask.*8102023090500000365'
# 根据流水单编号
re_2='postDataToVms.*810202303319013140224883'

# 注册匹配方法
re_array=(
    re_1
    re_2
)
re_help=''
re_content="${RE_CONTENT:-$re_1}"
for value in "${re_array[@]}"; do
    [[ "$re_content" = "$value" ]] && re_content="${!value}"
    re_help+="RE_CONTENT      $value     [${!value}]\n"
done

#线程坐标位置
thread_coordinate="${TC:-4}"

# 上下文数量
# A=0 # 下文行数
# B=0 # 上文行数
# C=0 # 上下文行数
context_row="${R:-10}" # 上下文显示数
context_type="${CONTEXT:-C}" # 上下文类型
context_array=(
    A
    B
    C
)
# DEBUG打印详情
debug_print="${DEBUG:-false}"

function echoDanger() {
    # 红底白字
    printf "\033[41;37m %s \033[0m\n" "$1"
}

function echoWarning() {
    # 黄底白字
    printf "\033[43;37m %s \033[0m\n" "$1"
}

function echoInfo() {
    # 青底黑字
    printf "\033[46;30m %s \033[0m\n" "$1"
}

function echoSuccess() {
    # 绿底白字
    printf "\033[42;37m %s \033[0m\n" "$1"
}

function echoPrimary() {
    # 蓝底白字
    printf "\033[44;37m %s \033[0m\n" "$1"
}

function run() {
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [文件组]        |-> ${files[*]}"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [目录组]        |-> ${dirs[*]}"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [文件名]        |-> $file"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [上下文类型]    |-> $context_type"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [上下文行数]    |-> $context_row"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [debug状态]     |-> $debug_print"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [检索关键字]    |-> $re_content"
    # 文件组参数解析
    IFS="," read -r -a array <<<"$files"
    files=("${array[@]}")

    # 文件夹组参数解析
    IFS="," read -r -a array <<<"$dirs"
    dirs=("${array[@]}")

    # 判断上下文类型是否合法
    if [[ ! "${context_array[*]}" =~ $context_type ]]; then
        echoDanger "上下文类型不合法，可选A B C exit 1" && exit 1
    fi
    # 判断文件及文件夹是否存在
    if [[ -n "$file" || -n "${files[*]}" || -n "${dirs[*]}" ]]; then
        false_not_status=false

        if [[ -n "$file" && ! -f "$file" ]];then
            false_not_status=true
        fi

        for f in "${files[@]}"; do
            if [ ! -f "$f" ];then
               false_not_status=true 
            fi
        done

        for d in "${dirs[@]}"; do
            if [ ! -d "$d" ];then
               false_not_status=true 
            fi
        done        

       $false_not_status && echoDanger "文件或目录不存在，请检查 exit 1" && exit 1
    fi

    if [[ -n "${dirs[*]}" && -n "$file" ]]; then
        # find查找
        find_result=$(find "${dirs[@]}" -type f -name "${file##*/}" -exec grep -"$context_type" "$context_row" -EiHn "$re_content" {} \;)
    elif [[ -n "${files[*]}" ]]; then
        # find查找
        find_result=$(find "${files[@]}" -type f -exec grep -"$context_type" "$context_row" -EiHn "$re_content" {} \;)
    else
        echoWarning "请选择其中一种方式dirs or files exit 1" && exit 1
    fi

    $debug_print && echoWarning "find_result:$find_result"

    if [[ -n "$find_result" ]]; then
        if [[ "$context_type" = "A" ]]; then
            context_row=0
        fi
        # 过滤中标数据
        # 下文时为1
        # line_result=$(echo "$find_result" | sed -n "1p")
        line_result=$(echo "$find_result" | sed -n "$((context_row + 1))p")

        $debug_print && echoWarning "line_result:$line_result"
        # 过滤中标数据线程号关键字
        thread=$(echo "$line_result" | awk '{print $'"$thread_coordinate"'}')
        # 过滤中标数据时间关键字
        mark=$(echo "$line_result" | awk '{print $1}')

        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [中标位置]      |-> $mark"
        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [中标线程]      |-> $thread"

        # 匹配相同线程号数据
        result=$(echo "$find_result" | awk '$"'"$thread_coordinate"'" == "'"$thread"'" {print}')
        $debug_print && echoWarning "result:$result"    
        result_count=$(echo "$result" | awk 'END{print NR}')
        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [数据总行]      |-> $result_count"

        # 标注匹配数据行号（完整数据）
        new_result="$(echo "$result" | awk '{print NR" "$0}')"
        # echo "$(echo "$new_result"|grep -C "")"
        $debug_print && echoWarning "new_result:$new_result"
        # 过滤中标数据所在行号
        line_number=$(echo "$new_result" | awk '$2 == "'"$mark"'" {print $1}')
        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [中标行号]      |-> $line_number"
        if [[ -n "$line_number" ]]; then
            d=$(echo "$new_result" | awk 'NR < '"$line_number"' {printf "\033[42;36m "$0" \033[0m \n" }') # 上文数据
            l=$(echo "$new_result" | awk 'NR == '"$line_number"' {print}')                                # 中标数据
            p=$(echo "$new_result" | awk 'NR > '"$line_number"' {printf "\033[42;37m "$0" \033[0m \n"}')  # 下文数据

            if [[ -n "$d" ]]; then
                printf "%b\n" "$d"
            fi

            echoDanger "$l"

            if [[ -n "$p" ]]; then
                printf "%b\n" "$p"
            fi
        fi
    else
        echoWarning "没有检索到数据"
        exit 1
    fi
}

function help() {
    echo "Usage argsa: $0 [-a file1,file2...]
                          [-d dir1,dir2... -f file]
                          [-s [re]查看可用正则 [demo]查看调用方式 [var]查看可用变量]
                          [-h]"
    echo "-a    指定一个或多个文件"
    echo "-d    指定一个或多个文件夹"
    echo "-f    指定一个文件"
    echo "-s    查看变量配置"
    echo "-h    帮助"
}

while getopts :a:d:f:s:h option
do
    case "$option" in
        h)
            help
            exit 1
            ;;
        a)
            files=("$OPTARG")
            ;;
        d)
            dirs=("$OPTARG")
            flag=true
            ;;
        f)
            file="$OPTARG"
            flag=true
            ;;
        s)
            case "$OPTARG" in
                re)
                    printf "%b" "$re_help"
                    exit 1
                    ;;
                demo)
                    printf "CONTEXT=C  RE_CONTENT='cebApplyForRequest.*971774e4-4b8e-11ee-ab1d-b6f946515a16' ./re_log_print.sh -d 22 -f 22/logback_luna_info-2023-09-05.0.log"
                    printf "R=100 DEBUG=true %s -d 21,22 -f logback_luna_info-2023-09-05.0.log\n" "$0"
                    printf "R=100 RE_CONTENT=test %s -a 22/logback_luna_info-2023-09-05.0.log\n" "$0"
                    printf "R=100 RE_CONTENT='签章在服务器中不存在' %s -a 21/logback_luna_info-2023-09-05.0.log,22/logback_luna_info-2023-09-05.0.log\n" "$0"
                    printf "R=100 RE_CONTENT='签章在服务器中不存在' %s\n" "$0"
                    printf "R=100 RE_CONTENT='签章在服务器中不存在' DEBUG=true %s\n" "$0"
                    printf "R=100 RE_CONTENT='签章在服务器中不存在' DEBUG=true TC=3 %s\n" "$0"
                    exit 1
                    ;;
                var)
                    printf "RE_CONTENT    匹配正则              [%s]\n" "$re_content"
                    printf "DEBUG         调试模式              [%s]\n" "$debug_print"
                    printf "TC            线程坐标              [%s]\n" "$thread_coordinate"
                    printf "CONTEXT       上下文类型            [%s]\n" "$context_type"
                    printf "R             上下文显示行数        [%s]\n" "$context_row"
                    exit 1
                    ;;
            esac
            ;;
        \?)
            help >&2
            exit 1
            ;;
        :)
            echo "选项 -$OPTARG 需要参数" >&2
            exit 1
            ;;
        *)
            exit 1
            ;;
    esac
done

if [[ $# -eq 0 || ! $1 =~ ^- ]]; then
    help
    exit 1
elif [[ $flag && ( -z "${dirs[*]}" || -z "${file[*]}" ) ]]; then
    echo "用法: $0 -d dir1,dir2 -f file"
    echo "-d      指定一个或多个文件夹"
    echo "-f      指定文件名"
    exit 1
fi

run
