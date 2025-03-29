# Monitoring agent on Kubernetes using CSE ingress endpoint with an apikey

An example that shows how to deploy a Monitoring agent in a Kubernetes cluster to send Logs directly to IBM a Cloud Monitoring instance.

The example provisions the following resources:
- A new resource group, if an existing one is not passed in.
- A basic VPC (if `is_vpc_cluster` is true).
- A Kubernetes cluster.
- An IBM Cloud Monitoring instance
- Monitoring agent
