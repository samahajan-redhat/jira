#!/bin/bash
#mkdir /var/atlassian/application-data/jira/$MY_POD_NAME
#echo 'jira.shared.home=/var/atlassian/application-data/cluster' >> /var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties
#printf "%s" "jira.node.id=$MY_POD_NAME" >> "/var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties"

DIR="/var/atlassian/application-data/jira/jira-main-home"
if [ ! -d "$DIR" ] 
then
  mkdir $DIR
  echo 'jira.shared.home=/var/atlassian/application-data/cluster' >> /var/atlassian/application-data/jira/jira-main-home/cluster.properties
  printf "%s" "jira.node.id=$MY_POD_NAME" >> /var/atlassian/application-data/jira/jira-main-home/cluster.properties" 
  echo "Directory /var/atlassian/application-data/jira/jira-main-home exists."
else 
  /usr/bin/mkdir /var/atlassian/application-data/jira/$MY_POD_NAME
  /usr/bin/cp -rav $DIR /var/atlassian/application-data/jira/$MY_POD_NAME
  echo 'jira.shared.home=/var/atlassian/application-data/cluster' >> /var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties
  printf "%s" "jira.node.id=$MY_POD_NAME" >> "/var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties"
done 
    
