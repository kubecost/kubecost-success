#!/bin/bash

output_file="aks_cluster_summary_$(date +%Y%m%d_%H%M%S).csv"

echo "Subscription,Resource Group,Cluster,Node Pool,VM Size,Current Size,Current vCPUs,Min Nodes,Max Nodes,Min vCPUs,Max vCPUs" > "$output_file"

# Function to get vCPUs for a VM size
get_vcpus() {
    local vm_size=$1
    az vm list-sizes --location eastus --query "[?name=='$vm_size'].numberOfCores" -o tsv
}

# List all subscriptions
subscriptions=$(az account list --query "[].id" -o tsv)

for subscription in $subscriptions; do
    echo "Processing subscription: $subscription"
    az account set --subscription $subscription

    # List all AKS clusters in the subscription
    clusters=$(az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)
    
    while IFS=$'\t' read -r cluster_name resource_group; do
        echo " Processing cluster: $cluster_name"
        
        # Get node pools for the cluster
        node_pools=$(az aks nodepool list --cluster-name $cluster_name --resource-group $resource_group --query "[].{name:name, vmSize:vmSize, count:count, minCount:minCount, maxCount:maxCount}" -o tsv)
        
        while IFS=$'\t' read -r pool_name vm_size current_count min_count max_count; do
            echo "  Processing node pool: $pool_name"
            
            vcpus=$(get_vcpus $vm_size)
            current_vcpus=$((vcpus * current_count))
            min_vcpus=$((vcpus * min_count))
            max_vcpus=$((vcpus * max_count))
            
            echo "$subscription,$resource_group,$cluster_name,$pool_name,$vm_size,$current_count,$current_vcpus,$min_count,$max_count,$min_vcpus,$max_vcpus" >> "$output_file"
        done <<< "$node_pools"
    done <<< "$clusters"
done

echo "Processing complete. Results have been saved to $output_file"
