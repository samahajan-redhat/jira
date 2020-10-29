[ ! -d /var/atlassian/application-data/jira/jira-main-home ] && echo "MY_POD_NAME=jira-main-home" > ~/.bashrc 
exec bash
