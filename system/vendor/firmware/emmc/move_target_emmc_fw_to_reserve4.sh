#!/bin/bash
HYNIX_EMCP_PROD_NAME_3D_64G="HCG8a4"
HYNIX_EMCP_PROD_NAME_2D_32G="HBG4a2"
SUMSUNG_EMCP_PROD_NAME_3D_64G="RH64MB"
SUMSUNG_EMCP_PROD_NAME_2D_16G="QE63MB"
MICRON_EMCP_PROD_NAME_3D_64G="S0J9F8"
fw_path=""
cmpresult=`cat /proc/devinfo/emmc | grep "${HYNIX_EMCP_PROD_NAME_3D_64G}"`;
if [ "$cmpresult" != "" ]; then
	echo "cp Hynix 3D nand emcp fw to reserve4 for upgrade";
	fw_path="/system/vendor/firmware/emmc/3D_eMCP5.1_PRV_A2_EXT_CSD306_0x01.bin_crc.bin";
fi
cmpresult=`cat /proc/devinfo/emmc | grep "${HYNIX_EMCP_PROD_NAME_2D_32G}"`;
if [ "$cmpresult" != "" ]; then
	echo "cp Hynix 2D nand emcp fw to reserve4 for upgrade";
	fw_path="/system/vendor/firmware/emmc/2D_eMCP5.1_PRV_A5_EXT_CSD306_0x01.bin_crc.bin";
fi
cmpresult=`cat /proc/devinfo/emmc | grep "${SUMSUNG_EMCP_PROD_NAME_3D_64G}"`;
if [ "$cmpresult" != "" ]; then
	echo "cp Sumsung 3D emcp fw to reserve4 for upgrade";
	fw_path="/system/vendor/firmware/emmc/KMRH60014M-B614_MV6432_V3_D20_P05.bin_crc.bin";
fi
cmpresult=`cat /proc/devinfo/emmc | grep "${SUMSUNG_EMCP_PROD_NAME_2D_16G}"`;
if [ "$cmpresult" != "" ]; then
	echo "cp Sumsung 2D nand emcp fw to reserve4 for upgrade";
	fw_path="/system/vendor/firmware/emmc/sumsung_2D_16GB_eMMC_P06.bin_crc.bin";
fi
cmpresult=`cat /proc/devinfo/emmc | grep "${MICRON_EMCP_PROD_NAME_3D_64G}"`;
if [ "$cmpresult" != "" ]; then
	echo "cp Micron 3D nand emcp fw to reserve4 for upgrade";
	fw_path="/system/vendor/firmware/emmc/64GB_FFU_FW_HW_FW5.2.BIN_crc.bin";
fi
#reserve4 -> /dev/block/mmcblk0p7
if [ "$fw_path" != "" ]; then
	echo $fw_path;
	dd if="${fw_path}" of=/cache/src_fw_header bs=1 count=32;
	dd if=/dev/block/platform/bootdevice/by-name/reserve4 of=/cache/local_fw_header bs=1 count=32 skip=14680064;
	cmp -s /cache/src_fw_header /cache/local_fw_header;
	if [ $? -eq 1 ]; then
		echo "new fw found, copy to target partition";
		dd if="${fw_path}" of=/dev/block/platform/bootdevice/by-name/reserve4 bs=1 seek=14680064;
	fi
fi
