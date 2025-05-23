#!/bin/bash

source ./common.sh
app_name=shipping

check_root

echo "please enter root password to setup"
#read -s mysql_root_password 
PASSWORD=${SERVICE_PASS}

app_setup
maven_setup
systemd_setup

dnf install mysql -y &>>$log_file
validate $? "installing mysql"

mysql -h mysql.buymebot.shop -u root -p$PASSWORD -e 'use cities' &>>$log_file
if [ $? != 0 ]
then 
    mysql -h mysql.buymebot.shop -uroot -p$PASSWORD < /app/db/schema.sql &>>$log_file
    mysql -h mysql.buymebot.shop -uroot -p$PASSWORD < /app/db/app-user.sql &>>$log_file
    mysql -h mysql.buymebot.shop -uroot -p$PASSWORD < /app/db/master-data.sql &>>$log_file
    validate $? "loading data into mysql"
else
    echo -e " $y data already loaded $n" | tee -a $log_file
fi

systemctl restart shipping &>>$log_file
validate $? "restarting shipping"

print_time