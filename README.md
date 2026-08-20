# 澜知语音选股

Flutter 前端与 FastAPI 渐进式选股引擎组成的一体化项目，支持自然语言选股、条件增量叠加、撤销、股票列表、K 线和技术指标展示。

## 目录

```text
.
├── backend/                 # Python 3.11 + FastAPI + AkShare
├── lib/                     # Flutter App/Web 源码
├── test/                    # Flutter Widget 测试
├── Dockerfile               # Flutter Web 多阶段构建
├── nginx.conf               # Web 静态托管与 API 反向代理
└── docker-compose.yml       # frontend + backend + MySQL + Redis
```

## Docker 一键启动

```bash
cp .env.example .env
# 在 .env 中设置 OpenAI Key 和两组不同的 MySQL 强密码
docker compose up -d --build
docker compose ps
```

首次启动后执行一批行情初始化：

```bash
docker compose exec backend python -m selection_engine.pipeline
```

生产模式下，用户筛选只读取 MySQL 中的股票快照，不会在 API 请求中调用 AkShare。后台调度器默认每 60 分钟轮转更新 200 只股票：日线以 Parquet 保存到 `stock_data` 卷，股票元数据和预计算指标保存到 MySQL。可用 `UPDATE_INTERVAL_MINUTES`、`UPDATE_BATCH_SIZE`、`DETAIL_BATCH_SIZE` 和 `REQUEST_DELAY` 调整更新速度。详情接口独立限量，避免行业资料限流拖慢 K 线更新。全市场首次补齐会跨多个批次完成，失败股票会进入后续批次重试队列。

Compose 默认使用已验证的 `build/web` 产物构建轻量 Nginx 镜像，适合网络受限服务器。需要在容器内重新编译 Flutter Web 时，可移除 `frontend.build.target: prebuilt`，Dockerfile 会执行完整 Flutter 多阶段构建。

- Web App：`http://localhost:8080/`
- FastAPI：`http://localhost:8000/`
- Swagger API 文档：`http://localhost:8000/docs`
- 健康检查：`http://localhost:8000/health`

停止服务：

```bash
docker compose down
```

## 测试

后端单元测试及端到端测试：

```bash
cd backend
python -m pytest
python e2e_test.py
```

Flutter 检查：

```bash
flutter analyze
flutter test
```

端到端脚本会启动独立 FastAPI 进程，创建 5400 只确定性模拟股票的会话，连续叠加行业、板块、周线、均线偏离和 RPS 五个条件，并验证每一步严格缩小股票池以及撤销后的恢复结果。

## API 示例

```bash
curl -X POST http://localhost:8000/api/session

curl -X POST http://localhost:8000/api/session/SESSION_ID/condition \
  -H 'Content-Type: application/json' \
  -d '{"type":"ma_cross_weekly"}'

curl -X DELETE http://localhost:8000/api/session/SESSION_ID/condition/last
```

完整请求模型和响应模型请查看 Swagger 页面 `/docs`。

## 演示页面说明

1. 首页顶部显示当前股票池数量和已应用条件标签。
2. 底部可输入自然语言条件，Android/iOS App 支持按住麦克风使用本地 Whisper tiny 识别。
3. 点击股票进入 K 线页面，可动态显示成交量、MACD、KDJ 和 RSI。
4. Web 容器通过 Nginx 将 `/api/*` 代理到 FastAPI，浏览器无需额外配置后端地址。

## 生产注意事项

- 不要提交 `.env`、OpenAI Key、服务器密码或 Android 签名文件。
- 当前 Compose 暴露 8000 端口以便调试；正式环境可移除该端口映射，仅由 Nginx 访问后端。
- Debug APK 只用于测试，上架前应配置固定 applicationId、发布签名和 HTTPS。
