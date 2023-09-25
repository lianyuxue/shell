#!/bin/bash
# ---------------------------------
# Time: 2023/09/15
# AuthorName: lianyuxue
# Function: jar多个服务启动、停止、重启、状态
# ---------------------------------

# 当前路径
dir=$PWD

# 启动脚本名
start_file_name='restart.sh'

# 程序名
program_name='.jar'

# 正则匹配文件
# 匹配任何一个除了数字、字母、下划线，等价于[^0-9a-zA-Z_]
res_program_name="\\W*\\$program_name$"

# 输出格式
service_date=$(date +"%F %T")
echo_check="$service_date [check]"
echo_kill="$service_date [kill]"
echo_start="$service_date [start]"
echo_running="$service_date [running]"
echo_stop="$service_date [stop]"
echo_error="$service_date [error]"
echo_trap="$service_date [trap]"

# 指定顺序启动服务
service_arr=("$dir/dkh-luna-1" "$dir/project05")

# 命令执行
order_debug=true

# 版本
version="V1.0.0"

function ServiceStatus() {
	# 查看当前服务PID
	ids=$(pgrep -f "$1")
	echo "$ids"
}

function Contains() {
	# 数组判断
	local n=$#
	local value=${!n}
	for ((i = 1; i < $#; i++)); do
		if [ "${!i}" == "${value}" ]; then
			echo "y"
			return 0
		fi
	done
	echo "n"
	return 1
}

function ServiceRun() {
	# 服务启动
	# $1为服务路径名 $2为服务状态
	local dir_name=$1
	local status_name=$2
	local index=${#service_arr[*]}

	# 服务总数｜成功数｜失败数
	local service_count_success=0
	local service_count_failed=0
	local all_service_count=0

	local service_name=""
	local error_msg=""

	# 定义启动顺序
	if [[ $dir_name == '*' ]]; then
		for i in "$dir"/$dir_name; do
			if [[ -d $i && $(Contains "${service_arr[@]}" "$i") == "n" ]]; then
				service_arr["$index"]=$i
				((index++))
			fi
		done
	else
		service_arr=("$dir/$dir_name")
	fi

	all_service_count=${#service_arr[@]}
	echo "[$all_service_count] 当前服务启动顺序为：${service_arr[*]}"
	for i in "${service_arr[@]}"; do
		# 取第一个过滤项
		service_name=$(find "$i" -type f | grep -m 1 "$res_program_name" | xargs basename)
		local service_file_path=$i/$service_name
		local service_dir_name=${i##*/}

		if [[ -d $i && -f $service_file_path ]]; then
			echo "----------------------服务主目录：$service_dir_name | 服务名：$service_name ----------------------"

			# 服务检查
			ids=$(ServiceStatus "$service_name")
			echo "$echo_check $service_name PID:$ids"

			# 服务启动
			if [[ $status_name = 'START' || $status_name = 'RESTART' ]]; then
				if [[ $status_name = 'START' && -n $ids ]]; then
					((service_count_failed += 1))
					echo "$echo_running $service_name PID:$ids"
					echo -e "----------------------【$all_service_count/$service_count_success/$service_count_failed】$service_dir_name | $service_name END----------------------\n"
					continue
				elif [[ $status_name = 'RESTART' && -n $ids ]]; then
					for id in $ids; do
						# 执行命令
						error_msg=$($order_debug && kill -9 "$id" 2>&1)
					done

					# 防止没有权限导致失败
					if [[ -n $error_msg ]]; then
						((service_count_failed += 1))
						echo "$echo_error 当前$service_name 服务PID:$ids 未被杀死 原因:$error_msg"
						echo -e "----------------------【$all_service_count/$service_count_success/$service_count_failed】$service_dir_name | $service_name END----------------------\n"
						continue
					fi

					echo "$echo_kill $service_name PID:$ids"
				fi

				local start_name=$i/$start_file_name
				if [[ -f $start_name ]]; then
					echo "$echo_start $service_name"

					# 捕获Ctrl+C中止指令ls
					trap "echo $echo_trap" SIGINT

					# 执行脚本
					if ! error_msg=$($order_debug && cd "$i" && sleep 10 && /bin/sh "$start_name" 2>&1); then
						id=$(ServiceStatus "$service_name")
						if [[ -n $id ]]; then
							((service_count_success += 1))
							echo "$echo_running $service_name 启动成功 PID:$id"

							((service_count_failed += 1))
							echo "$echo_error $service_name 启动失败"
						fi
					else
						((service_count_failed += 1))
						echo "$echo_error $service_name 启动失败 原因:$error_msg"
					fi

				else
					((service_count_failed += 1))
					echo "$echo_error $service_name 当前服务名下没有$start_file_name 启动脚本"
				fi
			elif [[ $status_name = 'STOP' ]]; then
				if [[ -n $ids ]]; then
					for id in $ids; do
						# 执行命令
						error_msg=$($order_debug && kill -9 "$id" 2>&1)
					done

					# 防止没有权限导致失败
					if [[ -n $error_msg ]]; then
						((service_count_failed += 1))
						echo "$echo_error 当前$service_name 服务PID:$ids 未被杀死 原因:$error_msg"
						echo -e "----------------------【$all_service_count/$service_count_success/$service_count_failed】$service_dir_name | $service_name END----------------------\n"
						continue
					else
						((service_count_success += 1))
						echo "$echo_kill $service_name PID:$ids"
					fi
				else
					((service_count_failed += 1))
					echo "$echo_error $service_name 该服务没有运行"
				fi
			elif [[ $status_name = 'STATUS' ]]; then
				if [[ -n $ids ]]; then
					for id in $ids; do
						echo "$echo_running $service_name PID:$id"
					done
				else
					echo "$echo_stop" "$service_name"
				fi
				((service_count_success += 1))
			fi
		else
			echo "$echo_error 该服务主目录$i 不存在或服务主目录路径下没有$program_name 程序"
			((service_count_failed += 1))
		fi
		echo "----------------------[$all_service_count/$service_count_success/$service_count_failed] $service_dir_name | $service_name END----------------------"
	done
}

function One() {
	# $1为执行函数 $2为服务路径名 $3为服务状态
	if [[ -n $2 ]]; then
		if [[ -d "$dir"/$2 ]]; then
			"$1" "$2" "$3"
		else
			echo "error: $dir/$2 找不到当前服务路径"
		fi
	else
		echo "warning: 请指定服务"
	fi
}

function Start_All() {
	ServiceRun "*" "START"
}

function Start_One() {
	One ServiceRun "${1:-''}" "START"
}

function Restart_All() {
	ServiceRun "*" "RESTART"
}

function Restart_One() {
	One ServiceRun "${1:-''}" "RESTART"
}

function Stop_All() {
	ServiceRun "*" "STOP"
}

function Stop_One() {
	One ServiceRun "${1:-''}" "STOP"
}

function Status_All() {
	ServiceRun "*" "STATUS"
}

function Stataus_One() {
	One ServiceRun "${1:-''}" "STATUS"
}

case $1 in
start_all)
	Start_All
	;;
start_one)
	Start_One "$2"
	;;
restart_all)
	Restart_All
	;;
restart_one)
	Restart_One "$2"
	;;
stop_all)
	Stop_All
	;;
stop_one)
	Stop_One "$2"
	;;
status_all)
	Status_All
	;;
status_one)
	Stataus_One "$2"
	;;
help)
	echo "[ start_all | start_one | restart_all | restart_one | status_all | status_one | stop_all | stop_one | version | help ]"
	;;
version)
	echo "$version"
	;;
*)
	echo "[ start_all | start_one | restart_all | restart_one | status_all | status_one | stop_all | stop_one | version | help ]"
	;;
esac
