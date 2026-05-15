#!/bin/bash

output_file="oke_cluster_summary_$(date +%Y%m%d_%H%M%S).csv"
echo "Compartment,Cluster,Node Pool,Shape,Desired Size,Min Size,Max Size,Current OCPUs,Current vCPUs,Min OCPUs,Max OCPUs,Min vCPUs,Max vCPUs" > "$output_file"

# Function to get OCPUs and vCPUs for a shape
get_ocpus_vcpus() {
    local shape=$1
    ocpus=$(oci compute shape list --all --query "data[?name=='$shape'].ocpus" --output text)
    # Oracle: 1 OCPU (x86) = 2 vCPUs
    vcpus=$((ocpus * 2))
    echo "$ocpus,$vcpus"
}

# List all compartments (replace with your compartment OCID if needed)
for compartment_id in $(oci iam compartment list --all --query "data[?\"lifecycle-state\"=='ACTIVE'].id" --output text); do
    for cluster_id in $(oci ce cluster list --compartment-id $compartment_id --query "data[].id" --output text); do
        cluster_name=$(oci ce cluster get --cluster-id $cluster_id --query "data.name" --output text)
        for nodepool_id in $(oci ce node-pool list --compartment-id $compartment_id --cluster-id $cluster_id --query "data[].id" --output text); do
            nodepool=$(oci ce node-pool get --node-pool-id $nodepool_id --query "data" --output json)
            nodepool_name=$(echo $nodepool | jq -r '.name')
            shape=$(echo $nodepool | jq -r '.nodeShape')
            desired_size=$(echo $nodepool | jq -r '.quantityPerSubnet')
            min_size=$(echo $nodepool | jq -r '.autoscaling.minNodeCount // desired_size')
            max_size=$(echo $nodepool | jq -r '.autoscaling.maxNodeCount // desired_size')
            IFS=',' read ocpus vcpus <<< $(get_ocpus_vcpus $shape)
            current_ocpus=$((ocpus * desired_size))
            current_vcpus=$((vcpus * desired_size))
            min_ocpus=$((ocpus * min_size))
            max_ocpus=$((ocpus * max_size))
            min_vcpus=$((vcpus * min_size))
            max_vcpus=$((vcpus * max_size))
            echo "$compartment_id,$cluster_name,$nodepool_name,$shape,$desired_size,$min_size,$max_size,$current_ocpus,$current_vcpus,$min_ocpus,$max_ocpus,$min_vcpus,$max_vcpus" >> "$output_file"
        done
    done
done

echo "Processing complete. Results saved to $output_file"
