#!/bin/sh
version="20.5-Nexus"
source_img_name="CoreELEC-Amlogic-ng.arm-${version}-Generic"
source_img_file="${source_img_name}.img.gz"
source_img_url="https://github.com/twfjcn/CM311-1a-CoreELEC/releases/download/cm311-1a/CoreELEC-Amlogic-ng.arm-20.5-Nexus-Generic.img.gz"
target_img_prefix="CoreELEC-Amlogic-ng.arm-${version}"
target_img_name="${target_img_prefix}-E900V22C-$(date +%Y.%m.%d)"
mount_point="target"
common_files="common-files"
system_root="SYSTEM-root"
copy="copy"


etc_path="${system_root}/etc"
autostart_path="${system_root}/usr/bin"
modules_load_path="${system_root}/usr/lib/modules-load.d"
systemd_path="${system_root}/usr/lib/systemd/system"
libreelec_path="${system_root}/usr/lib/libreelec"
config_path="${system_root}/usr/config"
kodi_userdata="${mount_point}/.kodi/userdata"

echo "Welcome to build CoreELEC for Skyworth E900V22C!"
echo "Downloading CoreELEC-${version} generic image"
wget ${source_img_url} -O ${source_img_file} || exit 1
echo "Decompressing CoreELEC image"
gzip -d ${source_img_file} || exit 1

echo "Creating mount point"
mkdir ${mount_point}
echo "Mounting CoreELEC boot partition"
sudo mount -o loop,offset=4194304 ${source_img_name}.img ${mount_point}


echo "Decompressing SYSTEM image"
sudo unsquashfs -d ${system_root} ${mount_point}/SYSTEM



echo "Copying pr file path"
sudo cp ${copy}/pr ${system_root}/usr/bin
sudo chmod 0775 ${system_root}/usr/bin/pr


echo "Copying kodi.sh file path"
sudo cp ${copy}/kodi.sh ${system_root}/usr/lib/kodi
sudo chmod 0775 ${system_root}/usr/lib/kodi/kodi.sh




# 赋予 /usr/bin/pr 文件执行权限
sudo chmod +x ${system_root}/usr/bin/pr

# 检查权限是否设置成功
if [ -x ${system_root}/usr/bin/pr ]; then
    echo "/usr/bin/pr 已成功赋予执行权限。"
else
    echo "赋予 /usr/bin/pr 执行权限失败。"
    exit 1
fi

# 赋予 /usr/bin/updatecheck 文件执行权限
sudo chmod +x ${system_root}/usr/lib/kodi/kodi.sh

# 检查权限是否设置成功
if [ -x ${system_root}/usr/lib/kodi/kodi.sh ]; then
    echo "/usr/lib/kodi/kodi.sh 已成功赋予执行权限。"
else
    echo "赋予 /usr/lib/kodi/kodi.sh 执行权限失败。"
    exit 1
fi



echo "Compressing SYSTEM image"
sudo mksquashfs ${system_root} SYSTEM -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 -b 524288 -no-xattrs
echo "Replacing SYSTEM image"
sudo rm ${mount_point}/SYSTEM.md5
sudo dd if=/dev/zero of=${mount_point}/SYSTEM
sudo sync
sudo rm ${mount_point}/SYSTEM
sudo mv SYSTEM ${mount_point}/SYSTEM
sudo md5sum ${mount_point}/SYSTEM > SYSTEM.md5
sudo mv SYSTEM.md5 target/SYSTEM.md5
sudo rm -rf ${system_root}

echo "Unmounting CoreELEC boot partition"
sudo umount -d ${mount_point}
echo "Mounting CoreELEC data partition"
sudo mount -o loop,offset=541065216 ${source_img_name}.img ${mount_point}


echo "Unmounting CoreELEC data partition"
sudo umount -d ${mount_point}
echo "Deleting mount point"
rm -rf ${mount_point}

echo "Rename image file"
mv ${source_img_name}.img ${target_img_name}.img
echo "Compressing CoreELEC image"
gzip ${target_img_name}.img
sha256sum ${target_img_name}.img.gz > ${target_img_name}.img.gz.sha256
