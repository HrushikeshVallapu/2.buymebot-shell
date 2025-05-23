#!/bin/bash

source ./common.sh
app_name=mysql

check_root

echo "please enter root password to setup"
#read -s mysql_root_password
PASSWORD=${SERVICE_PASS}

dnf install mysql-server -y &>>$log_file
validate $? "installing mysql "

systemctl enable mysqld &>>$log_file
validate $? "enabling mysql"

systemctl start mysqld &>>$log_file
validate $? "starting mysql"

mysql_secure_installation --set-root-pass $PASSWORD
validate $? "setting root password"

print_time