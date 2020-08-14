#!/bin/bash
#
# Deploy using Terraform

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

BASE_DIR=$( dirname "$0" )
ABS_DIR=$( realpath $BASE_DIR )

cd $ABS_DIR/terraform

echo "$@" | grep "\-\-destroy" >/dev/null && {
    echo "> Destroying all infra resources..."
    terraform destroy
    exit 0
}

echo "> Initializing Terraform..."
terraform init

echo "> Creating all resources for infra demo..."
terraform apply