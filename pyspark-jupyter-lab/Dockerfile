# Base Python 3.10 image
# Moved off bullseye (Debian 11): it reached EOL and its security Release file
# expired, so "apt-get update" now fails outright (exit 100) and the image could
# no longer be built at all. Passing -o Acquire::Check-Valid-Until=false does NOT
# work around it. Bookworm (Debian 12) is supported and ships OpenJDK 17, which
# Spark 3.3.0 supports (Java 17 support landed in 3.3.0 via SPARK-33772).
FROM python:3.10.21-bookworm

# Expose Port
EXPOSE 8888 4040

# Change shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Upgrade pip
# Pinned to the version present in the last known-good published image so the
# resolver behaves identically on rebuilds.
RUN pip install --upgrade pip==24.3.1

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
# The path used to be hardcoded to ...-openjdk-amd64, which silently produced a
# broken arm64 image. TARGETARCH is set automatically by buildx ("amd64" or
# "arm64") and matches Debian's JVM directory naming, so this builds correctly
# for both architectures. The test below fails the build loudly if it ever
# points at a directory that does not exist.
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
# Versions pinned to those verified working in easewithdata/pyspark-jupyter-lab:latest
# (amd64, published 2025-02-26).
#
# The jupyter core stack below MUST stay pinned. "pip install jupyterlab" with no
# pin now resolves ipykernel to 7.x, which is a rewrite and breaks the kernel in
# this image (kernels stick on "busy", the server eventually stops responding).
# Pinning jupyterlab alone is NOT enough -- jupyterlab declares a loose ipykernel
# constraint and still pulls 7.x, so every package below is pinned explicitly.
RUN pip install \
      jupyterlab==4.3.4 \
      jupyterlab_server==2.27.3 \
      jupyter_server==2.15.0 \
      jupyter_server_terminals==0.5.3 \
      jupyter_client==8.6.3 \
      jupyter_core==5.7.2 \
      jupyter-events==0.11.0 \
      jupyter-lsp==2.2.5 \
      ipykernel==6.29.5 \
      ipython==8.31.0 \
      traitlets==5.14.3 \
      tornado==6.4.2 \
      pyzmq==26.2.0 \
      nbconvert==7.16.4 \
      nbformat==5.10.4 \
      nbclient==0.10.2 \
      notebook_shim==0.2.4
RUN pip install pyspark==3.3.0
RUN pip install kafka-python==2.0.2
RUN pip install delta-spark==2.2.0
RUN pip install boto3==1.35.90
# numpy was not present in the old image, so there is no "known-good" version to
# copy. Pinned to the last 1.x release: PySpark 3.3.0 predates numpy 2.x and its
# pandas/arrow interop breaks against it.
RUN pip install numpy==1.26.4

# Change to working directory and clone git repo
WORKDIR /home/jupyter

# Clone Ease with Apache Spark Repo to Start
RUN git clone https://github.com/subhamkharwal/ease-with-apache-spark.git

# Fix Jupyter logging issue
RUN ipython profile create
RUN echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

# Start the container with root privilages
CMD ["python3", "-m", "jupyterlab", "--ip", "0.0.0.0", "--allow-root"]
