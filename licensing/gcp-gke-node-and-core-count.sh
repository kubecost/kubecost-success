#!/bin/bash

output_file="gke_cluster_summary_$(date +%Y%m%d_%H%M%S).csv"
echo "Project,Cluster,Location,Node Pool,Machine Type,Current Size,Current vCPUs,Min Nodes,Max Nodes,Min vCPUs,Max vCPUs" > "$output_file"

# Function to get vCPUs for a machine type
get_vcpus() {
    local machine_type=$1
    local location=$2
    local vcpus

    if [[ $machine_type == custom-* ]]; then
        vcpus=$(echo $machine_type | cut -d'-' -f2)
    else
        if [[ $location == *"-"* ]]; then
            vcpus=$(gcloud compute machine-types describe $machine_type --zone=$location --format="value(guestCpus)" 2>/dev/null)
        else
            local zone=$(gcloud compute zones list --filter="region:$location" --limit=1 --format="value(name)" 2>/dev/null)
            if [ -n "$zone" ]; then
                vcpus=$(gcloud compute machine-types describe $machine_type --zone=$zone --format="value(guestCpus)" 2>/dev/null)
            fi
        fi
    fi

    echo ${vcpus:-1}
}

# Iterate through all projects
for project in $(gcloud projects list --format="value(projectId)")
do
    echo "Processing project: $project"
    
    gcloud config set project $project

    # Check if Kubernetes Engine API is enabled
    api_enabled=$(gcloud services list --format="value(NAME)" \
                  --filter="NAME:container.googleapis.com" 2>/dev/null)
    
    if [[ -z "$api_enabled" ]]; then
        echo "  Kubernetes Engine API is not enabled for this project. Skipping."
        continue
    fi

    # Attempt to list clusters, if it fails, skip this project
    clusters=$(gcloud container clusters list --format="csv[no-heading](name,location)" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "  Failed to list clusters for this project. Skipping."
        continue
    fi
    
    while IFS=',' read -r cluster_name location
    do
        echo "  Processing cluster: $cluster_name"
        
        node_pools=$(gcloud container node-pools list --cluster=$cluster_name --location=$location --format="csv[no-heading](name,config.machineType)" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "    Failed to list node pools for this cluster. Skipping."
            continue
        fi
        
        while IFS=',' read -r pool_name machine_type
        do
            pool_info=$(gcloud container node-pools describe $pool_name --cluster=$cluster_name --location=$location --format="csv[no-heading](initialNodeCount,autoscaling.minNodeCount,autoscaling.maxNodeCount)" 2>/dev/null)
            if [[ $? -ne 0 ]]; then
                echo "    Failed to get info for node pool $pool_name. Skipping."
                continue
            fi
            IFS=',' read -r initial_count min_count max_count <<< "$pool_info"

            current_count=$initial_count
            if [[ -z "$current_count" || "$current_count" -eq 0 ]]; then
                current_count=$(gcloud container node-pools describe $pool_name --cluster=$cluster_name --location=$location --format="value(autoscaling.currentNodeCount)" 2>/dev/null)
            fi
            
            if [[ -z "$current_count" || "$current_count" -eq 0 ]]; then
                instance_group_url=$(gcloud container node-pools describe $pool_name --cluster=$cluster_name --location=$location --format="value(instanceGroupUrls[0])" 2>/dev/null)
                if [[ -n "$instance_group_url" ]]; then
                    current_count=$(gcloud compute instance-groups managed describe ${instance_group_url##*/} --zone=$location --format="value(targetSize)" 2>/dev/null)
                fi
            fi
            
            current_count=${current_count:-0}
            min_count=${min_count:-$current_count}
            max_count=${max_count:-$current_count}
            
            vcpus=$(get_vcpus $machine_type $location)
            current_vcpus=$((vcpus * current_count))
            min_vcpus=$((vcpus * min_count))
            max_vcpus=$((vcpus * max_count))
            
            echo "$project,$cluster_name,$location,$pool_name,$machine_type,$current_count,$current_vcpus,$min_count,$max_count,$min_vcpus,$max_vcpus" >> "$output_file"
            
        done <<< "$node_pools"
    done <<< "$clusters"
done

echo "Processing complete. Results have been saved to $output_file"
