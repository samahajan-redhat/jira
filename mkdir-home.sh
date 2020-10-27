/usr/bin/mkdir /var/atlassian/application-data/jira/$MY_POD_NAME
printf "%s" "jira.node.id=$MY_POD_NAME" > "/var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties"
echo 'jira.shared.home=/var/atlassian/application-data/cluster' >> /var/atlassian/application-data/jira/$MY_POD_NAME/cluster.properties
