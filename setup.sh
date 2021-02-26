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
*/5 * * * * root /usr/local/bin/update-config.sh --hcloud-token ${TOKEN} --port ${PORT}
EOF

mkdir -p /etc/docker/
echo -e '{
  "log-driver": "local"
}' > /etc/docker/daemon.json

yes | ufw enable
ufw allow from 10.0.0.0/16
&/usr/local/bin/update-config.sh