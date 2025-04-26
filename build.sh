#!/bin/sh
version="21.2-Omega"
source_img_name="CoreELEC-Amlogic-ng.arm-${version}-Generic"
source_img_file="${source_img_name}.img.gz"
source_img_url="https://github.com/CoreELEC/CoreELEC/releases/download/${version}/${source_img_file}"
target_img_prefix="CoreELEC-Amlogic-ng.arm-${version}"
target_img_name="${target_img_prefix}-E900V22C-$(date +%Y.%m.%d)"
mount_point="target"
common_files="common-files"
system_root="SYSTEM-root"
modules_load_path="${system_root}/usr/lib/modules-load.d"
systemd_path="${system_root}/usr/lib/systemd/system"
libreelec_path="${system_root}/usr/lib/libreelec"
config_path="${system_root}/usr/config"
kodi_userdata="${mount_point}/.kodi/userdata"
copy="copy"  # 新增，指定 copy 文件夹

# Prepare functions
mount_partition() {
  img=$1
  offset=$2
  mount_point=$3
  sudo mount -o loop,offset=${offset} ${img} ${mount_point}
}
unmount_partition() {
  mount_point=$1
  sudo umount -d ${mount_point}
}
copy_with_permissions() {
  src=$1
  dest=$2
  mode=$3
  sudo cp ${src} ${dest}
  sudo chown root:root ${dest}
  sudo chmod ${mode} ${dest}
}

# Prepare Image
wget -q --show-progress ${source_img_url} -O ${source_img_file} || exit 1
gzip -d ${source_img_file} || exit 1
mkdir ${mount_point}

# Modify boot partition
mount_partition ${source_img_name}.img 4194304 ${mount_point}
sudo cp ${common_files}/e900v22c.dtb ${mount_point}/dtb.img
sudo unsquashfs -d ${system_root} ${mount_point}/SYSTEM

# 新增：复制 pr 文件并赋予执行权限
copy_with_permissions ${copy}/pr ${system_root}/usr/bin/pr 0755

# 新增：复制 kodi.sh 文件并赋予执行权限
copy_with_permissions ${copy}/kodi.sh ${system_root}/usr/lib/kodi/kodi.sh 0755

# 原脚本中对 common_files 文件夹下其他文件的操作不再执行

sudo mksquashfs ${system_root} SYSTEM -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 -b 524288 -no-xattrs
sudo rm ${mount_point}/SYSTEM.md5
sudo dd if=/dev/zero of=${mount_point}/SYSTEM
sudo sync
sudo rm ${mount_point}/SYSTEM
sudo mv SYSTEM ${mount_point}/SYSTEM
sudo md5sum ${mount_point}/SYSTEM > target/SYSTEM.md5
sudo rm -rf ${system_root}
unmount_partition ${mount_point}

# Modify data partition
mount_partition ${source_img_name}.img 541065216 ${mount_point}
sudo mkdir -p -m 0755 ${kodi_userdata}/keymaps
copy_with_permissions ${common_files}/advancedsettings.xml ${kodi_userdata}/advancedsettings.xml 0644
copy_with_permissions ${common_files}/backspace.xml ${kodi_userdata}/keymaps/backspace.xml 0644
unmount_partition ${mount_point}
rm -rf ${mount_point}

# Output Image
mv ${source_img_name}.img ${target_img_name}.img
gzip ${target_img_name}.img
