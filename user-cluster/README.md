# Migrate User Cluster Workers

## How?

Create new worker nodes in target cloud
* Machine controller with new Machine Deployment at target cloud

User worker nodes and Pods need to talk to each other at any time
* Strap a VPN overlay by DaemonSets across current and target cloud
* Route overlay CNI traffic through VPN network


Ensure reachability
* Keep old and create new cluster Ingress endpoints
* Transfer workload to new cloud
* Delete after workload / connectivity is ensured

## Workflow

### Prepare Environment
  * Ensure ssh-key is deployed on nodes
  * Machine Deployment `spec.paused: true`: [`worker/machine-deployment/00_pause.sh`](worker/machine-deployment/00_pause.sh)

### Deploy open-vpn-server on seed cluster: [`control-plane/00_vpn_deploy.sh`](./control-plane/00_vpn_deploy.sh)
Script will automate the following steps:
* Pause cluster `spec.paused: true`: [`control-plane/cluster.pause.true.patch.yaml`](./control-plane/cluster.pause.true.patch.yaml)
* Patch VPN Server [`control-plane/vpn.server.dep.patch.yaml`](control-plane/vpn.server.dep.patch.yaml)

### Deploy open-vpn-client and patch overlay:  [`worker/vpn-overlay/00_deploy.sh`](worker/vpn-overlay/00_deploy.sh)
Script will automate the following steps:
#### Demo: routing before
**Demo commands:**
```bash
# connect to one node
ssh ubuntu@IP_OF_NODE

ip addr show
ip addr show kube
ip addr show fannel.1

# ip routes
ip route
### show vpn 10.20.0.0 entries
```

`ip route show`
```
default via 10.2.0.1 dev ens192 proto dhcp src 10.2.9.219 metric 100 
10.2.0.0/17 dev ens192 proto kernel scope link src 10.2.9.219 
10.2.0.1 dev ens192 proto dhcp scope link src 10.2.9.219 metric 100 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.25.0.2 dev calic80d1693095 scope link 
172.25.0.3 dev cali294f50cc84b scope link 
172.25.0.4 dev calia90d581c59d scope link 
172.25.0.5 dev caliaf6202561c2 scope link 
172.25.0.6 dev cali74f0663c2f2 scope link 
172.25.0.8 dev cali31c31a63415 scope link 
172.25.0.9 dev caliaa0c159aa96 scope link 
172.25.1.0/24 via 172.25.1.0 dev flannel.1 onlink
```
`ip addr`
```
13: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 26:86:8e:aa:2b:b7 brd ff:ff:ff:ff:ff:ff
    inet 172.25.0.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::2486:8eff:feaa:2bb7/64 scope link 
       valid_lft forever preferred_lft forever
17: kube: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 100
    link/none 
    inet 10.20.0.46 peer 10.20.0.45/32 scope global kube
       valid_lft forever preferred_lft forever
    inet6 fe80::6aad:d242:bd7c:9815/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever

```
```
default via 10.2.0.1 dev ens192 proto dhcp src 10.2.9.219 metric 100 
10.2.0.0/17 dev ens192 proto kernel scope link src 10.2.9.219 
10.2.0.1 dev ens192 proto dhcp scope link src 10.2.9.219 metric 100 
10.20.0.0/24 via 10.20.0.45 dev kube 
10.20.0.45 dev kube proto kernel scope link src 10.20.0.46 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.25.0.2 dev calic80d1693095 scope link 
172.25.0.3 dev cali294f50cc84b scope link 
172.25.0.4 dev calia90d581c59d scope link 
172.25.0.5 dev caliaf6202561c2 scope link 
172.25.0.6 dev cali74f0663c2f2 scope link 
172.25.0.8 dev cali31c31a63415 scope link 
172.25.0.9 dev caliaa0c159aa96 scope link 
172.25.1.0/24 via 172.25.1.0 dev flannel.1 onlink
```  
#### Applied changes
* Created VPN interface, see [`worker/vpn-overlay/vpn.client.ds.yaml`](worker/vpn-overlay/vpn.client.ds.yaml)
* Applied canal change of interface to `kube`, see [`(worker/vpn-overlay/canal.conf.cm.patch.yaml`](worker/vpn-overlay/canal.conf.cm.patch.yaml) 
```
default via 10.2.0.1 dev ens192 proto dhcp src 10.2.9.219 metric 100 
10.2.0.0/17 dev ens192 proto kernel scope link src 10.2.9.219 
10.2.0.1 dev ens192 proto dhcp scope link src 10.2.9.219 metric 100 
10.20.0.0/24 via 10.20.0.45 dev kube 
10.20.0.45 dev kube proto kernel scope link src 10.20.0.46 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.25.0.2 dev calic80d1693095 scope link 
172.25.0.3 dev cali294f50cc84b scope link 
172.25.0.4 dev calia90d581c59d scope link 
172.25.0.5 dev caliaf6202561c2 scope link 
172.25.0.6 dev cali74f0663c2f2 scope link 
172.25.0.8 dev cali31c31a63415 scope link 
172.25.0.9 dev caliaa0c159aa96 scope link 
172.25.1.0/24 via 172.25.1.0 dev flannel.1 onlink
```
```
17: kube: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 100
    link/none 
    inet 10.20.0.46 peer 10.20.0.45/32 scope global kube
       valid_lft forever preferred_lft forever
    inet6 fe80::6aad:d242:bd7c:9815/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
18: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 0e:aa:9c:fb:cc:6f brd ff:ff:ff:ff:ff:ff
    inet 172.25.0.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::caa:9cff:fefb:cc6f/64 scope link 
       valid_lft forever preferred_lft forever
```

### Update Cluster Spec & Cloud Credentials: [`control-plane/10_update_target_cloud.sh`](control-plane/10_update_target_cloud.sh)
Script will automate the following steps:
- Identify cluster and pause cluster [`control-plane/cluster.pause.true.patch.yaml`](control-plane/cluster.pause.true.patch.yaml)
- Remove current cloud provider credentials (vsphere ony right now) [`control-plane/vsphere/cluster.cloud.remove.cred.patch.yaml`](control-plane/vsphere/cluster.cloud.remove.cred.patch.yaml)
- Unpause cluster to process changes [`control-plane/cluster.pause.false.patch.yaml`](control-plane/cluster.pause.false.patch.yaml)
- Render and create new cloud provider secrets:
  - `aws`: [`control-plane/aws/target.secret.template.yaml`](control-plane/aws/target.secret.template.yaml)
  - `gcp`: [`control-plane/gcp/target.secret.template.yaml`](control-plane/gcp/target.secret.template.yaml)
- Patch new cloud provider credentials ref and settings:
  - `aws`: [`control-plane/aws/target.cluster.cloud.patch.yaml`](control-plane/aws/target.cluster.cloud.patch.yaml)
  - `gcp`: [`control-plane/gcp/target.cluster.cloud.patch.yaml`](control-plane/gcp/target.cluster.cloud.patch.yaml)
- Unpause Cluster with new Cloud Provider to start reconciling
- Collect meta data for machine deployment

### Apply new Machine Deployment [`worker/machine-deployment/10_deploy.sh`](worker/machine-deployment/10_deploy.sh)
- Create new machine deployment:
  - `aws` [`worker/machine-deployment/aws/md.target.template.yaml`](worker/machine-deployment/aws/md.target.template.yaml)
  - `gcp` [`worker/machine-deployment/gcp/md.target.template.yaml`](worker/machine-deployment/gcp/md.target.template.yaml)
- Watch the reconciling and creation of machines at the target cloud

### Test new cluster ingress entrypoint
By default the updated cloud controller manager (CCM) should reconcile and create a new load balancer by default at AWS. In may some cases the existing service blocks it. In such cases you could deploy a second service e.g. like [`worker/machine-deployment/ingress.svc.lb.yaml`](worker/machine-deployment/ingress.svc.lb.yaml).

To see if the cluster have successfully created a new cloud load balancer, go to:
- Cloud LB
  - `aws` [AWS Console > EC2 > Load Balancer](https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#LoadBalancers:sort=loadBalancerName) and check:
  - `gcp` [GCP Console > Network services > Load balancing](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list)
- LB exists with matching kubernetes tag
- new cloud Nodes are registered and healthy

Ensure Cluster Workload is accessible:
- Ensure VPN servers is patched [`control-plane/00_vpn_deploy.sh`](control-plane/00_vpn_deploy.sh)
- Ensure VPN is still deployed [`worker/vpn-overlay/00_deploy.sh`](worker/vpn-overlay/00_deploy.sh)
- LoadBalancer external IP is serving the ingress content

### Migrate Workload and update DNS

- Start to remove the wokroload of the old nodes
  a) drain, one-by-one with: `kubectl drain --ignore-daemonsets --delete-local-data to-migrate-vsphere-node-xxxx`
  b) mark current nodes as not schedule: `kubectl cordon node` + reschedule workload e.g. `kubectl rollout restart deployment xxx`
- Test after first node drain if workload is still reachable and continue
- Change DNS configuration from the old endpoint to new external name or IP of AWS load balancer

### Cleanup old cloud resources
- Delete `node` objects in cluster: `kubectl delete node to-migrate-vsphere-node-xxxx`
- Delete machines and all used resources at old cloud provider and cleanup 
- (if used) Delete/Adjust LB/DNS settings at old cloud

## TODOs and next Steps
* Automate clean up procedure
* Manage migration by Operator
  * Health checks
  * Wait conditions for migration steps
* Stabilize VPN connection
  * Multiple VPN servers
  * Soft switchover between VPN / Host network overlay
  * Evaluate Wireguard usage

