#!/bin/sh
LOG_TAG="sap_etc_symlinks"

# This script is executed once only by FP.
FIXED_FIRST_SIM_OPERATOR=$(/product/bin/laop_cmd getprop persist.vendor.lge.sim.operator.first NODEF)

if [ "$FIXED_FIRST_SIM_OPERATOR" != "NODEF" ]; then
    exit 0;
fi

# wait for ntocde_etc_symlinks done
LAST_BUILD_INCREMENTAL=$(getprop persist.product.lge.runtime_symlinks.incremental 0)
time_count=1
while [ $time_count -le 100 ]
do
    if [ "$LAST_BUILD_INCREMENTAL" != "0" ]; then
        break;
    fi
    sleep 1
    let time_count=$time_count+1
done
log -p w -t ${LOG_TAG} "[SBP] Wait ${time_count} seconds for ntcode_etc_symlinks done"

DEFAULT_ICCID_PERSIST_VALUE=89000000000000000000
CURRENT_ICCID=$(/product/bin/laop_cmd getprop persist.vendor.lge.iccid ${DEFAULT_ICCID_PERSIST_VALUE})

if [ "$CURRENT_ICCID" = "$DEFAULT_ICCID_PERSIST_VALUE" ]; then
    log -p w -t ${LOG_TAG} "[SBP] sap_etc_symlinks exit - SIM is not loaded yet."
    exit 0;
fi

SIM_OPERATOR=$(getprop persist.vendor.lge.sim.operator NODEF)
SUB_SIM_OPERATOR=$(/product/bin/laop_cmd getprop persist.vendor.lge.sim.operator.sub NODEF)
CUPSS_ROOTDIR=$(getprop ro.vendor.lge.capp_cupss.rootdir /OP)
IS_LP=$(getprop persist.product.lge.first-sim 0)

if [ "$SIM_OPERATOR" = "BELL" ] && [ "$IS_LP" = "0" ]; then
    exit 0;
fi

if [ "$SUB_SIM_OPERATOR" = "SKC" ] || [ "$SUB_SIM_OPERATOR" = "SOC" ] || [ "$SUB_SIM_OPERATOR" = "PCC" ]; then
    SIM_OPERATOR=$SUB_SIM_OPERATOR
fi

SOURCE_ETC_PATH=${CUPSS_ROOTDIR}/etc/${SIM_OPERATOR}
TARGET_DATA_PATH=/data/laop
TARGET_ETC_PATH=${TARGET_DATA_PATH}/etc

if [ ! -d "${TARGET_ETC_PATH}" ]; then
    log -p e -t ${LOG_TAG} "[SBP] sap_etc_symlinks exit - ${TARGET_ETC_PATH} not exist"
    exit 0;
fi

log -p i -t ${LOG_TAG} "[SBP] sap_etc_symlinks - SOURCE_ETC_PATH = $SOURCE_ETC_PATH"

# copy 3rd-party app properties for the matched operator
if [ -d "${SOURCE_ETC_PATH}" ]; then
    cp -rf ${SOURCE_ETC_PATH:?}/* ${TARGET_ETC_PATH}/
    chown -R system:system ${TARGET_ETC_PATH}
    chmod -R 0755 ${TARGET_ETC_PATH}
fi

#FIX FIRST_SIM_OPERATOR
/product/bin/laop_cmd setprop persist.vendor.lge.sim.operator.first "${SIM_OPERATOR}"
exit 0
