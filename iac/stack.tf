resource "null_resource" "applyDeployments" {
  triggers = {
    hash = filemd5("../etc/deployments.yaml")
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = "../etc/${var.settings.cluster.identifier}-kubeconfig.yaml"
      MANIFEST_FILENAME = "../etc/deployments.yaml"
    }

    quiet   = true
    command = "../bin/applyManifest.sh"
  }
}

resource "null_resource" "applyServices" {
  triggers = {
    hash = filemd5("../etc/services.yaml")
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = "../etc/${var.settings.cluster.identifier}-kubeconfig.yaml"
      MANIFEST_FILENAME = "../etc/services.yaml"
    }

    quiet   = true
    command = "../bin/applyManifest.sh"
  }
}