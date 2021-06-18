#/usr/bin/env sh

set -ex

cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: psp-clusterrole-bind
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: psp-clusterrole
subjects:
- kind: ServiceAccount
  name: ${NAMESPACE}-service-account
  namespace: ${NAMESPACE}
EOF

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spark
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: psp-spark-bind
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: psp-clusterrole
subjects:
- kind: ServiceAccount
  name: spark
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: spark-admin-bind
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: spark
  namespace: ${NAMESPACE}
EOF

cat << EOF > alluxio.yaml
properties:
    alluxio.master.mount.table.root.ufs: ${ALLUXIO_UFS}
    alluxio.master.mount.table.root.option.aws.accessKeyId: ${AWS_ACCESS_KEY_ID}
    alluxio.master.mount.table.root.option.aws.secretKey: ${AWS_SECRET_ACCESS_KEY}
    alluxio.underfs.s3.default.mode: 777
    alluxio.underfs.s3.inherit.acl: false
    alluxio.security.authentication.type: "NOSASL"
    alluxio.security.authorization.permission.enabled: false
journal:
    type: "UFS"
    ufsType: "local"
    folder: "/journal"
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
    mediumtype: MEM, SSD
    path: /dev/shm,/ssd
    name: alluxio-mem,alluxio-ssd
    quota: ${CACHE_MEM_SIZE},${CACHE_SSD_SIZE}
    type: emptyDir
EOF

helm repo add alluxio-charts https://alluxio-charts.storage.googleapis.com/openSource/2.6.0
helm install alluxio -f alluxio.yaml alluxio-charts/alluxio -n ${ENVIRONMENT_NAME}
