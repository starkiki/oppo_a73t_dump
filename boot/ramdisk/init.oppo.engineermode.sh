#!/system/bin/sh

##################################################################
if [ -f /persist/engineermode/adb_switch ]; then
    setprop persist.sys.allcommode true
    setprop persist.allcommode true
    setprop persist.sys.oppo.usbactive true
    setprop persist.sys.adb.engineermode 0
    setprop sys.usb.config adb
    setprop persist.sys.usb.config adb
    adb_switch=`cat /persist/engineermode/adb_switch`
    if [ "$adb_switch"x = "ENABLE_BY_MASTERCLEAR"x ]; then
        setprop persist.sys.oppo.fromadbclear true
        rm /persist/engineermode/adb_switch
    fi
fi
###################################################################
