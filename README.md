媒体批量去广告脚本

-----------------------------

需要安装ffmpeg

第一次运行会自动生成空数据库文件，自行编辑media_file,start_time这两个字段：

media_file是媒体路径，start_time是片头时长。编辑好后将list.db跟脚本放到一个目录，直接运行就可以了，失败的会在生成的fail_logs.txt里记录。
