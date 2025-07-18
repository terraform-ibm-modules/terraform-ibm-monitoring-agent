# Deploy agent in IKS cluster

An example that shows how to deploy the agent in an IKS cluster.

The following resources are provisioned:

- A new resource group, if an existing one is not passed in.
- A basic VPC (if `is_vpc_cluster` is true).
- A Kubernetes cluster.
- An IBM Cloud Monitoring instance.
- An SCC Workload Protection instance.
- The Monitoring and Workload Protection agent.
