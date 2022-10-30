#!/bin/sh

function is_data_partition_mounted {
    local ret=0

    proc_mounts="/proc/mounts"
    while read -r line
    do
        mount_info=($line)
        mount_path=${mount_info[1]}
        mount_fs=${mount_info[2]}

    if [[ $mount_path == "/data" ]]; then

        if [[ $mount_fs == "ext4" ]] || [[ $mount_fs == "f2fs" ]]; then
            ret=1
            break
        fi
    fi
    done < "$proc_mounts"

    echo $ret
}

LOG_TAG="runtime_boot_res"
# TODO: Rename runtime_boot_res to check_google_submission in Q-OS

IS_DATA_MOUNTED=`is_data_partition_mounted`

if [[ $IS_DATA_MOUNTED != 1 ]]; then
    log -p i -t "${LOG_TAG}" "[SBP] data partition is not mounted yet."
    exit 0;
fi

PRODUCT_NAME=`getprop ro.product.name`
CUPSS_ROOT_DIR=$(getprop ro.vendor.lge.capp_cupss.rootdir /product/OP)
OP_ROOT_PATH=$(/product/bin/laop_cmd getprop ro.vendor.lge.capp_cupss.op.dir)

if [ "$1" == "media" ]; then
    log -p i -t "${LOG_TAG}" "[SBP] Copy data preload media"
    OP_PRELOAD_DIR="$OP_ROOT_PATH/_COMMON/media/0/Preload/LG"
    OP_PRELOAD_POS_DONE="/data/media/op_preload_done.ini"
    OP_PRELOAD_DONE="/data/system/op_preload_done.ini"
    PRELOAD_LINK_LOCATION_DIR="/data/media/0/Preload"

    if [ ! -f ${OP_PRELOAD_DONE} ] && [ ! -f ${OP_PRELOAD_POS_DONE} ]; then
        if [[ ${PRODUCT_NAME} == *"aosp"* ]]; then
            echo "op_preload_skip" > ${OP_PRELOAD_DONE}
        else
            if [ -d ${OP_PRELOAD_DIR} ]; then
                if [ ! -d ${PRELOAD_LINK_LOCATION_DIR} ]; then
                    mkdir -p ${PRELOAD_LINK_LOCATION_DIR}
                fi
                PRELOAD_LIST=$(ls ${OP_PRELOAD_DIR})
                for PRELOAD_ITEM in ${PRELOAD_LIST}; do
                    if [ -f ${OP_PRELOAD_DIR}/${PRELOAD_ITEM} ]; then
                        ln -sfn ${OP_PRELOAD_DIR}/${PRELOAD_ITEM} ${PRELOAD_LINK_LOCATION_DIR}/${PRELOAD_ITEM}
                    fi
                done
                chown -R media_rw:media_rw ${PRELOAD_LINK_LOCATION_DIR}
                chmod -R 0775 ${PRELOAD_LINK_LOCATION_DIR}
            fi
            echo "op_preload_done" > ${OP_PRELOAD_POS_DONE}
        fi
    fi
    exit 0
fi

log -p i -t "${LOG_TAG}" "[SBP] Check Google submission"

USER_APP_MANAGER_INSTALLATION_FILE=/data/local/app-ntcode-conf.json
DOWNCA_APP_MANAGER_INSTALLATION_FILE=$CUPSS_ROOT_DIR/config/app-special-conf.json
SMARTCA_RES_PATH=/mnt/product/carrier/_SMARTCA_RES

if [ -d $OP_ROOT_PATH ]; then
    if [ ! -f $DOWNCA_APP_MANAGER_INSTALLATION_FILE ]; then
        DOWNCA_APP_MANAGER_INSTALLATION_FILE=$OP_ROOT_PATH/_COMMON/app-enabled-conf.json
    fi
fi
rm ${USER_APP_MANAGER_INSTALLATION_FILE}

# Single CA Google submission
SINGLECA_SUBMIT=$(/product/bin/laop_cmd getprop ro.vendor.lge.singleca.submit)
if [ "${SINGLECA_SUBMIT}" = "1" ]; then
    if [ -f "${DOWNCA_APP_MANAGER_INSTALLATION_FILE}" ]; then
        ln -sf ${DOWNCA_APP_MANAGER_INSTALLATION_FILE} ${USER_APP_MANAGER_INSTALLATION_FILE}
        log -p i -t "${LOG_TAG}" "[SBP] Single CA Google submission"
    fi
fi

if [ ! -d ${SMARTCA_RES_PATH} ]; then
    if [ $(ls /data/shared/cust/bootanimation.zip) ]; then
        /product/bin/laop_cmd setprop persist.vendor.lge.smartca.changed 1
    fi
fi
exit 0
