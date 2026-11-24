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


dnf module disable nodejs -y &>> $LOG_FILE
validate $? "nodejs module disable" | tee -a $LOG_FILE

dnf module enable nodejs:20 -y &>> $LOG_FILE
validate $? "nodejs module enable" | tee -a $LOG_FILE

dnf install nodejs -y &>> $LOG_FILE
validate $? "nodejs installation" | tee -a $LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "roboshop user creation" | tee -a $LOG_FILE
else
      echo "roboshop user already exists"
fi


mkdir -p /app 

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
validate $? "cart zip download" | tee -a $LOG_FILE

cd /app 

rm -rf /app/*  # this removes all the files in /app directory before unzipping the new files. This is to avoid any conflicts with old files.

unzip /tmp/cart.zip
validate $? "cart zip unzip" | tee -a $LOG_FILE

cd /app 
npm install 
validate $? "cart npm install" | tee -a $LOG_FILE


cp  $SCRIPT_DIR/cart.service  /etc/systemd/system/cart.service  
validate $? "cart service copy" | tee -a $LOG_FILE

systemctl daemon-reload
systemctl enable cart 
systemctl start cart

validate $? "cart service start" | tee -a $LOG_FILE


