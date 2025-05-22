#!/bin/bash

source ./common.sh
app_name=catalogue

check_root
app_setup
nodejs_setup
systemd_setup

cp $script_dir/mongodb.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$log_file
validate $? "installing mongoDB client "

STATUS=$(mongosh --host mongodb.buymebot.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then 
    mongosh --host mongodb.buymebot.shop </app/db/master-data.js &>>$log_file
    validate $? "loading master data into mongo"
else 
    echo -e "$g data is already loaded $n"
fi
print_time