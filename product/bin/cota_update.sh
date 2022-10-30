#!/bin/sh
LOG_TAG="cota_update"
log -p i -t "${LOG_TAG}" "[SBP] smartca resource update start"

SMARTCA_RES_PATH=/mnt/product/carrier/_SMARTCA_RES
SMARTCA_DATA_RES_PATH=/data/shared/cust

# prevent copying smartca bootanimation, in ResourcePackageManagmer, when it is running in GQA SingleCA
SINGLECA_SUBMIT=$(/product/bin/laop_cmd getprop ro.vendor.lge.singleca.submit)
if [ "${SINGLECA_SUBMIT}" = "1" ]; then
    /product/bin/laop_cmd setprop persist.vendor.lge.smartca.changed 2
    exit 0
fi

chown -R system:system ${SMARTCA_DATA_RES_PATH}
chmod 775 ${SMARTCA_DATA_RES_PATH}
chmod -R 775 ${SMARTCA_DATA_RES_PATH:?}/*

chown -R system:system ${SMARTCA_RES_PATH}
chmod 775 ${SMARTCA_RES_PATH}
chmod -R 775 ${SMARTCA_RES_PATH:?}/*

if [ -n "$(ls ${SMARTCA_DATA_RES_PATH}/PowerOn.ogg)" ]; then
    cp -pf ${SMARTCA_DATA_RES_PATH}/PowerOn.ogg ${SMARTCA_RES_PATH}
fi

if [ -n "$(ls ${SMARTCA_DATA_RES_PATH}/bootanimation.zip)" ]; then
    cp -pf ${SMARTCA_DATA_RES_PATH}/bootanimation.zip ${SMARTCA_RES_PATH}
fi

/product/bin/laop_cmd setprop persist.vendor.lge.smartca.changed 2
