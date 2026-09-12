# Base Python 3.7 image
#
# Moved off bullseye (Debian 11): it reached EOL and its security Release file
# expired, so "apt-get update" now fails outright (exit 100) and the image could
# no longer be built at all. Bookworm (Debian 12) is still supported and receives
# security updates, and python:3.7-bookworm publishes both amd64 and arm64.
#
# Bookworm does not carry openjdk-11 (it was dropped from Debian 12), so this
# image now ships OpenJDK 17. Spark 3.3.0 officially supports Java 8/11/17 and
# bundles the --add-opens module options needed for 17, so this is a supported
# combination; it was verified end to end (SparkSession + Delta write/read) on
# both architectures before being published.
FROM python:3.7-bookworm

# Expose Port
EXPOSE 8888 4040

# Change shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Upgrade pip
# Pinned: 24.0 is the last pip release that supports Python 3.7 and is the
# version present in the known-good published image.
RUN pip install --upgrade pip==24.0

# Install OpenJDK
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    apt-get clean;

# Fix certificate issues
RUN apt-get install -y ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Insatall nano & vi
RUN apt-get install -y nano && \
    apt-get install -y vim;

# Setup JAVA_HOME -- useful for docker commandline
# TARGETARCH is set automatically by buildx ("amd64" or "arm64") and matches
# Debian's JVM directory naming, so this image builds for both architectures.
# The hardcoded "-amd64" that used to be here silently produced a broken
# JAVA_HOME on arm64.
ARG TARGETARCH
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-${TARGETARCH}/
RUN test -d "$JAVA_HOME" || { echo "JAVA_HOME not found: $JAVA_HOME"; exit 1; }

# Download and Setup Spark binaries
WORKDIR /tmp
RUN wget https://archive.apache.org/dist/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz
RUN tar -xvf spark-3.3.0-bin-hadoop3.tgz
RUN mv spark-3.3.0-bin-hadoop3 spark
RUN mv spark /
RUN rm spark-3.3.0-bin-hadoop3.tgz

# Set up environment variables
ENV SPARK_HOME /spark
RUN export SPARK_HOME
ENV PYSPARK_PYTHON /usr/local/bin/python
RUN export PYSPARK_PYTHON
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.5-src.zip
RUN export PYTHONPATH
ENV PATH $PATH:$SPARK_HOME/bin
RUN export PATH

# Fix configuration files
RUN mv $SPARK_HOME/conf/log4j2.properties.template $SPARK_HOME/conf/log4j2.properties
RUN mv $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf
RUN mv $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh

# Install Jupyter Lab, PySpark, Kafka, boto & Delta Lake
#
# Every version below is taken from "pip freeze" of the last known-good
# published image (easewithdata/pyspark-jupyter-lab-old:latest, 2025-02-26).
#
# DO NOT RELAX THESE PINS. The original "pip install jupyterlab" was unpinned,
# and resolving it fresh today pulls an ipykernel that breaks the kernel on this
# stack (kernels stay stuck on "busy" and the server stops responding).
# Pinning jupyterlab alone is NOT enough -- jupyterlab declares only a loose
# ipykernel constraint, so the whole jupyter core stack has to be pinned
# explicitly.
RUN pip install \
      jupyterlab==3.6.8 \
      jupyterlab_server==2.24.0 \
      jupyter_server==1.24.0 \
      jupyter_client==7.4.9 \
      jupyter_core==4.12.0 \
      jupyter-events==0.6.3 \
      jupyter_server_fileid==0.9.3 \
      jupyter_server_ydoc==0.8.0 \
      jupyter-ydoc==0.2.5 \
      y-py==0.6.2 \
      ypy-websocket==0.8.4 \
      notebook==6.5.7 \
      nbclassic==1.1.0 \
      ipykernel==6.16.2 \
      ipython==7.34.0 \
      traitlets==5.9.0 \
      tornado==6.2 \
      pyzmq==26.2.0 \
      debugpy==1.7.0 \
      nbconvert==7.6.0 \
      nbformat==5.8.0 \
      nbclient==0.7.4 \
      notebook_shim==0.2.4 \
      jsonschema==4.17.3 \
      anyio==3.7.1
RUN pip install pyspark==3.3.0
RUN pip install kafka-python==2.0.2
RUN pip install delta-spark==2.2.0
RUN pip install boto3==1.33.13

# Change to working directory and clone git repo
WORKDIR /home/jupyter

# Clone Ease with Apache Spark Repo to Start
RUN git clone https://github.com/subhamkharwal/ease-with-apache-spark.git

# Fix Jupyter logging issue
RUN ipython profile create
RUN echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

# Start the container with root privilages
CMD ["python3", "-m", "jupyterlab", "--ip", "0.0.0.0", "--allow-root"]
