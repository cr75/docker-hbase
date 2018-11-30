from ubuntu:14.04
MAINTAINER Kevin Carter <kevin@tlm.us>

# Borrowed heavily from Apache Nutch base dockerfile @ https://github.com/apache/nutch/blob/2.x/docker/hbase/Dockerfile

WORKDIR /root/

# Install package with add-apt-repository
RUN apt-get update && apt-get install -y software-properties-common

# Enable Ubuntu repositories
RUN add-apt-repository -y multiverse && \
  add-apt-repository -y restricted && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && apt-get upgrade -y

# Install Oracle Java from PPA
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && apt-get install -y oracle-java8-installer oracle-java8-set-default

# Install dependencies
RUN apt-get install -y ant openssh-server zookeeperd vim telnet subversion rsync curl build-essential maven

# Setup system user and group to own and run Hadoop
RUN addgroup hadoop && adduser --ingroup hadoop hduser
RUN usermod -a -G hadoop zookeeper

# Setup SSH keys for passwordless access
RUN su -l -c 'ssh-keygen -t rsa -f /home/hduser/.ssh/id_rsa -P ""' hduser && cat /home/hduser/.ssh/id_rsa.pub | su -l -c 'tee -a /home/hduser/.ssh/authorized_keys' hduser
ADD config/ssh-config /home/hduser/.ssh/config
RUN chmod 600 /home/hduser/.ssh/config
RUN chown hduser /home/hduser/.ssh/config

# Fix Ubuntu 13.10 SSH daemon problem with docker: http://docs.docker.io/en/latest/examples/running_ssh_service/
RUN sed -ri 's/session[[:blank:]]+required[[:blank:]]+pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd

# Download
RUN svn checkout http://svn.apache.org/repos/asf/nutch/branches/2.x/ nutch-sources

# Deploy and setup file permissions
RUN mv /root/nutch-sources /opt/apache-nutch-2.x && \
  chown -R root:root /opt/apache-nutch-2.x && \
  mkdir /opt/apache-nutch-2.x/logs && \
  chown -R hduser:hadoop /opt/apache-nutch-2.x/logs

# Setup hduser environment
ADD config/bashrc /home/hduser/.bashrc

# Add nutch configs
ADD config/hbase-site.xml /tmp/nutch-etc/hbase-site.xml
ADD config/nutch-site.xml /tmp/nutch-etc/nutch-site.xml
RUN mv /tmp/nutch-etc/* /opt/apache-nutch-2.x/conf/

# Update and build nutch runtime
ENV JAVA_HOME="/usr/lib/jvm/java-8-oracle" \
  NUTCH_ROOT="/opt/apache-nutch-2.x"
RUN echo 'gora.datastore.default=org.apache.gora.hbase.store.HBaseStore' >> $NUTCH_ROOT/conf/gora.properties
RUN vim -c 'g/name="gora-hbase"/+1d' -c 'x' $NUTCH_ROOT/ivy/ivy.xml
RUN vim -c 'g/name="gora-hbase"/-1d' -c 'x' $NUTCH_ROOT/ivy/ivy.xml
RUN sed -e '35 i <dependency org="org.apache.hbase" name="hbase-common" rev="0.98.8-hadoop2" conf="*->default" />' $NUTCH_ROOT/ivy/ivy.xml > $NUTCH_ROOT/ivy/ivy.xml.tmp && mv $NUTCH_ROOT/ivy/ivy.xml.tmp $NUTCH_ROOT/ivy/ivy.xml

RUN cd $NUTCH_ROOT && ant runtime
RUN ln -s /opt/apache-nutch-2.x/runtime/deploy /opt/nutch && mkdir -p /opt/nutch/logs && chown -R hduser:hadoop /opt/nutch/logs

# Download Hadoop
RUN cd /root/
RUN wget -q 'https://archive.apache.org/dist/hadoop/core/hadoop-2.5.1/hadoop-2.5.1.tar.gz'
RUN wget -q 'http://archive.apache.org/dist/hbase/hbase-0.98.8/hbase-0.98.8-hadoop2-bin.tar.gz'
RUN wget -q 'https://github.com/protocolbuffers/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz'

# Deploy and setup file permissions
RUN tar xfz /root/hadoop-2.5.1.tar.gz -C /opt && \
  ln -s /opt/hadoop-2.5.1 /opt/hadoop && \
  chown -R root:root /opt/hadoop-2.5.1 && \
  mkdir /opt/hadoop-2.5.1/logs && \
  chown -R hduser:hadoop /opt/hadoop-2.5.1/logs

# Unpack and compile Google protobuf
RUN tar xfz /root/protobuf-2.5.0.tar.gz -C /opt && chown -R root:root /opt/protobuf-2.5.0
RUN cd /opt/protobuf-2.5.0 && ./configure && make && make check && make install

# Deploy and setup file permissions
RUN tar xfz /root/hbase-0.98.8-hadoop2-bin.tar.gz -C /opt && chown -R root:root /opt/hbase-0.98.8-hadoop2

# link binaries, create logs directory
RUN ln -s /opt/hbase-0.98.8-hadoop2 /opt/hbase &&  mkdir /opt/hbase/logs && chown -R hduser:hadoop /opt/hbase/logs

# Add Hadoop and HBase configs
ADD config/core-site.xml /tmp/hadoop-etc/core-site.xml
ADD config/mapred-site.xml /tmp/hadoop-etc/mapred-site.xml
ADD config/hdfs-site.xml /tmp/hadoop-etc/hdfs-site.xml
ADD config/yarn-site.xml /tmp/hadoop-etc/yarn-site.xml
ADD config/hbase-site.xml /tmp/hbase-etc/hbase-site.xml
RUN mv /tmp/hadoop-etc/* /opt/hadoop/etc/hadoop
RUN mv /tmp/hbase-etc/* /opt/hbase/conf/

ENV NUTCH_HOME /opt/nutch
ENV HADOOP_HOME /opt/hadoop
ENV NUTCHSERVER_PORT 8899
