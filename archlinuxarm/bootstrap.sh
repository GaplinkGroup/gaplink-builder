#!/usr/bin/sh

SH_COM=$(cd "${0%/*}";pwd)/$(basename $0)
readlink $SH_COM >/dev/null 2>&1
if [ $? -eq 0 ];then
    R_SH_COM=$(readlink $SH_COM)
    BASE_DIR=${R_SH_COM%/*}
else
    BASE_DIR=${SH_COM%/*}
fi
cd $BASE_DIR

SOURCE_ROOT=../gaplink-core/root
BOOTSTRAP_ROOT=../
GAPLINK_UI=../gaplink-ui

# TODO: check network

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

/usr/bin/curl -L -o gaplink-core.tar.gz https://github.com/GaplinkGroup/gaplink-core/archive/master.tar.gz
/usr/bin/curl -L -o gaplink-ui.tar.gz https://github.com/GaplinkGroup/gaplink-ui/archive/master.tar.gz
/usr/bin/tar xf gaplink-core.tar.gz
/usr/bin/tar xf gaplink-ui.tar.gz
/bin/rm -rf ../gaplink-core
/bin/rm -rf ../gaplink-ui
/bin/mv gaplink-core-master ../gaplink-core
/bin/mv gaplink-ui-master ../gaplink-ui


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

# enable service
systemctl enable systemd-networkd-wait-online.service
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
