#!/bin/bash

source ./common.sh
app_name=mongodb

check_root()

cp mongodb.repo /etc/yum.repos.d/mongodb.repo #copying mongodb.repo to the wanted location in vm
validate $? "copying mongodb repo"

dnf install mongodb-org -y &>>$log_file
validate $? "installing mongodb server"

systemctl enable mongod &>>$log_file
systemctl start mongod &>>$log_file
validate $? "enabling and  starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "update listen adress" 

systemctl restart mongod &>>$log_file
validate $? "restarting mongodb " 

print_time()