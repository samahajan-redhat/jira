/usr/bin/mkdir /var/atlassian/application-data/jira-home/$MY_POD_NAME
echo 'jira.shared.home=/var/atlassian/application-data/cluster' >> /var/atlassian/application-data/jira-home/$MY_POD_NAME/cluster.properties
printf "%s" "jira.node.id=$MY_POD_NAME" >> "/var/atlassian/application-data/jira-home/$MY_POD_NAME/cluster.properties"
