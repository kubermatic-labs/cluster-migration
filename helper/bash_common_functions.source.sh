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


############ common bash functions

function check_continue() {
    echo ""
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" && return 0;;
        *)     echo "no" && return 1;;
    esac
}

function render_yaml() {
  eval "cat <<EOF
$(<$1)
EOF
"
}

function kexp(){
  if [ -t 0 ]; then
    echo "kexp has no piped input!"
    echo "usage: COMMAND | kexp"
  else
    yq d - 'metadata.resourceVersion' |
    yq d - 'metadata.uid' |
    yq d - 'metadata.creationTimestamp' |
    yq d - 'metadata.selfLink' |
    yq d - 'metadata.managedFields' |
    yq d - 'metadata.annotations.kubectl*' |
    yq d - 'spec.template.spec.providerSpec.value.overwriteCloudConfig' |
    yq d - 'status'
  fi
}