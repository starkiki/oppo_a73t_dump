#!/system/bin/sh
#
#ifdef VENDOR_EDIT
#jie.cheng@swdp.shanghai, 2015/11/09, add init.oppo.hypnus.sh
#persist_enable_logging=`getprop persist.sys.oppo.junklog`
persist_enable_logging=true
enable_logging=1

#wait data partition
if [ "$0" != "/data/hypnus/init.oppo.hypnus.sh" ]; then
        n=0
        while [ n -lt 10 ]; do
                if [ "`stat -f -c '%t' /data/`" == "ef53" ];then
                        log "hypnus wait for data, data is ready"
                        break
                else
                        n=$((n+1));
                        log "hypnus wait for data, retry: n="$n
                        sleep 2
                fi
        done
        if [ -f /data/hypnus/init.oppo.hypnus.sh ]; then
                sh /data/hypnus/init.oppo.hypnus.sh
                exit
        fi
else
        log "hypnus load sh from data"
fi

complete=`getprop sys.boot_completed`
enable=`getprop persist.sys.enable.hypnus`

case "$persist_enable_logging" in
    "true")
        enable_logging=1
	;;
    "false")
        enable_logging=0
	;;
esac

if [ ! -n "$complete" ] ; then
        complete="0"
fi

case "$enable" in
    "1")
        n=0
        while [ n -lt 3 ]; do
		#load data folder module if it is exist
                if [ -f /data/hypnus/hypnus.ko ]; then
                        insmod /data/hypnus/hypnus.ko -f boot_completed=$complete
                else
                        insmod /system/lib/modules/hypnus.ko -f boot_completed=$complete
                fi
                if [ $? != 0 ];then
                        if [ -f /data/hypnus/hypnus.ko ]; then
                                insmod /data/hypnus/hypnus.ko -f
                        else
                                insmod /system/lib/modules/hypnus.ko -f
                        fi
			if [ $? != 0 ];then
                                n=$((n+1));
                                echo "Error: insmod hypnus.ko failed, retry: n="$n > /dev/kmsg
                        else
                                echo "Hypnus module insmod!" > /dev/kmsg
                                break
			fi
                else
                        echo "Hypnus module insmod!" > /dev/kmsg
                        break
                fi
        done

        chown system:system /sys/kernel/hypnus/scene_info
        chown system:system /sys/kernel/hypnus/action_info
        chown system:system /sys/kernel/hypnus/view_info
        chown system:system /sys/kernel/hypnus/notification_info
	chmod 0664 /sys/kernel/hypnus/notification_info
	chown system:system /sys/kernel/hypnus/log_state
        chcon u:object_r:sysfs_hypnus:s0 /sys/kernel/hypnus/view_info
	echo $enable_logging > /sys/module/hypnus/parameters/enable_logging
        # 1 queuebuffer only; 2 queue and dequeuebuffer;
        setprop persist.report.tid 2
        chown system:system /data/hypnus
        ;;
esac

case "$enable" in
    "0")
        rmmod hypnus
        ;;
esac

# only wait when /sdcard is not ready
if [ ! -d /sdcard/oppo_log ]; then
	sleep 30
fi

if [ -d /sdcard/oppo_log/hypnus ]; then
	rm -rf /sdcard/oppo_log/hypnus/*
fi
if [ -d /sdcard/oppo_log/junk_logs/kernel ]; then
	rm -rf /sdcard/oppo_log/junk_logs/kernel/*
fi
if [ -d /sdcard/oppo_log/junk_logs/ftrace ]; then
	rm -rf /sdcard/oppo_log/junk_logs/ftrace/*
fi

#endif /* VENDOR_EDIT */
