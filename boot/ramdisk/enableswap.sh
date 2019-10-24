#!/bin/sh
echo lz4 > /sys/block/zram0/comp_algorithm
#ifdef VENDOR_EDIT
#huacai.zhou@PSW.BSP.kernel.drv, 2018/03/09, add oppo optimize for low memory devices
MemTotalStr=`cat /proc/meminfo | grep MemTotal`
MemTotal=${MemTotalStr:16:8}

if [ $MemTotal -lt 2097152 ]; then
  #config 1.2GB zram size with memory less than 2 GB
  echo 1288490188 > /sys/block/zram0/disksize

  #set swappiness and direct_swappiness for low memory devices
  echo 180 > /proc/sys/vm/swappiness
  echo 60 > /proc/sys/vm/direct_swappiness
else
  echo 0 > /sys/block/zram0/disksize
fi
#endif /*VENDOR_EDIT*/
/system/bin/mkswap /dev/block/zram0
/system/bin/swapon /dev/block/zram0
