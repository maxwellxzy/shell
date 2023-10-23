#!/bin/bash
# 定义钉钉机器人的webhook地址
webhook="https://oapi.dingtalk.com/robot/send?access_token=your_access_token"
msg=`tail /home/maxwell/auto/bwh_access.log -n 1`
  # 调用curl命令发送消息到钉钉机器人
  curl $webhook \
 -H 'Content-Type: application/json' \
 -d "{\"msgtype\": \"text\",\"text\": {\"content\":\"BWH:$msg\"}}"
