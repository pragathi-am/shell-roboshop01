#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop01"
LOG_FILE="/var/log/shell-roboshop01/$0.log"

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

dnf module disable redis -y
dnf module enable redis:7 -y

validate $? "redis module 7  enable" | tee -a $LOG_FILE

dnf install redis -y 
validate $? "redis installation" | tee -a $LOG_FILE

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
validate $? "redis.conf ip modification" | tee -a $LOG_FILE

sed -i "/protected-mode /c\protected-mode no" /etc/redis/redis.conf
validate $? "redis.conf protected mode modification" | tee -a $LOG_FILE

sed -i -e "s/127.0.0.1/0.0.0.0/g" -e "/protected-mode /c\protected-mode no" /etc/redis/redis.conf   
validate $? "redis.conf ip and protected mode modification" | tee -a $LOG_FILE


systemctl enable redis
systemctl start redis
validate $? "redis service enable and start" | tee -a $LOG_FILE