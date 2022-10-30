#!/system/bin/sh
#
# Copyright (C) 2016 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script copies preloaded content from system_other to data partition

# Helper function to copy files
function do_copy_file() {
  source_file=$1
  dest_name=$2
  dest_root_folder=$3

  # Move to a temporary file so we can do a rename and have the preopted file
  # appear atomically in the filesystem.
  temp_dest_name=${dest_name}.tmp
  if ! cp -f ${source_file} ${temp_dest_name} ; then
    log -p w -t preload_copy "Unable to copy file ${source_file} to ${temp_dest_name}!"
  else
    log -p i -t preload_copy "Copied file from ${source_file} to ${temp_dest_name}"
    fsync ${temp_dest_name}
    if ! mv -f ${temp_dest_name} ${dest_name} ; then
      log -p w -t preload_copy "Unable to rename temporary file from ${temp_dest_name} to ${dest_name}"
    else
      fsync ${dest_name}
      log -p i -t preload_copy "Renamed temporary file from ${temp_dest_name} to ${dest_name}"
      if [[ "${dest_root_folder}" == *"preload"* ]] ; then
        chown system:system ${dest_name}
        chmod 644 ${dest_name}
      elif [[ "${dest_root_folder}" == *"media"* ]] ; then
        chown media_rw:media_rw ${dest_name}
        chmod 664 ${dest_name}
      else
        log -p w -t preload_copy "do_copy_file, Unable to find folder name ${dest_root_folder}, dest_name: ${dest_name}"
      fi
    fi
  fi
}

# Helper function to copy folder
function do_copy_folder() {
  source_folder=$1
  dest_root_folder=$2

  for folder in $(find ${source_folder} -type d); do
    temp_name=${folder/${source_folder}/}
    dest_name=${dest_root_folder}${temp_name}

    mkdir -p ${dest_name}

    if [[ "${dest_root_folder}" == *"temp"* ]] ; then
      chown -R system:system ${dest_root_folder}
      chmod -R 755 ${dest_root_folder}
    elif [[ "${dest_root_folder}" == *"preload"* ]] ; then
      chown -R system:system ${dest_name}
      chmod -R 755 ${dest_name}
    elif [[ "${dest_root_folder}" == *"media"* ]] ; then
      chown media_rw:media_rw ${dest_name}
      chmod 775 ${dest_name}
    else
      log -p w -t preload_copy "do_copy_folder, Unable to find folder name ${dest_root_folder}"
    fi

    #log -p i -t preload_copy "do_copy_folder : source_folder: ${source_folder}, dest_root_folder: ${dest_root_folder}, folder: ${folder}"
    #log -p i -t preload_copy "do_copy_folder : temp_name: ${temp_name}, dest_name: ${dest_name}"
  done

  for file in $(find ${source_folder} -type f -name "*.*"); do
    temp_name=${file/${source_folder}/}
    dest_name=${dest_root_folder}${temp_name}

    #log -p i -t preload_copy "do_copy_folder : source_folder: ${source_folder}, dest_root_folder: ${dest_root_folder}, file: ${file}"
    #log -p i -t preload_copy "do_copy_folder : temp_name: ${temp_name}, dest_name: ${dest_name}"

    # Copy files in background to speed things up
    do_copy_file ${file} ${dest_name} ${dest_root_folder} &
  done
}

OP_ROOT=`getprop ro.vendor.lge.capp_cupss.rootdir`
TO=`getprop ro.vendor.lge.build.target_operator`
TC=`getprop ro.vendor.lge.build.target_country`
#OP_NAME=`cat ${OP_ROOT}/totc.cfg`
OP_NAME=${TO}_${TC}

FACTORY_FLAG=`getprop vendor.lge.factory.cppreloads`

if [ $# -eq 1 ]; then
  # Where system_other is mounted that contains the preloads dir
  mountpoint=$1

  log -p i -t preload_copy "preload_copy from ${mountpoint}"
  log -p i -t preload_copy "FACTORY_FLAG: ${FACTORY_FLAG}, OP_ROOT: ${OP_ROOT}, OP_NAME: ${OP_NAME}"

  if [[ "$FACTORY_FLAG" == "0" ]] ; then
    log -p i -t preload_copy "FACTORY_FLAG is 0. exit"
    if [[ "$(whoami)" == "system" ]]; then
      echo "FACTORY_FLAG is 0. exit" > /data/anr/preload_copy_log
    fi
    exit 0
  fi

  CACHE_DATA_DIR="/cache/data"
  DATA_PRELOAD_DIR="/data/preload"
  DATA_PRELOAD_TEMP_DIR="/data/preload/temp"
  DATA_MEDIA_DIR="/data/media"
  # All preload contents do the copy task
  # NOTE: this implementation will break in any path with spaces to favor
  # background copy tasks
  if [[ "${mountpoint}" == "${CACHE_DATA_DIR}" ]] ; then
    mkdir -p ${DATA_PRELOAD_DIR}
    chown system:system ${DATA_PRELOAD_DIR}
    chmod 755 ${DATA_PRELOAD_DIR}

    mkdir -p ${DATA_PRELOAD_TEMP_DIR}
    chown system:system ${DATA_PRELOAD_TEMP_DIR}
    chmod 775 ${DATA_PRELOAD_TEMP_DIR}

    do_copy_folder ${CACHE_DATA_DIR}/preload/ ${DATA_PRELOAD_DIR}/ &
    do_copy_folder ${CACHE_DATA_DIR}/media/ ${DATA_PRELOAD_TEMP_DIR}/
  elif [[ "${mountpoint}" == "${DATA_PRELOAD_TEMP_DIR}" ]] ; then
    do_copy_folder ${DATA_PRELOAD_TEMP_DIR}/ ${DATA_MEDIA_DIR}/
    wait
    rm -rf ${DATA_PRELOAD_TEMP_DIR}
  elif [[ "${mountpoint}" == *"preload"* ]] ; then
    if [[ "$OP_ROOT" == *"SUPERSET"* ]] ; then
      ENTRY=`ls -F ${mountpoint}`
      for item in $ENTRY
      do
        if [[ "$item" == */* ]] ; then
          do_copy_folder ${mountpoint}/${item} ${DATA_PRELOAD_DIR} &
        fi
      done
    else
      do_copy_folder ${mountpoint}/_COMMON ${DATA_PRELOAD_DIR} &

      if [ ${OP_NAME} ] ; then
        do_copy_folder ${mountpoint}/${OP_NAME} ${DATA_PRELOAD_DIR} &
      fi
    fi
    wait
  else
    do_copy_folder ${mountpoint} ${DATA_MEDIA_DIR}
  fi

  wait
  exit 0
elif [ $# -eq 2 ]; then
  mountpoint=$1
  force=$2

  log -p i -t preload_copy "preload_copy from ${mountpoint} force=${force}"

  if [[ ${force} -ne 1 ]] ; then
    exit 0
  fi

  SYSTEM_PRELOAD_DIR="/system/preload"
  DATA_PRELOAD_DIR="/data/preload"
  SYSTEM_MEDIA_DIR="/system/media/music"
  PRODUCT_MEDIA_DIR="/product/media/music"
  DATA_LG_MEDIA_DIR="/data/media/0/Preload/LG"

  if [[ "${mountpoint}" == "${SYSTEM_PRELOAD_DIR}" ]] ; then
    do_copy_folder ${SYSTEM_PRELOAD_DIR}/ ${DATA_PRELOAD_DIR}/
  elif [ "${mountpoint}" == "${SYSTEM_MEDIA_DIR}" ] || [ "${mountpoint}" == "${PRODUCT_MEDIA_DIR}" ] ; then
    do_copy_folder ${mountpoint}/ ${DATA_LG_MEDIA_DIR}/
  else
    log -p i -t preload_copy "preload_copy from undefined ${mountpoint} force=${force}"
  fi

  wait
  exit 0
else
  log -p e -t preload_copy "Usage: preload_copy.sh <system_other-mount-point> <force_flag:optional>"
  exit 1
fi
