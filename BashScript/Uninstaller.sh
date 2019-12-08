#!/bin/bash

kubectl delete ns $1
kubectl delete CustomResourceDefinition scheduledsparkapplications.sparkoperator.k8s.io -n $1
kubectl delete CustomResourceDefinition sparkapplications.sparkoperator.k8s.io -n $1
kubectl delete pv parquet-pv