#!/bin/bash

userid=$(id -u)
r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"
logs_folder="/var/log/buymebot-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"

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
        echo -e "$g installation of $2 success $n" | tee -a $log_file
    else   
        echo -e "$r installation of $2 failed $n" | tee -a $log_file
        exit 1
    fi
}

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
