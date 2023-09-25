#!/bin/bash

help_flag=false

while getopts ":f:d:a:h:" opt; do
  case $opt in
  f)
    file="$OPTARG"
    ;;
  d)
    dirs="$OPTARG"
    ;;
  a)
    files="$OPTARG"
    ;;
  h)
    help_flag=true
    help="$OPTARG"
    ;;
  \?)
    echo "无效的选项: -$OPTARG" >&2
    exit 1
    ;;
  # :)
  #   echo "选项 -$OPTARG 需要参数." >&2
  #   exit 1
  #   ;;
  esac
done
echo "$help"
if [[ "$help_flag" == true ]]; then
  case $help in 
    re)
      echo "re"
      ;;
    demo)
      echo "demo"
      ;;
    var)
      echo "var"
      ;;
    *)
      echo "用法: $0 -h re/demo/var"
      echo "re      查看可用正则"
      echo "demo    查看调用方式"
      echo "var     查看可用变量"
      exit 1
      ;;
  esac
elif [[ -z "$files" && -z "$dirs" ]]; then
  echo "用法: $0 -a file1 file2"
  echo "-a      指定一个文件"
  exit 1
elif [[ -n "$dirs" && -z "$file" ]]; then
  echo "用法: $0 -d dir1 dir2 -f file"
  echo "-d      指定一个或多个文件夹"
  echo "-f      指定文件名"
  exit 1
fi
