resource "local_file" "configMaps" {
  filename = "../etc/configMaps.yaml"
  content  = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: akamai-secure-lke-automation
  namespace: ${var.settings.cluster.namespace}
data:
  run.sh: |-
    #!/bin/bash

    function checkDependencies() {
      export LINODE_CLI_CMD=$(which linode-cli)

      if [ -z "$LINODE_CLI_CMD" ]; then
        echo "linode-cli is not installed!"

        exit 1
      fi

      export CLUSTER_ID=$($LINODE_CLI_CMD --text \
                                          --no-headers \
                                          --format id \
                                          lke clusters-list \
                                          --label ${var.settings.cluster.identifier})

      if [ -z "$CLUSTER_ID" ]; then
        echo "LKE cluster not found!"

        exit 1
      fi
    }

    function createFirewall() {
      export FIREWALL_ID=$($LINODE_CLI_CMD --text \
                                           --no-headers \
                                           --format id \
                                           firewalls list \
                                           --label ${var.settings.cluster.identifier}-fw)

      if [ -z "$FIREWALL_ID" ]; then
        export FIREWALL_ID=$($LINODE_CLI_CMD --text \
                                             --no-headers \
                                             --format id \
                                             firewalls create \
                                             --label ${var.settings.cluster.identifier}-fw \
                                             --rules.inbound_policy DROP \
                                             --rules.outbound_policy ACCEPT
      fi
    }

    function assignNodesToFirewall() {
      export NODES=$($LINODE_CLI_CMD --text \
                                     --no-headers \
                                     --format instance_id \
                                     lke pools-list $CLUSTER_ID)

      for NODE in $NODES; do
        $LINODE_CLI_CMD firewalls \
                        device-create \
                        --id $NODE \
                        --type linode $FIREWALL_ID;
      done
    }

    function main() {
      checkDependencies
      createFirewall
      assignNodesToFirewall
    }

    main
EOT
}