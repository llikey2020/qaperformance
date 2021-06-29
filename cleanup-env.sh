#/usr/bin/env sh

set -ex

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_EVENTLOG_DIR} || true

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_WAREHOUSE} || true
kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_DEPENDENCY_DIR} || true
helm uninstall alluxio alluxio-charts/alluxio || true
kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true

#/opt/spark/sbin/stop-history-server.sh
