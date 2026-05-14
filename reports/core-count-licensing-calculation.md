# Kubecost Core Count Calculation for Licensing

## Overview

Kubecost uses a **30-day rolling average** of CPU cores to determine licensing requirements. This document explains exactly how this calculation works, what it measures, and how it affects your license.

## Quick Summary

- **Metric**: Average concurrent CPU cores over 30 days
- **Free Tier Limit**: 250 cores
- **Calculation Frequency**: Every 3 hours (cached)
- **Data Source**: Node asset data (post-reconciliation)

## The Formula

```
Average Core Count = Total CPU Core Hours / Total Minutes × 60
```

### SQL Implementation

```sql
COALESCE(
    SUM(CPUCoreHours) / datediff('minute', MIN("Start"), MAX("End")) * 60, 
    0
) AS CPUCores
```

## How It Works

### 1. Time Window

- **Duration**: 30 days (720 hours)
- **Rolling**: The window moves forward each day
- **Calculation**: `windowEnd = now()`, `windowStart = now() - 30 days`

### 2. Data Collection

Kubecost queries node data from one of two tables depending on data age:

- **Recent data** (< retention period): `Node1hTypedReconciledTable` (hourly granularity)
- **Older data**: `Node1dTypedReconciledTable` (daily granularity)

The post-reconciliation tables are used to ensure accuracy by including all pipeline fixes like:
- Ghost node deduplication
- Node attribution corrections
- Data quality improvements

### 3. Calculation Process

**Step 1: Sum CPU Core Hours**
- Aggregate all `CPUCoreHours` across all nodes in your clusters
- This represents the total compute capacity consumed

**Step 2: Calculate Time Span**
- Find the earliest `Start` time in the window
- Find the latest `End` time in the window
- Calculate the difference in minutes

**Step 3: Convert to Average Cores**
- Divide total core hours by total minutes
- Multiply by 60 to convert from "cores per minute" to "cores per hour"
- This gives you the **average number of cores running concurrently**

**Step 4: Group by Cluster**
- The calculation is performed per cluster
- Results are summed for the total core count across all clusters

## Example Calculation

### Scenario
You have a Kubernetes environment that scales throughout the month:

- **Week 1**: 200 cores running continuously
- **Week 2**: 300 cores running continuously  
- **Week 3**: 250 cores running continuously
- **Week 4**: 150 cores running continuously

### Calculation

```
Total Core Hours = (200 × 168) + (300 × 168) + (250 × 168) + (150 × 168)
                 = 33,600 + 50,400 + 42,000 + 25,200
                 = 151,200 core hours

Total Minutes = 30 days × 24 hours × 60 minutes
              = 43,200 minutes

Average Cores = 151,200 / 43,200 × 60
              = 210 cores
```

**Result**: Your 30-day average is **210 cores**, which is under the 250-core free tier limit.

## Licensing Enforcement

### Free Tier (No License)

- **Limit**: 250 cores (30-day average)
- **Behavior when exceeded**:
  1. Kubecost automatically starts a trial if one hasn't been started
  2. If trial has expired, API access is blocked with HTTP 402 (Payment Required)
  3. Grace period: 16 days after trial expiration

### Enterprise License

- **Core count specified in license**: Encoded in the x509 certificate (OID `1.2.3.4.5.6.7.8.3`)
- **No automatic blocking**: Enterprise licenses don't enforce core limits via API blocking
- **Monitoring**: Core count is still calculated for license compliance tracking

### Checking Your Core Count

You can check your current core count via the diagnostic endpoint:

```bash
curl http://your-kubecost-url/diagnostic/corecount
```

This endpoint is **ungated** (always accessible) so you can check your usage even if you're over the limit.

## Important Considerations

### 1. Why 30 Days?

The 30-day window smooths out temporary spikes and provides a fair representation of your actual sustained usage. This prevents:
- Short-term testing from triggering license requirements
- Temporary scale-ups (e.g., Black Friday) from causing immediate license issues
- Daily fluctuations from affecting your license status

### 2. What Counts as a "Core"?

- **Physical cores**: Each CPU core on a node
- **vCPUs**: In cloud environments, each vCPU counts as one core
- **All nodes**: Includes master nodes, worker nodes, and any other nodes in your clusters
- **All clusters**: If you have multiple clusters, cores are summed across all of them

### 3. Scaling Considerations

The average calculation means:
- **Scaling up temporarily** has minimal impact on your 30-day average
- **Sustained increases** will gradually increase your average
- **Scaling down** takes 30 days to fully reflect in the average

### 4. Cache Behavior

- Core count is **cached for 3 hours**
- This reduces database load
- Your actual usage may change, but enforcement uses the cached value
- Cache is refreshed automatically

## Troubleshooting

### "Why is my core count higher than expected?"

1. **Check all clusters**: The count includes ALL clusters monitored by Kubecost
2. **Review node types**: Ensure you're not counting nodes you don't expect
3. **Look at historical data**: The 30-day average includes past usage
4. **Check for ghost nodes**: While reconciliation should catch these, verify no duplicate nodes exist

### "My cluster scaled down but I'm still over the limit"

This is expected behavior. The 30-day rolling average means:
- It takes time for reductions to fully reflect
- Each day, 1/30th of the old data rolls off
- After 30 days of lower usage, your average will fully reflect the new scale

### "How do I reduce my core count?"

1. **Scale down clusters**: Reduce the number of nodes or node sizes
2. **Remove unused clusters**: Stop monitoring clusters you no longer need
3. **Wait**: Allow the 30-day window to roll forward with lower usage

## Technical Details

### Source Code References

- **Middleware**: `pkg/gating/middleware.go`
  - Constants: `coreCountNumDays = 30`, `maxCoreCount = 250`
  - Cache duration: `cacheExpiration = 3 * time.Hour`

- **Query Implementation**: `pkg/db/asset/db/assetqueryservice.go`
  - Function: `QueryCoreCount()`
  - Tables: `Node1hTypedReconciledTable`, `Node1dTypedReconciledTable`

### Data Tables

- **Hourly**: `Node1hTypedReconciledTable` - Recent data with hourly granularity
- **Daily**: `Node1dTypedReconciledTable` - Historical data with daily granularity
- **Reconciled**: Both tables include post-processing fixes for data quality

## FAQ

**Q: Does this include GPU cores?**  
A: No, only CPU cores are counted for licensing. GPU resources are tracked separately.

**Q: What about idle cores?**  
A: All provisioned cores count, regardless of utilization. If a node has 8 cores, all 8 count even if only 2 are being used.

**Q: Can I exclude certain nodes from the count?**  
A: No, all nodes in monitored clusters are included in the calculation.

**Q: How does this work with node autoscaling?**  
A: The 30-day average naturally accounts for autoscaling. Nodes that exist for only part of the window contribute proportionally to the average.

**Q: What happens during a trial?**  
A: During an active trial, the core count limit is not enforced. You can exceed 250 cores without API blocking.

**Q: How is this different from node count licensing?**  
A: Core count measures total CPU capacity, while node count simply counts the number of nodes. A cluster with 10 nodes of 4 cores each would be 40 cores but 10 nodes.

## Support

For questions about licensing or core count calculations:
- Contact Kubecost Support
- Join the #kubecost-licensing Slack channel (internal)
- Review your license details in the Kubecost UI

---

**Last Updated**: 2026-05-14  
**Applies to**: Kubecost v3.0+