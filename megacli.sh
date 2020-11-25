#!/bin/bash
#Path to megacli
MEGACLI="/opt/MegaRAID/MegaCli/MegaCli64"
NAMESPACE="megacli"
#All about disks
VD_PDID_ERRORS=`$MEGACLI -ldpdinfo -aALL | grep -E "(Id|State  |Media Error|Firmware state)"`
#Battery info
BBU_OUT=`$MEGACLI -AdpBbuCmd -aAll | grep -E "(BBU status for Adapter|^Voltage|^Current|Battery State|Battery Replacement required|^Remaining Capacity|^Full Charge Capacity|^Max Error)"`

#echo "${BBU_OUT}"

adapter=0
bat_voltage=()
bat_amp=()
bat_state=()
bat_replacment=()
bat_remaining_cap=()
bat_full_cap=()
bat_max_error=()


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



echo "# HELP ${NAMESPACE}_bbu_voltage BBU Voltage mV."
echo "# TYPE ${NAMESPACE}_bbu_voltage gauge"
for index in ${!bat_voltage[*]}
do
    echo "${NAMESPACE}_bbu_voltage{adapter=${index}} ${bat_voltage[$index]}"
done

echo "# HELP ${NAMESPACE}_bbu_amp_current BBU Current mA."
echo "# TYPE ${NAMESPACE}_bbu_amp_current gauge"
for index in ${!bat_amp[*]}
do
    echo "${NAMESPACE}_bbu_amp_current{adapter=${index}} ${bat_amp[$index]}"
done

echo "# HELP ${NAMESPACE}_bbu_bat_state Battery State."
echo "# TYPE ${NAMESPACE}_bbu_bat_state gauge"
for index in ${!bat_state[*]}
do
    echo "${NAMESPACE}_bbu_bat_state{adapter=${index}} ${bat_state[$index]}"
done

echo "# HELP ${NAMESPACE}_bbu_bat_replacment Battery needs to be replaced."
echo "# TYPE ${NAMESPACE}_bbu_bat_replacment gauge"
for index in ${!bat_replacment[*]}
do
    echo "${NAMESPACE}_bbu_bat_replacment{adapter=${index}} ${bat_replacment[$index]}"
done

echo "# HELP ${NAMESPACE}_bbu_remaining_cap BBU Remaining Capacity mAh."
echo "# TYPE ${NAMESPACE}_bbu_remaining_cap gauge"
for index in ${!bat_remaining_cap[*]}
do
    echo "${NAMESPACE}_bbu_remaining_cap{adapter=${index}} ${bat_remaining_cap[$index]}"
done

echo "# HELP ${NAMESPACE}_bbu_full_cap BBU Full Charge Capacity mAh."
echo "# TYPE ${NAMESPACE}_bbu_full_cap gauge"
for index in ${!bat_full_cap[*]}
do
    echo "${NAMESPACE}_bbu_full_cap{adapter=${index}} ${bat_full_cap[$index]}"
done

echo "# HELP ${NAMESPACE}_bbu_max_error Battery Max Error percent."
echo "# TYPE ${NAMESPACE}_bbu_max_error gauge"
for index in ${!bat_max_error[*]}
do
    echo "${NAMESPACE}_bbu_max_error{adapter=${index}} ${bat_max_error[$index]}"
done
