#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/bootdevice/by-name/recovery:19104672:72a939d7a874cce014b70930f2d26c89589489b1; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/bootdevice/by-name/boot:11791264:084c987e194b1baff4fcbaf01db244c5abd1dfaf EMMC:/dev/block/platform/bootdevice/by-name/recovery 72a939d7a874cce014b70930f2d26c89589489b1 19104672 084c987e194b1baff4fcbaf01db244c5abd1dfaf:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
