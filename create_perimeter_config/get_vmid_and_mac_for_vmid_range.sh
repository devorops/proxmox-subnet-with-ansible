#!/bin/sh
source ./ini_parser.sh

SERVER=alchemy4
USERNAME=root@pam
NODE=alchemy4
PASSWORD=******
FROM_VMID=6000
TO_VMID=6006
SUBNET_NAME="Testnet"
SUBNET_MASK=255.255.255.240
INVENTORY_DIR="some-path/inventory/Testnet/"

while [[ $# > 0 ]]; do
  key="$1"
  case $key in
    -u)
      USERNAME=$2
      shift
    ;;

    -p)
      PASSWORD=$2
      shift
    ;;

    -f)
      FROM_VMID=$2
      shift
    ;;
    
    -t)
      TO_VMID=$2
      shift
    ;;
    
    -s)  
      SERVER=$2
      shift
    ;;

    -m)
      SUBNET_MASK=$2
      shift
    ;;

    -i)
      INVENTORY_DIR=$2
      shift
    ;;

    -d)
      PLAYBOOK_DIR=$2
      shift
    ;;


    -h|--help|-?)
      echo "Usage:"
      echo "$0 [options]"
      echo " -u <username>   Username, default $USERNAME"
      echo " -p <password>   Password, default $PASSWORD"
      echo " -s <server>     Server to connect to, default $SERVER"
      echo " -f <fromVmid>   First available subnet vmid number, default $FROM_VMID"
      echo " -t <toVmid>     Last available subnet vmid number, default $TO_VMID"
      echo " -m <subnetMask> Internal subnet-mask, default $SUBNET_MASK"
      echo " -i <inventoryDir> The main inventory directory passed, default $INVENTORY_DIR"
      echo " -d <inventoryDir> The inventory dir"

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

#echo "PATH_TO_USER_INVENTORY_FILE:"$PATH_TO_USER_INVENTORY_FILE

RESPONSE=$(curl -s -k -d "username=$USERNAME&password=$PASSWORD" https://$SERVER:8006/api2/json/access/ticket)
TOKEN=$(echo $RESPONSE | jq -r .data.ticket)
NODES=$(curl -s -k https://$SERVER:8006/api2/json/nodes -b "PVEAuthCookie=$TOKEN" | jq -r '.data[].node')

for NODE in $(echo $NODES); do
  curl -s -k https://$SERVER:8006/api2/json/nodes/$NODE/qemu -b "PVEAuthCookie=$TOKEN" > /tmp/proxvm-qemu.json
  for VMID in $(cat /tmp/proxvm-qemu.json | jq -r .data[].vmid); do
    if [ $VMID -le $TO_VMID ] && [ $VMID -ge $FROM_VMID ]; then
      curl -s -k https://$SERVER:8006/api2/json/nodes/$NODE/qemu/$VMID/config -b "PVEAuthCookie=$TOKEN" > /tmp/proxvm-$VMID.json
      JSON=$(cat /tmp/proxvm-qemu.json | jq -r ".data[] | select(.vmid | tonumber | contains($VMID))") 
      NET=$(cat /tmp/proxvm-$VMID.json | jq -r .data.net0)
      HWADDR=$(echo $NET | sed -re "s/[a-zA-Z0-9]+=([a-zA-Z0-9:]+),.*/\1/g")
      #echo $VMID
      #echo "MAC:$HWADDR"
      IP=$(parse_inventory_and_get_ip_by_given_vmid -v $VMID -f $INVENTORY_DIR/user_subnet_vms)
      if [[ "$IP" = "" ]]; then
        IP=$(parse_inventory_and_get_ip_by_given_vmid -v $VMID -f $INVENTORY_DIR/subnet_templates_and_admin_vms)
      fi
      if [[ "$IP" != "" ]]; then
        echo "Creating dhcp entry with following values: MASK=$SUBNET_MASK MAC=$HWADDR IP=$IP"
        HWADDR=$(echo $HWADDR|sed 's/\(.*\)/\L\1/')
        HWADDR=$(echo $HWADDR|sed 's/://g')
        HWADDR=$(echo $HWADDR|sed 's/.\{4\}/&-/g')
        HWADDR=$(echo $HWADDR|sed 's/.$//')

        sed -i "/forbidden-ip/a\ static-bind ip-address $IP mask $SUBNET_MASK hardware-address $HWADDR" ../ansible_hpe_cw7/configs/template.cfg
      fi  
    fi
  done
done

rm -rf /tmp/proxvm-*.json
