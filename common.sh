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

check_root(){
    if [ $userid -ne 0 ]
    then 
        echo -e "$r you are not root user $n" | tee -a $log_file
        exit 1
    else
        echo "preparing to start the installation" | tee -a $log_file
    fi
}

validate(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$g  $2 success $n" | tee -a $log_file
    else   
        echo -e "$r  $2 failed $n" | tee -a $log_file
        exit 1
    fi
}
nginx_setup(){

    dnf module disable nginx -y &>>$log_file
    validate $? "disabling nginx"

    dnf module enable nginx:1.24 -y &>>$log_file
    validate $? "enabling nginx:1.24"

    dnf install nginx -y &>>$log_file
    validate $? "installing nginx"

    systemctl enable nginx &>>$log_file
    systemctl start nginx 
    validate $? "Starting nginx"
}

python3_setup(){
    dnf install python3 gcc python3-devel -y &>>$log_file
    validate $? "installing python3"

    pip3 install -r requirements.txt &>>$log_file
    validate $? "installing dependencies"
}

maven_setup(){

    dnf install maven -y &>>$log_file
    validate $? "installing maven and java"

    mvn clean package &>>$log_file
    validate $? "packaging the shipping application"

    mv target/shipping-1.0.jar shipping.jar &>>$log_file
    validate $? "moving and renaming jar file"
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$log_file
    validate $? "disabling nodejs"

    dnf module enable nodejs:20 -y &>>$log_file
    validate $? "enabling nodejs:20"

    dnf install nodejs -y &>>$log_file
    validate $? "installing nodejs:20"

    npm install &>>$log_file
    validate $? "installing dependencies"
}

systemd_setup(){

    cp $script_dir/$app_name.service /etc/systemd/system/$app_name.service
    validate $? "copying $app_name service"

    systemctl daemon-reload &>>$log_file
    systemctl enable $app_name &>>$log_file
    systemctl start $app_name
    validate $? "starting $app_name"
}

app_setup(){
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

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$log_file
    validate $? "downloading $app_name zip file"


    rm -rf /app/*
    cd /app
    unzip /tmp/$app_name.zip &>>$log_file
    validate $? "unzipping $app_name"

}
print_time(){
    end_time=$(date +%s)
    total_time=$(($end_time - $start_time))
    echo -e "script execution completed, $y time taken : $total_time seconds $n" | tee -a $log_file
}