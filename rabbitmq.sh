#!/bin/bash

source ./common.sh
app_name=rabbitmq

check_root

echo "please enter rabbitmq password to setup"
# read -s rabbitmq_password
PASSWORD=${SERVICE_PASS}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "copying rabbitmq repo file"

dnf install rabbitmq-server -y &>>$log_file
validate $? "installing rabbitmq "

systemctl enable rabbitmq-server &>>$log_file
validate $? "enabling rabbitmq"

systemctl start rabbitmq-server &>>$log_file
validate $? "starting rabbitmq"

rabbitmqctl add_user roboshop $PASSWORD &>>$log_file
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$log_file

print_time