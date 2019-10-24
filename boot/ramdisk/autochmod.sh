#!/system/bin/sh

config="$1"
ROOT_AUTOTRIGGER_PATH=/sdcard/oppo_log

#ifdef VENDOR_EDIT
#Jiemin.Zhu@PSW.AD.Memroy.Performance.1137310, 2017/10/12, add for low memory device
function oppolowram() {
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}
    #lower than 2GB ram
    if [ $MemTotal -lt 2097152 ]; then
        setprop dalvik.vm.heapstartsize 8m
        setprop ro.config.oppo.low_ram true
        setprop ro.config.max_starting_bg 3
    fi
}
#endif /* VENDOR_EDIT */

#Haoran.Zhang@PSW.AD.BuildConfig.StandaloneUserdata.0, 2017/09/13, Add for set prop sys.build.display.full_id
function userdatarefresh(){
   mkdir /data/engineermode
   ro_ver=`getprop ro.build.display.id`;
   info_file="/data/engineermode/data_version"
   prop_key="sys.build.display.full_id"
   #info_file is not empty
   if [ -s $info_file ] ;then
       data_ver=`cat $info_file | head -1 | xargs echo -n`
       setprop $prop_key "$ro_ver""_$data_ver"
       #mtk only
       nv_prop_val=`getprop ro.mediatek.version.release`
       if [ $nv_prop_val ] ;then
       setprop sys.mediatek.version.release "$nv_prop_val""_$data_ver"
       fi
       #end mtk only
   else
          if [ ! -f $info_file ] ;then
            if [ ! -f /data/engineermode/.sd.txt ]; then
              cp  /system/media/.sd.txt  /data/engineermode/.sd.txt
            fi
            cp /system/engineermode/*  /data/engineermode/
            #create an empty file
            rm $info_file
            touch $info_file
            chmod 0644 /data/engineermode/.sd.txt
            chmod 0644 /data/engineermode/persist*
          fi
          setprop $prop_key "$ro_ver""_00000000"
   fi
   #add for sendtest version
   if [ `getprop ro.build.fix_data_hash` ]; then
      setprop $prop_key "$ro_ver"
      nv_prop_val=`getprop ro.mediatek.version.release`
      setprop sys.mediatek.version.release "$nv_prop_val"
   fi
   #end
   chmod 0750 /data/engineermode
   chmod 0740 /data/engineermode/default_workspace_device*.xml
   chown system:launcher /data/engineermode
   chown system:launcher /data/engineermode/default_workspace_device*.xml
}
#end

#ifdef VENDOR_EDIT
#Yanzhen.Feng@PSW.Android.DebugTool.LayerDump, 2015/12/09, Add for SurfaceFlinger Layer dump
function layerdump(){
    dumpsys window > /data/log/dumpsys_window.txt
    mkdir -p ${ROOT_AUTOTRIGGER_PATH}
    LOGTIME=`date +%F-%H-%M-%S`
    ROOT_SDCARD_LAYERDUMP_PATH=${ROOT_AUTOTRIGGER_PATH}/LayerDump_${LOGTIME}
    cp -R /data/log ${ROOT_SDCARD_LAYERDUMP_PATH}
    rm -rf /data/log
}
#endif /* VENDOR_EDIT */
#ifdef VENDOR_EDIT
#Yanzhen.Feng@PSW.Android.OppoDebug, 2017/03/20, Add for systrace on phone
function cont_systrace(){
    sleep 10
    mkdir -p ${ROOT_AUTOTRIGGER_PATH}/systrace
    CATEGORIES=`atrace --list_categories | $XKIT awk '{printf "%s ", $1}'`
    echo ${CATEGORIES} > ${ROOT_AUTOTRIGGER_PATH}/systrace/categories.txt
    while true
    do
        systrace_duration=`getprop debug.oppo.systrace.duration`
        if [ "$systrace_duration" != "" ]
        then
            LOGTIME=`date +%F-%H-%M-%S`
            SYSTRACE_DIR=${ROOT_AUTOTRIGGER_PATH}/systrace/systrace_${LOGTIME}
            mkdir -p ${SYSTRACE_DIR}
            ((sytrace_buffer=$systrace_duration*1536))
            atrace -z -b ${sytrace_buffer} -t ${systrace_duration} ${CATEGORIES} > ${SYSTRACE_DIR}/atrace_raw
            /system/bin/ps -t > ${SYSTRACE_DIR}/ps.txt
            /system/bin/printf "%s\n" /proc/[0-9]*/task/[0-9]* > ${SYSTRACE_DIR}/task.txt

            systrace_status=`getprop debug.oppo.cont_systrace`
            if [ "$systrace_status" == "false" ]; then
                break
            fi
        fi
    done
}
#endif /* VENDOR_EDIT */
function junklogcat() {

    JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    mkdir -p ${JUNKLOGPATH}

    system/bin/logcat -f ${JUNKLOGPATH}/junklogcat.txt -v threadtime *:V
}
function junkdmesg() {
    JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    mkdir -p ${JUNKLOGPATH}
    system/bin/dmesg > ${JUNKLOGPATH}/junkdmesg.txt
}
function junksystrace_start() {
    JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    mkdir -p ${JUNKLOGPATH}

    #setup
    setprop debug.atrace.tags.enableflags 0x86E
    # stop;start
    adb shell "echo 16384 > /sys/kernel/debug/tracing/buffer_size_kb"

    echo nop > /sys/kernel/debug/tracing/current_tracer
    echo 'sched_switch sched_wakeup sched_wakeup_new sched_migrate_task binder workqueue irq cpu_frequency mtk_events' > /sys/kernel/debug/tracing/set_event
#just in case tracing_enabled is disabled by user or other debugging tool
    echo 1 > /sys/kernel/debug/tracing/tracing_enabled >nul 2>&1
    echo 0 > /sys/kernel/debug/tracing/tracing_on
#erase previous recorded trace
    echo > /sys/kernel/debug/tracing/trace
    echo press any key to start capturing...
    echo 1 > /sys/kernel/debug/tracing/tracing_on
    echo "Start recordng ftrace data"
    echo s_start > sdcard/s_start2.txt
}
function junksystrace_stop() {
    JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    mkdir -p ${JUNKLOGPATH}
    echo s_stop > sdcard/s_stop.txt
    echo 0 > /sys/kernel/debug/tracing/tracing_on
    echo "Recording stopped..."
    cp /sys/kernel/debug/tracing/trace ${JUNKLOGPATH}/junksystrace
    echo 1 > /sys/kernel/debug/tracing/tracing_on

}

function junk_log_monitor(){
    DIR=/sdcard/oppo_log/junk_logs/DCS
    MAX_NUM=10
    IDX=0
    if [ -d "$DIR" ]; then
        ALL_FILE=`ls -t $DIR`
        for i in $ALL_FILE;
        do
            echo "now we have file $i"
            let IDX=$IDX+1;
            echo ========file num is $IDX===========
            if [ "$IDX" -gt $MAX_NUM ] ; then
               echo rm file $i\!;
            rm -rf $DIR/$i
            fi
        done
    fi
}

#ifdef VENDOR_EDIT
#Fei.Mo@PSW.BSP.Sensor, 2017/09/01 ,Add for power monitor top info
function thermalTop(){
   top -m 3 -n 1 > /data/system/dropbox/thermalmonitor/top
   chown system:system /data/system/dropbox/thermalmonitor/top
}
#endif /*VENDOR_EDIT*/

#ifdef VENDOR_EDIT
#Deliang.Peng@PSW.MultiMedia.Display.Service.Log, 2017/7/7,add for native watchdog
function nativedump() {
    LOGTIME=`date +%F-%H-%M-%S`
    SWTPID=`getprop debug.swt.pid`
    JUNKLOGSFBACKPATH=/sdcard/oppo_log/native/${LOGTIME}
    NATIVEBACKTRACEPATH=${JUNKLOGSFBACKPATH}/user_backtrace
    mkdir -p ${NATIVEBACKTRACEPATH}
    cat proc/stat > ${JUNKLOGSFBACKPATH}/proc_stat.txt &
    cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_0_.txt &
    cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_1.txt &
    cat /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_2.txt &
    cat /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_3.txt &
    cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_4.txt &
    cat /sys/devices/system/cpu/cpu5/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_5.txt &
    cat /sys/devices/system/cpu/cpu6/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_6.txt &
    cat /sys/devices/system/cpu/cpu7/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_7.txt &
    cat /sys/devices/system/cpu/cpu0/online > ${JUNKLOGSFBACKPATH}/cpu_online_0_.txt &
    cat /sys/devices/system/cpu/cpu1/online > ${JUNKLOGSFBACKPATH}/cpu_online_1_.txt &
    cat /sys/devices/system/cpu/cpu2/online > ${JUNKLOGSFBACKPATH}/cpu_online_2_.txt &
    cat /sys/devices/system/cpu/cpu3/online > ${JUNKLOGSFBACKPATH}/cpu_online_3_.txt &
    cat /sys/devices/system/cpu/cpu4/online > ${JUNKLOGSFBACKPATH}/cpu_online_4_.txt &
    cat /sys/devices/system/cpu/cpu5/online > ${JUNKLOGSFBACKPATH}/cpu_online_5_.txt &
    cat /sys/devices/system/cpu/cpu6/online > ${JUNKLOGSFBACKPATH}/cpu_online_6_.txt &
    cat /sys/devices/system/cpu/cpu7/online > ${JUNKLOGSFBACKPATH}/cpu_online_7_.txt &
    cat /proc/gpufreq/gpufreq_var_dump > ${JUNKLOGSFBACKPATH}/gpuclk.txt &
    top -n 1 -m 5 > ${JUNKLOGSFBACKPATH}/top.txt  &
    cp -R /data/native/* ${NATIVEBACKTRACEPATH}
    rm -rf /data/native
    ps -t > ${JUNKLOGSFBACKPATH}/pst.txt
}
#endif /*VENDOR_EDIT*/

function gettpinfo() {
    tplogflag=`getprop persist.sys.oppodebug.tpcatcher`
    # tplogflag=511
    # echo "$tplogflag"
    if [ "$tplogflag" == "" ]
    then
        echo "tplogflag == error"
    else
        kernellogpath=sdcard/mtklog/tp_debug_info/
        subcur=`date +%F-%H-%M-%S`
        subpath=$kernellogpath/$subcur.txt
        mkdir -p $kernellogpath
        echo $tplogflag
        # tplogflag=`echo $tplogflag | $XKIT awk '{print lshift($0, 1)}'`
        tpstate=0
        tpstate=`echo $tplogflag | $XKIT awk '{print and($1, 1)}'`
        echo "switch tpstate = $tpstate"
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off"
        else
            echo "switch tpstate on"
        # mFlagMainRegister = 1 << 1
        subflag=`echo | $XKIT awk '{print lshift(1, 1)}'`
        echo "1 << 1 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 1 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 1 $tpstate"
            echo /proc/touchpanel/debug_info/main_register  >> $subpath
            cat /proc/touchpanel/debug_info/main_register  >> $subpath
        fi
        # mFlagSelfDelta = 1 << 2;
        subflag=`echo | $XKIT awk '{print lshift(1, 2)}'`
        echo " 1<<2 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 2 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 2 $tpstate"
            echo /proc/touchpanel/debug_info/self_delta  >> $subpath
            cat /proc/touchpanel/debug_info/self_delta  >> $subpath
        fi
        # mFlagDetal = 1 << 3;
        subflag=`echo | $XKIT awk '{print lshift(1, 3)}'`
        echo "1 << 3 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 3 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 3 $tpstate"
            echo /proc/touchpanel/debug_info/delta  >> $subpath
            cat /proc/touchpanel/debug_info/delta  >> $subpath
        fi
        # mFlatSelfRaw = 1 << 4;
        subflag=`echo | $XKIT awk '{print lshift(1, 4)}'`
        echo "1 << 4 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 4 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 4 $tpstate"
            echo /proc/touchpanel/debug_info/self_raw  >> $subpath
            cat /proc/touchpanel/debug_info/self_raw  >> $subpath
        fi
        # mFlagBaseLine = 1 << 5;
        subflag=`echo | $XKIT awk '{print lshift(1, 5)}'`
        echo "1 << 5 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 5 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 5 $tpstate"
            echo /proc/touchpanel/debug_info/baseline  >> $subpath
            cat /proc/touchpanel/debug_info/baseline  >> $subpath
        fi
        # mFlagDataLimit = 1 << 6;
        subflag=`echo | $XKIT awk '{print lshift(1, 6)}'`
        echo "1 << 6 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 6 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 6 $tpstate"
            echo /proc/touchpanel/debug_info/data_limit  >> $subpath
            cat /proc/touchpanel/debug_info/data_limit  >> $subpath
        fi
        # mFlagReserve = 1 << 7;
        subflag=`echo | $XKIT awk '{print lshift(1, 7)}'`
        echo "1 << 7 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 7 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 7 $tpstate"
            echo /proc/touchpanel/debug_info/reserve  >> $subpath
            cat /proc/touchpanel/debug_info/reserve  >> $subpath
        fi
        # mFlagTpinfo = 1 << 8;
        subflag=`echo | $XKIT awk '{print lshift(1, 8)}'`
        echo "1 << 8 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 8 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 8 $tpstate"
        fi

        echo $tplogflag " end else"
	fi
    fi

}
function write_logswitch_on(){
    /system/bin/settings  put System log_switch_type 1
}

function write_logswitch_off(){
    /system/bin/settings  put System log_switch_type 0
}
function screen_record(){
    ROOT_SDCARD_RECORD_LOG_PATH=${ROOT_AUTOTRIGGER_PATH}/screen_record
    mkdir -p  ${ROOT_SDCARD_RECORD_LOG_PATH}
    /system/bin/screenrecord  --time-limit 1800 --size 320x640 --bit-rate 500000 --verbose ${ROOT_SDCARD_RECORD_LOG_PATH}/screen_record.mp4
}

function inittpdebug(){
    panicstate=`getprop persist.sys.assert.panic`
    tplogflag=`getprop persist.sys.oppodebug.tpcatcher`
    if [ "$panicstate" == "true" ]
    then
        tplogflag=`echo $tplogflag , | $XKIT awk '{print or($1, 1)}'`
    else
        tplogflag=`echo $tplogflag , | $XKIT awk '{print and($1, 510)}'`
    fi
    setprop persist.sys.oppodebug.tpcatcher $tplogflag
}
function settplevel(){
    tplevel=`getprop persist.sys.oppodebug.tplevel`
    if [ "$tplevel" == "0" ]
    then
        echo 0 > /proc/touchpanel/debug_level
    elif [ "$tplevel" == "1" ]
    then
        echo 1 > /proc/touchpanel/debug_level
    elif [ "$tplevel" == "2" ]
    then
        echo 2 > /proc/touchpanel/debug_level
    fi
}

#Jianping.Zheng@PSW.Android.Stability.Crash, 2017/06/20, Add for collect futexwait block log
function collect_futexwait_log() {
    collect_path=/data/system/dropbox/extra_log
    if [ ! -d ${collect_path} ]
    then
        mkdir -p ${collect_path}
        chmod 700 ${collect_path}
        chown system:system ${collect_path}
    fi

    #time
    echo `date` > ${collect_path}/futexwait.time.txt

    #ps -t info
    ps -t > $collect_path/ps.txt

    #D status to dmesg
    echo w > /proc/sysrq-trigger

    #systemserver trace
    system_server_pid=`ps |grep system_server | $XKIT awk '{print $2}'`
    kill -3 ${system_server_pid}
    sleep 10
    cp /data/anr/traces.txt $collect_path/

    #systemserver native backtrace
    debuggerd64 -b ${system_server_pid} > $collect_path/systemserver.backtrace.txt
}

#Jianping.Zheng@PSW.Android.Stability.Hang.DeathHealer, 2017/05/08, Add for systemserver futex_wait block check
function check_systemserver_futexwait_block() {
    futexblock_interval=`getprop persist.sys.futexblock.interval`
    if [ x"${futexblock_interval}" = x"" ]; then
        futexblock_interval=180
    fi

    exception_max=`getprop persist.sys.futexblock.max`
    if [ x"${exception_max}" = x"" ]; then
        exception_max=60
    fi

    while [ true ];do
        system_server_pid=`ps |grep system_server | $XKIT awk '{print $2}'`
        if [ x"${system_server_pid}" != x"" ]; then
            exception_count=0
            while [ $exception_count -lt $exception_max ] ;do
                systemserver_stack_status=`ps | grep system_server | $XKIT awk '{print $6}'`
                inputreader_stack_status=`ps -t $system_server_pid | grep InputReader  | $XKIT awk '{print $6}'`
                if [ x"${systemserver_stack_status}" == x"futex_wait" ] && [ x"${inputreader_stack_status}" == x"futex_wait" ]; then
                    exception_count=`expr $exception_count + 1`
                    if [ x"${exception_count}" = x"${exception_max}" ]; then
                        echo "Systemserver,FutexwaitBlocked-"`date` > "/proc/sys/kernel/hung_task_oppo_kill"
                        setprop sys.oppo.futexwaitblocked "`date`"
                        collect_futexwait_log
                        kill -9 $system_server_pid
                        sleep 60
                        break
                    fi
                    sleep 1
                else
                    break
                fi
            done
        fi
        sleep "$futexblock_interval"
    done
}
#end, add for systemserver futex_wait block check

#Jianping.Zheng@PSW.Android.Stability.Crash, 2017/06/12, Add for record d status thread stack
function record_d_threads_stack() {
    record_path=$1
    echo "\ndate->" `date` >> ${record_path}
    ignore_threads="kworker/u16:1|mdss_dsi_event|mmc-cmdqd/0|msm-core:sampli|kworker/10:0|mdss_fb0\
|mts_thread|fuse_log|ddp_irq_log_kth|disp_check|decouple_trigge|ccci_fsm1|ccci_poll1|hang_detect\
|gauge_coulomb_t|battery_thread|power_misc_thre|gauge_timer_thr|ipi_cpu_dvfs_rt|smart_det|charger_thread"
    d_status_tids=`ps -t | grep " D " | grep -iEv "$ignore_threads" | $XKIT awk '{print $2}'`;
    if [ x"${d_status_tids}" != x"" ]
    then
        sleep 5
        d_status_tids_again=`ps -t | grep " D " | grep -iEv "$ignore_threads" | $XKIT awk '{print $2}'`;
        for tid in ${d_status_tids}
        do
            for tid_2 in ${d_status_tids_again}
            do
                if [ x"${tid}" == x"${tid_2}" ]
                then
                    thread_stat=`cat /proc/${tid}/stat | grep " D "`
                    if [ x"${thread_stat}" != x"" ]
                    then
                        echo "tid:"${tid} "comm:"`cat /proc/${tid}/comm` "cmdline:"`cat /proc/${tid}/cmdline`  >> ${record_path}
                        echo "stack:" >> ${record_path}
                        cat /proc/${tid}/stack >> ${record_path}
                    fi
                    break
                fi
            done
        done
    fi
}
#Canjie.Zheng@PSW.Android.OppoDebug.JunkLog, 2017/06/30, add for clan junk log.
function cleanjunk() {
    rm -rf data/oppo_log/junk_logs/ftrace/*
    rm -rf data/oppo_log/junk_logs/kernel/*
}

#Jianping.Zheng@PSW.Android.Stability.Crash, 2017/04/04, Add for record performance
function perf_record() {
    check_interval=`getprop persist.sys.oppo.perfinteval`
    if [ x"${check_interval}" = x"" ]; then
        check_interval=60
    fi
    perf_record_path=/data/oppo_log/perf_record_logs
    while [ true ];do
        if [ ! -d ${perf_record_path} ];then
            mkdir -p ${perf_record_path}
        fi

        echo "\ndate->" `date` >> ${perf_record_path}/cpu.txt
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq >> ${perf_record_path}/cpu.txt

        echo "\ndate->" `date` >> ${perf_record_path}/mem.txt
        cat /proc/meminfo >> ${perf_record_path}/mem.txt

        echo "\ndate->" `date` >> ${perf_record_path}/buddyinfo.txt
        cat /proc/buddyinfo >> ${perf_record_path}/buddyinfo.txt

        echo "\ndate->" `date` >> ${perf_record_path}/top.txt
        top -t -m 8 -n 1 >> ${perf_record_path}/top.txt

        record_d_threads_stack "${perf_record_path}/d_status.txt"

        sleep "$check_interval"
    done
}

function cpfaceunlock() {
    mv /data/system/users/0/faceunlock/ sdcard/mtklog/
}

function powerlog() {
    pmlog=data/system/powermonitor_backup/
    if [ -d "$pmlog" ]; then
        mkdir -p sdcard/mtklog/powermonitor_backup
        cp -r data/system/powermonitor_backup/* sdcard/mtklog/powermonitor_backup/
    fi
}

#Canjie.Zhang@PSW.AD.OppoDebug.LogKit.1080426, 2017/11/09, Add for logkit2.0 clean log command
function cleanlog() {
    rm -rf sdcard/mtklog/
    rm -rf sdcard/oppo_log/
    rm -rf storage/sdcard1/mtklog/
}

case "$config" in

#ifdef VENDOR_EDIT
#Yanzhen.Feng@PSW.Android.DebugTool.LayerDump, 2015/12/09, Add for SurfaceFlinger Layer dump
    "layerdump")
        layerdump
        ;;
#endif /* VENDOR_EDIT */
#Haoran.Zhang@PSW.AD.BuildConfig.StandaloneUserdata.0, 2017/09/13, Add for set prop sys.build.display.full_id
    "userdatarefresh")
        userdatarefresh
        ;;
#end    
#ifdef VENDOR_EDIT
#Jiemin.Zhu@PSW.AD.Memroy.Performance.1137310, 2017/10/12, add for low memory device
    "oppolowram")
        oppolowram
        ;;
#endif
#ifdef VENDOR_EDIT
#Yanzhen.Feng@PSW.Android.OppoDebug, 2017/03/20, Add for systrace on phone
    "cont_systrace")
        cont_systrace
        ;;
#endif /* VENDOR_EDIT */
    "junklogcat")
        junklogcat
    ;;
    "junkdmesg")
        junkdmesg
    ;;
    "junkststart")
        junksystrace_start
    ;;
    "junkststop")
        junksystrace_stop
    ;;
    "cleanjunk")
        cleanjunk
    ;;
    "gettpinfo")
        gettpinfo
    ;;
    "inittpdebug")
        inittpdebug
    ;;
    "junklogmonitor")
        junk_log_monitor
    ;;
    "screen_record")
        screen_record
    ;;
    "settplevel")
        settplevel
    ;;
    "write_off")
        write_logswitch_off
    ;;
    "write_on")
        write_logswitch_on
    ;;
#ifdef VENDOR_EDIT
#Deliang.Peng@PSW.MultiMedia.Display.Service.Log, 2017/7/7,add for native watchdog
    "nativedump")
        nativedump
    ;;
#endif /* VENDOR_EDIT */
#Jianping.Zheng@PSW.Android.Stability.Hang.DeathHealer, 2017/05/08, Add for systemserver futex_wait block check
        "checkfutexwait")
        check_systemserver_futexwait_block
#end, add for systemserver futex_wait block check
#Jianping.Zheng@PSW.Android.Stability.Crash, 2017/04/04, Add for record performance
    ;;
        "perf_record")
        perf_record
    ;;
        "cpfaceunlock")
        cpfaceunlock
    ;;
        "powerlog")
        powerlog
    ;;
    #Fei.Mo@PSW.BSP.Sensor, 2017/09/01 ,Add for power monitor top info
    "thermal_top")
        thermalTop
    #end, Add for power monitor top info
    ;;
#Canjie.Zhang@PSW.AD.OppoDebug.LogKit.1080426, 2017/11/09, Add for logkit2.0 clean log command
    "cleanlog")
        cleanlog
    ;;
       *)

      ;;
esac
