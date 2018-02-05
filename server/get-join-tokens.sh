#!/usr/bin/env bash

#echo "get-join-tokens"

# Exit if any of the intermediate steps fail
set -e

# Extract input variables
eval "$(jq -r '@sh "HOST=\(.host)"')"

#echo $HOST

# Get worker join token
WORKER=$(ssh -F ~/.ssh/config -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$HOST docker swarm join-token worker -q)
MANAGER=$(ssh -F ~/.ssh/config -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$HOST docker swarm join-token manager -q)

#echo $WORKER
#echo $MANAGER

# Pass back a JSON object
jq -n --arg worker $WORKER --arg manager $MANAGER '{"worker":$worker,"manager":$manager}'
