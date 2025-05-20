resource "local_file" "cronJob" {
  filename = "../etc/cronJob.yaml"
  content  = <<EOT
apiVersion: batch/v1
kind: CronJob
metadata:
  name: akamai-secure-lke
  namespace: ${var.settings.cluster.namespace}
spec:
  concurrencyPolicy: Forbid
  failedJobsHistoryLimit: 3
  schedule: "* * * * *"
  successfulJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: akamai-secure-lke
              image: ghcr.io/fvilarinho/akamai-secure-lke:latest
              command: [ "/home/akamai-secure-lke/bin/run.sh" ]
              volumeMounts:
                - name: akamai-secure-lke-automation
                  mountPath: /home/akamai-secure-lke/bin/run.sh
                  subPath: run.sh
                - name: akamai-secure-lke-secrets
                  mountPath: /home/akamai-secure-lke/.config/linode-cli
                  subPath: linode-cli
          volumes:
            - name: akamai-secure-lke-automation
              configMap:
                name: akamai-secure-lke-automation
            - name: akamai-secure-lke-secrets
              secret:
                secretName: akamai-secure-lke-secrets
EOT
}