# kc-data-validation-tool

Provides various ways to do data auditing via the aws api and kubecost assets api to validate what's being emitted in Kubecost and in AWS Cost Explorer.

## AWS Filters

## Filter by service file via AWS Cost Explorer
```
aws ce get-cost-and-usage --time-period Start=$(date -v-3d +"%Y-%m-%d"),End=$(date -v-2d +"%Y-%m-%d") \
--granularity=DAILY --metrics AMORTIZED_COST --group-by Type=DIMENSION,Key=SERVICE  \
--filter file://
```
## Filter by all services in AWS Cost Explorer
```
aws ce get-cost-and-usage --time-period Start=$(date -v-4d +"%Y-%m-%d"),End=$(date -v-3d +"%Y-%m-%d") --granularity=DAILY --metrics AMORTIZED_COST --group-by Type=DIMENSION,Key=SERVICE 

```
## Filter and output to table
```
aws ce get-cost-and-usage --time-period Start=$(date -v-4d +"%Y-%m-%d"),End=$(date -v-3d +"%Y-%m-%d") --granularity=DAILY --metrics AMORTIZED_COST --group-by Type=DIMENSION,Key=SERVICE --filter file://s3.json --output table
```
## Filter and output to text
```
aws ce get-cost-and-usage --time-period Start=$(date -v-4d +"%Y-%m-%d"),End=$(date -v-3d +"%Y-%m-%d") --granularity=DAILY --metrics AMORTIZED_COST --group-by Type=DIMENSION,Key=SERVICE --filter file://s3.json --output text
```
## Filter via kubecost assets api

```
curl http://localhost:9090/model/assets -d aggregate=service -d window=2022-09-22T00:00:00Z,2022-09-23T00:00:00Z -G | jq
```
