# Kubecost Enterprise Custom Pricing API Reference (v3.2+)

This document provides comprehensive API documentation for programmatically managing Enterprise Custom Pricing in Kubecost v3.2 and later.

## Prerequisites

- Kubecost v3.2 or later
- Enterprise Custom Pricing enabled (`enterpriseCustomPricing.enabled=true`)
- Valid Enterprise license
- API access to the Kubecost aggregator service

## Base URL

All API endpoints are relative to your Kubecost aggregator service:

```
http://<kubecost-aggregator-service>:9004
```

For example:
```
http://kubecost-aggregator.kubecost.svc.cluster.local:9004
```

## Authentication

If SAML/OIDC is enabled, include authentication headers:

```bash
curl -H "Authorization: Bearer <token>" \
  http://kubecost-aggregator:9004/pricing/status
```

## API Endpoints

### 1. Get Pricing Status

Check if Enterprise Custom Pricing is enabled and get current configuration status.

**Endpoint:** `GET /pricing/status`

**Response:**
```json
{
  "code": 200,
  "data": {
    "enabled": true,
    "source": "configmap",
    "lastUpdated": "2026-06-02T19:00:00Z",
    "specCount": 8
  }
}
```

**Example:**
```bash
curl http://kubecost-aggregator:9004/pricing/status
```

---

### 2. Get Current Pricing Spec

Retrieve the current pricing specification as CSV.

**Endpoint:** `GET /pricing/spec`

**Query Parameters:**
- `format` (optional): Response format. Options: `json` (default), `csv`

**Response (JSON - default):**
```json
{
  "code": 200,
  "data": {
    "nodePricing": {...},
    "gpuPricing": {...},
    "volumePricing": {...},
    "loadBalancerPricing": {...},
    "metadata": {
      "checksum": "abc123...",
      "createdAt": "2026-06-02T19:00:00Z"
    }
  }
}
```

**Response (CSV format):**
```json
{
  "code": 200,
  "data": {
    "rows": [
      "Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit",
      "v1,node,a4,,,,hour,0.24",
      "v1,node,a4,us-east-2,,,hour,0.26",
      "v1,gpu,T4,,,,hour,3.82"
    ]
  }
}
```

**Examples:**

Get full spec (JSON):
```bash
curl http://kubecost-aggregator:9004/pricing/spec | jq .
```

Get CSV rows:
```bash
curl "http://kubecost-aggregator:9004/pricing/spec?format=csv" | jq -r '.data.rows[]'
```

Save as CSV file:
```bash
curl "http://kubecost-aggregator:9004/pricing/spec?format=csv" | jq -r '.data.rows[]' > pricing.csv
```

---

### 3. Upload/Update Pricing Spec

Upload a new pricing specification or update the existing one.

**Endpoint:** `POST /pricing/spec`

**Content-Type:** `multipart/form-data`

**Request Body:** CSV file as multipart form data

**Response:**
```json
{
  "code": 200,
  "data": {
    "nodePricing": {...},
    "gpuPricing": {...},
    "volumePricing": {...},
    "loadBalancerPricing": {...},
    "metadata": {
      "checksum": "abc123...",
      "createdAt": "2026-06-02T19:30:00Z"
    }
  }
}
```

**Examples:**

Upload CSV file:
```bash
curl -X POST \
  -F "file=@pricing.csv" \
  http://kubecost-aggregator:9004/pricing/spec
```

Generate and upload programmatically:
```bash
cat > /tmp/pricing.csv <<EOF
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,node,custom-instance,,,,hour,0.50
v1,gpu,A100,,,,hour,5.00
EOF

curl -X POST \
  -F "file=@/tmp/pricing.csv" \
  http://kubecost-aggregator:9004/pricing/spec
```

**Important Notes:**
- Only CSV format is supported (not JSON)
- File must be uploaded as multipart form data
- Cannot update if pricing is configured via Helm (returns 400 error)
- Spec is automatically validated before saving

---

### 4. Validate Pricing Spec

Validate a pricing specification without applying it.

**Endpoint:** `POST /pricing/spec/validate`

**Content-Type:** `multipart/form-data`

**Request Body:** CSV file as multipart form data

**Response (Valid):**
```json
{
  "code": 200,
  "data": {
    "uri": "",
    "parsed": true,
    "valid": true,
    "messages": [],
    "matchedData": [
      {
        "csvLine": 2,
        "numAssetsAffected": 150,
        "window": {
          "start": "2026-05-01T00:00:00Z",
          "end": "2026-06-02T00:00:00Z"
        }
      }
    ]
  }
}
```

**Response (Invalid):**
```json
{
  "code": 200,
  "data": {
    "uri": "",
    "parsed": false,
    "valid": false,
    "messages": [
      "failed to parse CSV: invalid format on line 3"
    ]
  }
}
```

**Example:**
```bash
curl -X POST \
  -F "file=@pricing.csv" \
  http://kubecost-aggregator:9004/pricing/spec/validate
```

**Important Notes:**
- Returns 200 even for invalid specs (check `data.valid` field)
- `matchedData` shows which CSV lines will affect historical data
- Only returned when retroactive pricing is enabled
- Helps estimate impact before applying changes

---

### 5. Delete Pricing Spec

Remove the current pricing specification and revert to default pricing.

**Endpoint:** `DELETE /pricing/spec`

**Response:**
```json
{
  "code": 200,
  "data": null
}
```

**Example:**
```bash
curl -X DELETE http://kubecost-aggregator:9004/pricing/spec
```

---

### 6. Apply Pricing Retroactively

Trigger retroactive application of pricing changes to historical data. Uses a two-step token-based confirmation to prevent accidental data modifications.

**Endpoint:** `POST /pricing/apply`

**Query Parameters:**
- `window` (optional): Time window to reprocess (e.g., `7d`, `30d`, `2024-01-01T00:00:00Z,2024-02-01T00:00:00Z`)
- `token` (optional): Confirmation token from first request

**Two-Step Process:**

**Step 1: Request Token**
```bash
curl -X POST "http://kubecost-aggregator:9004/pricing/apply?window=7d"
```

**Response:**
```json
{
  "code": 200,
  "data": {
    "token": "550e8400-e29b-41d4-a716-446655440000",
    "message": "submit request with token to confirm"
  }
}
```

**Step 2: Confirm with Token**
```bash
curl -X POST "http://kubecost-aggregator:9004/pricing/apply?window=7d&token=550e8400-e29b-41d4-a716-446655440000"
```

**Response:**
```json
{
  "code": 200,
  "data": {
    "token": "550e8400-e29b-41d4-a716-446655440000",
    "message": "success: running pricing"
  }
}
```

**Examples:**

Apply for last 7 days (two-step):
```bash
# Step 1: Get token
TOKEN=$(curl -s -X POST "http://kubecost-aggregator:9004/pricing/apply?window=7d" | jq -r '.data.token')

# Step 2: Confirm with token
curl -X POST "http://kubecost-aggregator:9004/pricing/apply?window=7d&token=$TOKEN"
```

Apply for custom date range:
```bash
# Step 1: Get token
TOKEN=$(curl -s -X POST "http://kubecost-aggregator:9004/pricing/apply?window=2024-01-01T00:00:00Z,2024-02-01T00:00:00Z" | jq -r '.data.token')

# Step 2: Confirm
curl -X POST "http://kubecost-aggregator:9004/pricing/apply?window=2024-01-01T00:00:00Z,2024-02-01T00:00:00Z&token=$TOKEN"
```

**Important Notes:**
- Tokens expire after 5 minutes
- Each token can only be used once
- Window parameter must match between both requests
- Deletes pricing records that don't match current spec checksum
- Only works when `APPLY_ENTERPRISE_CUSTOM_PRICING_RETROACTIVELY=true`

---

## CSV Pricing Spec Format

### Required Columns

| Column | Description | Example Values |
|--------|-------------|----------------|
| `Version` | Spec version (always `v1`) | `v1` |
| `AssetClass` | Type of resource | `node`, `gpu`, `volume`, `loadbalancer` |
| `InstanceType` | Instance/resource type | `a4`, `T4`, `standard`, or empty |
| `Region` | Cloud region | `us-east-2`, `eu-west-1`, or empty |
| `LabelName` | Kubernetes label key | `my.org/instance`, or empty |
| `LabelValue` | Kubernetes label value | `a6`, or empty |
| `Unit` | Pricing unit | `hour`, `cpucorehour`, `ramgbhour`, `gbhour` |
| `PricePerUnit` | Price per unit | `0.24`, `3.82` |

### Pricing Rules Priority

Pricing is matched in the following order (highest to lowest priority):

1. **Label-based pricing**: Matches `LabelName` and `LabelValue`
2. **Region + Instance Type**: Matches `Region` and `InstanceType`
3. **Instance Type only**: Matches `InstanceType`
4. **Asset Class default**: Matches `AssetClass` only

### Examples

**Node pricing by instance type:**
```csv
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,node,m5.large,,,,hour,0.096
v1,node,m5.xlarge,,,,hour,0.192
```

**Regional pricing:**
```csv
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,node,m5.large,us-east-1,,,hour,0.096
v1,node,m5.large,eu-west-1,,,hour,0.108
```

**Label-based pricing (highest priority):**
```csv
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,node,,,my.org/tier,premium,cpucorehour,0.08
v1,node,,,my.org/tier,premium,ramgbhour,0.008
```

**GPU pricing:**
```csv
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,gpu,T4,,,,hour,3.82
v1,gpu,V100,,,,hour,8.50
v1,gpu,A100,,,,hour,12.00
```

**Storage pricing:**
```csv
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,volume,standard,,,,gbhour,0.05
v1,volume,ssd,,,,gbhour,0.10
v1,volume,__local__,,,,gbhour,0.08
```

**Load balancer pricing:**
```csv
Version,AssetClass,InstanceType,Region,LabelName,LabelValue,Unit,PricePerUnit
v1,loadbalancer,,,,,hour,0.42
```

- [Enterprise Custom Pricing Configuration](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-csv-pricing)
- [Kubecost API Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=apis)
- [On-Premises Deployment Guide](./README.md)

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/kubecost/kubecost/issues
- IBM Support: https://support.ibm.com
- Slack Community: https://kubecost.slack.com