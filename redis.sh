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
dnf module disable redis -y &>>$log_file
validate $? "disabling redis"

dnf module enable redis:7 -y &>>$log_file
validate $? "enabling redis:7"

dnf install redis -y &>>$log_file
validate $? "installing redis:7"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
validate $? "updating listen address"

#sed -i 's/^[[:space:]]*protected-mode yes/protected-mode no/g' /etc/redis/redis.conf
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "updating protected mode"

systemctl enable redis &>>$log_file
systemctl start redis 
validate $? "starting redis"

end_time=$(date +%s)
total_time=$(($end_time - $start_time))

echo -e "script execution completely, $y time taken : $total_time seconds $n" | tee -a $log_file