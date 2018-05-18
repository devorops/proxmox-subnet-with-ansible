#!/bin/sh
function parse_inventory_and_get_ip_by_given_vmid {
local SECTION_NUM=0
local VARS_SECTION_NUM=0
local SECTION=""
local VALID_SECTION_TYPE=false
local VALID_VMID_SECTION=false
local LINE_NUM=0
local VMID=-1
local INVENTORY_FILE=""
local IP=""

while [[ $# > 0 ]]; do
  key="$1"
  case $key in
    -f)
      INVENTORY_FILE=$2
      shift
    ;;

    -v)
      VMID=$2
      shift
    ;;

    -h|--help|-?)
      echo "$0 [options]"
      echo " -v <vmid> Vmid marker"
      echo " -f <file> Inventory file to parse"
      exit 0
    ;;


    *)
      # unknown option
      echo "Error: unknown option $1"
      exit 1
    ;;

  esac
  shift # past argument or value
done

while read -r line || [ -n "$line" ]; do
	LINE_NUM=$((LINE_NUM+1))
	# Skip comments and empty lines
	if [ -z "$line" ] || [[ "$line" =~ ^#.* ]]; then
        	continue
       	fi

	# Do we have a section marker?
	if [[ "${line}" =~ ^\[[a-zA-Z0-9_:-]{1,}\]$ ]]; then
		VALID_SECTION_TYPE=false
		VALID_VMID_SECTION=false
		IP=""
		# Is this a 'vars' section?
		if [[ "${line}" =~ ^\[[a-zA-Z0-9_:-]{1,}\:vars\]$ ]]; then
			#echo "VALID_VARS_SECTION"
			VALID_SECTION_TYPE=true
			VARS_SECTION_NUM=$((VARS_SECTION_NUM+1))
              	fi
		# Set SECTION var to name of section (strip [ and ] from section marker)
		SECTION="${line#[}"
		SECTION="${SECTION%]}"
		SECTION_NUM=$((SECTION_NUM+1))
               	continue
	fi
        if [[ $VALID_SECTION_TYPE ]]; then
		# split line at "=" sign
	      	IFS="="
		read -r VAR VAL <<< "${line}"

                # delete spaces around the equal sign (using extglob)
                VAR="$(echo -e "${VAR}" | tr -d '[:space:]')"
		VAL="$(echo -e "${VAL}" | tr -d '[:space:]')"
                VAR=$(echo $VAR)
                if [ "$VAR" = "vmid" ] || [ "$VAR" = "ansible_host" ]; then
                        if [[ "$VAL" =~ ^\".*\"$  ]]; then
                                # remove existing double quotes
                                VAL="${VAL%\"}"
                                VAL="${VAL#\"}"
			elif [[ "$VAL" =~ ^\'.*\'$ ]]; then
                                # remove existing single quotes
                                 VAL="${VAL#\'}"
                                 VAL="${VAL%\'}"
                        fi
                fi

                if [ "$VAR" = "vmid" ] && [ $VAL -eq $VMID ]; then
			#echo "VALIM_VMID_SECTION"
			VALID_VMID_SECTION=true
#                        if [[ "$IP" -ne "" ]]; then
 #                               echo $IP
 #                               break
 #                       fi
                fi
                if [ "$VAR" = "ansible_host" ]; then
			if [ "$VALID_VMID_SECTION" = true ]; then
                                echo $VAL
				break
                        else
                                IP=$VAL
                        fi
                fi
        fi
done < $INVENTORY_FILE
}
