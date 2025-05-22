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



validate(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$g  $2 success $n" | tee -a $log_file
    else   
        echo -e "$r  $2 failed $n" | tee -a $log_file
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$log_file
validate $? "installing python3"


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

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
validate $? "downloading payment zip file"


rm -rf /app/*
cd /app
unzip /tmp/payment.zip &>>$log_file
validate $? "unzipping payment"

pip3 install -r requirements.txt &>>$log_file
validate $? "installing dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service
validate $? "copying payment service"

systemctl daemon-reload &>>$log_file
validate $? "reloading server"

systemctl enable payment &>>$log_file
systemctl start payment 
validate $? "starting payment service"

end_time=$(date +%s)
total_time=$(($end_time - $start_time))

echo -e "script execution completely, $y time taken : $total_time seconds $n" | tee -a $log_file