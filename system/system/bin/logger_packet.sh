#!/system/bin/sh

source check_data_mount.sh
log_to_data_partition=`is_ext4_f2fs_data_partition`

ro_build_ab_update=`getprop ro.build.ab_update`
if [ "$ro_build_ab_update" = "true" ]; then
tmp_log_path="mnt/product/els"
else
tmp_log_path="cache"
fi

packet_log_prop=`getprop persist.product.lge.data.packet.enable`

touch /data/logger/packet.pcap
chmod 0644 /data/logger/packet.pcap

optionC="-C20"

storage_low_prop=`getprop persist.product.lge.service.logger.low`

if [ "$radio_log_prop" = "3"]; then
    if [ "$storage_low_prop" = "1" ]; then
        optionC="-C2"
    fi
fi

if test "2" -eq "$packet_log_prop"
then
  optionSize="-s200"
else
  optionSize="-s0"
fi

if test "$packet_log_prop" -ge "1"
then
    if [[ $log_to_data_partition == 1 ]]; then
        touch /data/logger/encryption_log/packet.pcap00
        chmod 0644 /data/logger/encryption_log/packet.pcap00
        move_log "/data/logger/encryption_log/packet.pcap00" "/${tmp_log_path}/encryption_log/packet.pcap00"
        # 2013-08-08 hobbes.song@lge.com LGP_DATA_TOOL_TCPDUMP  @ver2[START]
        build_type=`getprop ro.build.type`
        case "$build_type" in
                "user")
                    /system/bin/tcd -i any $optionC -W 10 -Z root $optionSize -w /data/logger/packet.pcap
                ;;
        esac
        case "$build_type" in
                "eng" | "userdebug")
                    /system/bin/tcpdump -i any $optionC -W 10 -Z root $optionSize -w /data/logger/packet.pcap
                ;;
        esac
        # 2013-08-08 hobbes.song@lge.com LGP_DATA_TOOL_TCPDUMP  @ver2[END]
    else
        touch /${tmp_log_path}/encryption_log/packet.pcap
        chmod 0644 /${tmp_log_path}/encryption_log/packet.pcap
        # 2013-08-08 hobbes.song@lge.com LGP_DATA_TOOL_TCPDUMP  @ver2[START]
        build_type=`getprop ro.build.type`
        case "$build_type" in
                "user")
                    /system/bin/tcd -i any $optionC -W 10 -Z root $optionSize -w /${tmp_log_path}/encryption_log/packet.pcap
                ;;
        esac
        case "$build_type" in
                "eng" | "userdebug")
                    /system/bin/tcpdump -i any $optionC -W 10 -Z root $optionSize -w /${tmp_log_path}/encryption_log/packet.pcap
                ;;
        esac
        # 2013-08-08 hobbes.song@lge.com LGP_DATA_TOOL_TCPDUMP  @ver2[END]
    fi
fi
