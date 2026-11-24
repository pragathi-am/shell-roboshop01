#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop01"
LOG_FILE="/var/log/shell-roboshop01/$0.log"
SCRIPT_DIR=$pwd   
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


dnf install maven -y
validate $? "maven installation" | tee -a $LOG_FILE


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "roboshop user creation" | tee -a $LOG_FILE
else
      echo "roboshop user already exists"
fi


mkdir -p /app 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
validate $? "shipping zip download" | tee -a $LOG_FILE

cd /app 

rm -rf /app/*  # this removes all the files in /app directory before unzipping the new files. This is to avoid any conflicts with old files.

unzip /tmp/shipping.zip
validate $? "shipping zip unzip" | tee -a $LOG_FILE

cd /app 
mvn clean package 
validate $? "shipping maven build" | tee -a $LOG_FILE

mv target/shipping-1.0.jar shipping.jar 
validate $? "shipping jar rename" | tee -a $LOG_FILE

cp  $SCRIPT_DIR/shipping.service  /etc/systemd/system/shipping.service  
validate $? "shipping service copy" | tee -a $LOG_FILE

systemctl daemon-reload
systemctl enable shipping 
systemctl start shipping    

validate $? "shipping service start" | tee -a $LOG_FILE

dnf install mysql -y 
validate $? "mysql client installation" | tee -a $LOG_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" 
if [ $? -ne 0 ]; then
    echo "shipping db is not present. creating shipping db"
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOG_FILE
    validate $? "shipping db creation" | tee -a $LOG_FILE
else
    echo -e "$R shipping db is already present, skipping $N" | tee -a $LOG_FILE
fi


systemctl restart shipping
validate $? "shipping service restart" | tee -a $LOG_FILE