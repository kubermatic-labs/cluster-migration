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
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "please set cluster id: 00_deploy.sh CLUSTER_ID PROJECT_ID [TARGET_CLOUD]"
  kubectl get cluster
  exit 1
fi
if [[ $# -lt 2 ]] || [[ "$1" == "--help" ]]; then
  echo "please set project id: 00_deploy.sh CLUSTER_ID PROJECT_ID [TARGET_CLOUD]"
  echo "execute on master: 'kubectl get project'"
  kubectl get project
  exit 1
fi
CLUSTER_ID="$1"
PROJECT_ID="$2"
TARGET_CLOUD=${3:-gcp}
SOURCE_CLOUD="vsphere"
set -euf -o pipefail

######## ENV setting
COMMON_FUNCTIONS='../../helper/bash_common_functions.source.sh'

if [[ ${TARGET_CLOUD} == "aws" ]]; then
  #### KEY file contains:
  # B64_AWS_ACCESS_KEY_ID
  # B64_AWS_SECRET_ACCESS_KEY
  # AWS_REGION="eu-west-1"
  # K8C_DATACENTER_NAME="migration-aws-eu-west-1"
  KEY_FILE='../../.env/aws.tobi.lab.source.sh'
elif [[ ${TARGET_CLOUD} == "gcp" ]]; then
  #### KEY file contains:
  ### double B64 decoded
  # B64_GCP_SA=
  # K8C_DATACENTER_NAME="gcp"
  KEY_FILE='../../.env/gcp.tobi.source.sh'
fi
echo "TARGET_CLOUD: $TARGET_CLOUD"
#DRY_RUN='--dry-run=server -o yaml'
DRY_RUN=''
########
source ${COMMON_FUNCTIONS}
source ${KEY_FILE}

TMP_FOLDER=".tmp/${TARGET_CLOUD}"
mkdir -p ${TMP_FOLDER}

if check_continue "[step 0] backup spec -  cluster ${CLUSTER_ID}"; then
  kubectl get cluster ${CLUSTER_ID} -o yaml > ${TMP_FOLDER}/backup.cluster.${CLUSTER_ID}.yaml
fi
if check_continue "[step 1] pause cluster ${CLUSTER_ID}"; then
  kubectl ${DRY_RUN} patch cluster ${CLUSTER_ID} \
    --patch "$(cat cluster.pause.true.patch.yaml)" --type merge
fi


tmpfile="${TMP_FOLDER}/patch.cluster.${CLUSTER_ID}.yaml"
if check_continue "[step 1] patch cloud provider -  cluster ${CLUSTER_ID}"; then
  kubectl --dry-run=server -o yaml patch cluster ${CLUSTER_ID} \
    --patch "$(render_yaml ${SOURCE_CLOUD}/cluster.cloud.remove.cred.patch.yaml)" --type merge | kexp > $tmpfile
  echo -e "\n ..... check cluster spec"
  echo "1. remove cloud secret reference"
  echo -e "`pwd`/$tmpfile"
  if check_continue "apply updated $tmpfile -  cluster ${CLUSTER_ID}"; then
    kubectl apply -f "$tmpfile"
  fi
fi

if check_continue "[step 1] unpause cluster ${CLUSTER_ID} to start reconciling"; then
  kubectl ${DRY_RUN} patch cluster ${CLUSTER_ID} \
    --patch "$(cat cluster.pause.false.patch.yaml)" --type merge

  echo -e "\n[step 1] ..... wait reconciling, check cloud cluster spec" && sleep 10
  kubectl get cluster ${CLUSTER_ID} -o yaml | kexp
  if check_continue "watch"; then
    watch kubectl -n "cluster-${CLUSTER_ID}" get pod
  fi
fi

if check_continue "[step 2] pause cluster ${CLUSTER_ID}"; then
  kubectl ${DRY_RUN} patch cluster ${CLUSTER_ID} \
    --patch "$(cat cluster.pause.true.patch.yaml)" --type merge
fi

if check_continue "[step 2] patch cloud provider -  cluster ${CLUSTER_ID}"; then
  if check_continue "[step 2] create secret -  cluster ${CLUSTER_ID}"; then
    render_yaml ${TARGET_CLOUD}/target.secret.template.yaml | kubectl ${DRY_RUN} apply -f -
  fi
  kubectl --dry-run=server -o yaml patch cluster ${CLUSTER_ID} \
    --patch "$(render_yaml ${TARGET_CLOUD}/target.cluster.cloud.patch.yaml)" --type merge | kexp > $tmpfile
  echo -e "\n[step 2] ..... check cluster spec"
  echo "- remove orig cloud"
  echo "- remove finalizer"
#  echo "- remove managedFields ref to orig cloud"
  echo -e "`pwd`/$tmpfile"
  if check_continue "[step 2] apply updated $tmpfile -  cluster ${CLUSTER_ID}"; then
    kubectl apply -f "$tmpfile"
  fi

fi

if check_continue "[step 2] unpause cluster ${CLUSTER_ID} to start reconciling"; then
  kubectl ${DRY_RUN} patch cluster ${CLUSTER_ID} \
    --patch "$(cat cluster.pause.false.patch.yaml)" --type merge

  echo -e "\n[step 2] ..... wait reconciling, check cloud cluster spec" && sleep 10
  kubectl get cluster ${CLUSTER_ID} -o yaml | kexp
  if check_continue "watch"; then
    watch kubectl -n "cluster-${CLUSTER_ID}" get pod
  fi
fi

if check_continue "[step 2] metadata for md of cluster ${CLUSTER_ID}"; then
  echo "####### DATA for machine deployment"
  echo "#cluster id"
  kubectl get cluster -o yaml ${CLUSTER_ID} | yq e '.metadata.name' -
  echo "#project id"
  kubectl get cluster -o yaml ${CLUSTER_ID} | yq e '.metadata.labels' -
  echo "#cloud spec"
  kubectl get cluster -o yaml ${CLUSTER_ID} | yq e '.spec.cloud.'"${TARGET_CLOUD}" -
fi

if check_continue "[step 3] rollout VPN overlay ${CLUSTER_ID}"; then
  ./20_vpn_deploy.sh ${CLUSTER_ID}
fi

pause_script " ===> Deploy new MachineDeployment!"
pause_script " ===> Deploy now VPN overlay to nodes!"
pause_script " ===> Check VPN by ssh and IPs"
pause_script " ===> Start Migration of Workload :-)"
#
#if check_continue "remove vsphere spec -  cluster ${CLUSTER_ID}"; then
#  kubectl ${DRY_RUN} patch cluster ${CLUSTER_ID} \
#    --patch "$(cat cluster.cloud.remove.vpshere.patch.yaml)" --type merge
#
#  echo -e "\n ..... check cluster spec"
#  kubectl get cluster ${CLUSTER_ID} -o yaml | kexp
#fi
#
#if check_continue "recreate cluster ${CLUSTER_ID} control plane"; then
#   kubectl -n cluster-${CLUSTER_ID} delete deployment --all
#
#  echo -e "\n ..... wait reconciling, check cloud cluster spec"
#  watch kubectl get pod -n cluster-${CLUSTER_ID}
#fi
#exit
