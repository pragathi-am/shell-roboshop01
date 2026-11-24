#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop01"
LOG_FILE="/var/log/shell-roboshop01/$0.log"
SCRIPT_DIR=$pwd   
MONGODB_HOST="mongodb.daws88spr.online"

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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "rabbitmq.repo copy" | tee -a $LOG_FILE

dnf install rabbitmq-server -y  
validate $? "rabbitmq-server installation" | tee -a $LOG_FILE

systemctl enable rabbitmq-server
systemctl start rabbitmq-server 

validate $? "rabbitmq-server service start" | tee -a $LOG_FILE

rabbitmqctl add_user roboshop roboshop123
validate $? "rabbitmq user creation" | tee -a $LOG_FILE

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "rabbitmq user permission" | tee -a $LOG_FILE