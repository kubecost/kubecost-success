# Actions API Specification

## Overview

The Actions API provides endpoints for managing automated cost optimization actions in Kubecost. These APIs enable configuration management, action submission, completion tracking, and health monitoring through heartbeats.

**Authentication**: All endpoints (except `/action/config/sync`) require license validation through middleware chains that validate license expiration, core limits, and node count limits.

---

## Endpoints

### 1. Check Actions Enabled Status

```
GET /action/enabled
```

Returns whether the Actions feature is enabled in the current Kubecost installation.

**Response:**
```json
{
  "code": 200,
  "data": true
}
```

---

### 2. Get All Action Configurations

```
GET /action/configs
```

Retrieves all action configurations across all scopes (global, cluster, local).

**Response:**
```json
{
  "code": 200,
  "data": [
    {
      "id": "b39c41c6-c900-4cf2-9473-fff29069492c",
      "source": "API",
      "scope": "local",
      "cluster": "all",
      "name": "production-rightsizing-nightly",
      "action": "containerRequestRightSizing",
      "config": {
        "cpu": true,
        "enabled": true,
        "exclusionWindow": "",
        "filter": "namespace:\"production\"",
        "maintenanceWindow": "* 23 * * *",
        "memory": true,
        "profile": "Development",
        "rightSizingWindow": "48h"
      }
    }
  ]
}
```

---

### 3. Get Single Action Configuration

```
GET /action/config?id=<string>
```

| Parameter | Required | Type   | Description                                    |
|-----------|----------|--------|------------------------------------------------|
| `id`      | ✓        | string | Unique identifier of the action configuration |

**Example:**
```
GET /action/config?id=550e8400-e29b-41d4-a716-446655440000
```

**Response (for Example 1):**
```json
{
  "code": 200,
  "data": {
    "id": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
    "source": "API",
    "scope": "local",
    "name": "my-rightsizing-action",
    "action": "containerRequestRightSizing",
    "config": {
      "cpu": true,
      "enabled": true,
      "exclusionWindow": "",
      "filter": "namespace:\"production\"",
      "maintenanceWindow": "* 23 * * *",
      "memory": true,
      "profile": "Development",
      "rightSizingWindow": "48h"
    }
  }
}
```

---

### 4. Create or Update Action Configuration

```
POST /action/config
```

Creates a new action configuration or updates an existing one. Configurations with `source: "helm"` cannot be modified via API.

**Request Body Example 1 (using profile):**
```json
{
  "source": "API",
  "scope": "local",
  "name": "my-rightsizing-action",
  "action": "containerRequestRightSizing",
  "config": {
    "cpu": true,
    "enabled": true,
    "exclusionWindow": "",
    "filter": "namespace:\"production\"",
    "maintenanceWindow": "* 23 * * *",
    "memory": true,
    "profile": "Development",
    "rightSizingWindow": "48h"
  }
}
```

**Request Body Example 2 (using individual parameters):**
```json
{
  "source": "API",
  "scope": "global",
  "name": "custom-rightsizing",
  "action": "containerRequestRightSizing",
  "config": {
    "cpu": true,
    "enabled": true,
    "filter": "namespace:\"staging\"",
    "memory": true,
    "rightSizingWindow": "7d",
    "algorithmCPU": "max",
    "algorithmRAM": "max",
    "quantileCPU": 0.95,
    "quantileRAM": 0.95,
    "targetUtilizationCPU": 0.8,
    "targetUtilizationRAM": 0.8,
    "minRecCPUMillicores": 10,
    "minRecRAMBytes": 10485760,
    "maintenanceWindow": "0 2 * * 0",
    "exclusionWindow": ""
  }
}
```

**Fields:**
- `id` (optional): If provided, updates existing config; if omitted, creates new config
- `source` (optional): Must be `"API"` or omitted. Cannot be `"helm"`
- `scope` (required): `"global"`, `"cluster"`, or `"local"`
- `cluster` (conditional): Required when `scope` is `"cluster"`
- `name` (optional): Human-readable name (cannot be `"system"` - reserved)
- `action` (required): Action type identifier
- `config` (required): Action-specific configuration parameters

**Supported Action Types:**
- `containerRequestRightSizing` / `rightsizing`: Container resource request optimization
- `namespaceTurndown`: Namespace shutdown automation
- `resourceQuotaRightSizing`: Resource quota optimization

**Response:**
```json
{
  "code": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "source": "API",
    "scope": "local",
    "cluster": "all",
    "name": "staging-rightsizing-weekly",
    "action": "containerRequestRightSizing",
    "config": {
      "cpu": true,
      "enabled": true,
      "exclusionWindow": "",
      "filter": "namespace:\"staging\"",
      "maintenanceWindow": "* 2 * * 0",
      "memory": true,
      "profile": "Production",
      "rightSizingWindow": "7d"
    }
  }
}
```

---

### 5. Delete Action Configuration

```
DELETE /action/config?id=<string>
```

Deletes an action configuration by ID. Configurations with `source: "helm"` or `scope: "local"` cannot be deleted via API.

| Parameter | Required | Type   | Description                                    |
|-----------|----------|--------|------------------------------------------------|
| `id`      | ✓        | string | Unique identifier of the action configuration |

**Example:**
```
DELETE /action/config?id=550e8400-e29b-41d4-a716-446655440000
```

**Response:**
```json
{
  "code": 200,
  "data": null
}
```

---

### 6. Query Completed Actions

```
GET /actions/completed?window=<string>
```

Retrieves completed actions with filtering, pagination, and time window support.

| Parameter | Required | Type    | Default | Options                                                                      |
|-----------|----------|---------|---------|------------------------------------------------------------------------------|
| `window`  | ✓        | string  | -       | `12h`, `7d`, timestamps, RFC-3339, etc.                                      |
| `type`    |          | string  | -       | `containerRequestRightSizing`, `namespaceTurndown`, `resourceQuotaRightSizing` |
| `status`  |          | string  | -       | `success` or `failure`                                                       |
| `cluster` |          | string  | -       | Cluster name                                                                 |
| `limit`   |          | integer | `0`     | integers > 0                                                                 |
| `offset`  |          | integer | `0`     | integers > 0                                                                 |

**Example:**
```
GET /actions/completed?window=7d&cluster=production&type=containerRequestRightSizing&status=success&limit=50
```

**Response:**
```json
{
  "code": 200,
  "data": {
    "totalActionsCount": 150,
    "window": {
      "start": "2025-07-18T00:00:00Z",
      "end": "2025-07-25T00:00:00Z"
    },
    "actions": [
      {
        "id": "8b01eb9b-d33b-4086-a82b-83048188556b",
        "configName": "resize test deployments",
        "cluster": "cluster-1",
        "action": "containerRequestRightSizing",
        "parameters": {
          "cluster": "cluster-1",
          "containerName": "test",
          "controllerKind": "deployment",
          "controllerName": "test",
          "lastCPURequest": "1000m",
          "lastRAMRequest": "500Mi",
          "namespace": "kubecost",
          "targetCPURequest": "500m",
          "targetRAMRequest": "200Mi"
        },
        "status": "failure",
        "errors": [
          "error1",
          "error2"
        ],
        "createdAt": "2025-07-18T14:00:00Z",
        "completedAt": "2025-07-18T15:00:00Z"
      },
      {
        "id": "cf23ddc4-068f-4273-bf27-b6d07768c06f",
        "configName": "turn down test namespaces",
        "cluster": "cluster-1",
        "action": "namespaceTurndown",
        "parameters": {
          "cluster": "cluster-1",
          "namespace": "test"
        },
        "status": "success",
        "createdAt": "2025-07-18T11:00:00Z",
        "completedAt": "2025-07-18T12:00:00Z"
      }
    ]
  }
}
```

---

### 7. Get Heartbeats

```
GET /action/heartbeats
```

Retrieves heartbeat records from action controllers, indicating their health and status.

| Parameter | Required | Type    | Description                                |
|-----------|----------|---------|--------------------------------------------|
| `cluster` |          | string  | Filter by cluster name                     |
| `start`   |          | string  | Start time in RFC3339 format               |
| `end`     |          | string  | End time in RFC3339 format                 |
| `limit`   |          | integer | Maximum number of results to return        |
| `offset`  |          | integer | Number of results to skip for pagination   |

**Example:**
```
GET /action/heartbeats?cluster=production&start=2024-01-01T00:00:00Z&end=2024-01-31T23:59:59Z&limit=100
```

**Response:**
```json
{
  "code": 200,
  "data": [
    {
      "timestamp": "2024-01-15T10:30:00Z",
      "metadata": {
        "status": "healthy",
        "cluster": "production",
        "version": "1.0.0",
        "actionsProcessed": 42
      }
    }
  ]
}
```

---

### 8. Get Latest Heartbeats

```
GET /action/heartbeats/latest
```

Retrieves the most recent heartbeat timestamp for each cluster.

**Response:**
```json
{
  "code": 200,
  "data": {
    "production": "2024-01-15T10:30:00Z",
    "staging": "2024-01-15T10:29:45Z",
    "development": "2024-01-15T10:28:30Z"
  }
}
```

---

## Sync Endpoints

These endpoints trigger manual synchronization of various action components. They are typically called by scheduled jobs or for manual intervention.

### 9. Sync Action Configurations

```
POST /action/config/sync
```

Manually triggers synchronization of action configurations from bucket storage to local database. **This endpoint does NOT require license middleware.**

**Response:**
```json
{
  "code": 200,
  "data": "Successfully synced config manager"
}
```

---

### 10. Submit Recommended Actions

```
POST /action/submitter/sync
```

Manually triggers the submission of recommended actions to the action queue. Normally runs on a cron schedule (every 10 minutes).

**Response:**
```json
{
  "code": 200,
  "data": "Successfully submitted actions"
}
```

---

### 11. Ingest Completed Actions

```
POST /action/ingestor/sync
```

Manually triggers ingestion of completed actions from bucket storage to local database. Normally runs on a cron schedule (every 10 minutes).

**Response:**
```json
{
  "code": 200,
  "data": "Successfully ingested completed actions"
}
```

---

### 12. Ingest Heartbeats

```
POST /action/heartbeat/sync
```

Manually triggers ingestion of heartbeats from bucket storage to local database. Normally runs on a cron schedule (every 5 minutes).

**Response:**
```json
{
  "code": 200,
  "data": "Action Service: successfully ingested heartbeats"
}
```

---

### 13. Get action runs

```
GET /actions/runs?window=<string>
```

Retrieves a list of action runs. An 'action run' represents the outcome of one scheduled execution of an action configuration.

| Parameter | Required | Type    | Default | Description                                     |
|-----------|----------|---------|---------|-------------------------------------------------|
| `window`  | ✓        | string  | -       | Time window (e.g., `12h`, `7d`, RFC-3339)       |
| `runId`   |          | string  | -       | Filter by specific run ID                       |
| `limit`   |          | integer | `0`     | Maximum number of results to return             |
| `offset`  |          | integer | `0`     | Number of results to skip for pagination        |

**Example:**
```
GET /actions/runs?window=7d&limit=2&offset=0
```

**Response:**
```json
{
   "code": 200,
   "data": {
      "window": {
         "start": "2025-07-18T00:00:00Z",
         "end": "2025-07-25T00:00:00Z"
      },
      "itemCount": 42,
      "runs": [
         {
            "runId": "8b01eb9b-d33b-4086-a82b-83048188556b",
            "actionConfigName": "production-rightsizing-nightly",
            "actionType": "containerRequestRightSizing",
            "start": "2025-07-24T23:00:00Z",
            "end": "2025-07-24T23:15:30Z",
            "countRecommended": 150,
            "countSuccess": 145,
            "countFailure": 3,
            "countPending": 2,
            "status": "completed"
         },
         {
            "runId": "b39c41c6-c900-4cf2-9473-fff29069492c",
            "actionConfigName": "production-rightsizing-nightly",
            "actionType": "containerRequestRightSizing",
            "start": "2025-07-23T23:00:00Z",
            "end": null,
            "countRecommended": 152,
            "countSuccess": 120,
            "countFailure": 1,
            "countPending": 31,
            "status": "pending"
         }
      ]
   }
}
```

## Action-Specific Parameters

### Container Request Right-Sizing

**Action Type:** `containerRequestRightSizing`

**Parameters:**
```json
{
  "cluster": "production",
  "namespace": "default",
  "controllerKind": "Deployment",
  "controllerName": "nginx",
  "containerName": "nginx",
  "targetCPURequest": "500m",
  "targetRAMRequest": "512Mi",
  "lastCPURequest": "1000m",
  "lastRAMRequest": "1Gi"
}
```

**Config Fields:**
- `cluster` (string, optional): Cluster name for cluster-scoped configurations
- `actionConfigName` (string, optional): Name reference for the action configuration
- `profile` (string, optional): Name of a savings profile (e.g., "Development", "Production"). When specified, uses pre-configured recommendation parameters from the profile. If not specified, individual parameters below must be provided.
- `filter` (string, optional): Allocation filter expression to target specific workloads
- `enabled` (boolean, optional): Whether this action configuration is enabled
- `cpu` (boolean, optional): Enable CPU request right-sizing
- `memory` (boolean, optional): Enable memory request right-sizing
- `rightSizingWindow` (string, optional): Analysis window (e.g., "48h", "7d")
- `maintenanceWindow` (string, optional): Cron expression defining when actions can be executed (e.g., `"* 23 * * *"` for 11 PM daily)
- `exclusionWindow` (string, optional): Cron expression defining when actions should NOT be executed
- `algorithmCPU` (string, optional): Algorithm for CPU recommendations (only if not using profile)
- `algorithmRAM` (string, optional): Algorithm for RAM recommendations (only if not using profile)
- `quantileCPU` (number, optional): CPU quantile for recommendations (0.0-1.0, only if not using profile)
- `quantileRAM` (number, optional): RAM quantile for recommendations (0.0-1.0, only if not using profile)
- `targetUtilizationCPU` (number, optional): Target CPU utilization (0.0-1.0, only if not using profile)
- `targetUtilizationRAM` (number, optional): Target RAM utilization (0.0-1.0, only if not using profile)
- `targetRAMUtilization` (number, optional): Legacy target RAM utilization field (0.0-1.0)
- `minRecCPUMillicores` (number, optional): Minimum recommended CPU in millicores (only if not using profile)
- `minRecRAMBytes` (number, optional): Minimum recommended RAM in bytes (only if not using profile)

**Note:** Either `profile` OR the individual algorithm/quantile/targetUtilization parameters must be specified. The `profile` parameter takes precedence if both are provided.

---

### Namespace Turndown

**Action Type:** `namespaceTurndown`

**Parameters:**
```json
{
  "cluster": "production",
  "namespace": "test-namespace"
}
```

---

### Resource Quota Right-Sizing

**Action Type:** `resourceQuotaRightSizing`

**Parameters:**
```json
{
  "cluster": "production",
  "namespace": "default",
  "name": "compute-quota",
  "targetCPURequest": "10",
  "targetRAMRequest": "20Gi",
  "targetCPULimit": "20",
  "targetRAMLimit": "40Gi",
  "lastCPURequest": "5",
  "lastRAMRequest": "10Gi",
  "lastCPULimit": "10",
  "lastRAMLimit": "20Gi"
}
```

---

## Error Responses

All endpoints return errors in a consistent format:

```json
{
  "code": 400,
  "status": "error",
  "message": "Detailed error message"
}
```

**Common Error Codes:**
- `400 Bad Request`: Invalid input parameters or request body
- `402 Payment Required`: License expired or usage limits exceeded
- `404 Not Found`: Requested resource not found
- `500 Internal Server Error`: Server-side error or service not initialized

---

## Cron Schedules

The Actions service runs several background jobs on cron schedules:

- **Config Sync**: Every 10 minutes (`*/10 * * * *`)
- **Action Submission**: Every 10 minutes (`*/10 * * * *`)
- **Completed Actions Ingestion**: Every 10 minutes (`*/10 * * * *`)
- **Heartbeat Ingestion**: Every 5 minutes (`*/5 * * * *`)
- **System Config Update**: Every 10 minutes (`*/10 * * * *`)

These can be manually triggered using the sync endpoints.

---

## Notes

1. **License Middleware**: Most endpoints require valid Kubecost license with sufficient limits. The middleware chain validates license expiration, core usage limits, and node count limits.

2. **Bucket Storage**: Actions use bucket storage (S3, GCS, etc.) for configuration synchronization, action queues, and result storage.

3. **Time Formats**:
   - RFC3339 format for timestamps: `2024-01-15T10:30:00Z`
   - Kubecost window format: `start,end` or duration strings like `7d`, `12h`

4. **Reserved Names**: The action name `"system"` is reserved and cannot be used for user-created configurations.

5. **Read-Only Configs**: Configurations with `source: "helm"` are managed by Helm and cannot be modified or deleted via API.