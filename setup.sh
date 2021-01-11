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

curl -o /usr/local/bin/update-config.sh https://raw.githubusercontent.com/lingwooc/hetzner-cloud-init/master/update-config.sh
chmod +x /usr/local/bin/update-config.sh

cat <<EOF >> /etc/crontab
* * * * * root /usr/local/bin/update-config.sh --hcloud-token ${TOKEN} --port ${PORT}
EOF
apt-add-repository ppa:ansible/ansible -y
apt install ansible ufw gettext-base fail2ban -y
ansible-galaxy collection install community.general

ufw allow from 10.0.0.2
