# Cloudability Advanced Containers Deployment Guide

![Cloudability Advanced Containers Architecture](/assets/cac.png)

This guide provides step-by-step instructions for deploying the IBM Finops agent for Cloudability Advanced Containers powered by Kubecost.
## Prerequisites

1. **Pull images to store in internal registry (if applicable)**
   - [ ] Set up private container registry
   - [ ] Download and push Kubecost images to internal container registry. The command below lists all images. Only the finops agent and cluster-controller (optional) are needed for the IBM Finops agent. They are located at icr.io/ibm-finops/ and icr.io/kubecost
   ```bash
   helm template kubecost --repo https://kubecost.github.io/kubecost/ kubecost --skip-tests | yq '..|.image? | select(.)' | sort -u
   ```
   - [ ] Configure Helm repository mirror

2. Create a user and attach the CloudabilityContainerUploader role. This needs to be provisioned in front door using the [Kubernetes Cluster Provisioning Documentation](https://www.ibm.com/docs/en/cloudability-commercial/cloudability-essentials/saas?topic=cloudability-kubernetes-cluster-provisioning). After creating the user, generate the API key. This will generate a public and private access key which is part of the checklist below and will be used in the [ibm-finops-agent.yaml](/cloudy-advanced-containers/ibm-finops-agent.yaml) file.
   - [ ] agent.cloudability.secret.cloudabilityAccessKey=<publicKey>
   - [ ] agent.cloudability.secret.cloudabilitySecretKey=<privateKey>
   - [ ] agent.cloudability.secret.EnvId="<CLOUDABILITY_ENV_ID>
   - [ ] federatedStorage.existingSecret=”<secret_with_federated_storage_config>”

## Install IBM Finops Agent

1. **Finpops Agent Installation**
   - [ ] Configure [federated-store.yaml](/cloudy-advanced-containers/federated-store.yaml) pointing to the s3 bucket being used for Cloudability Container insights. This can be found under the Monitor > Clusters tab in the Cloudability Advanced Containers UI (located under insights in Cloudability) 

   - [ ] Create secret for object storage in ibm-finops-agent namespace.
```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n ibm-finops-agent
```
   - [ ] Add the repo

```bash
   helm repo add ibm-finops https://kubecost.github.io/finops-agent-chart 
   helm repo update
``` 
   - [ ] Install IBM FinOps CAC on agent clusters using the customized [agent values file template](/cloudy-advanced-containers/ibm-finops-agent.yaml).

```bash
helm upgrade --install ibm-finops-agent ibm-finops/finops-agent \ \ 
  --namespace ibm-finops-agent --create-namespace \ 
     -f ibm-finops-agent.yaml
```
   - [ ] Verify ETL pipeline is working and that the agent is reporting metrics in the kubecost console. This can take anywhere from 25 mins or more depending on how pods are running on the local agent cluster. Ensure the finops pod is running and check finops-agent pod logs for errors pushing to the bucket often found in the beginning of the log stream.

## Optional Configuration

 **Kubecost Actions**

Continuous Container Requst Right-sizing & Resource Quota Right-sizing Automation

1. **Install the Cluster Controller from the Kubecost repo**

   - [ ] Install the Cluster Controller from the Kubecost repo using the cluster-controller values file template. Ensure you modify global.clusterID to match the cluster name of the agent cluster.

```bash
helm upgrade --install ibm-kubecost-cluster-controller --repo https://kubecost.github.io/kubecost/ kubecost \ \ 
  --namespace ibm-finops-agent --create-namespace \ 
     -f cluster-controller.yaml
```


## Troubleshooting

Common issues and their solutions will be documented here.

## References

- [Cloudability Advanced Documentation](https://www.ibm.com/docs/en/cloudability-commercial/cloudability-essentials/saas?topic=allocation-cloudability-advanced-containers)
- [Helm Chart Reference](https://github.com/kubecost/ibm-finops-agent)
- [Support Resources](https://support.ibm.com) 
