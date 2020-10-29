#!/usr/bin/python3 -B

import os
import shutil

from entrypoint_helpers import env, gen_cfg, gen_container_id, str2bool, start_app


RUN_USER = env['run_user']
RUN_GROUP = env['run_group']
JIRA_INSTALL_DIR = env['jira_install_dir']

home_dir_path = '/var/atlassian/application-data/jira'
master_home_dir_name = "jira-main-home"
cluster_properties_file_name = "cluster.properties"

def create_home_dir():
    pod_name = os.environ.get('MY_POD_NAME')
    master_home_dir_path = os.path.join(home_dir_path, master_home_dir_name)
    if not os.path.exists(master_home_dir_path):
        os.makedirs(master_home_dir_path)
        with open(os.path.join(master_home_dir_path, cluster_properties_file_name), 'w+') as cluster_properties_file:
            lines = ["jira.node.id=master-pod \n",
                     "jira.shared.home=/var/atlassian/application-data/cluster"]
            cluster_properties_file.writelines(lines)
        cluster_properties_file.close()
        return master_home_dir_path
    else:
        pod_home_dir_path = os.path.join(home_dir_path, pod_name)
        if os.path.exists(pod_home_dir_path):
            shutil.rmtree(pod_home_dir_path)
        shutil.copytree(master_home_dir_path, pod_home_dir_path)
        os.remove(os.path.join(pod_home_dir_path,
                               cluster_properties_file_name))
        with open(os.path.join(pod_home_dir_path, cluster_properties_file_name), 'w+') as cluster_properties_file:
            lines = ["jira.node.id="+pod_name+"\n",
                     "jira.shared.home=/var/atlassian/application-data/cluster"]
            cluster_properties_file.writelines(lines)
        cluster_properties_file.close()
        return pod_home_dir_path

JIRA_HOME = create_home_dir()
os.environ["jira_home"]=JIRA_HOME
os.environ["JIRA_HOME"]=JIRA_HOME
gen_container_id()
if os.stat('/etc/container_id').st_size == 0:
    gen_cfg('container_id.j2', '/etc/container_id',
            user=RUN_USER, group=RUN_GROUP, overwrite=True)
gen_cfg('server.xml.j2', f'{JIRA_INSTALL_DIR}/conf/server.xml')
gen_cfg('seraph-config.xml.j2',
        f'{JIRA_INSTALL_DIR}/atlassian-jira/WEB-INF/classes/seraph-config.xml')
gen_cfg('dbconfig.xml.j2', f'{JIRA_HOME}/dbconfig.xml',
        user=RUN_USER, group=RUN_GROUP, overwrite=False)
#if str2bool(env.get('clustered')):
    #gen_cfg('cluster.properties.j2', f'{JIRA_HOME}/cluster.properties', user=RUN_USER, group=RUN_GROUP, overwrite=False)
#os.system('sh /var/atlassian/application-data/jira-main-home.sh')
#os.system('sh /var/atlassian/application-data/mkdir-home3.sh')
#os.system('sh /var/atlassian/application-data/mkdir-home.sh')

start_app(f'{JIRA_INSTALL_DIR}/bin/start-jira.sh -fg', JIRA_HOME, name='Jira')
