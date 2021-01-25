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
COMMON_FUNCTIONS='../../../helper/bash_common_functions.source.sh'
source ${COMMON_FUNCTIONS}
set -euf -o pipefail

if check_continue "update canal overlay to use default interface"; then
  kubectl -n kube-system patch cm canal-config --patch "$(cat canal.conf.cm.patch.revert.yaml)" --type strategic
  # restart to load changed config
  kubectl -n kube-system rollout restart daemonset canal
  watch kubectl -n kube-system get pod -l k8s-app=canal -o wide
fi

if check_continue "remove VPN node network DaemonSet"; then
  kubectl -n kube-system delete -f vpn.client.ds.yaml
  watch kubectl -n kube-system get pod -l role=openvpn-client -o wide
fi
