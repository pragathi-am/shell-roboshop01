#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop01"
LOG_FILE="/var/log/shell-roboshop01/$0.log"
SCRIPT_DIR=$(pwd)   
MYSQL_HOST="mysql.daws88spr.online"

if [ $USER_ID -ne 0 ]; then 
    echo "you are not root user. please use root user to run this"
    exit 1
fi

mkdir -p $LOG_FOLDER

R='\e[31m'
G='\e[32m'  
Y='\e[33m'
B='\e[34m'


validate(){
  if [ $1 -eq 0 ]; then
        echo -e "$2 $G successfully $N" | tee -a $LOG_FILE
  else
        echo -e "$2 $R failed" | tee -a $LOG_FILE
  fi
}


dnf module list nginx &>> $LOG_FILE
validate $? "nginx module list" | tee -a $LOG_FILE

dnf module disable nginx -y &>> $LOG_FILE
dnf module enable nginx:1.24 -y &>> $LOG_FILE
dnf install nginx -y &>> $LOG_FILE
validate $? "nginx installation" | tee -a $LOG_FILE 

systemctl enable nginx 
systemctl start nginx 
validate $? "nginx service enable and start" | tee -a $LOG_FILE

rm -rf /usr/share/nginx/html/* 
validate $? "nginx html folder cleanup" | tee -a $LOG_FILE

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "frontend zip download" | tee -a $LOG_FILE

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip

validate $? "frontend zip unzip" | tee -a $LOG_FILE

rm -rf /etc/nginx/nginx.conf
cp  $SCRIPT_DIR/nginx.conf  /etc/nginx/nginx.conf   
validate $? "nginx configuration copy" | tee -a $LOG_FILE


systemctl restart nginx     
validate $? "nginx service restart" | tee -a $LOG_FILE