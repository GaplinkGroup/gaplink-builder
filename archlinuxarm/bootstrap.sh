#!/usr/bin/sh

SOURCE_ROOT=../gaplink-core/root
BOOTSTRAP_ROOT=../
GAPLINK_UI=../gaplink-ui

# TODO: check network

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# TODO: check pacman-key --init

# prefer pacman mirror
/bin/cp -f $SOURCE_ROOT/etc/pacman.d/mirrorlist /etc/pacman.d/

# install dependency
pacman -Syy
pacman -S --noconfirm - < packages_requirements.txt
if [ $? -ne 0 ]
then
    echo "pacman install error"
    exit 1
fi

/bin/rm -f "$SOURCE_ROOT"/etc/systemd/system/multi-user.target.wants/*
/bin/rm -f "$SOURCE_ROOT"/etc/systemd/system/network-online.target.wants/*
/bin/rm -f "$SOURCE_ROOT"/etc/systemd/system/timers.target.wants/*
/bin/rm -f "$SOURCE_ROOT"/etc/fstab

/bin/rm -f /etc/systemd/network/*

chown -R root.root $SOURCE_ROOT/etc
/bin/cp -d -rf $SOURCE_ROOT/etc/* /etc/

# install gaplink-ui
/bin/rm -rf /opt/gaplink-ui
mkdir -p /opt/gaplink-ui
/bin/cp -r $GAPLINK_UI/* /opt/gaplink-ui/
bash $BOOTSTRAP_ROOT/scripts/enable_pdosqlite.sh

# install ntpclient
tar xvf $BOOTSTRAP_ROOT/ntpclient_2015_365.tar.gz
pushd ntpclient-2015
make
/bin/cp ntpclient /usr/local/bin/
chmod a+x /usr/local/bin/ntpclient
popd
rm -rf ntpclient-2015

# enable service
systemctl enable systemd-networkd-wait-online.service
systemctl enable ntpclient.timer
systemctl enable ipset.service
systemctl enable sshd.service
systemctl enable iptables.service
systemctl enable ebtables.service
systemctl enable dnsmasq.service
systemctl enable systemd-networkd.service
systemctl enable haveged.service
systemctl enable v2ray.service
systemctl enable ip6tables.service
systemctl enable gaplinkui.service



mount -o remount,noatime,nodiratime /
mount -o remount,noatime,nodiratime /boot
genfstab / | grep mmcblk >/etc/fstab

# TODO: change root password
