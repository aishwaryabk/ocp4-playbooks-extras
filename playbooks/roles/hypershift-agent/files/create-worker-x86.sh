#!/bin/bash

# Create x86_64 worker
echo "ibmcloud login --apikey $1"

hyp_name=$2
bastion_ip=$4

for ((count=0; count < $3; count++))
do 
  hyp_name=$2
  bastion_ip=$4
  ibmcloud login --apikey $1
  ibmcloud target -r jp-tok -g ipi-resource-group
  ibmcloud pi ws tg crn:v1:bluemix:public:power-iaas:tok04:a/bf9f1f230466481b95a99f18739fede9:d3814f7d-bbf0-4c56-aaa2-e0d2ddec6e38::
  ibmcloud cis instance-set rdr-ipi-validation-dns


  #ibmcloud pi ins create $hyp_name-power-worker-$count --image rhcos-417--tier1 --subnets ocp-private-net --memory 16 --processors 0.5 --processor-type shared --sys-type e980
  #instance_id=$(ibmcloud pi ins list | grep ${hyp_name}-power-worker-$count | awk '{print $1}')
  echo $instance_id
  #instance_ip=$(ibmcloud pi ins get 852c250d-8414-4826-ad17-79cd324b6752 --json | jq -r '.networks[].ipAddress')
  echo $instance_ip
  instance_mac=$(ibmcloud pi ins get 852c250d-8414-4826-ad17-79cd324b6752 --json | jq -r '.networks[].macAddress')
  
  ## get initrd and other urls from ISO
  ssh -i /root/id_rsa root@$bastion_ip "hyp_name=$hyp_name instance_ip=$instance_ip instance_mac=$instance_mac count=$count bash -s" << 'EOF'
    mkdir -p /tmp/shared
    echo "$instance_ip" > /tmp/shared/ipx86addr
    
    
    ./agent-ci/scripts/cleanup-pxe-boot.sh $hyp_name 1 $hyp_name-power-worker-$count,$instance_mac,$instance_ip
    sleep 240
EOF
#need to be rebooted
#  oc get agent
done
