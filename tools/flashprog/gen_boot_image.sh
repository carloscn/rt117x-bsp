# !/bin/bash

# 0:    XIP     - norflash
# 1:    Non-XIP - itcm
# 2:    Non-XIP - sdram
# 3:    XIP     - norflash (secure-signed)
# 4:    Non-XIP - itcm (secure-signed)
# 5:    Non-XIP - sdram (secure-signed)

MODE_XIP_NORFLASH=0
MODE_RAM_ITCM=1
MODE_RAM_SDRAM=2
MODE_XIP_NORFLASH_SIGNED=3
MODE_RAM_ITCM_SIGNED=4
MODE_RAM_SDRAM_SIGNED=5

function usage {
    echo ""
    echo "usage: "
    echo "     $bash ./gen_boot_image.sh ./images/helloworld.s19 0"
    echo ""
}

if [ $# -lt 1 ]; then
    echo "[ERR] Failed on input number $#!"
    usage
    exit -1
fi

IN_IMAGE=${1}
IN_MODE=${2}
OUT_IMAGE=ivt_image.bin
OUT_IMAGE_NO_EXT=${OUT_IMAGE%.bin}
OUT_IMAGE_NOPADDING=${OUT_IMAGE_NO_EXT}_nopadding.bin
ROOT_DIR=$(dirname "$0")
IMAGES_DIR=${ROOT_DIR}/images
TOOLS=${ROOT_DIR}/tools
EXE_ELFTOSB=${TOOLS}/elftosb
BD_DIR=${ROOT_DIR}/bd_files

function __check_ret() {
	if [ $1 -ne 0 ]; then
        echo "[ERR] Failed on $2! Return $1!"
        exit -1
    fi
}

if [ ${IN_MODE} -eq ${MODE_XIP_NORFLASH} ]; then
    echo "[INFO] use the XIP mode - nor flash QSPI."
    BD_FILE=${BD_DIR}/imx_xip_norflash_unsigned.bd
elif [ ${IN_MODE} -eq ${MODE_RAM_ITCM} ]; then
    echo "[INFO] use the non-XIP mode - itcm onchip ram."
    BD_FILE=${BD_DIR}/imx_ram_itcm_unsigned.bd
elif [ ${IN_MODE} -eq ${MODE_RAM_SDRAM} ]; then
    echo "[INFO] use the non-XIP mode - external SDRAM ram."
    BD_FILE=${BD_DIR}/imx_ram_sdram_unsigned.bd
elif [ ${IN_MODE} -eq ${MODE_RAM_ITCM_SIGNED} ]; then
    echo "[INFO] use the non-XIP mode - external SDRAM ram."
    BD_FILE=${BD_DIR}/imx_ram_itcm_signed.bd
else
    echo "[ERR] Unsupport mode!"
    exit -1
fi

echo "[INFO] Check nxp tools."

ls ${IN_IMAGE} > /dev/null
__check_ret $? "${IN_IMAGE} does not exist!"

nxp_tools_set=("${EXE_ELFTOSB}" "cst")
for i in "${nxp_tools_set[@]}"; do
    echo "[INFO]    * checking ${i}."
    if [ ! -f ${i} ]; then
        echo "[ERR] ${i} does not exist!"
        exit -1
    fi
    ${i} --version > /dev/null
    if [ $? -ne 0 ]; then
        echo "[ERR] Failed on $2! Return $1!"
        exit -1
    fi
done

echo "[INFO] Generating bootable image."
rm -rf ivt_image_nopadding.bin ivt_image.bin
${EXE_ELFTOSB} -f imx -V -c ${BD_FILE} -o ${OUT_IMAGE} ${IN_IMAGE}
__check_ret $? "${EXE_ELFTOSB} -f imx -V -c ${BD_FILE} -o ${OUT_IMAGE} ${IN_IMAGE} > /dev/null"
ls -al ${OUT_IMAGE} ${OUT_IMAGE_NOPADDING} > /dev/null
__check_ret $? "${OUT_IMAGE} or ${OUT_IMAGE_NOPADDING} does not exist! ${EXE_ELFTOSB} gen failed!"

FILESIZE=$(stat -c%s "${OUT_IMAGE}")
if [ $((10#${FILESIZE})) -gt 300000 ]; then
    echo "[ERR] The ${IN_IMAGE} mem layout error! Please double check the project RAM list design!"
    rm -rf ${OUT_IMAGE} ${OUT_IMAGE_NOPADDING}
    exit -1
fi

ls -al ivt_image*

echo "[INFO] Done!"