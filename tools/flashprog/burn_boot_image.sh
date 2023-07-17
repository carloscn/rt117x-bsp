# !/bin/bash

function usage {
    echo ""
    echo "usage: "
    echo "     $bash ./gen_boot_image.sh /dev/ttyACM0 ./ivt_image_nopadding.bin"
    echo ""
}

if [ $# -lt 1 ]; then
    echo "[ERR] Failed on input number $#!"
    usage
    exit -1
fi

TARGET_HW=${1}
IN_IMAGE=${2}
ROOT_DIR=$(dirname "$0")
IMAGES_DIR=${ROOT_DIR}/images
TOOLS=${ROOT_DIR}/tools
EXE_BLHOST=./${TOOLS}/blhost
EXE_ELFTOSB=./${TOOLS}/elftosb
BD_DIR=${ROOT_DIR}/bd_files

function __check_ret() {
	if [ $1 -ne 0 ]; then
        echo "[ERR] Failed on $2! Return $1!"
        exit -1
    fi
}

function __check_result_log() {

    if [ ! -f "result.log" ]; then
        echo "wait for result.log".
    else
        ret=`cat result.log | jq '.status.value'`
        if [ ${ret} != $1 ]; then
            echo "[ERR] failed on return json file, json returns [${ret}] != [$1], when executes : [$3]"
            cat result.log
            exit -1
        fi
        return
    fi
}

# pre step: check input
echo "[INFO] Check nxp tools."
ls ${TARGET_HW} > /dev/null
__check_ret $? "${TARGET_HW} does not exist! Please insert a correct board!"

ls ${IN_IMAGE} > /dev/null
__check_ret $? "${IN_IMAGE} does not exist!"

nxp_tools_set=("${EXE_BLHOST}")
for i in "${nxp_tools_set[@]}"; do
    echo "[INFO]    * checking ${i} tool."
    if [ ! -f ${i} ]; then
        echo "[ERR] ${i} does not exist!"
        exit -1
    fi
done

rm -rf result.log
# step 2: try to connect to board
echo "[INFO] Try to connect to the board."
echo "[INFO]    * try to get-property from board."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- get-property 17 0 > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- get-property 17 0"

echo "[INFO]    * try to load ivt_flashloader.bin to board. (about blocks 10s)"
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- load-image ${IMAGES_DIR}/ivt_flashloader.bin > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- load-image ${IMAGES_DIR}/ivt_flashloader.bin"

sleep 2
echo "[INFO]    * try to check ivt_flashloader image status 1 0 on board."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- get-property 1 0  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- get-property 1 0"

echo "[INFO]    * try to check ivt_flashloader image status 24 0 on board."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- get-property 24 0  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- get-property 24 0"

echo "[INFO]    * try to check efuse-read-once on board."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- efuse-read-once 22  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- efuse-read-once 22"

echo "[INFO]    * try to read-memory on board."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- read-memory 1074675776 4 ./readReg.dat 0  > result.log
__check_result_log "10200" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- read-memory 1074675776 4"

echo "[INFO]    * try to fill-memory on board."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538976256 4 3482320897 word  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538976256 4 3482320897 word"

echo "[INFO]    * try to config-memory on board."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- configure-memory 9 538976256  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- configure-memory 9 538976256"

echo "[INFO]    * try to write config-memory on board."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538976256 4 3221225479 word  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538976256 4 3221225479 word"

echo "[INFO]    * try to re-write config-memory on board."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538976260 4 0 word  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538976256 4 3221225479 word"

echo "[INFO]    * try to re-config-memory on board."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- configure-memory 9 538976256  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- configure-memory 9 538976256"

echo "[INFO]    * try to re-read-memory on board."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- read-memory 805307392 1024 ./temp_nor_cfg.dat 9  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- read-memory 805307392 1024 ./NorCfg.dat 9"

# step 3: burn image
echo "[INFO] Burning bootable image."
echo "[INFO]    * erase-memory."
${EXE_BLHOST} -t 2048000 -p ${TARGET_HW},115200 -j -- flash-erase-region 0x30000000 0xFFFF 9 > result.log
__check_result_log "0" $? ".${EXE_BLHOST} -t 2048000 -p ${TARGET_HW},115200 -j -- flash-erase-region 805306368 36864 9"

echo "[INFO]    * fill-memory."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 0x20203000 4 0xF000000F word  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- fill-memory 538980352 4 4026531855 word"

echo "[INFO]    * config-memory."
${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- configure-memory 9 0x20203000  > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 50000 -p ${TARGET_HW},115200 -j -- configure-memory 9 538980352"

echo "[INFO]    * write-memory."
${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- write-memory 0x30001000 ${IN_IMAGE} 9 > result.log
__check_result_log "0" $? "${EXE_BLHOST} -t 5242000 -p ${TARGET_HW},115200 -j -- write-memory 805310464 ${IN_IMAGE} 9"

echo "[INFO] Done!"