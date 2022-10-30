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

LOG_TAG="ntcode_etc_symlinks"

IS_DATA_MOUNTED=`is_data_partition_mounted`

if [[ $IS_DATA_MOUNTED != 1 ]]; then
    log -p i -t "${LOG_TAG}" "[SBP] data partition is not mounted yet."
    exit 0;
fi

LAST_BUILD_INCREMENTAL=$(getprop persist.product.lge.runtime_symlinks.incremental 0)
CURRENT_BUILD_INCREMENTAL=$(getprop ro.build.version.incremental NODEF)

if [ "${LAST_BUILD_INCREMENTAL}" = "${CURRENT_BUILD_INCREMENTAL}" ]; then
    exit 0;
fi

SOURCE_PATH=$(getprop ro.vendor.lge.capp_cupss.rootdir /product/OP)
SOURCE_ETC_PATH=${SOURCE_PATH}/etc
TARGET_DATA_PATH=/data/laop
TARGET_ETC_PATH=${TARGET_DATA_PATH}/etc

# $TARGET_ETC_PATH MUST be updated in MR or OSU.
log -p i -t "${LOG_TAG}" "[SBP] clean-up ${TARGET_ETC_PATH} for MR or OSU"
rm -rf ${TARGET_ETC_PATH:?}/*

if [ ! -d "${TARGET_ETC_PATH}" ]; then
    log -p i -t "${LOG_TAG}" "[SBP] mkdir ${TARGET_ETC_PATH}"
    mkdir -p ${TARGET_ETC_PATH}
    chmod -R 775 ${TARGET_DATA_PATH}
    restorecon ${TARGET_DATA_PATH}
fi

if [ ! -d "${TARGET_ETC_PATH}" ]; then
    log -p e -t "${LOG_TAG}" "[SBP] exit - cannot mkdir ${TARGET_ETC_PATH}"
    exit 0;
fi

# copy 3rd party app properties for LGE to /data
LGE_3RD_PARTY_KEY_PATH=/system/vendor/etc/LGE
if [ -d "${LGE_3RD_PARTY_KEY_PATH}" ]; then
    cp -rpf ${LGE_3RD_PARTY_KEY_PATH:?}/* ${TARGET_ETC_PATH}/
fi

# Read NT-Code MCC
NTCODE=$(/product/bin/laop_cmd getprop ro.vendor.lge.ntcode_mcc XXX)
if [ "${NTCODE}" = "XXX" ]; then
    #Nothing to do - fail to read ntcode
    log -p e -t "${LOG_TAG}" "[SBP] exit - fail to read ntcode"
fi

# For dedicatie operator with speical NT-code, eg., VDF: "2","FFF,FFF,FFFFFFFF,FFFFFFFF,11","999,01F,FFFFFFFF,FFFFFFFF,FF"
MCCMNC_LIST=$(/product/bin/laop_cmd getprop persist.vendor.lge.mccmnc-list "FFFFF")

DEDICATE_OPERATOR_MCCMNC="XXXXXX"
if [[ "${MCCMNC_LIST}" = *"999"* ]]; then
    DEDICATE_OPERATOR_MCCMNC=${MCCMNC_LIST%%999*}
    DEDICATE_MCCMNC_INDEX=${#DEDICATE_OPERATOR_MCCMNC}
    DEDICATE_OPERATOR_MCCMNC=${MCCMNC_LIST:$DEDICATE_MCCMNC_INDEX:6}
    DEDICATE_OPERATOR_MCCMNC=${DEDICATE_OPERATOR_MCCMNC%,}
fi

if [ -d "${SOURCE_ETC_PATH}/${DEDICATE_OPERATOR_MCCMNC}" ]; then
    cp -rpf ${SOURCE_ETC_PATH}/${DEDICATE_OPERATOR_MCCMNC}/* ${TARGET_ETC_PATH}/
    log -p i -t "${LOG_TAG}" "[SBP] cp -rpf ${SOURCE_ETC_PATH}/${DEDICATE_OPERATOR_MCCMNC}/* ${TARGET_ETC_PATH}/"
elif [ -d "${SOURCE_ETC_PATH}/${NTCODE}" ]; then
    cp -rpf ${SOURCE_ETC_PATH:?}/${NTCODE}/* ${TARGET_ETC_PATH}/
    log -p i -t "${LOG_TAG}" "[SBP] cp -rpf ${SOURCE_ETC_PATH}/${NTCODE}/* ${TARGET_ETC_PATH}/"
elif [ -d "${SOURCE_ETC_PATH}/FFF" ]; then
    cp -rpf ${SOURCE_ETC_PATH:?}/FFF/* ${TARGET_ETC_PATH}/
    log -p i -t "${LOG_TAG}" "[SBP] cp -rpf ${SOURCE_ETC_PATH}/FFF/* ${TARGET_ETC_PATH}/"
fi

# Restore sap_etc_symlink in MR
FIXED_FIRST_SIM_OPERATOR=$(/product/bin/laop_cmd getprop persist.vendor.lge.sim.operator.first NODEF)
if [ "${FIXED_FIRST_SIM_OPERATOR}" != "NODEF" ]; then
    if [ -d "${SOURCE_ETC_PATH}/${FIXED_FIRST_SIM_OPERATOR}" ]; then
        cp -rpf ${SOURCE_ETC_PATH:?}/${FIXED_FIRST_SIM_OPERATOR}/* ${TARGET_ETC_PATH}/
        log -p i -t "${LOG_TAG}" "[SBP] cp -rpf ${SOURCE_ETC_PATH}/${FIXED_FIRST_SIM_OPERATOR}/* ${TARGET_ETC_PATH}/"
    fi
fi

EEA_PATH=$(getprop ro.boot.product.lge.eea_type NODEF)
IS_OVERLAY_FS=$(getprop ro.vendor.lge.feature.product_overlayfs false)
if  [ "$EEA_PATH" = "4c" ] ; then
    if [ "$IS_OVERLAY_FS" != "true" ] ; then
        cp -rpf ${SOURCE_ETC_PATH}/sysconfig/eea*_search_chrome.xml ${TARGET_ETC_PATH}/
        log -p i -t "${LOG_TAG}" "[SBP] cp -rpf ${SOURCE_ETC_PATH}/sysconfig/eea*_search_chrome.xml ${TARGET_ETC_PATH}/"
    fi
fi

chown -R system:system ${TARGET_DATA_PATH}
chmod -R 0755 ${TARGET_DATA_PATH}

setprop persist.product.lge.runtime_symlinks.incremental "${CURRENT_BUILD_INCREMENTAL}"
exit 0
