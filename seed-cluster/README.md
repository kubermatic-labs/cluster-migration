# Migrate Seed Cluster

## How?
Create new seed master nodes at new cloud
* New Kubernetes API  Load Balancer
* API Endpoint needs to be updated by DNS
* Block seed cluster upgrades to ensure worst case recovery


Migrate user cluster control plane
* Handle migration the same way (like user cluster workload)
* Ensure etcd quorum and migration by data replication
* Block user cluster upgrades to ensure worst case recovery


## Workflow

### Prepare Environment
* Ensure ssh-key is deployed on nodes

### Migrate Seed Master Nodes:
1. Setup VPN Overlay
2. Pause existing Cluster & Machine Deployment
3. Create and join new 2 Master Nodes
4. Add new LB Service & Update DNS
5. Remove 2 old Master Nodes and move etcd quorum to new cloud
6. Create 3rd Master Node at new cloud and remove last old Master Node

### Migrate Seed Worker Nodes:
1. VPN Overlay, Pause existing Cluster, Machine Deployment
2. Create 2 new Workers (migration steps similar to user cluster)
3. Taint existing workers as non-schedule
4. Scale up etcd count of user cluster to 5
⇒ data replicated by etcd
5. Create new LB for NodePort Proxy and update DNS
6. Add 1 new worker and drain 1 old workers
⇒ etcd quorum migrated to new cloud
7. Drain missing worker nodes, cleanup old cloud
8. Scale down etcd count of user cluster to 3
9. Remove VPN Overlay

### TODO
* add kubeone migration steps similar to [`../user-cluster/README.md`](../user-cluster/README.md)

