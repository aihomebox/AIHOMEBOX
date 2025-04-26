#!/bin/sh
version="20.5-Nexus"
source_img_name="CoreELEC-Amlogic-ng.arm-${version}-Generic"
source_img_file="${source_img_name}.img.gz"
source_img_url="https://github.com/aihomebox/AIHOMEBOX/releases/download/AIHOME/CoreELEC-Amlogic-ng.arm-20.5-Nexus-Generic.img.gz"
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

# 复制 pr 文件并赋予执行权限
pr_dest="${system_root}/usr/bin/pr"
sudo cp ${copy}/pr ${pr_dest}
if [ $? -eq 0 ]; then
    sudo chmod +x ${pr_dest}
    if [ -x ${pr_dest} ]; then
        echo "/usr/bin/pr 已成功赋予执行权限。"
    else
        echo "赋予 /usr/bin/pr 执行权限失败。"
        exit 1
    fi
else
    echo "复制 pr 文件到 /usr/bin 失败。"
    exit 1
fi

# 复制 kodi.sh 文件并赋予执行权限
kodi_sh_dest="${system_root}/usr/lib/kodi/kodi.sh"
sudo cp ${copy}/kodi.sh ${kodi_sh_dest}
if [ $? -eq 0 ]; then
    sudo chmod +x ${kodi_sh_dest}
    if [ -x ${kodi_sh_dest} ]; then
        echo "/usr/lib/kodi/kodi.sh 已成功赋予执行权限。"
    else
        echo "赋予 /usr/lib/kodi/kodi.sh 执行权限失败。"
        exit 1
    fi
else
    echo "复制 kodi.sh 文件到 /usr/lib/kodi 失败。"
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
