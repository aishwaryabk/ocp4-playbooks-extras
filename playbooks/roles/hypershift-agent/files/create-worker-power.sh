#!/bin/bash

# Create power worker
echo "Create power worker"
hyp_name=$2
bastion_ip=$4

for ((count=0; count < $3; count++))
do 
  echo "in for loop"
  hyp_name=$2
  bastion_ip=$4
  worker_count=$3

  iso_url=$(oc get infraenv $hyp_name-ppc -n clusters-$hyp_name -o json | jq -r '."status"."isoDownloadURL"')
  echo $iso_url
  ibmcloud login --apikey $1
  ibmcloud target -r jp-tok -g ipi-resource-group
  ibmcloud pi ws tg crn:v1:bluemix:public:power-iaas:tok04:a/bf9f1f230466481b95a99f18739fede9:d3814f7d-bbf0-4c56-aaa2-e0d2ddec6e38::
  ibmcloud cis instance-set rdr-ipi-validation-dns
  ibmcloud pi ins create $hyp_name-power-worker-$count --image rhcos-417--tier1 --subnets ocp-private-net --memory 16 --processors 0.5 --processor-type shared --sys-type e980
  sleep 300
  instance_id=$(ibmcloud pi ins list | grep ${hyp_name}-power-worker-$count | awk '{print $1}')
  echo $instance_id
  instance_ip=$(ibmcloud pi ins get $instance_id --json | jq -r '.networks[].ipAddress')
  echo $instance_ip
  instance_mac=$(ibmcloud pi ins get $instance_id --json | jq -r '.networks[].macAddress')
  echo $instance_mac
  ssh -i /root/id_rsa root@$bastion_ip "hyp_name=$hyp_name iso_url=$iso_url instance_ip=$instance_ip instance_mac=$instance_mac count=$count worker_count=$worker_count bash -s" << 'EOF'
    echo $iso_url > /tmp/${hyp_name}-iso-download-link
    mkdir -p /tmp/shared
    echo "$instance_ip" > /tmp/shared/ippoweraddr
    echo "./agent-ci/scripts/setup-pxe-boot.sh $hyp_name $worker_count $hyp_name-power-worker-$count,$instance_mac,$instance_ip"
    ./agent-ci/scripts/setup-pxe-boot.sh $hyp_name $worker_count $hyp_name-power-worker-$count,$instance_mac,$instance_ip
    sleep 240
EOF
  #Reboot power worker node
  ibmcloud pi ws tg crn:v1:bluemix:public:power-iaas:tok04:a/bf9f1f230466481b95a99f18739fede9:d3814f7d-bbf0-4c56-aaa2-e0d2ddec6e38
  ibmcloud pi ins ls
  ibmcloud pi ins act $instance_id --operation soft-reboot
  sleep 600

  echo "Waiting for agent to be generated..."

  # Loop until an agent shows up
#  while true; do
#    echo "In while loop for agent approval"
#    agent=$(oc get agents -n "clusters-$hyp_name" --no-headers 2>/dev/null | awk '{print $1}')
#    echo "$agent"

#    if [ -n "$agent" ]; then
#      echo "Agent detected: $agent"

#      if oc get agent -A --no-headers | awk '{if ($worker_count=="false" || $4=="false") exit 0} END{exit 1}'; then
#        oc -n "clusters-$hyp_name" patch agent $agent -p '{"spec":{"approved":true,"hostname":"worker-$count.$hyp_name.qe-ppc64le.cis.ibm.net"}}' --type merge
#        oc -n clusters scale nodepool $hyp_name-ppc --replicas $((count+1))
#      else
#        echo "Agents are already approved"
#      fi

#      break
#    fi

#    sleep 5

#  done

#  while true; do
#    echo "In while loop for agent done status"
#    if oc get agent -A --no-headers | awk '{if ($5=="Done") exit 0} END{exit 1}'; then
#      echo "Done"
      #gives n agents status -- based on number of agents.
      #needs to check if all are in done state
#      break
#    else
#      echo "Not Done"
#    fi
#    sleep 10
#  done
done
