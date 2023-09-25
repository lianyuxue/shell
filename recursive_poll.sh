#!/bin/bash
# ---------------------------------
# Time: 2023/09/15
# AuthorName: lianyuxue
# Function: 遍历目录文件
# ---------------------------------

count_file=1
# 定义递归函数
poll_directory() {
    local dir="$1"

    # 遍历目录中的所有文件和子目录
    for file in "$dir"/*; do
        # 检查文件是否存在并且是一个普通文件
        if [[ -f "$file" ]]; then
            # 在这里对每个文件执行你的操作
            echo "处理文件$count_file: $file"
            ((count_file+=1));
            # 可以在这里调用其他命令或脚本来处理文件
        elif [[ -d "$file" ]]; then
            # 如果是一个子目录，则递归调用该函数
            poll_directory "$file"
        fi
    done
}

# 定义要轮询的根目录
#root_directory="/Users/lianyuxue/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/2.0b4.0.9/4d99f1d438fdb45bb93581f47f6e26dc/Message/MessageTemp/52d1d668e74d41728a5badf3382bdefd/File/光大-061901投产文件"

# 调用递归函数开始轮询
poll_directory "$1"
