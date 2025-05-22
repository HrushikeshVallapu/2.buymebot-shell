#!/bin/bash

source ./common.sh
check_root

nginx_setup

rm -rf /usr/share/nginx/html/* &>>$log_file
validate $? "removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "dowloading frontend zip file"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$log_file
validate $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$log_file
validate $? "remove default nginx.conf"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf
validate $? "copying nginx.conf"

systemctl restart nginx 
validate $? "restarting nginx"