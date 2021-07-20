#/usr/bin/env sh

set -ex

kubectl delete --ignore-not-found=true svc/${HISTORY_SERVER_POD_NAME} deploy/${HISTORY_SERVER_POD_NAME} || true

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_WAREHOUSE} || true
kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_DEPENDENCY_DIR} || true
if [[ ${RUN_CONDITION} == "cold" || ${IS_MANUAL} == "true" ]]; then
    helm uninstall alluxio || true
fi

kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true