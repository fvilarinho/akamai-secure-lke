resource "local_sensitive_file" "secrets" {
  filename = "../etc/secrets.yaml"
  content  = <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: linode-cli-secret
  namespace: ${var.settings.cluster.namespace}
type: Opaque
stringData:
  linode-cli: |-
    [default]
    token = ${var.credentials.linode.token}
EOT
}