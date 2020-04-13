FROM ubuntu:16.04

MAINTAINER Hemanth 

# Installing basic requirements along with python2 and python3 
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    gcc \
    git \
    libpq-dev \
    make \
    python-pip \
    python2.7 \
    python2.7-dev \
    ssh \
    vim \
    wget \
    && apt-get autoremove \
    && apt-get clean

# Installing software-properties-common to solve "add-apt" issue
RUN apt-get install -y software-properties-common

# SSH Keys
RUN \
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  chmod 0600 ~/.ssh/authorized_keys  

# java-8
RUN apt-get update 
RUN apt-get install -y openjdk-8-jdk

# Scala
RUN wget http://www.scala-lang.org/files/archive/scala-2.11.8.tgz && \
    tar -xzf /scala-2.11.8.tgz -C /usr/local/ && \
    ln -s /usr/local/scala-2.11.8 $SCALA_HOME && \
    rm scala-2.11.8.tgz 
RUN apt-get update
RUN apt-get install curl

# Sbt
RUN curl -L -o sbt-1.0.4.deb https://dl.bintray.com/sbt/debian/sbt-1.0.4.deb && \ 
	dpkg -i sbt-1.0.4.deb && \ 
	rm sbt-1.0.4.deb && \ 
	apt-get update && \ 
	apt-get install sbt && \ 
	sbt sbtVersion

# Postgresql
RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" \
    && wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \ 
    && apt-get update \ 
    && apt-get install -y postgresql-9.6 postgresql-contrib-9.6

RUN /etc/init.d/postgresql start
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf &&\
    echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf
#    psql --command "CREATE USER user WITH SUPERUSER PASSWORD 'user';" &&\
#    createdb -O docker docker


# Hadoop
RUN \
    wget https://archive.apache.org/dist/hadoop/core/hadoop-2.7.3/hadoop-2.7.3.tar.gz && \
    tar -xzf hadoop-2.7.3.tar.gz && \
    mv hadoop-2.7.3 /opt/hadoop && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/" >> /opt/hadoop/etc/hadoop/hadoop-env.sh 

RUN mv /opt/hadoop/etc/hadoop/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml_bac
RUN echo " <configuration> \
<property> \
<name>fs.default.name</name> \
<value>hdfs://localhost:9000</value> \
</property> \
<property> \
<name>hadoop.tmp.dir</name> \
<value>/home/rupesh/hadoopdata/tmpdir</value> \
</property> \
</configuration>" >> /opt/hadoop/etc/hadoop/core-site.xml

RUN mv /opt/hadoop/etc/hadoop/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml_bac
RUN echo "<configuration> \
<property> \
<name>dfs.replication</name> \
<value>1</value> \
</property> \
<property> \
<name>dfs.permission</name> \
<value>false</value> \
</property> \
<property> \
<name>dfs.data.dir</name> \
<value>/hdd/data_drive_mnt/docker-volumes/hdfs/datanode</value> \
</property> \
<property> \
<name>dfs.name.dir</name> \
<value>/hdd/data_drive_mnt/docker-volumes/hdfs/namenode</value> \
</property> \
</configuration>" >> /opt/hadoop/etc/hadoop/hdfs-site.xml

#RUN mv /opt/hadoop/etc/hadoop/mapred-site.xml.template /opt/hadoop/etc/hadoop/mapred-site.xml

RUN echo "<configuration> \
    <property> \
        <name>mapreduce.framework.name</name> \
        <value>yarn</value> \
    </property> \
</configuration>" >> /opt/hadoop/etc/hadoop/mapred-site.xml

RUN mv /opt/hadoop/etc/hadoop/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml_bac
RUN echo "<configuration> \
<property> \
<name>yarn.nodemanager.aux-services</name> \
<value>mapreduce_shuffle</value> \
</property> \
<property> \
<name>yarn.nodemanager.auxservices.mapreduce.shuffle.class</name> \
<value>org.apache.hadoop.mapred.ShuffleHandler</value> \
</property> \
</configuration>" >> /opt/hadoop/etc/hadoop/yarn-site.xml

# Spark
RUN apt-get update \
    && apt-get dist-upgrade -y \
    && wget https://archive.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz \
    && tar -xzf spark-2.4.4-bin-hadoop2.7.tgz && \
    mv spark-2.4.4-bin-hadoop2.7 /spark && \
    rm spark-2.4.4-bin-hadoop2.7.tgz

RUN mv /spark/conf/spark-defaults.conf.template /spark/conf/spark-defaults.conf
RUN echo "spark.local.dir /hdd/data_drive_mnt/docker-volumes/sparkdata/spark-local-dir/" >> /spark/conf/spark-defaults.conf


RUN mv /spark/conf/spark-env.sh.template /spark/conf/spark-env.sh

RUN echo "SPARK_WORKER_CORES=2 \
SPARK_WORKER_INSTANCES=2 \
SPARK_WORKER_MEMORY=3G \
SPARK_DRIVER_MEMORY=2G \
SPARK_WORKER_DIR="/hdd/data_drive_mnt/docker-volumes/sparkdata/spark-tmp/"" >> /spark/conf/spark-env.sh

RUN echo "export HADOOP_HOME=/opt/hadoop" >> ~/.bashrc
RUN echo "export HADOOP_INSTALL=/opt/hadoop" >> ~/.bashrc
RUN echo "export HADOOP_MAPRED_HOME=\$HADOOP_HOME" >> ~/.bashrc
RUN echo "export HADOOP_COMMON_HOME=\$HADOOP_HOME" >> ~/.bashrc
RUN echo "export HADOOP_HDFS_HOME=\$HADOOP_HOME" >> ~/.bashrc
RUN echo "export YARN_HOME=\$HADOOP_HOME" >> ~/.bashrc
RUN echo "export HADOOP_COMMON_LIB_NATIVEDIR=\$HADOOP_HOME/lib/native" >> ~/.bashrc
RUN echo "export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin" >> ~/.bashrc
#RUN echo "export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native">> ~/.bashrc

RUN /bin/bash -c "source ~/.bashrc"
#RUN source /root/.bashrc
   

RUN apt-get install sudo -y

#RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh -O ~/anaconda.sh && \
#    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
#    rm ~/anaconda.sh && \
#    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
 #   echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \ 
 #   echo "conda activate base" >> ~/.bashrc

#Conda
RUN wget https://repo.continuum.io/archive/Anaconda3-5.0.1-Linux-x86_64.sh && \
    bash Anaconda3-5.0.1-Linux-x86_64.sh -b && \
    rm Anaconda3-5.0.1-Linux-x86_64.sh

#Env for conda
ENV PATH /root/anaconda3/bin:$PATH
RUN conda update conda

#Create conda environment here and add packages as needed
RUN conda create -n pythonenv python=3.6.8 pandas numpy keras tensorflow scikit-learn 
#RUN source activate pythonenv
RUN echo "export PATH=/root/anaconda3/bin:\$PATH" >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"


#Setting environment variables for spark, sbt, scala
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME /opt/hadoop
ENV PATH ${HADOOP_HOME}/bin:$PATH
ENV SPARK_HOME /spark
ENV PATH ${SPARK_HOME}/bin:$PATH

ENV SBT_VERSION		1.0.4
ENV SBT_HOME		/usr/local/sbt
ENV SCALA_VERSION	2.11.8
ENV SCALA_HOME		/usr/local/scala-2.11.8
ENV PATH		$SCALA_HOME/bin:$SBT_HOME/bin:$PATH

#Expose all the ports here
EXPOSE 5432 8088 50070 50075 50030 50060 4040

RUN /bin/bash -c "source ~/.bashrc"

#GIT CLONE  
#MAKE SURE YOU DELETE THE TOKEN AFTER CREATING THE IMAGE 
WORKDIR /opt/repos
RUN git clone -b branch_name https://token@github.com/name/repo_name.git 
WORKDIR /opt/repos

#Create a jar while building the images itself 
#RUN sbt assembly

#Test Case for Git
#RUN /bin/bash -c "export uname"
#RUN /bin/bash -c "export pname"
#RUN /bin/bash -c "git clone https://$uname:$pname@github.com/harshahemanth/yolo.git"

# Git Clones
#ARG username
#ARG password
#RUN git clone https://$username:$password@github.com/harsha3loq/monit_dev.git
#Not the best way to clone . . .
CMD []
ENTRYPOINT ["/bin/bash"]
