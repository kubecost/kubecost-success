# Kubecost Scripts

This directory contains utility scripts for working with Kubecost data and APIs. These scripts help automate common tasks, extract data for analysis, and integrate Kubecost with other systems.

## Scripts Overview

| Script Name | Description | Language |
|-------------|-------------|----------|
| [allocation-query-reconciled-csv.py](#allocation-query-reconciled-csvpy) | Queries Kubecost allocation data for a specific date and exports to CSV | Python |

---

## Script Details

### allocation-query-reconciled-csv.py

**Purpose**: Queries the Kubecost API for allocation data from 2 days ago and outputs the data in CSV format.

**Requirements**:
- Python 3.x
- `requests` library (`pip install requests`)

**Usage**:
```bash
python allocation-query-reconciled-csv.py <kubecost_url>
```

**Example**:
```bash
python allocation-query-reconciled-csv.py kubecost.example.com
```

**Example Output**:
```
Kubecost API Query Script
==================================================
Using Kubecost URL: kubecost.example.com
Querying Kubecost for date: 2025-06-18
URL: https://kubecost.example.com/model/allocation/summary?accumulate=true&aggregate=namespace%2Cpod&chartType=costovertime&costUnit=daily&external=false&filter=&idle=true&idleByNode=false&includeSharedCostBreakdown=false&shareCost=0&shareIdle=false&shareLabels=&shareNamespaces=&shareSplit=weighted&shareTenancyCosts=false&window=2025-06-18T00%3A00%3A00Z%2C2025-06-18T23%3A59%3A59Z&offset=0&limit=25&format=csv
--------------------------------------------------------------------------------
API Response Status: SUCCESS
Response Size: 12345 bytes

Response Data Preview:
['namespace,pod,cpuCost,ramCost,gpuCost,pvCost,networkCost,loadBalancerCost,externalCost,totalCost', 'kube-system,coredns-123456,0.12,0.05,0.00,0.00,0.01,0.00,0.00,0.18', 'default,app-frontend-123456,0.25,0.15,0.00,0.02,0.03,0.01,0.00,0.46']

==================================================
Query completed successfully!
Data saved to CSV: kubecost_data_2025-06-18.csv
```

**Description**:
This script queries the Kubecost API for allocation data from 2 days ago. It formats the request to get data for a single day in CSV format and saves the response to a CSV file named with the target date (e.g., `kubecost_data_2025-06-18.csv`).

The script:
1. Takes a Kubecost URL as a command-line parameter
2. Calculates the date from 2 days ago
3. Constructs a properly formatted API request to the Kubecost allocation endpoint
4. Requests the data in CSV format
5. Saves the response directly to a CSV file
6. Provides status updates and error handling

**Customization**:
- To change the target date, modify the `timedelta(days=2)` value in the script
- To change the aggregation level, modify the `aggregate` parameter in the `params` dictionary
- To change the output format, modify the `format` parameter in the `params` dictionary
- To use a different protocol (e.g., http instead of https), modify the `base_url` line in the script

---

## Adding New Scripts

When adding new scripts to this directory, please:

1. Follow the naming convention: descriptive names with hyphens between words
2. Include a docstring at the top of the script explaining its purpose
3. Add proper error handling and logging
4. Update this README.md with details about your script following the template below

### Template for New Script Documentation

```markdown
### script-name.py

**Purpose**: Brief description of what the script does.

**Requirements**:
- Required software/libraries

**Usage**:
```bash
python script-name.py [arguments]
```

**Example Output**:
```
Example output here
```

**Description**:
Detailed description of what the script does, how it works, and any important information users should know.

**Customization**:
- Notes on how to customize or configure the script
```

---

## Support

For issues with these scripts, please contact the Kubecost team or file an issue in the repository.

// Made with Bob
