#!/system/bin/sh

integer max_count=10
backup_folder=/data/ramoops
count_file=$backup_folder/next_count
console_ramoops=/data/ramoops/console-ramoops
# save pl_lk log
pl_lk_backup_folder=$backup_folder/pl_lk
pl_lk_count_file=$pl_lk_backup_folder/next_count

# save last_pl_lk log
#last_pl_lk_backup_folder=$backup_folder/last_pl_lk
#last_pl_lk_count_file=$last_pl_lk_backup_folder/next_count

if ls $console_ramoops ; then
	if ls $count_file ; then
		integer count=`cat $count_file`
		count=$count+0
		case $count in
            "" ) count=0
		esac
	else
		count=0
	fi
	echo [[[[ Written $backup_folder/ramoops$count $max_count ]]]]
	cat $console_ramoops > $backup_folder/ramoops$count
	cat /proc/cmdline >> $backup_folder/ramoops$count
	cat /proc/cmdline >> $backup_folder/cmdline$count
	# reason is att permission certification
	chmod 664 $backup_folder/ramoops$count
	chmod 664 $backup_folder/cmdline$count
	echo update_time_state >> $backup_folder/ramoops$count
	echo update_time_state >> $backup_folder/cmdline$count

	# save pl_lk log
	if ls /proc/pl_lk ; then
		cat /proc/pl_lk > $pl_lk_backup_folder/pl_lk$count
		chmod 664 $pl_lk_backup_folder/pl_lk$count
		echo update_time_state >> $pl_lk_backup_folder/pl_lk$count
	fi

	count=$count+1
	if  (($count>=$max_count)) ; then
		count=0
		echo restart
	fi
	echo $count > $count_file
	chmod 664 $count_file

	#save pl_lk log
	if ls /proc/pl_lk ; then
		echo $count > $pl_lk_count_file
		chmod 664 $pl_lk_count_file
	fi
fi

# seperate last_pl_lk works to remain it without ramoops condition
#if ls /proc/last_pl_lk ; then
#	if ls $last_pl_lk_count_file ; then
#		integer count=`cat $last_pl_lk_count_file`
#		count=$count+0
#		case $count in
#           "" ) count=0
#		esac
#	else
#		count=0
#	fi
#
#	# save last_pl_lk log
#	cat /proc/last_pl_lk > $last_pl_lk_backup_folder/last_pl_lk$count
#	chmod 664 $last_pl_lk_backup_folder/last_pl_lk$count
#	echo update_time_state >> $last_pl_lk_backup_folder/last_pl_lk$count
#
#	count=$count+1
#	if  (($count>=$max_count)) ; then
#		count=0
#		echo restart
#	fi
#
#	echo $count > $last_pl_lk_count_file
#	chmod 664 $last_pl_lk_count_file
#fi
