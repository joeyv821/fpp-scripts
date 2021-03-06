#!/bin/sh

PLATFORM=$(cat /etc/fpp/platform)

if [ "x${PLATFORM}" != "xRaspberry Pi" ]
then
	echo "ERROR: This script only works on the Raspberry Pi SD image"
	exit
fi

echo "Creating /etc/init.d/overlayroot init script"
cat <<-EOF | sudo tee /etc/init.d/overlayroot > /dev/null
#!/bin/sh
### BEGIN INIT INFO
# Provides:          overlayroot
# Required-Start:    \$hostname
# Required-Stop:
# Should-Start:
# Default-Start:     S
# Default-Stop:
# Short-Description: FPP OS image read-only root initialization
# Description:       FPP OS image read-only root initialization
### END INIT INFO
#########################################################################
# /etc/init.d/overlayroot: setup overlayfs on read-only root
#########################################################################


export PATH=/bin:/usr/bin:/usr/sbin:/sbin

mount -t tmpfs tmpfs /etc.rw

mkdir /etc.rw/work
mkdir /etc.rw/upper

mount -t overlay -o lowerdir=/etc.ro,upperdir=/etc.rw/upper,workdir=/etc.rw/work overlay /etc

EOF

echo "Marking /etc/init.d/overlayroot executable"
sudo chmod 755 /etc/init.d/overlayroot

echo "Activating /etc/init.d/overlayroot init script"
sudo update-rc.d overlayroot defaults

echo "Adding 'fastboot ro' to kernel boot arguments"
sudo sed -i -e "s/ fastboot ro$//" /boot/cmdline.txt
sudo sed -i -e "s/$/ fastboot ro/" /boot/cmdline.txt

echo "Updating /etc/fstab to mount root and /boot read-only"
sudo sed -i -e "s/vfat.*defaults/vfat    ro,defaults/" /etc/fstab
sudo sed -i -e "s/ext4.*defaults/ext4    ro,defaults/" /etc/fstab

echo "Making /etc.ro and /etc.rw directories for overlay filesystem"
sudo mkdir /etc.ro
sudo mkdir /etc.rw

echo "Copying contents of /etc to /etc.ro for underlay"
sudo rsync -a /etc/ /etc.ro/

echo "============================================================================="
echo "Setup complete, you will need to reboot the Pi for the changes to take effect"
echo "This script will self-delete to prevent re-running."
echo "============================================================================="

sudo rm -f /home/fpp/media/scripts/ConvertPiRootToReadOnly.sh

