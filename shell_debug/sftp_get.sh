#!/bin/bash

# 本地目录
local_dir="/Users/lianyuxue/Desktop/shell/shell_debug"
# 远程目录
remote_dir="/opt"

# 远程IP信息
sftp_remote='127.0.0.1'
sftp_user='root'
sftp_port='8810'
sftp_password='password'
#sftp类型
sftp_type='put'
# 执行参数-afpR
sftp_arg='-fpR'
# 循环目录
dir_arrt=(11 12 21 22 31 32)

cd "$local_dir" || exit
if [[ -n $1 ]];then
    dir_arrt=("$1")
    dec_dir=$2
fi
if [[ $sftp_type == 'get' ]];then
    sftp_arg='-afpR'
fi
echo "遍历目录: ${dir_arrt[*]}"
echo "sftp type: $sftp_type"
for i in "${dir_arrt[@]}"; do
    stati_time_s=$(date +%s)
    echo "-->>start $(date +"%F %T")<<--"
    /usr/bin/expect << EOF
    set timeout 3
    spawn sftp -P $sftp_port ${sftp_user}@${sftp_remote}
    expect  {
        "yes/no" { send "yes\r" exp_continue }
        "assword:" { send "$sftp_password\r" }   
    }
    expect "sftp> "
    send "cd $remote_dir\r"
    expect "sftp> "
    send "$sftp_type $sftp_arg $i $dec_dir\r"
    set timeout -1
    expect "sftp> "
    send "bye\r"
EOF
    echo "bye"
    echo "-->>end $(date +"%F %T") 耗时:$(($(date +%s) - stati_time_s))s<<--" 
done

