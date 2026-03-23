# MCP Helm Chart

A universal Helm chart for deploying [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers on Kubernetes. Supports two deployment modes: **direct** for MCP servers with native HTTP transport, and **proxy** for stdio-only servers wrapped by an HTTP gateway.

## TL;DR

```bash
helm repo add mcp https://javdet.github.io/mcp-helm-chart
helm install my-mcp mcp/mcp -f values.yaml
```

Or install from a local clone:

```bash
git clone https://github.com/javdet/mcp-helm-chart.git
helm install my-mcp ./mcp-helm-chart -f values.yaml
```

## Introduction

Many MCP servers only speak stdio and cannot be deployed as long-running HTTP services. This chart solves that problem by offering two modes:

| Mode | When to use | How it works |
|------|-------------|--------------|
| `direct` | The MCP server image already supports HTTP/SSE (e.g. `grafana/mcp-grafana`) | Deploys the image as-is with optional `command`/`args` overrides |
| `proxy` | The MCP server is stdio-only (e.g. `@digitalocean/mcp`, `kubernetes-mcp-server`) | Runs a Node.js sidecar with [supergateway](https://github.com/nicolo-ribaudo/supergateway)/[@michlyn/mcpgateway](https://www.npmjs.com/package/@michlyn/mcpgateway) that wraps the stdio command into Streamable HTTP |

## Prerequisites

- Kubernetes >= 1.21
- Helm >= 3.0

## Installing the Chart

```bash
helm install my-mcp mcp/mcp \
  --namespace mcp \
  --create-namespace \
  -f values.yaml
```

## Uninstalling the Chart

```bash
helm uninstall my-mcp --namespace mcp
```

## Examples

### Direct mode — Grafana MCP server

```yaml
mode: direct

image:
  repository: grafana/mcp-grafana
  tag: "v0.4.0"

containerPort: 8080

args:
  - "-t"
  - "streamable-http"
  - "--address"
  - "0.0.0.0:8080"

env:
  - name: GRAFANA_URL
    value: "https://grafana.example.com"

secret:
  enabled: true
  data:
    GRAFANA_SERVICE_ACCOUNT_TOKEN: "glsa_..."
```

### Proxy mode — DigitalOcean MCP server (stdio)

```yaml
mode: proxy

containerPort: 8080

proxy:
  gateway:
    stdioCommand: "npx -y @digitalocean/mcp --services apps,droplets,doks,networking"
    outputTransport: streamable-http
    port: 8080
    httpPath: /mcp

secret:
  enabled: true
  data:
    DIGITALOCEAN_API_TOKEN: "dop_v1_..."
```

### Proxy mode — Kubernetes MCP server (stdio)

```yaml
mode: proxy

containerPort: 8080

proxy:
  gateway:
    stdioCommand: "npx -y kubernetes-mcp-server@latest"

volumes:
  - name: kubeconfig
    secret:
      secretName: kubeconfig-secret

volumeMounts:
  - name: kubeconfig
    mountPath: /root/.kube/config
    readOnly: true
```

## Parameters

### Deployment mode

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mode` | Deployment mode: `direct` or `proxy` | `direct` |

### Common parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of pod replicas | `1` |
| `containerPort` | Port the MCP server listens on inside the container | `8080` |
| `nameOverride` | Override the chart name | `""` |
| `fullnameOverride` | Override the full release name | `""` |

### Direct mode image configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `""` |
| `image.tag` | Container image tag (immutable tags are recommended) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Registry credentials for private images | `[]` |
| `command` | Override the container entrypoint | `[]` |
| `args` | Override the container arguments | `[]` |

### Proxy mode configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `proxy.image.repository` | Proxy container image repository | `node` |
| `proxy.image.tag` | Proxy container image tag | `20-slim` |
| `proxy.image.pullPolicy` | Proxy image pull policy | `IfNotPresent` |
| `proxy.gateway.package` | NPM package used as the HTTP gateway | `@michlyn/mcpgateway` |
| `proxy.gateway.stdioCommand` | The stdio MCP command to wrap (required in proxy mode) | `""` |
| `proxy.gateway.outputTransport` | HTTP transport protocol exposed by the gateway | `streamable-http` |
| `proxy.gateway.port` | Port the gateway listens on (should match `containerPort`) | `8080` |
| `proxy.gateway.httpPath` | HTTP path for the MCP endpoint | `/mcp` |

### Environment variables

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env` | Extra environment variables injected into the container | `[]` |
| `envFrom` | Extra `envFrom` sources (configMapRef, secretRef) | `[]` |

### Secret

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secret.enabled` | Create a Secret resource and mount it via `envFrom` | `false` |
| `secret.annotations` | Annotations added to the Secret | `{}` |
| `secret.data` | Key-value pairs stored as `stringData` in the Secret | `{}` |

### Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Service port (maps to `containerPort` on the pod) | `80` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress resource creation | `false` |
| `ingress.className` | IngressClass name | `""` |
| `ingress.annotations` | Annotations for the Ingress resource | `{}` |
| `ingress.hosts` | Ingress host rules | `[]` |
| `ingress.tls` | TLS configuration for the Ingress | `[]` |

### ServiceAccount

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create a ServiceAccount resource | `true` |
| `serviceAccount.name` | Override ServiceAccount name (defaults to fullname) | `""` |
| `serviceAccount.annotations` | Annotations added to the ServiceAccount | `{}` |
| `serviceAccount.automountServiceAccountToken` | Mount the API token into pods | `true` |

### Resource management

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources` | CPU/memory resource requests and limits | `{}` |

### Probes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `probes.livenessProbe` | Liveness probe configuration | tcpSocket on port `http` |
| `probes.readinessProbe` | Readiness probe configuration | tcpSocket on port `http` |

### Volumes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `volumes` | Extra volumes to add to the pod | `[]` |
| `volumeMounts` | Extra volume mounts for the container | `[]` |

### Pod scheduling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `affinity` | Affinity rules for pod assignment | `{}` |

### HashiCorp Vault (Banzai Cloud webhook)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vault.role` | Vault role used for Kubernetes authentication | `""` |
| `vault.path` | Vault auth backend mount path | `""` |

### Pod metadata & security

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Annotations added to each pod | `{}` |
| `podLabels` | Extra labels added to each pod | `{}` |
| `podSecurityContext` | Pod-level security context | `{}` |
| `securityContext` | Container-level security context | `{}` |

## How Proxy Mode Works

In proxy mode the chart launches a `node:20-slim` container and runs:

```
npx -y @michlyn/mcpgateway \
  --stdio '<your stdioCommand>' \
  --outputTransport streamable-http \
  --port 8080 \
  --httpPath /mcp
```

The gateway spawns the stdio MCP server as a child process, translates stdio messages to/from HTTP, and exposes a Streamable HTTP endpoint that any MCP client can connect to.

## License

This project is licensed under the MIT License.
