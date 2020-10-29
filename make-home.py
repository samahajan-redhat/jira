import os
import shutil

home_dir_path = '/var/atlassian/application-data/jira'
master_home_dir_name = "jira-main-home"
cluster_properties_file_name = "cluster.properties"


def create_home_dir():
    pod_name = os.environ.get('MY-POD-NAME')
    master_home_dir_path = os.path.join(home_dir_path, master_home_dir_name)
    if not os.path.exists(master_home_dir_path):
        os.makedirs(master_home_dir_path)
        with open(os.path.join(master_home_dir_path, cluster_properties_file_name), 'w+') as cluster_properties_file:
            lines = ["jira.node.id=master-pod \n",
                     "jira.shared.home=/var/atlassian/application-data/cluster"]
            cluster_properties_file.writelines(lines)
        cluster_properties_file.close()
        print('home-dir='+master_home_dir_path)
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
        print('home-dir='+pod_home_dir_path)
        return pod_home_dir_path


if __name__ == "__main__":
    os.environ["MY-POD-NAME"] = "Test-pod-1"
    create_home_dir()
