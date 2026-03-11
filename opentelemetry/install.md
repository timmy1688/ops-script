以下是根据你**最新配置文件**重新整理的**完整、可执行的部署文档**（2025–2026 年常见实践版本）。

目标依然是：**Python 零代码注入** → OpenTelemetry Collector → Tempo（MinIO S3 后端） → Grafana 看到 trace & service graph。

### 当前环境关键信息（请对照确认）

- Kubernetes 版本 ≥ 1.24
- Helm 3 已安装
- OpenTelemetry Operator 已存在（通常在 `observability` 命名空间）
- MinIO：`10.100.10.34:9000`，bucket `tempo-traces` 已创建
- Grafana：`10.100.10.30:3000`
- Python 业务命名空间：`devops`
- Tempo / Collector 建议统一部署在 `observability` 命名空间
- 当前全部使用 http + insecure（生产必须改成 https）

### 1. Tempo 部署（单体模式）

**文件**：`tempo-values.yaml`

```yaml
tempo:
  target: singleBinary

  config:
    server:
      http_listen_port: 3200

    distributor:
      receivers:
        otlp:
          protocols:
            grpc: {}
            http: {}

    storage:
      trace:
        backend: s3
        s3:
          bucket: tempo-traces
          endpoint: 10.100.10.34:9000
          insecure: true
          access_key: minioadmin          # ← 务必替换
          secret_key: minioadmin          # ← 务必替换
        wal:
          path: /var/tempo/wal
        blocklist_poll: 5m

    overrides:
      defaults:
        metrics_generator:
          processors: [service-graphs, span-metrics]

    metrics_generator:
      registry:
        external_labels:
          source: tempo
          cluster: your-cluster-name      # ← 建议改成真实集群名

resources:
  limits:
    cpu: 2
    memory: 4Gi
  requests:
    cpu: 1
    memory: 2Gi

service:
  type: NodePort
  ports:
    http: 3200       # → NodePort 通常随机，也可手动指定 nodePort: 32000
    grpc: 4317
    http-otlp: 4318

persistence:
  enabled: false     # 生产建议改为 true + 指定 storageClass
```

**部署命令**

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install tempo grafana/tempo \
  --namespace observability --create-namespace \
  -f tempo-values.yaml
```

**快速验证**

```bash
kubectl -n observability get pods -l app.kubernetes.io/name=tempo
kubectl -n observability get svc tempo
```

### 2. OpenTelemetry Collector 部署

**文件**：`otel-collector-values.yaml`

```yaml
mode: deployment
replicaCount: 1

image:
  repository: otel/opentelemetry-collector-k8s
  tag: 0.100.0
  pullPolicy: IfNotPresent

config:
  receivers:
    otlp:
      protocols:
        grpc: {}
        http: {}

  processors:
    batch: {}
    k8sattributes:
      extract:
        metadata:
          - k8s.namespace.name
          - k8s.pod.name
          - k8s.deployment.name

  exporters:
    otlp/tempo:
      endpoint: "tempo.observability.svc.cluster.local:4317"
      tls:
        insecure: true

  service:
    telemetry:
      metrics:
        readers:
          - pull:
              exporter:
                prometheus:
                  host: "0.0.0.0"
                  port: 8889

    pipelines:
      traces:
        receivers: [otlp]
        processors: [k8sattributes, batch]
        exporters: [otlp/tempo]
```

**部署命令**

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace observability \
  -f otel-collector-values.yaml
```

**验证**

```bash
kubectl -n observability get pods -l app.kubernetes.io/name=opentelemetry-collector
kubectl -n observability logs -l app.kubernetes.io/name=opentelemetry-collector --tail=50
# 看到 "Everything is ready. Begin running and processing data." 即正常
```

### 3. Python 自动注入（核心零代码部分）

**文件**：`instrumentation-python.yaml`

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: python-auto
  namespace: devops
spec:
  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest
    env:
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        value: "http://otel-collector-opentelemetry-collector.observability.svc.cluster.local:4318"

      - name: OTEL_SERVICE_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['app']

      - name: OTEL_RESOURCE_ATTRIBUTES
        value: "k8s.namespace.name=$(OTEL_RESOURCE_ATTRIBUTES_NAMESPACE),deployment.environment=prod"

      - name: OTEL_PROPAGATORS
        value: "tracecontext,baggage"

      - name: OTEL_TRACES_SAMPLER
        value: "parentbased_traceidratio"

      - name: OTEL_TRACES_SAMPLER_ARG
        value: "0.1"          # 验证期间建议临时改成 "1.0"
```

**应用 Instrumentation**

```bash
kubectl apply -f instrumentation-python.yaml -n devops
```

**修改 Python Deployment（添加 annotation）**

```yaml
spec:
  template:
    metadata:
      annotations:
        instrumentation.opentelemetry.io/inject-python: "true"
```

然后重启 Deployment：

```bash
kubectl rollout restart deployment/<你的 deployment 名称> -n devops
```

**验证注入是否成功**

```bash
# 找一个刚重启的 pod
kubectl get pod -n devops -l app=<你的app标签> -o name | head -1 | xargs -I{} kubectl exec {} -n devops -- env | grep -i otel
```

应该能看到 `OTEL_EXPORTER_OTLP_ENDPOINT`、`OTEL_SERVICE_NAME` 等变量。

### 4. Grafana 添加 Tempo 数据源

1. 登录 Grafana → Connections → Data sources → Add data source → Tempo
2. URL 填写方式（任选其一）：

   - 测试最快：`http://localhost:3200`  
     先执行 `kubectl port-forward svc/tempo -n observability 3200:3200`

   - 推荐生产方式：通过 Ingress 或 LoadBalancer 暴露 3200 端口

3. 点击 **Save & Test** → 应显示绿色

### 5. 最终验证链路是否打通

1. 对 Python 服务发起几次请求（curl、浏览器、业务流量都可以）
2. 等待 15–90 秒
3. Grafana → Explore → 选择 Tempo 数据源
   - Service name 下拉框  → 应该能看到你 Deployment 的 `app` label 值
   - 或直接 Search traces → 看是否有数据
4. 如果看到 trace → 点开详情 → 能看到 span、service graph 即成功

### 6. 常见问题 & 生产升级方向（建议按序做）

| 优先级 | 项目                              | 当前状态          | 建议行动                                  |
|--------|-----------------------------------|-------------------|--------------------------------------------|
| ★★★★★  | 访问凭证                          | minioadmin        | 立即更换成随机强密码                       |
| ★★★★   | MinIO + Tempo TLS                 | insecure: true    | 配置证书，改 insecure: false               |
| ★★★★   | Tempo 持久化                      | persistence false | 开启 + PVC（推荐 local-path 或 longhorn）  |
| ★★★    | 采样率                            | 10%               | 验证完改回 0.1 ~ 0.25，流量大再加 tail-sampling |
| ★★★    | Collector 部署方式                | Deployment        | 流量大 → 改 DaemonSet + gateway 模式       |
| ★★     | Tempo 服务暴露                    | NodePort          | 改 Ingress（带 TLS）                       |
| ★★     | 监控 Tempo & Collector            | 无                | 接入 Prometheus / VictoriaMetrics          |

如果部署过程中出现任何具体报错（pod crash、连接拒绝、没有 trace 等），请直接贴出：

- 报错组件（tempo / collector / python pod）
- 相关命令 + 输出（describe / logs / events）

我再帮你针对性定位和修复。

祝部署顺利！
