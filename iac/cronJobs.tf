# Creates the cron job manifest file. This file contains the definition of the job that will run the automation.
resource "local_file" "cronJobs" {
  filename = "../etc/cronJobs.yaml"
  content  = <<EOT
apiVersion: batch/v1
kind: CronJob
metadata:
  name: akamai-secure-lke
  namespace: ${var.settings.cluster.namespace}
spec:
  concurrencyPolicy: Forbid
  schedule: "* * * * *"
  failedJobsHistoryLimit: 1
  successfulJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          dnsPolicy: None
          dnsConfig:
            nameservers:
              - 8.8.8.8
          containers:
            - name: akamai-secure-lke
              image: ghcr.io/fvilarinho/akamai-secure-lke:latest
              imagePullPolicy: Always
              command: [ "/home/akamai-secure-lke/bin/run.sh" ]
              volumeMounts:
                - name: akamai-secure-lke-automation
                  mountPath: /home/akamai-secure-lke/bin/run.sh
                  subPath: run.sh
                - name: akamai-secure-lke-automation
                  mountPath: /home/akamai-secure-lke/etc/banner.txt
                  subPath: banner.txt
                - name: akamai-secure-lke-secrets
                  mountPath: /home/akamai-secure-lke/.config/linode-cli
                  subPath: linode-cli
          volumes:
            - name: akamai-secure-lke-automation
              configMap:
                name: akamai-secure-lke-automation
                defaultMode: 0777
            - name: akamai-secure-lke-secrets
              secret:
                secretName: akamai-secure-lke-secrets
EOT
}

# Applies the cron job manifest in the cluster.
resource "null_resource" "applyCronJobs" {
  triggers = {
    hash = md5(local_file.cronJobs.content)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = "../etc/${var.settings.cluster.identifier}-kubeconfig.yaml"
      MANIFEST_FILENAME = local_file.cronJobs.filename
    }

    quiet   = true
    command = "../bin/applyManifest.sh"
  }

  depends_on = [
    local_file.cronJobs,
    null_resource.applyConfigMaps,
    null_resource.applySecrets
  ]
}