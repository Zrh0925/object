# Docker 容器化部署实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 TodoList 应用从 PM2/Nginx 直装迁移到 Docker Compose，通过 GitHub Actions 自动部署到阿里云 Ubuntu 服务器

**Architecture:** 三容器架构（frontend Nginx + backend Node + MySQL），服务器本地构建，不依赖外部镜像仓库

**Tech Stack:** Docker Compose, Nginx Alpine, Node 20 Alpine, MySQL 8.0, GitHub Actions

---

## 文件结构

| 操作 | 文件 | 职责 |
|------|------|------|
| 新建 | `server/Dockerfile` | Node 后端容器：安装依赖、tsx 直接运行源码 |
| 新建 | `client/Dockerfile` | 前端容器：Vite 构建 → Nginx 托管 |
| 新建 | `deploy/nginx/default.conf` | Nginx 容器配置：静态文件 + /api/ 反代 |
| 修改 | `docker-compose.yml` | 完整编排：mysql + server + client 三服务 |
| 新建 | `.github/workflows/deploy.yml` | CI/CD：SSH 连服务器 → git pull → docker compose up --build -d |

### Task 1: 创建后端 Dockerfile

**文件:** 新建 `server/Dockerfile`

- [ ] **创建 server/Dockerfile**

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npx", "tsx", "src/index.ts"]
```

- [ ] **验证内容写入正确**

### Task 2: 创建前端 Dockerfile

**文件:** 新建 `client/Dockerfile`

- [ ] **创建 client/Dockerfile**

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf
```

- [ ] **验证内容写入正确**

### Task 3: 创建 Nginx 容器配置

**文件:** 新建 `deploy/nginx/default.conf`

- [ ] **创建 Nginx 配置文件**

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://server:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### Task 4: 更新 docker-compose.yml

**文件:** 修改 `docker-compose.yml`

- [ ] **替换 docker-compose.yml 内容**

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: todolist-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: todolist
      MYSQL_USER: todolist
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 5s
      retries: 10

  server:
    build: ./server
    container_name: todolist-server
    restart: unless-stopped
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      PORT: 3000
      DB_HOST: mysql
      DB_PORT: 3306
      DB_USER: todolist
      DB_PASSWORD: ${MYSQL_PASSWORD}
      DB_NAME: todolist

  client:
    build: ./client
    container_name: todolist-client
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - server

volumes:
  mysql_data:
```

- [ ] **确认旧内容已替换、格式正确**

### Task 5: 创建 GitHub Actions 工作流

**文件:** 新建 `.github/workflows/deploy.yml`

- [ ] **创建 deploy.yml**

```yaml
name: 部署

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: SSH 登录服务器并部署
        uses: appleboy/ssh-action@v1.2.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: root
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /root/todolist
            git pull
            docker compose up --build -d
            docker image prune -f
```

### Task 6: 最终检查

- [ ] `server/Dockerfile` 是否存在、内容正确
- [ ] `client/Dockerfile` 是否存在、内容正确
- [ ] `deploy/nginx/default.conf` 是否存在、Nginx 反代地址为 `http://server:3000`
- [ ] `docker-compose.yml` 是否包含三服务（mysql/server/client）
- [ ] `.github/workflows/deploy.yml` 是否存在、Secret 名是否匹配
- [ ] `.gitignore` 是否已包含 `.env`（当前已有，无需修改）

### Task 7: 提交

- [ ] **git add & commit**

```bash
git add server/Dockerfile client/Dockerfile deploy/nginx/default.conf docker-compose.yml .github/workflows/deploy.yml
git commit -m "feat: Docker 容器化部署 + GitHub Actions CI/CD"
```
