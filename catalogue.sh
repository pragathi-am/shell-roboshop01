#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop01"
LOG_FILE="/var/log/shell-roboshop01/$0.log"
SCRIPT_DIR=$(pwd)   
MONGODB_HOST="mongodb.daws88spr.online"
echo "SCRIPT_DIR: $SCRIPT_DIR"

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

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "catalogue zip download" | tee -a $LOG_FILE

cd /app 

rm -rf /app/*  # this removes all the files in /app directory before unzipping the new files. This is to avoid any conflicts with old files.

unzip /tmp/catalogue.zip
validate $? "catalogue zip unzip" | tee -a $LOG_FILE

cd /app 
npm install &>> $LOG_FILE
validate $? "catalogue npm install" | tee -a $LOG_FILE




cp  $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service  
validate $? "catalogue service copy" | tee -a $LOG_FILE

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue

validate $? "catalogue service start" | tee -a $LOG_FILE


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  
validate $? "mongo.repo copy" | tee -a $LOG_FILE

dnf install mongodb-mongosh -y
validate $? "mongodb-mongosh installation" | tee -a $LOG_FILE



INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -lt 0 ]; then 
   echo "catalogue database is not created. now loading "
   mongosh --host $MONGODB_HOST </app/db/master-data.js   
   validate $? "loading master data schema" | tee -a $LOG_FILE
else
   echo "catalogue database is already created $R SKIPPING $N"
fi

systemctl restart catalogue
validate $? "catalogue service restart" | tee -a $LOG_FILE