#!/bin/bash
# Copyright 2020 The Kubermatic Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


cd $(dirname $(realpath $0))
SOURCE_CLOUD='vsphere'
COMMON_FUNCTIONS='../../../helper/bash_common_functions.source.sh'
source ${COMMON_FUNCTIONS}

function rescheduleWorkload() {
  ns=$1
  echo "...................."
  kubectl get pod -o wide -n $ns
  if check_continue "Reschedule Workload '$ns' to new nodes"; then
    #### TODO check potential first scale up then restart after new LB
    kubectl rollout restart deployment -n $ns
    watch kubectl get pod -o wide -n $ns
    echo "Workload $ns migrated!"
    pause_script ".... now test reachability"
  fi
}

if check_continue "Taint old nodes to move workload"; then
  kubectl get nodes -o wide
  echo -e "\n=> nodes to taint at $SOURCE_CLOUD:"
  kubectl get nodes --no-headers | grep -i $SOURCE_CLOUD | awk '{print $1}'
  if check_continue "cordon nodes now?"; then
    kubectl get nodes --no-headers | grep -i $SOURCE_CLOUD | awk '{print $1}' | xargs kubectl cordon
  fi
  rescheduleWorkload "echoserver"
  rescheduleWorkload "ingress-nginx"
fi

if check_continue "Apply second Ingress LB"; then
  kubectl apply -f ingress.svc.lb.yaml
  watch kubectl get -n ingress-nginx svc,pod -o wide
fi

if [[ "$SOURCE_CLOUD" == "vsphere" ]] ; then
  if check_continue "Remove on-prem MetalLB"; then
    kubectl delete ns metallb-system
    pause_script " ===> Please to remove the addon from KKP as well"
    kubectl delete -n ingress-nginx svc ingress-nginx-controller
    pause_script " ===> unpause cluster at seed or restart cloud controller manager"
  fi
  if check_continue "Remove VPN and revert Canal config"; then
    ../vpn-overlay/99_revert.sh
  fi
  if check_continue "Drain nodes"; then
    kubectl get nodes --no-headers | grep -i vsphere | awk '{print $1}' | xargs kubectl drain --ignore-daemonsets --delete-emptydir-data
  fi
  if check_continue "Remove nodes"; then
    kubectl get nodes --no-headers | grep -i vsphere | awk '{print $1}' | xargs kubectl delete node
  fi
fi