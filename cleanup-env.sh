#/usr/bin/env sh

set -ex

helm uninstall history-server || true
helm uninstall spark-dashboard || true

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_WAREHOUSE} || true
kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_DEPENDENCY_DIR} || true
if [[ ${RUN_CONDITION} == "cold" || ${IS_MANUAL} == "true" ]]; then
    helm uninstall alluxio || true
fi

kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true