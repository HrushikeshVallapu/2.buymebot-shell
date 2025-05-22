#!/bin/bash

source ./common.sh
app_name=redis

check_root

dnf module disable redis -y &>>$log_file
validate $? "disabling redis"

dnf module enable redis:7 -y &>>$log_file
validate $? "enabling redis:7"

dnf install redis -y &>>$log_file
validate $? "installing redis:7"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
validate $? "updating listen address"

#sed -i 's/^[[:space:]]*protected-mode yes/protected-mode no/g' /etc/redis/redis.conf
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "updating protected mode"

systemctl enable redis &>>$log_file
systemctl start redis 
validate $? "starting redis"

print_time