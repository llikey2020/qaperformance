#/usr/bin/env sh

set -ex

# The ALLUXIO_UFS and AWS_* env vars need to be setup before running
# In GitLab, these are stored as project variables in Settings -> CI/CD -> Variables

cat << EOF > alluxio.yaml
properties:
    alluxio.master.mount.table.root.ufs: ${ALLUXIO_UFS}
    alluxio.master.mount.table.root.option.aws.accessKeyId: ${AWS_ACCESS_KEY_ID}
    alluxio.master.mount.table.root.option.aws.secretKey: ${AWS_SECRET_ACCESS_KEY}
    alluxio.underfs.s3.default.mode: 777
    alluxio.underfs.s3.inherit.acl: false
    alluxio.security.authentication.type: NOSASL
    alluxio.security.authorization.permission.enabled: false
journal:
    type: UFS
    ufsType: local
    folder: /journal
    size: 1Gi
    volumeType: emptyDir
    medium: ""
master:
    count: 1
shortCircuit:
    enabled: false
tieredstore:
    levels:
    - level: 0
      alias: SSD
      mediumtype: SSD
      path: /ssd
      name: alluxio-ssd
      quota: ${CACHE_SSD_SIZE}
      type: emptyDir
EOF

helm repo add alluxio-charts https://alluxio-charts.storage.googleapis.com/openSource/2.6.0
helm install alluxio -f alluxio.yaml alluxio-charts/alluxio --wait

echo -n "${AWS_ACCESS_KEY_ID}" > aws-access-key
echo -n "${AWS_SECRET_ACCESS_KEY}" > aws-secret-key
kubectl create secret generic aws-secrets --from-file=aws-access-key --from-file=aws-secret-key

cat << EOF > values.yaml
s3:
  enableS3: true
  enableIAM: false
  secret: aws-secrets
  logDirectory: ${ALLUXIO_UFS}spark-logs/performance
  # accessKeyName is an AWS access key ID. Omit for IAM role-based or provider-based authentication.
  accessKeyName: aws-access-key
  # secretKey is AWS secret key. Omit for IAM role-based or provider-based authentication.
  secretKeyName: aws-secret-key

gcs:
  enableGCS: false
  logDirectory: gs://spark-hs/

pvc:
  enablePVC: false

nfs:
  enableExampleNFS: false

service:
  type: NodePort
  port:
    number: 18080
  annotations: {}

rbac:
  create: false
EOF

helm repo add stable https://charts.helm.sh/stable
helm install -f values.yaml spark-history-server stable/spark-history-server --namespace performance-47-testing

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs mkdir /${SPARK_EVENTLOG_DIR} || true