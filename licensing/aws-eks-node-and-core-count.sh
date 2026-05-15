#!/bin/bash

output_file="eks_cluster_summary_$(date +%Y%m%d_%H%M%S).csv"
echo "Region,Cluster,Node Group,Instance Type,Desired Size,Min Size,Max Size,Current vCPUs,Min vCPUs,Max vCPUs" > "$output_file"

# Function to get vCPU count for an EC2 instance type
get_vcpus() {
    local instance_type=$1
    aws ec2 describe-instance-types --instance-types "$instance_type" \
        --query "InstanceTypes[0].VCpuInfo.DefaultVCpus" --output text
}

# List all AWS regions
for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Processing region: $region"
    # List all EKS clusters in the region
    for cluster in $(aws eks list-clusters --region "$region" --query "clusters[]" --output text); do
        echo "  Processing cluster: $cluster"
        # List all node groups in the cluster
        for nodegroup in $(aws eks list-nodegroups --cluster-name "$cluster" --region "$region" --query "nodegroups[]" --output text); do
            echo "    Processing node group: $nodegroup"
            # Get node group configuration
            info=$(aws eks describe-nodegroup --cluster-name "$cluster" --nodegroup-name "$nodegroup" --region "$region" --query "nodegroup")
            instance_type=$(echo $info | jq -r '.instanceTypes[0]')
            desired_size=$(echo $info | jq -r '.scalingConfig.desiredSize')
            min_size=$(echo $info | jq -r '.scalingConfig.minSize')
            max_size=$(echo $info | jq -r '.scalingConfig.maxSize')
            vcpus=$(get_vcpus $instance_type)
            current_vcpus=$((vcpus * desired_size))
            min_vcpus=$((vcpus * min_size))
            max_vcpus=$((vcpus * max_size))
            echo "$region,$cluster,$nodegroup,$instance_type,$desired_size,$min_size,$max_size,$current_vcpus,$min_vcpus,$max_vcpus" >> "$output_file"
        done
    done
done

echo "Processing complete. Results saved to $output_file"
