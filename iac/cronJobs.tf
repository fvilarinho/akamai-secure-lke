resource "local_file" "cronJob" {
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
                  mountPath: /home/akamai-secure-lke/bin
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