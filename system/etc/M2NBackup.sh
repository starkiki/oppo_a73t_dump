#!/sbin/sh

busybox rm -rf /data/oppo/ota
busybox mkdir -p /data/oppo/ota
busybox mkdir -p /data/oppo/ota/com.coloros.fingerprint/shared_prefs/
busybox cp -Rf data/data/com.coloros.fingerprint/shared_prefs/fingerprint_preferences.xml /data/oppo/ota/com.coloros.fingerprint/shared_prefs/
busybox chmod -R 777 /data/oppo/ota

#added by feifei.liu@Launcher.ThemeSpace
#for themespace. Android6.x update to Android7.0 via OTA, need clear files in /data/theme
busybox rm -rf /data/theme/com.android.contacts
busybox rm -rf /data/theme/com.android.mms
busybox rm -rf /data/theme/com.android.server.telecom
busybox rm -rf /data/theme/com.oppo.launcher
busybox rm -rf /data/theme/com.oppo.yellowpage
busybox rm -rf /data/theme/com.coloros.filemanager
busybox rm -rf /data/theme/icons
busybox rm -rf /data/theme/wallpaper
busybox rm -rf /data/theme/lockwallpaper

busybox rm -rf /data/theme/com.android.bluetooth
busybox rm -rf /data/theme/com.android.dialer
busybox rm -rf /data/theme/com.android.phone
busybox rm -rf /data/theme/com.android.settings
busybox rm -rf /data/theme/com.android.systemui
busybox rm -rf /data/theme/com.android.wallpaper.livepicker
busybox rm -rf /data/theme/com.oppo.filemanager
busybox rm -rf /data/theme/com.oppo.gesture
busybox rm -rf /data/theme/com.oppo.phonenoareainquire
busybox rm -rf /data/theme/com.oppo.maxxaudio
busybox rm -rf /data/theme/com.oppo.usbselection
busybox rm -rf /data/theme/com.oppo.widget.smallweather
busybox rm -rf /data/theme/oppo-framework-res
busybox rm -rf /data/theme/lock/lockstyle
busybox rm -rf /data/theme/widget/weather_4x2
#for themespace,add end.

