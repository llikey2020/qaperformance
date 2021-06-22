#/usr/bin/env sh

set -ex

helm uninstall alluxio alluxio-charts/alluxio || true
kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true
kubectl delete pod ${HTTP_SVC} --wait=true --ignore-not-found=true
