DIR="/var/atlassian/application-data/jira/jira-main-home"

if [ ! -d "$DIR" ]; then
  mkdir -p "$DIR" && echo 'jira.shared.home=/var/atlassian/application-data/cluster' >> /var/atlassian/application-data/jira/jira-main-home/cluster.properties && /bin/bash /var/atlassian/application-data/jira/mkdir-home4.sh && JIRA_HOME=/var/atlassian/application-data/jira/jira-main-home
else 
  mkdir /var/atlassian/application-data/jira/$MY_POD_NAME && cp -rav $DIR/* /var/atlassian/application-data/jira/$MY_POD_NAME && rm -rf /var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties  && echo 'jira.shared.home=/var/atlassian/application-data/cluster' > /var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties && /bin/bash /var/atlassian/application-data/jira/mkdir-home5.sh && JIRA_HOME=/var/atlassian/application-data/jira/$MY_POD_NAME
  exit 1
fi
