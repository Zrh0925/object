#!/bin/bash
# TodoList 一键部署脚本（在阿里云服务器上执行）
set -e

cd /root/todolist || {
  echo "目录 /root/todolist 不存在，请先 git clone"
  exit 1
}

echo ">>> 拉取最新代码"
git pull

echo ">>> 重新构建并启动容器"
docker compose up --build -d

echo ">>> 清理旧镜像"
docker image prune -f

echo "部署完成"
