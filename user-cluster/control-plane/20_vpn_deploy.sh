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
COMMON_FUNCTIONS='../../helper/bash_common_functions.source.sh'
source ${COMMON_FUNCTIONS}


if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "please set cluster id: 00_deploy.sh CLUSTER_ID"
  kubectl get cluster
  exit 1
fi
CLUSTER_ID="$1"
set -euf -o pipefail

if check_continue "pause cluster ${CLUSTER_ID}"; then
  kubectl patch cluster ${CLUSTER_ID} \
    --patch "$(cat cluster.pause.true.patch.yaml)" --type merge

    echo -e "\n ..... check cluster spec"
  kubectl get cluster ${CLUSTER_ID} -o yaml | kexp
fi

if check_continue "patch VPN server for client-to-client network"; then
  kubectl -n "cluster-${CLUSTER_ID}" patch deployment openvpn-server \
    --patch "$(cat vpn.server.dep.patch.yaml)" --type strategic
  watch kubectl -n "cluster-${CLUSTER_ID}" get pod
fi