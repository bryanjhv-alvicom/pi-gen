#!/bin/bash -e

# rename old files
cp /boot/config.txt{,.old}
mv /etc/network/interfaces{.new,}

# remove bogus stuff
systemctl disable raspberrypi-net-mods sshswitch
apt-get autoremove --purge -y apt-listchanges debconf-i18n libraspberrypi-dev triggerhappy

# downgrade wireless for 5ghz
curl 'http://archive.raspberrypi.org/debian/pool/main/f/firmware-nonfree/firmware-brcm80211_20210315-3+rpt2_all.deb' -o brcm80211.deb
apt install -y --allow-downgrades ./brcm80211.deb
apt-mark hold firmware-brcm80211
rm brcm80211.deb

# boot without waiting
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_wait 1
rmdir /etc/systemd/system/dhcpcd.service.d
echo "disable_splash=1" >> /boot/config.txt

# setup gps daemon
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_serial 2
sed -i '/USBAUTO/s/true/false/' /etc/default/gpsd
sed -i '/GPSD_OPTIONS/s/"$/-n"/' /etc/default/gpsd
sed -i '/DEVICES/s#"$#/dev/serial0"#' /etc/default/gpsd
systemctl enable gpsd
# no bluetooth for faster uart
systemctl disable hciuart
echo "dtoverlay=disable-bt" >> /boot/config.txt

# setup mpu sensor
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_i2c 0
echo "dtparam=i2c1_baudrate=400000" >> /boot/config.txt
# TODO: configure more stuff here

# setup realtime clock
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_i2c 0
echo "dtparam=i2c_vc=on" >> /boot/config.txt
echo "dtoverlay=i2c-rtc,ds3231,i2c0" >> /boot/config.txt
systemctl disable fake-hwclock
apt-get autoremove --purge -y fake-hwclock

# setup can bus for fms
SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_spi 0
echo "dtoverlay=mcp2515-can0,oscillator=8000000" >> /boot/config.txt
cat >> /etc/network/interfaces.d/can0 << EOL
allow-hotplug can0
iface can0 can static
	bitrate 250000
EOL

# user home setup
pushd "/home/${FIRST_USER_NAME}"
echo "unset HISTFILE" >> .bash_aliases
# configure our custom software
mkdir -p bin etc .config/systemd/user
cat >> .config/systemd/user/pispatch.service << EOL
[Unit]
After=network.target
After=gpsd.service
StartLimitBurst=10000
StartLimitIntervalSec=1s

[Service]
Type=simple
Restart=always
ExecStart=/home/pi/bin/pispatch
EnvironmentFile=/home/pi/etc/pispatch

[Install]
WantedBy=default.target
EOL
# fix all permissions
chown -R 1000:1000 .
popd
