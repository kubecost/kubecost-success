# Kubecost Grafana — Local Deployment (Podman)

Spin up a local Grafana instance with all four Kubecost dashboards pre-loaded, the required plugins installed, and the Infinity datasource pre-configured against `https://demo.kubecost.xyz`.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| [Podman](https://podman.io/docs/installation) v4+ | `podman --version` |
| Grafana v13.1 image | Pulled automatically on first run (`grafana:13.1`) |
| [podman-compose](https://github.com/containers/podman-compose) | `pip install podman-compose` or install via your package manager |

> **Docker alternative:** The same `podman-compose.yaml` works with `docker compose` if you prefer Docker — no changes required.

---

## Directory structure

```
grafana/
├── dashboards/                          # Dashboard JSON files (source)
│   ├── kubecost-cost-overview.json
│   ├── kubecost-cluster-namespace-efficiency.json
│   ├── kubecost-period-over-period.json
│   └── kubecost-workload-usage-requests.json
└── deployment/
    ├── podman-compose.yaml
    ├── README.md                        # ← you are here
    └── provisioning/
        ├── dashboards/
        │   └── kubecost.yaml            # Tells Grafana where to load dashboards from
        └── datasources/
            └── kubecost-demo.yaml       # Infinity datasource → demo.kubecost.xyz
```

---

## Quick start

Run all commands from the **`grafana/deployment/`** directory.

```bash
cd grafana/deployment

# Start Grafana (pulls the image on first run, installs plugins on startup)
podman-compose up -d

# Follow logs to watch plugin installation progress
podman logs -f kubecost-grafana
```

Once you see `HTTP Server Listen` in the logs, open **http://localhost:3000** in your browser.

No login is required — anonymous access is enabled with Admin privileges so you can explore and edit freely.

---

## What's provisioned automatically

| Item | Detail |
|---|---|
| **Plugins** | `yesoreyeram-infinity-datasource`, `marcusolsson-treemap-panel` |
| **Datasource** | Infinity datasource named `Kubecost_Data_Source`, base URL `https://demo.kubecost.xyz` |
| **Dashboards** | All four dashboards loaded into a `Kubecost` folder |

> **Note:** The dashboard JSON files use the Grafana v13 CRD envelope format (`apiVersion`/`kind`/`spec`). The `kubernetesClientDashboardsFolders` feature toggle is enabled in `podman-compose.yaml` so the file provisioner can parse this format correctly. Without it, Grafana raises "Dashboard title cannot be empty".

Dashboards are mounted read-only from `../dashboards/` so any edits to the JSON source files are reflected on container restart without rebuilding.

---

## Stopping and cleaning up

```bash
# Stop the container
podman-compose down

# Remove the container and any anonymous volumes
podman-compose down -v
```

---

## Pointing at a different Kubecost instance

Edit [`provisioning/datasources/kubecost-demo.yaml`](provisioning/datasources/kubecost-demo.yaml) and change the `baseUrl`:

```yaml
jsonData:
  baseUrl: http://<your-kubecost-host>:<port>
```

Then restart:

```bash
podman-compose down && podman-compose up -d
```

If your Kubecost instance requires authentication, add the relevant fields under `jsonData` / `secureJsonData`.  
See the [Infinity datasource docs](https://grafana.com/grafana/plugins/yesoreyeram-infinity-datasource/) for the full list of auth options.

---

## Persisting dashboard edits

By default, changes made in the Grafana UI are not persisted (the container is stateless). To persist changes, add a named volume to `podman-compose.yaml`:

```yaml
services:
  grafana:
    ...
    volumes:
      - grafana-data:/var/lib/grafana
      - ../dashboards:/var/lib/grafana/dashboards:ro,z
      - ./provisioning:/etc/grafana/provisioning:ro,z

volumes:
  grafana-data:
```

> **Note:** If you add a `grafana-data` volume you will need to remove it explicitly (`podman volume rm grafana-data`) to start completely fresh.
