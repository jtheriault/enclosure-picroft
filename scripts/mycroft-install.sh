#!/usr/bin/env bash
function message () {
  MSG_HEAD=" [msg]: "
  echo ${MSG_HEAD} $1
}

message "Enable running apt under qemu"
sudo cat <<EOF > /etc/ld.so.preload
#$(cat /etc/ld.so.preload)
EOF

message "Downloading and installing repo signing key from keyserver"
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F3B1AA8B
echo "deb http://repo.mycroft.ai/repos/apt/debian debian main" > /etc/apt/sources.list.d/repo.mycroft.ai.list

message "Installing mycroft-core and it's dependencies."
apt-get update && apt-get install mycroft-core -y
apt-get install -y

message "Adding crontab entry to check for mycroft-core and mimic updates every day at midnight"
echo "PATH=/usr/bin:/bin:/usr/sbin:/sbin" > /tmp/currentcron
echo "00 * * * *  /usr/bin/apt-get update  >> /var/log/mycroft-update.log  && /usr/bin/apt-get install --only-upgrade mycroft-core mimic -y  >> /var/log/mycroft-update.log" >> /tmp/currentcron
crontab /tmp/currentcron
rm /tmp/currentcron

message "Restore non-qemu settings"
sudo cat <<EOF > /etc/ld.so.preload
$(cat /etc/ld.so.preload | cut -d '#' -f2)
EOF
