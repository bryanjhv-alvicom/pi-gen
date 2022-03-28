#!/bin/bash -e

# rename old files
cp /boot/config.txt{,.old}
mv /etc/network/interfaces{.new,}

# boot without waiting
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_wait 1
rmdir /etc/systemd/system/dhcpcd.service.d
echo "disable_splash=1" >> /boot/config.txt

# no bluetooth for faster uart
systemctl disable hciuart.service
echo "dtoverlay=disable-bt" >> /boot/config.txt

# configure hardware interfaces
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_i2c 0
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_spi 0
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_serial 2
echo "dtparam=i2c1_baudrate=400000" >> /boot/config.txt

# remove bogus stuff
systemctl disable raspberrypi-net-mods.service sshswitch.service
apt-get autoremove --purge -y apt-listchanges debconf-i18n libraspberrypi-dev triggerhappy

# setup gps daemon
sed -i '/USBAUTO/s/true/false/' /etc/default/gpsd
sed -i '/GPSD_OPTIONS/s/"$/-n"/' /etc/default/gpsd
sed -i '/DEVICES/s#"$#/dev/serial0"#' /etc/default/gpsd

# some useful extras
echo "unset HISTFILE" >> "/home/${FIRST_USER_NAME}/.bash_aliases"
chown 1000:1000 "/home/${FIRST_USER_NAME}/.bash_aliases"

# downgrade wireless for 5ghz
curl 'http://archive.raspberrypi.org/debian/pool/main/f/firmware-nonfree/firmware-brcm80211_20210315-3+rpt2_all.deb' -o brcm80211.deb
apt install -y --allow-downgrades ./brcm80211.deb
apt-mark hold firmware-brcm80211
rm brcm80211.deb
