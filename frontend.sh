#!/bin/bash

userid=$(id -u)
r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"
logs_folder="/var/log/buymebot-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"
script_dir=$PWD

mkdir -p $logs_folder
echo "script started executing at $(date)" | tee -a $log_file

if [ $userid -ne 0 ]
then 
    echo -e "$r you are not root user $n" | tee -a $log_file
    exit 1
else
    echo "preparing to start the installation" | tee -a $log_file
fi

validate(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$g  $2 success $n" | tee -a $log_file
    else   
        echo -e "$r  $2 failed $n" | tee -a $log_file
        exit 1
    fi
}

dnf module disable nginx -y &>>$log_file
validate $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "enabling nginx:1.24"

dnf install nginx -y &>>$log_file
validate $? "installing nginx"

systemctl enable nginx &>>$log_file
systemctl start nginx 
validate $? "Starting nginx"

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