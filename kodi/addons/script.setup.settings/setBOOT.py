# -*- coding: utf-8 -*-
import xbmc
import xbmcgui
import os
import subprocess

nandscript = '/usr/bin/setboot'
if os.path.exists(nandscript):
    # 创建确认对话框
    dialog = xbmcgui.Dialog()
    result = dialog.yesno('默认启动系统设置', '是否要进入默认启动系统设置？')
    if result:
        try:
            xbmc.executebuiltin('Notification(设置, 开机默认启动)')
            #os.system('chmod +x /usr/bin/setboot')
            subprocess.call('/usr/bin/setboot')
            xbmc.sleep(2000)  # 暂停 2 秒，注意这里用 xbmc.sleep，单位是毫秒
            # xbmc.executebuiltin('Powerdown')
        except Exception as e:
            xbmc.executebuiltin(f'Notification(错误, 执行脚本时出错: {str(e)})')

CE = '/tmp/ce'
if os.path.exists(CE):
    dialog = xbmcgui.Dialog()
    result = dialog.yesno('默认启动系统设置', '当前默认启动为安卓系统，是否要更改为默认启动为影院系统？')
    if result:
        try:
            xbmc.executebuiltin('Notification(开机默认启动影院系统, 设置成功)')
            os.remove(CE)
        except Exception as e:
            xbmc.executebuiltin(f'Notification(错误, 删除文件时出错: {str(e)})')
else:
    dialog = xbmcgui.Dialog()
    result = dialog.yesno('默认启动系统设置', '当前默认启动为影院系统，是否要更改为默认启动安卓系统？')
    if result:
        xbmc.executebuiltin('Notification(开机默认启动安卓系统, 设置成功)')

