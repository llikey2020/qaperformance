#/usr/bin/env sh

set -ex

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -R /${SPARK_WAREHOUSE}
kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -R /${SPARK_DEPENDENCY_DIR}
helm uninstall alluxio alluxio-charts/alluxio || true
kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true
