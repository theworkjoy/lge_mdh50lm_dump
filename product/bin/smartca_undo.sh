#!/bin/sh
LOG_TAG="smartca_undo"
log -p i -t "${LOG_TAG}" "[SBP] smartca undo start"

SMARTCA_RES_PATH=/mnt/product/carrier/_SMARTCA_RES
SMARTCA_DATA_RES_PATH=/data/shared/cust

rm -rf ${SMARTCA_RES_PATH:?}
rm -rf ${SMARTCA_DATA_RES_PATH:?}

# set 2 to distinguish undo task done
/product/bin/laop_cmd setprop persist.vendor.lge.smartca.undo 2
