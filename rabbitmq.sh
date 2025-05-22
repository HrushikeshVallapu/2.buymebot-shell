#!/bin/bash


start_time=$(date +%s)
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

echo "please enter rabbitmq password to setup"
read -s rabbitmq_password

validate(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$g  $2 success $n" | tee -a $log_file
    else   
        echo -e "$r  $2 failed $n" | tee -a $log_file
        exit 1
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "copying rabbitmq repo file"

dnf install rabbitmq-server -y &>>$log_file
validate $? "installing rabbitmq "

systemctl enable rabbitmq-server &>>$log_file
validate $? "enabling rabbitmq"

systemctl start rabbitmq-server &>>$log_file
validate $? "starting rabbitmq"

rabbitmqctl add_user roboshop $rabbitmq_password &>>$log_file
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$log_file

end_time=$(date +%s)
total_time=$(($end_time - $start_time))

echo -e "script execution completely, $y time taken : $total_time seconds $n" | tee -a $log_file