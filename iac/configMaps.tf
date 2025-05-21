# Creates the config maps manifest file. This file contains all the settings and scripts required for the automation.
resource "local_file" "configMaps" {
  filename = "../etc/configMaps.yaml"
  content  = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: akamai-secure-lke-automation
  namespace: ${var.settings.cluster.namespace}
data:
  banner.txt: |2+
        _   _                   _   ___                        _    _  _____
       /_\ | |____ _ _ __  __ _(_) / __| ___ __ _  _ _ _ ___  | |  | |/ / __|
      / _ \| / / _` | '  \/ _` | | \__ \/ -_) _| || | '_/ -_) | |__| ' <| _|
     /_/ \_\_\_\__,_|_|_|_\__,_|_| |___/\___\__|\_,_|_| \___| |____|_|\_\___|

     ================== Firewall Provisioning Automation ====================

  run.sh: |-
    #!/bin/bash

    # Checks the dependencies of this script.
    function checkDependencies() {
      if [ -f "$ETC_DIR/banner.txt" ]; then
        cat "$ETC_DIR/banner.txt"
      fi

      export LINODE_CLI_CMD=$(which linode-cli)

      if [ -z "$LINODE_CLI_CMD" ]; then
        echo "- linode-cli is not installed!"

        exit 1
      fi

      export CLUSTER_ID=$($LINODE_CLI_CMD --text \
                                          --no-headers \
                                          --format id \
                                          lke clusters-list \
                                          --label ${var.settings.cluster.identifier})

      if [ -z "$CLUSTER_ID" ]; then
        echo "- LKE cluster '${var.settings.cluster.identifier}' was not found! Please create it first!"

        exit 1
      else
        echo "- LKE cluster '${var.settings.cluster.identifier}' was found!"
      fi
    }

    # Creates the firewall based on the cluster identifier.
    function createFirewall() {
      export FIREWALL_ID=$($LINODE_CLI_CMD --text \
                                           --no-headers \
                                           --format id \
                                           firewalls list \
                                           --label ${var.settings.cluster.identifier}-fw)

      if [ -z "$FIREWALL_ID" ]; then
        echo "- The firewall '${var.settings.cluster.identifier}-fw' was not found! Creating it now..."

        export FIREWALL_ID=$($LINODE_CLI_CMD --text \
                                             --no-headers \
                                             --format id \
                                             firewalls create \
                                             --label ${var.settings.cluster.identifier}-fw \
                                             --rules.inbound_policy DROP \
                                             --rules.outbound_policy ACCEPT)
      else
        echo "- The firewall '${var.settings.cluster.identifier}-fw' was found!"
      fi
    }

    # Automatically assign the cluster nodes into the the firewall, enabling the traffic coming from the node balancers only.
    function assignNodesToFirewall() {
      export NODES=$($LINODE_CLI_CMD --text \
                                     --no-headers \
                                     --format nodes.instance_id \
                                     lke pools-list $CLUSTER_ID)

      INBOUND_IPS=

      for NODE in $NODES; do
        NODE_IPS=$($LINODE_CLI_CMD --text \
                                   --no-headers \
                                   --format ipv4 \
                                   linodes view $NODE)

        PUBLIC_NODE_IP=$(echo $NODE_IPS | awk -F' ' '{print $1}')
        PRIVATE_NODE_IP=$(echo $NODE_IPS | awk -F' ' '{print $2}')

        if [ -z "$INBOUND_IPS" ]; then
          INBOUND_IPS="\"$PUBLIC_NODE_IP/32\", \"$PRIVATE_NODE_IP/32\""
        else
          INBOUND_IPS="$INBOUND_IPS, \"$PUBLIC_NODE_IP/32\", \"$PRIVATE_NODE_IP/32\""
        fi
      done

      INBOUND_RULES="[{\"label\": \"allow-lke-bgp\", \"action\": \"ACCEPT\", \"protocol\": \"TCP\", \"ports\": \"179\", \"addresses\": {\"ipv4\": [\"192.168.128.0/17\"]}}, {\"label\": \"allow-lke-tunneling\", \"action\": \"ACCEPT\", \"protocol\": \"UDP\", \"ports\": \"51820\", \"addresses\": {\"ipv4\": [\"192.168.128.0/17\"]}}, {\"label\": \"allow-lke-healthchecks\", \"action\": \"ACCEPT\", \"protocol\": \"TCP\", \"ports\": \"10250\", \"addresses\": {\"ipv4\": [\"192.168.128.0/17\"]}}, {\"label\": \"allow-nb-tcp-traffic\", \"action\": \"ACCEPT\", \"protocol\": \"TCP\", \"ports\": \"30000-32767\", \"addresses\": {\"ipv4\": [\"192.168.255.0/24\"]}}, {\"label\": \"allow-nb-udp-traffic\", \"action\": \"ACCEPT\", \"protocol\": \"UDP\", \"ports\": \"30000-32767\", \"addresses\": {\"ipv4\": [\"192.168.255.0/24\"]}}, {\"label\": \"allow-internal-tcp-traffic\", \"action\": \"ACCEPT\", \"protocol\": \"TCP\", \"ports\": \"1-65535\", \"addresses\": {\"ipv4\": [$INBOUND_IPS]}}, {\"label\": \"allow-internal-udp-traffic\", \"action\": \"ACCEPT\", \"protocol\": \"UDP\", \"ports\": \"1-65535\", \"addresses\": {\"ipv4\": [$INBOUND_IPS]}}]"

      $LINODE_CLI_CMD firewalls rules-update --inbound "$INBOUND_RULES" $FIREWALL_ID > /dev/null

      NEW_NODE=0

      for NODE in $NODES; do
        NODE_IS_ALREADY_IN_FIREWALL=$($LINODE_CLI_CMD --text \
                                                      --no-headers \
                                                      --format entity.id \
                                                      firewalls devices-list $FIREWALL_ID | grep $NODE)

        if [ -z "$NODE_IS_ALREADY_IN_FIREWALL" ]; then
          NODE_LABEL=$($LINODE_CLI_CMD --text \
                                       --no-headers \
                                       --format label \
                                       linodes view $NODE)

          echo "- The new node '$NODE_LABEL' was identified! Adding it into the firewall..."

          $LINODE_CLI_CMD firewalls \
                          device-create \
                          --id $NODE \
                          --type linode $FIREWALL_ID > /dev/null

          NEW_NODE=1
        fi
      done

      if [ $NEW_NODE -eq 0 ]; then
        echo "- No new nodes were identified!"
      fi
    }

    # Main function.
    function main() {
      checkDependencies
      createFirewall
      assignNodesToFirewall
    }

    main
EOT
}

# Applies the config maps manifest in the cluster.
resource "null_resource" "applyConfigMaps" {
  triggers = {
    hash = md5(local_file.configMaps.content)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = "../etc/${var.settings.cluster.identifier}-kubeconfig.yaml"
      MANIFEST_FILENAME = local_file.configMaps.filename
    }

    quiet   = true
    command = "../bin/applyManifest.sh"
  }

  depends_on = [ local_file.configMaps ]
}