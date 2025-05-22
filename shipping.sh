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

echo "please enter root password to setup"
read -s mysql_root_password

validate(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$g  $2 success $n" | tee -a $log_file
    else   
        echo -e "$r  $2 failed $n" | tee -a $log_file
        exit 1
    fi
}

dnf install maven -y &>>$log_file
validate $? "installing maven and java"


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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "downloading shipping zip file"


rm -rf /app/*
cd /app
unzip /tmp/shipping.zip &>>$log_file
validate $? "unzipping shipping"

mvn clean package &>>$log_file
validate $? "packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$log_file
validate $? "moving and renaming jar file"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service
validate $? "copying shipping service"

systemctl daemon-reload &>>$log_file
systemctl enable shipping &>>$log_file
systemctl start shipping 
validate $? "starting shipping"

dnf install mysql -y &>>$log_file
validate $? "installing mysql"

mysql -h mysql.buymebot.shop -u root -p$mysql_root_password -e 'use cities' &>>$log_file
if [ $? != 0 ]
then 
    mysql -h mysql.buymebot.shop -uroot -p$mysql_root_password < /app/db/schema.sql &>>$log_file
    mysql -h mysql.buymebot.shop -uroot -p$mysql_root_password < /app/db/app-user.sql &>>$log_file
    mysql -h mysql.buymebot.shop -uroot -p$mysql_root_password < /app/db/master-data.sql &>>$log_file
    validate $? "loading data into mysql"
else
    echo -e " $y data already loaded $n" | tee -a $log_file
fi

systemctl restart shipping &>>$log_file
validate $? "restarting shipping"

end_time=$(date +%s)
total_time=$(($end_time - $start_time))

echo -e "script execution completely, $y time taken : $total_time seconds $n" | tee -a $log_file