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

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/53/packages/generic/alluxio-helm-chart/0.6.22/alluxio-0.6.22.tgz
tar -zxf alluxio-0.6.22.tgz
helm install alluxio -f alluxio.yaml --set journal.format.runFormat=true alluxio/ --wait

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${HISTORY_SERVER_POD_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${HISTORY_SERVER_POD_NAME}
  template:
    metadata:
      labels:
        app: ${HISTORY_SERVER_POD_NAME}
    spec:
      containers:
      - image: ${SPARK_IMAGE}
        name: ${HISTORY_SERVER_POD_NAME}
        volumeMounts:
        - mountPath: /opt/spark/logs
          name: log-vol
        command:
        - '/opt/spark/sbin/start-history-server.sh'
        env:
        - name: SPARK_NO_DAEMONIZE
          value: "false"
        - name: SPARK_HISTORY_OPTS
          value: "-Dspark.history.fs.logDirectory=alluxio://${ALLUXIO_SVC}/${SPARK_EVENTLOG_DIR}"
        ports:
        - name: http
          containerPort: 18080
          protocol: TCP
      volumes:
      - name: log-vol
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: ${HISTORY_SERVER_POD_NAME}
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 18080
    protocol: TCP
    name: ${HISTORY_SERVER_POD_NAME}
  selector:
    app: ${HISTORY_SERVER_POD_NAME}
EOF
