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
    alluxio.user.ufs.block.read.location.policy: alluxio.client.block.policy.DeterministicHashPolicy
    alluxio.user.ufs.block.read.location.policy.deterministic.hash.shards: 1
    alluxio.user.file.passive.cache.enabled: false
journal:
    type: UFS
    ufsType: local
    folder: /journal
    size: 1Gi
    volumeType: emptyDir
    medium: ""
master:
    count: 1
    resources:
      requests:
        cpu: 200m
        memory: 200Mi
jobMaster:
    resources:
      requests:
        cpu: 200m
        memory: 200Mi
worker:
    resources:
      requests:
        cpu: 200m
        memory: 200Mi
jobWorker:
    resources:
      requests:
        cpu: 200m
        memory: 200Mi

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

# Checking the status will fail if the service is not installed
if ! helm status alluxio ; then
  wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/53/packages/generic/alluxio-helm-chart/0.6.22/alluxio-0.6.22.tgz
  tar -zxf alluxio-0.6.22.tgz
  helm install alluxio -f alluxio.yaml --set journal.format.runFormat=true alluxio/ --wait
fi

if [[ ${SPARK_HISTORY_SERVER_ENABLED} == "true" ]]; then
  wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/55/packages/generic/history-server-helm-chart/0.1.0/history-server-0.1.0.tgz
  tar -zxf history-server-0.1.0.tgz
  helm install history-server --set eventLog.alluxioService=${ALLUXIO_SVC} --set eventLog.dir=${SPARK_EVENTLOG_DIR} history-server/ --wait
fi

helm install spark-dashboard spark-dashboard/ --wait

kubectl create secret docker-registry ${SPARK_REGISTRY_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${SPARK_QA_REGISTRY_USER} --docker-password=${SPARK_QA_REGISTRY_TOKEN}