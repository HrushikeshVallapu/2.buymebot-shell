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
dnf install mysql-server -y &>>$log_file
validate $? "installing mysql "

systemctl enable mysqld &>>$log_file
validate $? "enabling mysql"

systemctl start mysqld &>>$log_file
validate $? "starting mysql"

mysql_secure_installation --set-root-pass $mysql_root_password
validate $? "setting root password"



end_time=$(date +%s)
total_time=$(($end_time - $start_time))

echo -e "script execution completely, $y time taken : $total_time seconds $n" | tee -a $log_file