#!/bin/bash
#Path to megacli
MEGACLI="/opt/MegaRAID/MegaCli/MegaCli64"
NAMESPACE="megacli"
#Adapter
ADP_OUT=`$MEGACLI -AdpAllInfo -aALL -NoLog| grep -E "(^Adapter|Virtual Drives|Degraded|  Offline|Physical Devices|Disks|Critical Disks|Failed Disks)"`
#All about disks
VD_PDID_ERRORS=`$MEGACLI -ldpdinfo -aALL -NoLog| grep -E "(Id|State  |Media Error|Firmware state)"`
#Battery info
BBU_OUT=`$MEGACLI -AdpBbuCmd -aAll -NoLog| grep -E "(BBU status for Adapter|^Voltage|^Current|Battery State|Battery Replacement required|^Remaining Capacity|^Full Charge Capacity|^Max Error)"`

adapter=0

bat_voltage=()
bat_amp=()
bat_state=()
bat_replacment=()
bat_remaining_cap=()
bat_full_cap=()
bat_max_error=()

adp_vd_count=()
adp_vd_degraded=()
adp_vd_offline=()
adp_pd_count=()
adp_pd_disks=()
adp_pd_critical_disks=()
adp_pd_failed_disks=()


while read bbu_line
do
    exp="$(expr match "$bbu_line" '^BBU status for Adapter:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adapter=$exp
        continue
    fi

    exp="$(expr match "$bbu_line" '^Voltage:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        bat_voltage[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$bbu_line" '^Current:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        bat_amp[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$bbu_line" '^Battery State:[[:blank:]]*\([[:alpha:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        if [[ $exp == "Optimal" ]]
        then
            bat_state[$adapter]=1
        else
            bat_state[$adapter]=0
        fi
        continue
    fi

    exp="$(expr match "$bbu_line" 'Battery Replacement required[[:blank:]]*:[[:blank:]]*\([[:alpha:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        if [[ $exp == "No" ]]
        then
            bat_replacment[$adapter]=0
        else
            bat_replacment[$adapter]=1
        fi
        continue
    fi

    exp="$(expr match "$bbu_line" '^Remaining Capacity:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        bat_remaining_cap[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$bbu_line" '^Full Charge Capacity:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        bat_full_cap[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$bbu_line" '^Max Error =[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        bat_max_error[$adapter]=$exp
        continue
    fi
done <<< "${BBU_OUT}"


while read adp_line
do
    exp="$(expr match "$adp_line" '^Adapter #[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adapter=$exp
        continue
    fi

    exp="$(expr match "$adp_line" '^Virtual Drives[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_vd_count[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$adp_line" 'Degraded[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_vd_degraded[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$adp_line" 'Offline[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_vd_offline[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$adp_line" '^Physical Devices[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_pd_count[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$adp_line" 'Disks[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_pd_disks[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$adp_line" 'Critical Disks[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_pd_critical_disks[$adapter]=$exp
        continue
    fi

    exp="$(expr match "$adp_line" 'Failed Disks[[:blank:]]*:[[:blank:]]*\([[:digit:]]\+\).*')"
    if [ -n "${exp}" ]
    then
        adp_pd_failed_disks[$adapter]=$exp
        continue
    fi

done <<< "${ADP_OUT}"


printBBU() {
    echo "# HELP ${NAMESPACE}_bbu_voltage BBU Voltage mV."
    echo "# TYPE ${NAMESPACE}_bbu_voltage gauge"
    for index in ${!bat_voltage[*]}
    do
        echo "${NAMESPACE}_bbu_voltage{adapter=\"${index}\"} ${bat_voltage[$index]}"
    done

    echo "# HELP ${NAMESPACE}_bbu_amp_current BBU Current mA."
    echo "# TYPE ${NAMESPACE}_bbu_amp_current gauge"
    for index in ${!bat_amp[*]}
    do
        echo "${NAMESPACE}_bbu_amp_current{adapter=\"${index}\"} ${bat_amp[$index]}"
    done

    echo "# HELP ${NAMESPACE}_bbu_bat_state Battery State."
    echo "# TYPE ${NAMESPACE}_bbu_bat_state gauge"
    for index in ${!bat_state[*]}
    do
        echo "${NAMESPACE}_bbu_bat_state{adapter=\"${index}\"} ${bat_state[$index]}"
    done

    echo "# HELP ${NAMESPACE}_bbu_bat_replacment Battery needs to be replaced."
    echo "# TYPE ${NAMESPACE}_bbu_bat_replacment gauge"
    for index in ${!bat_replacment[*]}
    do
        echo "${NAMESPACE}_bbu_bat_replacment{adapter=\"${index}\"} ${bat_replacment[$index]}"
    done

    echo "# HELP ${NAMESPACE}_bbu_remaining_cap BBU Remaining Capacity mAh."
    echo "# TYPE ${NAMESPACE}_bbu_remaining_cap gauge"
    for index in ${!bat_remaining_cap[*]}
    do
        echo "${NAMESPACE}_bbu_remaining_cap{adapter=\"${index}\"} ${bat_remaining_cap[$index]}"
    done

    echo "# HELP ${NAMESPACE}_bbu_full_cap BBU Full Charge Capacity mAh."
    echo "# TYPE ${NAMESPACE}_bbu_full_cap gauge"
    for index in ${!bat_full_cap[*]}
    do
        echo "${NAMESPACE}_bbu_full_cap{adapter=\"${index}\"} ${bat_full_cap[$index]}"
    done

    echo "# HELP ${NAMESPACE}_bbu_max_error Battery Max Error percent."
    echo "# TYPE ${NAMESPACE}_bbu_max_error gauge"
    for index in ${!bat_max_error[*]}
    do
        echo "${NAMESPACE}_bbu_max_error{adapter=\"${index}\"} ${bat_max_error[$index]}"
    done
}

printADP() {
    echo "# HELP ${NAMESPACE}_adp_vd_count Adapter Virtual Drives count."
    echo "# TYPE ${NAMESPACE}_adp_vd_count gauge"
    for index in ${!adp_vd_count[*]}
    do
        echo "${NAMESPACE}_adp_vd_count{adapter=\"${index}\"} ${adp_vd_count[$index]}"
    done

    echo "# HELP ${NAMESPACE}_adp_vd_degraded_count Adapter Virtual Drives Degraded count."
    echo "# TYPE ${NAMESPACE}_adp_vd_degraded_count gauge"
    for index in ${!adp_vd_degraded[*]}
    do
        echo "${NAMESPACE}_adp_vd_degraded_count{adapter=\"${index}\"} ${adp_vd_degraded[$index]}"
    done

    echo "# HELP ${NAMESPACE}_adp_vd_offline_count Adapter Virtual Drives Offline count."
    echo "# TYPE ${NAMESPACE}_adp_vd_offline_count gauge"
    for index in ${!adp_vd_offline[*]}
    do
        echo "${NAMESPACE}_adp_vd_offline_count{adapter=\"${index}\"} ${adp_vd_offline[$index]}"
    done

    echo "# HELP ${NAMESPACE}_adp_pd_count Adapter Physical Devices count."
    echo "# TYPE ${NAMESPACE}_adp_pd_count gauge"
    for index in ${!adp_pd_count[*]}
    do
        echo "${NAMESPACE}_adp_pd_count{adapter=\"${index}\"} ${adp_pd_count[$index]}"
    done

    echo "# HELP ${NAMESPACE}_adp_pd_disks_count Adapter Physical Disks count."
    echo "# TYPE ${NAMESPACE}_adp_pd_disks_count gauge"
    for index in ${!adp_pd_disks[*]}
    do
        echo "${NAMESPACE}_adp_pd_disks_count{adapter=\"${index}\"} ${adp_pd_disks[$index]}"
    done

    echo "# HELP ${NAMESPACE}_adp_pd_critical_disks_count Adapter Physical Critical Disks count."
    echo "# TYPE ${NAMESPACE}_adp_pd_critical_disks_count gauge"
    for index in ${!adp_pd_critical_disks[*]}
    do
        echo "${NAMESPACE}_adp_pd_critical_disks_count{adapter=\"${index}\"} ${adp_pd_critical_disks[$index]}"
    done

    echo "# HELP ${NAMESPACE}_adp_pd_failed_disks_count Adapter Physical Failed Disks count."
    echo "# TYPE ${NAMESPACE}_adp_pd_failed_disks_count gauge"
    for index in ${!adp_pd_failed_disks[*]}
    do
        echo "${NAMESPACE}_adp_pd_failed_disks_count{adapter=\"${index}\"} ${adp_pd_failed_disks[$index]}"
    done
}

printBBU
printADP
