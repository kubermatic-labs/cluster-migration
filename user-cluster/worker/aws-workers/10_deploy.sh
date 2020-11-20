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
source ./00_input.sh

tmpfile=md.aws.cluster.${CLUSTER_ID}.yaml

if check_continue "create AWS md -  cluster ${CLUSTER_ID}"; then
  render_yaml md.aws.target.template.yaml > $tmpfile
  cat $tmpfile
fi
if check_continue "apply MD of $tmpfile"; then
  kubectl apply -f "$tmpfile"
fi
if check_continue "watch MD creation"; then
  watch kubectl -n kube-system get md,ma,node
fi