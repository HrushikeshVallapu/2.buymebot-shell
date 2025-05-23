source ./creds.secrets

start_time=$(date +%s)
instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "frontend")
domain_name="buymebot.shop"

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

for service in "${instances[@]}"
do
  echo "Connecting to $service"
    if [ "$service" != "frontend" ] 
    then
        host="$service.$domain_name"
    else
        host="$domain_name"
    fi

    # Using if/elif to set SERVICE_PASS
    if [ "$service" = "mysql" ] 
    then
        SERVICE_PASS="$MYSQL_PASSWORD"
    elif [ "$service" = "rabbitmq" ]
    then
        SERVICE_PASS="$RABBITMQ_PASSWORD"
    elif [ "$service" = "shipping" ]
    then
        SERVICE_PASS="$SHIPPING_PASSWORD"
    else
        SERVICE_PASS=""
    fi

    if [ -z "$SERVICE_PASS" ]
    then
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
    else
    # Pass the password as env var
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$host" 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "2.buymebot-shell" ]; then
  git clone https://github.com/HrushikeshVallapu/2.buymebot-shell.git
fi
cd 2.buymebot-shell
git reset --hard HEAD
git pull
chmod +x $service.sh
sudo SERVICE_PASS="$SERVICE_PASS" bash $service.sh
EOF
    fi

done

end_time=$(date +%s)
total_time=$(($end_time - $start_time))
total_minutes=$(($total_time / 60))
total_seconds=$(($total_time % 60))
echo -e "script execution completed, $y time taken : $total_minutes::$total_seconds seconds $n" | tee -a $log_file
