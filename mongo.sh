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


cp mongo.repo /etc/yum.repos.d/mongo.repo  
validate $? "mongo.repo copy" | tee -a $LOG_FILE

dnf install mongodb-org -y &>> $LOG_FILE
validate $? "mongodb-org installation" | tee -a $LOG_FILE


systemctl enable mongod 
validate $? "mongod service enable" | tee -a $LOG_FILE

systemctl start mongod 
validate $? "mongod service start" | tee -a $LOG_FILE

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "mongod.conf modification" | tee -a $LOG_FILE

systemctl restart mongod
validate $? "mongod service restart" | tee -a $LOG_FILE
