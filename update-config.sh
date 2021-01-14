#!/bin/bash

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --hcloud-token)
    TOKEN="$2"
    shift
    shift
  ;;
  --port)
    PORT="$2"
    shift
    shift
  ;;
  *)
    shift
  ;;
esac
done

ansible=$(which ansible | wc -l)
if [ "$ansible" == "0" ]
then
  echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" >> /etc/apt/sources.list
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
  apt update
  apt install ansible ufw jq gettext-base -y
  ansible-galaxy collection install community.general
fi

export PORT
curl -o - https://raw.githubusercontent.com/lingwooc/hetzner-cloud-init/master/playbook.yml | envsubst | cat > /usr/local/bin/playbook.yml
ansible-playbook /usr/local/bin/playbook.yml

NEW_NODE_IPS=( $(curl -H 'Accept: application/json' -H "Authorization: Bearer ${TOKEN}" 'https://api.hetzner.cloud/v1/servers' | jq -r '.servers[].private_net[0].ip') )

touch /etc/current_node_ips
cp /etc/current_node_ips /etc/old_node_ips
echo "" > /etc/current_node_ips

for IP in "${NEW_NODE_IPS[@]}"; do
  /usr/sbin/ufw allow in on ens10 from "$IP"
  echo "$IP" >> /etc/current_node_ips
done

IFS=$'\r\n' GLOBIGNORE='*' command eval 'OLD_NODE_IPS=($(cat /etc/old_node_ips))'

REMOVED=()
for i in "${OLD_NODE_IPS[@]}"; do
  skip=
  for j in "${NEW_NODE_IPS[@]}"; do
    [[ $i == $j ]] && { skip=1; break; }
  done
  [[ -n $skip ]] || REMOVED+=("$i")
done
declare -p REMOVED

for IP in "${REMOVED[@]}"; do
  /usr/sbin/ufw deny from "$IP"
done

curl -s https://www.cloudflare.com/ips-v4 -o /tmp/cf_ips
curl -s https://www.cloudflare.com/ips-v6 >> /tmp/cf_ips

# Allow traffic from Cloudflare IPs
for cfip in `cat /tmp/cf_ips`; do /usr/sbin/ufw allow proto tcp from $cfip to any port 443 comment 'Cloudflare IP'; done

# Self update
curl -o /usr/local/bin/update-config.sh https://raw.githubusercontent.com/lingwooc/hetzner-cloud-init/master/update-config.sh