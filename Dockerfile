#FROM docker-registry.default.svc:5000/rh1--prototype/jira-ubi8
#FROM registry.redhat.io/ubi8/ubi-minimal
FROM registry.access.redhat.com/ubi8/ubi-minimal
#FROM registry.access.redhat.com/ubi8/ubi

# The inspiration for this Dockerfile is coming from 3 places:
# - the Docker file for the openjdk-11 container Red Hat ships
#   https://catalog.redhat.com/software/containers/openjdk/openjdk-11-rhel7/5bf57185dd19c775cddc4ce5?container-tabs=dockerfile
# - the Dockerfile IBM Watson Health created (ask the team lead for access)
#   https://app.box.com/folder/122133188813
# - the Dockerfile from Atlassian
#   https://bitbucket.org/atlassian-docker/docker-atlassian-jira/src/master/Dockerfile
#

# First we set up environment details. Remember we're building off of the OpenJDK 11
# image, so we're inheriting additional ENV from that.
# Here are the Jira-specific ones:
#RUN POD_NAME=$(cat /etc/hostname)
ENV RUN_USER=jira \
    RUN_GROUP=jira \
    RUN_UID=1001 \
    RUN_GID=1001 \
    JIRA_INSTALL_DIR=/opt/atlassian/jira \
    TINI_VERSION=v0.18.0 \
    CLUSTERED=true \
    JIRA_HOME=/var/atlassian/application-data/jira/$MY_POD_NAME \
    JIRA_CLUSTER_HOME=/var/atlassian/application-data/cluster

ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0" \
    JAVA_VENDOR="openjdk" \
    JAVA_VERSION="1.8.0"

WORKDIR ${JIRA_HOME}
EXPOSE 8080 
CMD ["/entrypoint.py"]
ENTRYPOINT ["/tini", "-s", "--"]

# Next we install dependencies. This can be collapsed to less commands but clarity's
# sake they are separate.
USER root
RUN microdnf update
# Useful things IBM recommended plus 2 from Atlassian (fontconfig and jinja2)
RUN microdnf install -y wget python36 python36-devel  rsync findutils procps vim lsof iputils openssl curl fontconfig tar unzip \
                        python3-jinja2 shadow-utils
# OpenJDK 8 stuff
RUN microdnf install --setopt=tsflags=nodocs -y java-1.8.0-openjdk-devel
# Clean up after ourselves to keep the size down.
RUN microdnf clean all && [ ! -d /var/cache/yum ] || rm -rf /var/cache/yum

# TODO: check what the custom scripts do in the original openjdk image do
# RUN [ "sh", "-x", "/tmp/scripts/jboss.container.openjdk.jdk/configure.sh" ]

# FYI - where to download the standalone distributable
# DOWNLOAD_URL=https://product-downloads.atlassian.com/software/jira/downloads/${ARTEFACT_NAME}-${JIRA_VERSION}.tar.gz


# Now we start mucking around to make this all work together.
# Since we do not want to run as root, we make a lot of things world-writable or owned
# by the Jira user instead. Let's create our users and the install directory:
RUN groupadd --gid ${RUN_GID} ${RUN_GROUP}
RUN hostid=$(cat /etc/hostname)
RUN useradd --uid ${RUN_UID} --gid ${RUN_GID} --home-dir ${JIRA_HOME} --shell /bin/bash ${RUN_USER}
RUN echo PATH=$PATH > /etc/environment
RUN mkdir -p ${JIRA_INSTALL_DIR}
RUN mkdir -p /var/atlassian/application-data/jira
RUN mkdir -p /var/atlassian/application-data/cluster
ADD mkdir-home3.sh /var/atlassian/application-data/ 
ADD mkdir-home4.sh /var/atlassian/application-data/
ADD mkdir-home5.sh /var/atlassian/application-data/
ADD make-home.py /
RUN chown -R ${RUN_USER}:${RUN_GROUP} /make-home.py
ADD jira-main-home.sh /var/atlassian/application-data/
#ADD mkdir-home.sh /var/atlassian/application-data/
RUN chmod 770 /var/atlassian/application-data/mkdir-home3.sh
RUN chmod 770 /var/atlassian/application-data/mkdir-home4.sh
RUN chmod 770 /var/atlassian/application-data/mkdir-home5.sh
RUN chmod 770 /var/atlassian/application-data/jira-main-home.sh
#RUN chmod 770 /var/atlassian/application-data/mkdir-home.sh
#RUN mkdir -p ${JIRA_CLUSTER_HOME}
# this is not a direct download from atlassian.com, it's from lookaside
# it had to be recompressed with the leading directory in the structure removed
#ADD atlassian-jira-software-8.13.0.tar.gz ${JIRA_INSTALL_DIR}
#ADD https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.13.0.tar.gz ${JIRA_INSTALL_DIR}
ADD https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.13.0.zip  ${JIRA_INSTALL_DIR}
#RUN ls -l ${JIRA_INSTALL_DIR}/
#RUN ls -l /opt/atlassian/jira/
RUN cd /opt/atlassian/jira/ ; unzip atlassian-jira-software-8.13.0.zip
#RUN ls -l ${JIRA_INSTALL_DIR}/
RUN mv ${JIRA_INSTALL_DIR}/atlassian-jira-software-8.13.0-standalone/* ${JIRA_INSTALL_DIR}
RUN mkdir -p ${JIRA_INSTALL_DIR}/logs \
    mkdir -p ${JIRA_INSTALL_DIR}/temp \
    mkdir -p ${JIRA_INSTALL_DIR}/work \
    mkdir -p ${JIRA_INSTALL_DIR}/conf
#ADD atlassian-jira-software-8.13.0-standalone/conf/ ${JIRA_INSTALL_DIR}/conf
#ADD atlassian-jira-software-8.13.0-standalone/bin/ ${JIRA_INSTALL_DIR}/bin
ADD setenv.sh ${JIRA_INSTALL_DIR}/bin
#ADD https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-core-8.12.0.tar.gz  ${JIRA_INSTALL_DIR}
RUN chmod -R "u=rwX,g=rX,o=rX"                   ${JIRA_INSTALL_DIR}/
RUN chown -R root.                               ${JIRA_INSTALL_DIR}/
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/logs
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/temp
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/work
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/conf
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/bin
RUN chown -R ${RUN_USER}:${RUN_GROUP} /var/atlassian/application-data/jira
RUN chmod -R 777 /opt/atlassian/jira/work/
RUN sed -i -e 's/^JVM_SUPPORT_RECOMMENDED_ARGS=""$/: \${JVM_SUPPORT_RECOMMENDED_ARGS:=""}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh
RUN sed -i -e 's/^JVM_\(.*\)_MEMORY="\(.*\)"$/: \${JVM_\1_MEMORY:=\2}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh
RUN sed -i -e 's/-XX:ReservedCodeCacheSize=\([0-9]\+[kmg]\)/-XX:ReservedCodeCacheSize=${JVM_RESERVED_CODE_CACHE_SIZE:=\1}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh
RUN touch /etc/container_id
ADD dbconfig.xml $JIRA_HOME/
RUN chown ${RUN_USER}:${RUN_GROUP}               /etc/container_id
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_HOME}
RUN chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_CLUSTER_HOME}
RUN chgrp -R 0 /etc/container_id
RUN chmod -R g=u /etc/container_id
RUN chmod -R 460 /etc/container_id
RUN chgrp -R 0 ${JIRA_INSTALL_DIR}
RUN chmod -R g=u ${JIRA_INSTALL_DIR}
RUN chgrp -R 0 ${JIRA_HOME}
RUN chmod -R g=u ${JIRA_HOME}
ADD server.xml ${JIRA_INSTALL_DIR}/conf/server.xml
RUN chown ${RUN_USER}:${RUN_GROUP}  ${JIRA_INSTALL_DIR}/conf/server.xml
RUN chgrp -R 0 ${JIRA_CLUSTER_HOME}
RUN chmod -R g=u ${JIRA_CLUSTER_HOME}

# Tweak the entrypoint script
# not sure we need this after Docker 1.13, this happens automatically with --init
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod 755 /tini
#ADD tini /tini
RUN chown ${RUN_USER}:${RUN_GROUP}  /tini

VOLUME ["${JIRA_HOME}"] # Must be declared after setting perms

COPY entrypoint.py                                  /
RUN chmod 700                                       /entrypoint.py
RUN chown ${RUN_USER}:${RUN_GROUP}                  /entrypoint.py
COPY entrypoint_helpers.py                          /
RUN chmod 644                                       /entrypoint_helpers.py
RUN chown ${RUN_USER}:${RUN_GROUP}                  /entrypoint_helpers.py
ADD shared-components-support.tar.gz                /opt/atlassian/support
RUN chown -R ${RUN_USER}:${RUN_GROUP}               /opt/atlassian/support
ADD config/*                     	            /opt/atlassian/etc/
RUN chown -R ${RUN_USER}:${RUN_GROUP}               /opt/atlassian/jira/conf
RUN chown -R ${RUN_USER}:${RUN_GROUP} /var/atlassian/application-data/mkdir-home3.sh
RUN chown -R ${RUN_USER}:${RUN_GROUP} /var/atlassian/application-data/mkdir-home4.sh
RUN chown -R ${RUN_USER}:${RUN_GROUP} /var/atlassian/application-data/mkdir-home5.sh
#RUN chown -R ${RUN_USER}:${RUN_GROUP} /var/atlassian/application-data/mkdir-home.sh
#ADD cluster.properties				    $JIRA_HOME/cluster.properties
#RUN chmod 770					    $JIRA_HOME/cluster.properties
#RUN chown ${RUN_USER}:${RUN_GROUP}		    $JIRA_HOME/cluster.properties
USER ${RUN_UID}:${RUN_GID}

# Set up metadata about the container with labels
LABEL   com.redhat.component="jira-software-container" \
        name="jira-software" \
        maintainer="Red Hat Portfolio Management Enablement team (redhatone@redhat.com)" \
        description="Jira application container for RH1" \
        version="1.0" \
        distribution-scope="private"
