# Allocation Trends API

The Allocation Trends API provides cost allocation data over time for Kubernetes resources, enabling detailed cost analysis and trending across various dimensions.

## Request

**Endpoint**: `/model/allocation/trends`

**Method**: `GET`

**Query Parameters**:

### Required Parameters

- **window** (string): Time window for the query
  - Format: Relative time (e.g., `7d`, `30d`, `1h`) or absolute timestamps
  - Example: `7d`

### Aggregation Parameters

- **accumulate** (string): Accumulation period for data points
  - Options: `day`, `hour`, `false`
  - Default: `false`
  - Example: `day`

- **aggregate** (string): Dimension to aggregate results by
  - Options: `namespace`, `cluster`, `node`, `pod`, `container`, `controller`, `service`, `label:<key>`
  - Example: `namespace`

### Cost Configuration Parameters

- **chartType** (string): Chart visualization type
  - Options: `costovertime`, `proportional`
  - Default: `costovertime`

- **costUnit** (string): Cost calculation method
  - Options: `cumulative`, `hourly`, `daily`, `monthly`
  - Default: `cumulative`

- **external** (boolean): Include external cloud costs
  - Default: `false`

- **idle** (boolean): Include idle resource costs
  - Default: `true`

- **idleByNode** (boolean): Calculate idle costs at node level
  - Default: `false`

### Filtering Parameters

- **filter** (string): Filter expression for resources
  - Format: `<field>:<value>`
  - Example: `namespace:kube-system`

- **names** (string): Comma-separated list of specific resource names to include
  - Example: `kube-system,kubecost,ingress-nginx`
  - Special values:
    - `__idle__`: Idle/unused cluster resources
    - `__unmounted__`: Unmounted persistent volumes

### Cost Sharing Parameters

- **shareCost** (number): Percentage of shared costs to allocate
  - Range: 0-1
  - Default: `0`

- **shareIdle** (boolean): Share idle costs across resources
  - Default: `false`

- **shareLabels** (string): Comma-separated labels to use for cost sharing
  - Example: `app,team`

- **shareNamespaces** (string): Comma-separated namespaces to share costs with
  - Example: `default,kube-system`

- **shareSplit** (string): Method for splitting shared costs
  - Options: `weighted`, `even`
  - Default: `weighted`

- **shareTenancyCosts** (boolean): Include tenancy costs in sharing calculations
  - Default: `true`

- **includeSharedCostBreakdown** (boolean): Include detailed breakdown of shared costs
  - Default: `true`

## Response

### Success Response

**Status Code**: `200 OK`

**Response Body**:

```json
{
  "code": 200,
  "data": [
    {
      "namespace": "kube-system",
      "window": {
        "start": "2024-01-27T00:00:00Z",
        "end": "2024-02-03T00:00:00Z"
      },
      "cpuCost": 12.45,
      "gpuCost": 0.00,
      "ramCost": 8.32,
      "pvCost": 2.15,
      "networkCost": 1.23,
      "totalCost": 24.15,
      "cpuCoreHours": 168.5,
      "ramByteHours": 1073741824,
      "pvByteHours": 536870912
    }
  ]
}
```

**Response Fields**:

- **code** (integer): HTTP status code
- **data** (array): Array of allocation objects
  - **namespace** (string): Namespace name (or other aggregation dimension)
  - **window** (object): Time window for the data
    - **start** (string): Start timestamp (ISO 8601)
    - **end** (string): End timestamp (ISO 8601)
  - **cpuCost** (number): CPU cost in USD
  - **gpuCost** (number): GPU cost in USD
  - **ramCost** (number): RAM cost in USD
  - **pvCost** (number): Persistent volume cost in USD
  - **networkCost** (number): Network cost in USD
  - **totalCost** (number): Total cost in USD
  - **cpuCoreHours** (number): CPU core hours consumed
  - **ramByteHours** (number): RAM byte hours consumed
  - **pvByteHours** (number): Persistent volume byte hours consumed

### Error Response

**Status Code**: `400 Bad Request`

**Response Body**:

```json
{
  "code": 400,
  "message": "Invalid window parameter: must be in format '7d' or ISO 8601 timestamp",
  "data": null
}
```

## Examples

### Example 1: Basic namespace cost trends

Get daily cost trends for all namespaces over the past 7 days.

**Request**:

```bash
curl -X GET "https://demo.kubecost.xyz/model/allocation/trends?window=7d&aggregate=namespace&accumulate=day"
```

**Response**:

```json
{
  "code": 200,
  "data": [
    {
      "namespace": "kube-system",
      "window": {
        "start": "2024-01-27T00:00:00Z",
        "end": "2024-02-03T00:00:00Z"
      },
      "totalCost": 24.15
    }
  ]
}
```

### Example 2: Specific namespaces with idle costs

Query specific namespaces including idle resource costs.

**Request**:

```bash
curl -X GET "https://demo.kubecost.xyz/model/allocation/trends?\
window=7d&\
aggregate=namespace&\
accumulate=day&\
idle=true&\
costUnit=cumulative&\
names=kube-system,kubecost,ingress-nginx"
```

### Example 3: Cluster-level analysis with cost sharing

Analyze costs at the cluster level with shared cost breakdown.

**Request**:

```bash
curl -X GET "https://demo.kubecost.xyz/model/allocation/trends?\
window=30d&\
aggregate=cluster&\
accumulate=day&\
includeSharedCostBreakdown=true&\
shareTenancyCosts=true&\
shareSplit=weighted"
```

### Example 4: GPU workload tracking

Track costs for GPU-intensive namespaces.

**Request**:

```bash
curl -X GET "https://demo.kubecost.xyz/model/allocation/trends?\
window=7d&\
aggregate=namespace&\
names=cz-gpu-testing,gpu-operator&\
accumulate=day&\
costUnit=cumulative"
```

### Example 5: Complete request with all parameters

Full example using all available parameters.

**Request**:

```bash
curl -X GET "https://demo.kubecost.xyz/model/allocation/trends?\
accumulate=day&\
aggregate=namespace&\
chartType=costovertime&\
costUnit=cumulative&\
external=false&\
filter=&\
idle=true&\
idleByNode=false&\
includeSharedCostBreakdown=true&\
shareCost=0&\
shareIdle=false&\
shareLabels=&\
shareNamespaces=&\
shareSplit=weighted&\
shareTenancyCosts=true&\
window=7d&\
names=__idle__,__unmounted__,cz-gpu-testing,falcon-system,gpu-operator,ibm-finops-agent,ibm-finops-agent-nightly,ingress-nginx,kube-system,kubecost,kubecost-network-costs,kubecost-nightly,kubecost-v3,openshift-apiserver,openshift-cloud-ingress-operator,openshift-cluster-csi-drivers,openshift-cnv,openshift-etcd,openshift-ingress,openshift-kube-apiserver,openshift-machine-config-operator,openshift-monitoring,openshift-ovn-kubernetes,openshift-security,openshift-virtualization-os-images,turbonomic"
```

## Notes

- All costs are returned in USD
- Timestamps are in ISO 8601 format (UTC)
- Cost calculations include CPU, GPU, RAM, persistent volumes, and network costs
- Shared costs are distributed based on resource usage when enabled
- The `__idle__` resource represents unused cluster capacity
- The `__unmounted__` resource represents unmounted persistent volumes

## Related APIs

- [Allocation API](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=apis-allocation)
- [Assets API](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=apis-assets)
- [Cloud Cost API](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=apis-cloud-cost)