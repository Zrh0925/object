# Docker 容器化部署方案

## 概述

将 TodoList 应用（Vue 3 + Express + MySQL）以 Docker Compose 方式部署到阿里云 Ubuntu 服务器，通过 GitHub Actions 实现 `git push` 自动部署。

## 架构

```
git push main
      │
GitHub Actions (appleboy/ssh-action)
      │
      ▼ SSH
阿里云 Ubuntu 服务器
  ┌─ docker compose up --build -d ─────────────┐
  │                                             │
  │  todolist-client (nginx:alpine, port 80)    │
  │      │ /api/ → http://server:3000           │
  │  todolist-server (node:20-alpine, port 3000)│
  │      │ DB_HOST=mysql                         │
  │  todolist-mysql  (mysql:8.0, port 3306)     │
  │                                             │
  └─────────────────────────────────────────────┘
```

## 组件

| 服务 | 容器名 | 构建方式 | 基础镜像 |
|------|--------|----------|----------|
| 前端 | todolist-client | 多阶段构建 | nginx:alpine |
| 后端 | todolist-server | Dockerfile | node:20-alpine |
| 数据库 | todolist-mysql | 直接拉取 | mysql:8.0 |

## 文件清单

| 文件 | 说明 | 状态 |
|------|------|------|
| `server/Dockerfile` | 后端容器镜像 | 新建 |
| `client/Dockerfile` | 前端多阶段构建 + Nginx | 新建 |
| `deploy/nginx/default.conf` | Docker 版 Nginx 配置 | 新建 |
| `docker-compose.yml` | 完整编排（替换现有） | 修改 |
| `.github/workflows/deploy.yml` | CI/CD 自动部署 | 新建 |
| `.env` | 数据库密码（仅存服务器） | 新建（服务器本地） |

## GitHub Secrets

| Secret 名 | 用途 |
|-----------|------|
| `SERVER_HOST` | 阿里云公网 IP |
| `SERVER_SSH_KEY` | SSH 私钥 |

## 部署流程

1. 服务器首次配置：装 Docker → 克隆代码 → 创建 `.env` → `docker compose up -d`
2. 日常开发：`git push main` → GitHub Actions SSH 登录 → `git pull` → `docker compose up --build -d`
3. 不依赖外部镜像仓库，代码在服务器直接编译构建

## MySQL 数据持久化

使用 Docker 命名卷 `mysql_data`，容器销毁数据不丢失。
