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

dnf module disable nodejs -y &>>$log_file
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "enabling nodejs:20"

dnf install nodejs -y &>>$log_file
validate $? "installing nodejs:20"

id roboshop &>>$log_file
if [ $? != 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "creating systemuser"
else
    echo -e "$g user already exist $n" 
fi

mkdir -p /app &>>$log_file
validate $? "making home dirctry for user"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
validate $? "downloading catalogue zip file"


rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$log_file
validate $? "unzipping catalogue"

npm install &>>$log_file
validate $? "installing dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "copying catalogue service"

systemctl daemon-reload &>>$log_file
systemctl enable catalogue &>>$log_file
systemctl start catalogue
validate $? "starting catalogue"

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