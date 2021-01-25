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
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "please set cluster id: 10_deploy.sh CLUSTER_ID PROJECT_ID [TARGET_CLOUD]"
  kubectl get cluster
  exit 1
fi
if [[ $# -lt 2 ]] || [[ "$1" == "--help" ]]; then
  echo "please set project id: 10_deploy.sh CLUSTER_ID PROJECT_ID [TARGET_CLOUD]"
  echo "execute on master: 'kubectl get project'"
  kubectl get project
  exit 1
fi
CLUSTER_ID="$1"
PROJECT_ID="$2"
TARGET_CLOUD=${3:-gcp}

set -euf -o pipefail
if [[ ${TARGET_CLOUD} == "aws" ]]; then
  read -p "AWS_INSTANCE_PROFILE: " AWS_INSTANCE_PROFILE
  read -p "AWS_SECURITY_GROUP: " AWS_SECURITY_GROUP
fi
TMP_FOLDER=".tmp/${TARGET_CLOUD}"
mkdir -p ${TMP_FOLDER}
tmpfile=${TMP_FOLDER}/md.cluster.${CLUSTER_ID}.yaml

if check_continue "create ${TARGET_CLOUD} MachineDeployment -  cluster ${CLUSTER_ID}"; then
  pause_script "===> check if source MachineDeployment is paused!"
  render_yaml ${TARGET_CLOUD}/md.target.template.yaml > $tmpfile
  cat $tmpfile
fi
if check_continue "apply MachineDeployment of $tmpfile"; then
  kubectl apply -f "$tmpfile"
fi
if check_continue "watch MachineDeployment creation"; then
  watch kubectl -n kube-system get md,ma,node
fi
#if check_continue "Apply second Ingress LB"; then
#  kubectl apply -f ingress.svc.lb.yaml
#fi