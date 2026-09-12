# Base Python 3.10 image
# Moved off bullseye (Debian 11): it reached EOL and its security Release file
# expired, so "apt-get update" now fails outright and the image could no longer
# be built. Bookworm (Debian 12) is supported and ships OpenJDK 17, which is an
# officially supported JVM for Spark 3.5.x.
FROM python:3.10.21-bookworm

# Expose Port
EXPOSE 8888 4040

# Change shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Upgrade pip
RUN pip install --upgrade pip==25.0.1

# Install OpenJDK
RUN apt-get update && \
    apt install -y openjdk-17-jdk && \
    apt-get clean;
    
# Fix certificate issues
RUN apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Insatall nano & vi
RUN apt-get install -y nano && \
    apt-get install -y vim;

# Setup JAVA_HOME -- useful for docker commandline
# TARGETARCH is set automatically by buildx ("amd64" or "arm64") and matches
# Debian's JVM directory naming, so this image builds for both architectures.
ARG TARGETARCH
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-${TARGETARCH}/
RUN test -d "$JAVA_HOME" || { echo "JAVA_HOME not found: $JAVA_HOME"; exit 1; }

# Download and Setup Spark binaries
WORKDIR /tmp
RUN wget https://archive.apache.org/dist/spark/spark-3.5.5/spark-3.5.5-bin-hadoop3.tgz
RUN tar -xvf spark-3.5.5-bin-hadoop3.tgz
RUN mv spark-3.5.5-bin-hadoop3 spark
RUN mv spark /
RUN rm spark-3.5.5-bin-hadoop3.tgz

# Set up environment variables
ENV SPARK_HOME /spark
RUN export SPARK_HOME
ENV PYSPARK_PYTHON /usr/local/bin/python
RUN export PYSPARK_PYTHON
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip
RUN export PYTHONPATH
ENV PATH $PATH:$SPARK_HOME/bin
RUN export PATH

# Fix configuration files
RUN mv $SPARK_HOME/conf/log4j2.properties.template $SPARK_HOME/conf/log4j2.properties
RUN mv $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf
RUN mv $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh

# Install Jupyter Lab, PySpark, Kafka, boto & Delta Lake
# Versions pinned to those verified working in easewithdata/pyspark-jupyter:3.5.5
# (digest sha256:ee14e7ae1d34..., built 2025-03-09).
#
# The jupyter core stack below MUST stay pinned. jupyterlab==4.3.5 alone does not
# hold ipykernel back -- it still resolves to ipykernel 7.x, which is a rewrite and
# breaks the kernel here (kernel stuck on "busy", server eventually unresponsive).
RUN pip install \
      jupyterlab==4.3.5 \
      jupyterlab_server==2.27.3 \
      jupyter_server==2.15.0 \
      jupyter_server_terminals==0.5.3 \
      jupyter_client==8.6.3 \
      jupyter_core==5.7.2 \
      jupyter-events==0.12.0 \
      jupyter-lsp==2.2.5 \
      ipykernel==6.29.5 \
      ipython==8.33.0 \
      traitlets==5.14.3 \
      tornado==6.4.2 \
      pyzmq==26.2.1 \
      nbconvert==7.16.6 \
      nbformat==5.10.4 \
      nbclient==0.10.2 \
      notebook_shim==0.2.4
RUN pip install pyspark==3.5.5
RUN pip install kafka-python==2.0.2
RUN pip install delta-spark==3.3.0
RUN pip install boto3==1.37.8

# Change to working directory and clone git repo
WORKDIR /home/jupyter

# Clone Ease with Apache Spark Repo to Start
RUN git clone https://github.com/subhamkharwal/ease-with-apache-spark.git

# Download Spark Connect JAR
RUN wget https://repo1.maven.org/maven2/org/apache/spark/spark-connect_2.12/3.5.5/spark-connect_2.12-3.5.5.jar
RUN mv spark-connect_2.12-3.5.5.jar $SPARK_HOME/jars/

# PIP install for Spark Connect
# pandas/pyarrow/numpy pinned to the versions PySpark 3.5.5 was verified against
RUN pip install numpy==2.2.3
RUN pip install pandas==2.2.3
RUN pip install pyarrow==19.0.1
RUN pip install grpcio==1.70.0
RUN pip install protobuf==5.29.3
RUN pip install grpcio-status==1.70.0

# Fix Jupyter logging issue
RUN ipython profile create
RUN echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

# Start the container with root privilages
CMD ["python3", "-m", "jupyterlab", "--ip", "0.0.0.0", "--allow-root"]
