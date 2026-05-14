# Kubecost Core Count Calculation for Licensing

## Overview

Kubecost uses a **30-day rolling average** of CPU cores to determine licensing requirements. This document explains exactly how this calculation works, what it measures, and how it affects your license.

## Quick Summary

- **Metric**: Average concurrent CPU cores over 30 days
- **Calculation Frequency**: Every 3 hours (cached)
- **Data Source**: Node asset data (post-reconciliation)

## The Formula

```
Average Core Count = Total CPU Core Hours / Total Minutes × 60
```

### Calculation Process

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

### Checking Your Core Count

You can check your current core count via the diagnostic endpoint:

```bash
curl http://your-kubecost-url/diagnostic/corecount
```

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



## FAQ

**Q: Does this include GPU cores?**  
A: No, only CPU cores are counted for licensing. GPU resources are tracked separately.

**Q: What about idle cores?**  
A: All provisioned cores count, regardless of utilization. If a node has 8 cores, all 8 count even if only 2 are being used.

**Q: Can I exclude certain nodes from the count?**  
A: No, all nodes in monitored clusters are included in the calculation.

**Q: How does this work with node autoscaling?**  
A: The 30-day average naturally accounts for autoscaling. Nodes that exist for only part of the window contribute proportionally to the average.

### Detailed Autoscaling Example

Let's say you have a cluster that autoscales based on load:

**Baseline**: 10 nodes × 8 cores = 80 cores (running 24/7)

**Autoscaling Events**:
- **Days 1-20**: Baseline only (80 cores)
- **Days 21-25**: Traffic spike, scales up to 20 nodes × 8 cores = 160 cores (5 days)
- **Days 26-30**: Back to baseline (80 cores)

**Calculation**:

```
Baseline Core Hours:
- 30 days × 24 hours × 80 cores = 57,600 core hours

Additional Core Hours from Scale-Up:
- 5 days × 24 hours × 80 additional cores = 9,600 core hours

Total Core Hours = 57,600 + 9,600 = 67,200 core hours

Total Minutes = 30 days × 24 hours × 60 minutes = 43,200 minutes

Average Cores = 67,200 / 43,200 × 60 = 93.33 cores
```

**Key Insights**:
- Your baseline is 80 cores
- You scaled to 160 cores for only 5 days (16.7% of the month)
- Your 30-day average is **93.33 cores** (not 160!)
- The temporary spike added only ~13 cores to your average
- This is fair because you only used the extra capacity for 5 days

**Why This Matters**:
- **Short bursts don't penalize you**: A weekend traffic spike won't push you over licensing limits
- **Sustained increases do count**: If you scale up and stay up, it will gradually increase your average
- **Gradual impact**: Each day of higher usage adds 1/30th of that day's impact to your average
- **Gradual recovery**: Each day after scaling down removes 1/30th of the spike from your average

### Real-World Scenario - Black Friday

Imagine you're an e-commerce company:
- **Normal operation**: 100 cores year-round
- **Black Friday weekend**: Scale to 400 cores for 3 days
- **Impact on 30-day average**: 

```
Normal: 27 days × 24 hours × 100 cores = 64,800 core hours
Spike:   3 days × 24 hours × 400 cores = 28,800 core hours
Total: 93,600 core hours

Average = 93,600 / 43,200 × 60 = 130 cores
```

Your Black Friday spike (4× normal capacity for 3 days) only increases your 30-day average from 100 to 130 cores—a 30% increase, not 300%!

**Timeline of Impact**:

| Day After Spike | 30-Day Average | Notes |
|----------------|----------------|-------|
| Day 0 (during spike) | 130 cores | Spike is fully included |
| Day 10 | ~120 cores | Spike data is 1/3 rolled off |
| Day 20 | ~110 cores | Spike data is 2/3 rolled off |
| Day 30 | 100 cores | Back to baseline, spike fully rolled off |

This demonstrates how the rolling 30-day window provides a **fair and gradual** adjustment to your licensing requirements.


## Support

For questions about licensing or core count calculations:
- Contact Kubecost Support
- Join the #kubecost-licensing Slack channel (internal)
- Review your license details in the Kubecost UI

---

**Last Updated**: 2026-05-14  
**Applies to**: Kubecost v3.0+