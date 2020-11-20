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
set -euf -o pipefail
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "please set MachineDeployment id: 00_pause.sh MACHINE_DEPLOYMENT_ID"
  kubectl -n kube-system get md
  exit 1
fi
MD_ID="$1"

source ${COMMON_FUNCTIONS}
if check_continue "pause MachineDeployment ${MD_ID}"; then
  kubectl -n kube-system patch md ${MD_ID} \
    --patch "$(cat md.pause.false.patch.yaml)" --type merge
  echo "..."
  kubectl -n kube-system get md ${MD_ID} -o yaml | kexp
fi