ami_id="ami-09c813fb71547fc4f"
sg_id="sg-0142341bd063dfed3"
instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "frontend")
zone_id="Z06633071XX7HF3WWN7FZ"
domain_name="buymebot.shop"

for instance in ${instances[@]}
#for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0142341bd063dfed3 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        record_name="$instance.$domain_name"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        record_name="$domain_name"
    fi
    echo "$instance IP address: $IP"
     aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$record_name'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
done

#Waiting for DNS to resolve and SSH to be available

echo "Waiting for instances to be reachable via SSH..."
for instance in "${instances[@]}"; do
  echo "Checking SSH access for $instance..."
  for i in {1..10}; 
  do
    if [ $instance != "frontend" ]
    then
        nc -z -w3 "$instance.$domain_name" 22 && echo "$instance is ready for SSH" && break
        echo "  Attempt $i: $instance not ready yet. Waiting 10s..."
        sleep 10
    else
        nc -z -w3 "$domain_name" 22 && echo "$instance is ready for SSH" && break
        echo "  Attempt $i: $instance not ready yet. Waiting 10s..."
        sleep 10
    fi
  done
done

PASSWORD="DevOps321"
USER="ec2-user"

for service in "${instances[@]}";
do
  echo "Connecting to $service"
    if [ "$service" != "frontend" ]; 
    then
        host="$service.$domain_name"
    else
        host="$domain_name"
    fi

  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$host" 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "2.buymebot-shell" ]; then
  git clone https://github.com/HrushikeshVallapu/2.buymebot-shell.git
fi
cd 2.buymebot-shell
git reset --hard HEAD      # Discards local changes
git pull                   # Pulls latest from remote
chmod +x $service.sh
sudo bash $service.sh
EOF

done