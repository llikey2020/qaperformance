#/usr/bin/env sh

set -ex

helm uninstall alluxio alluxio-charts/alluxio || true
kubectl delete pod spark-driver --wait || true
