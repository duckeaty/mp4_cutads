#!/bin/bash  
  
# SQLite数据库文件名  
DATABASE="list.db"  
# 失败日志文件  
FAIL_LOG="fail_logs.txt"  
# 最大并行进程数  
MAX_PARALLEL_PROCESSES=4  
  
# 初始化SQLite数据库（如果尚未存在）  
init_db() {
    sqlite3 "$DATABASE" <<EOF
CREATE TABLE IF NOT EXISTS media_list (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    media_file TEXT NOT NULL UNIQUE,
    start_time TEXT,
    status INTEGER DEFAULT 0
);
EOF
}

# 向数据库中添加媒体文件记录  
add_media() {  
    local file="$1"  
    local start="$2"  
    sqlite3 "$DATABASE" "INSERT INTO media_list (media_file, start_time) VALUES ('$file', '$start');"  
}  
  
get_next_media() {  
    sqlite3 "$DATABASE" "SELECT media_file, start_time, status FROM media_list WHERE status < 1 LIMIT 1;"  
}  
  
update_media_status() {  
    local file="$1"  
    local status="$2"  
    sqlite3 "$DATABASE" "UPDATE media_list SET status = $status WHERE media_file = '$file';"  
}  
  
# 处理媒体文件  
process_media() {  
    local file="$1"  
    local start="$2"  
	local status="$3"
    local base=$(basename "$file")  
    local dir=$(dirname "$file")  
    local output="$dir/${base%.*}_processed.mp4"  
    local log="$FAIL_LOG" # 使用统一的失败日志文件，便于管理  
  
    # 使用ffmpeg处理媒体文件  
	if [ $status -eq 0 ]; then
		ffmpeg -hide_banner -i "$file" -ss "$start" -c copy "$output" > /dev/null 2>&1  
	else
		ffmpeg -ss "$start" -i "$file" -c:v copy -c:a aac -strict experimental -y "$output"
	fi
	local result=$?
  
    # 检查处理结果并更新状态和输出相应的信息  
    if [ $result -eq 0 ]; then  
        echo "Processed $file successfully."  
        update_media_status "$file" 1
    else
		echo "Error processing $file at $(date)" >> "$log"  
		update_media_status "$file" -1
    fi  
}  
  
# 主程序开始    
init_db    
    
# 启动媒体处理进程    
running_processes=0    
while true; do    
    media=$(get_next_media)    
    if [ -z "$media" ]; then    
        echo "All media files have been processed."    
        break    
    fi    
    
    IFS='|' read -r file start_time status <<< "$media" # 使用正确的分隔符    
    
    process_media "$file" "$start_time" "$status" # 在前台启动处理进程    
    running_processes=$((running_processes + 1)) # 更新运行中的进程数    
done    
    
# 等待所有进程完成    
wait