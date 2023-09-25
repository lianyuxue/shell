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
# A=0 # 上文行数
# B=0 # 下文行数
C="${C:-10}" # 上下行数

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
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [文件组] -> ${files[*]}"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [目录组] -> ${dirs[*]}"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [文件] -> $file"

    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [上下文] -> $C"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [debug状态] -> $debug_print"
    echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [检索关键字] -> $re_content"

    if [[ -n "${dirs[*]}" && -n "$file" ]]; then
        # 参数解析
        IFS="," read -r -a array <<<"$dirs"
        dirs=("${array[@]}")

        # find查找
        find_result=$(find "${dirs[@]}" -type f -name "$file" -exec grep -C "$C" -EiHn "$re_content" {} \;)
    elif [[ -n "${files[*]}" ]]; then
        # 参数解析
        IFS="," read -r -a array <<<"$files"
        files=("${array[@]}")

        # find查找
        find_result=$(find "${files[@]}" -type f -exec grep -C "$C" -EiHn "$re_content" {} \;)
    else
        echoWarning "请选择其中一种方式dirs or files exit 1"
        exit 1
    fi

    $debug_print && echoWarning "find_result:$find_result"

    if [[ -n "$find_result" ]]; then
        # 过滤中标数据
        line_result=$(echo "$find_result" | sed -n "$((C + 1))p")
        $debug_print && echoWarning "line_result:$line_result"
        # 过滤中标数据线程号关键字
        thread=$(echo "$line_result" | awk '{print $"'"$thread_coordinate"'"}')
        # 过滤中标数据时间关键字
        mark=$(echo "$line_result" | awk '{print $1}')

        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [中标位置] -> $mark"
        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [中标线程] -> $thread"

        # 匹配相同线程号数据
        result=$(echo "$find_result" | awk '$"'"$thread_coordinate"'" == "'"$thread"'" {print}')
        $debug_print && echoWarning "result:$result"
        result_count=$(echo "$result" | awk 'END{print NR}')
        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [数据总行] -> $result_count"

        # 标注匹配数据行号（完整数据）
        new_result="$(echo "$result" | awk '{print NR" "$0}')"
        # echo "$(echo "$new_result"|grep -C "")"
        $debug_print && echoWarning "new_result:$new_result"
        # 过滤中标数据所在行号
        line_number=$(echo "$new_result" | awk '$2 == "'"$mark"'" {print $1}')
        echoPrimary "$(date "+%Y-%m-%d %H:%M:%S") [中标行号] -> $line_number"

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
    else
        echoWarning "没有检索到数据"
        exit 1
    fi
}

while getopts ":f:d:a:h:" opt; do
    case $opt in
    f)
        file="$OPTARG"
        ;;
    d)
        dirs=("$OPTARG")
        ;;
    a)
        files=("$OPTARG")
        ;;
    h)
        help_flag=true
        help="$OPTARG"
        ;;
    \?)
        echo "无效的选项: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "选项 -$OPTARG 需要参数" >&2
        exit 1
        ;;
    esac
done

if [[ "$help_flag" == true ]]; then
    case $help in
    re)
        printf "%b" "$re_help"
        exit 1
        ;;
    demo)
        printf "C=100 DEBUG=true %s -d 21,22 -f logback_luna_info-2023-09-05.0.log\n" "$0"
        printf "C=100 RE_CONTENT=test %s -a 22/logback_luna_info-2023-09-05.0.log\n" "$0"
        printf "C=100 RE_CONTENT='签章在服务器中不存在' %s -a 21/logback_luna_info-2023-09-05.0.log,22/logback_luna_info-2023-09-05.0.log\n" "$0"
        printf "C=100 RE_CONTENT='签章在服务器中不存在' %s\n" "$0"
        printf "C=100 RE_CONTENT='签章在服务器中不存在' DEBUG=true %s\n" "$0"
        printf "C=100 RE_CONTENT='签章在服务器中不存在' DEBUG=true TC=3 %s\n" "$0"
        exit 1
        ;;
    var)
        printf "RE_CONTENT    匹配正则       [%s]\n" "$re_content"
        printf "DEBUG         调试模式       [%s]\n" "$debug_print"
        printf "TC            线程坐标       [%s]\n" "$thread_coordinate"
        printf "C             上下文数       [%s]\n" "$C"
        exit 1
        ;;
    *)
        echo "用法: $0 -h re | demo | var"
        echo "re      查看可用正则"
        echo "demo    查看调用方式"
        echo "var     查看可用变量"
        exit 1
        ;;
    esac
elif [[ -z "${files[*]}" && -z "${dirs[*]}" ]]; then
    echo "用法: $0 -a file1,file2"
    echo "-a    指定一个或多个文件"
    echo "-d    指定一个或多个文件夹"
    echo "-h    帮助"
    exit 1
elif [[ -n "$dirs" && -z "$file" ]]; then
    echo "用法: $0 -d dir1,dir2 -f file"
    echo "-d      指定一个或多个文件夹"
    echo "-f      指定文件名"
    exit 1
fi

run
