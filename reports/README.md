## Creating Reports

It is possble to create reports using helm and our API.

This example creates a report via the Reports API. This report gives information on spend for all clusters for the last 7 days. It also schedules a cadence in which to email the report on a weekly basis in pdf format.

```
curl --location 'http://localhost:9003/reports/allocation' \
--header 'Content-Type: application/json' \
--data-raw '{
    "window": "7d",
    "accumulate": false,
    "aggregateBy": "cluster",
    "chartDisplay": "series",
    "idle": "shareByCluster",
    "rate": "cumulative",
    "title": "Allocation Report Title",
    "filters": [],
    "sharedNamespaces": null,
    "sharedOverhead": 0,
    "sharedLabels": null,
    "schedule": {
        "emails": ["user@kubecost.com"],
        "interval": "daily",
        "intervalDay": 0,
        "format":"pdf"
    }
}'
```
