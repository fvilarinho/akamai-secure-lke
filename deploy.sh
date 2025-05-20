#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$TERRAFORM_CMD" ]; then
    echo "terraform is not installed!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh

  showBanner

  cd iac || exit 1
}

# Executes the provisioning of the infrastructure based on the IaC files.
function deploy() {
  $TERRAFORM_CMD init \
                 -upgrade \
                 -migrate-state || exit 1

  $TERRAFORM_CMD plan \
                 -out /tmp/akamai-secure-lke.plan || exit 1

  $TERRAFORM_CMD apply \
                 -auto-approve \
                 /tmp/akamai-secure-lke.plan
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  deploy
}

main