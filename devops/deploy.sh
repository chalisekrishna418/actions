#!/usr/bin/env sh

ME=$(basename "$0")

usage() {
  echo "Usage: $ME" >&2
  exit 1
}

DEPLOYMENT=$COMPONENT-deploy
CONTAINER=$COMPONENT
DATE=$(cat $TIMESTAMP)
NAMESPACES=$(kubectl get deploy -A -l repo=$REPO_NAME | cut -f1 -d " " | grep -v NAMESPACE)

trigger_deployment() {
    echo "[DEPLOYMENT STARTED] $1"
    kubectl -n $1 set image deployment/$DEPLOYMENT $CONTAINER=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
    kubectl -n $1 rollout status deploy $DEPLOYMENT
    echo "[DEPLOYMENT FINISHED] $1 (exit code: $?)"    
}

IFS=','
MAX_DEPLOYMENT=5
running=0
total=0

echo "ℹ️ Maximum parallel deployments: $MAX_DEPLOYMENT"

for NAMESPACE in $NAMESPACES
do
    trigger_deployment $NAMESPACE &
    let total+=1
    let running+=1
    if [ $running -eq $MAX_DEPLOYMENT ]; then
        echo "⌛ $running deployments in-progress, waiting to complete..."
        wait
        running=0
    fi
done

echo "⌛ $running deployments in-progress, waiting to complete..."
wait
echo "🎉 $total deployments completed!"
