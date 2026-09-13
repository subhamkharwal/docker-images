# Python 3.12 on Debian 13 (trixie).
# - PySpark 4.2.0 requires Python >= 3.10; 3.12 has the broadest wheel coverage
#   on both amd64 and arm64.
# - Must match base/Dockerfile exactly: driver and executors need the same
#   Python minor version.
FROM python:3.12.14-trixie

# Expose Port
EXPOSE 8888 4040

# Change shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Pin pip
RUN pip install --no-cache-dir --upgrade pip==26.2.1

# Install OpenJDK 21 (Spark 4.2 runs on Java 17/21/25; trixie ships 21 LTS),
# plus the tools the notebooks and Spark scripts rely on.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openjdk-21-jdk-headless ca-certificates procps wget git nano vim && \
    rm -rf /var/lib/apt/lists/*

# Setup JAVA_HOME -- useful for docker commandline
# TARGETARCH is set automatically by buildx ("amd64" or "arm64") and matches
# Debian's JVM directory naming, so this image builds for both architectures.
ARG TARGETARCH
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH}
RUN test -d "$JAVA_HOME" || { echo "JAVA_HOME not found: $JAVA_HOME"; exit 1; }

# Download and Setup Spark binaries
WORKDIR /tmp
RUN wget -q https://archive.apache.org/dist/spark/spark-4.2.0/spark-4.2.0-bin-hadoop3.tgz && \
    tar -xzf spark-4.2.0-bin-hadoop3.tgz && \
    mv spark-4.2.0-bin-hadoop3 /spark && \
    rm spark-4.2.0-bin-hadoop3.tgz

# Set up environment variables
ENV SPARK_HOME=/spark
ENV PYSPARK_PYTHON=/usr/local/bin/python3
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.9-src.zip
ENV PATH=$PATH:$SPARK_HOME/bin

# Fix configuration files
RUN mv $SPARK_HOME/conf/log4j2.properties.template $SPARK_HOME/conf/log4j2.properties && \
    mv $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf && \
    mv $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh

# Install Jupyter Lab, PySpark, Delta Lake, Kafka, boto and the Spark Connect
# client libraries in ONE resolver pass, every version pinned.
#
# The jupyter core stack MUST stay pinned. Pinning jupyterlab alone does not
# hold ipykernel back -- it floats to 7.x, which caused kernels to stick on
# "busy" in these images. ipykernel is held on the latest 6.x line.
#
# numpy/pandas/pyarrow must stay identical to base/Dockerfile so the driver and
# executors agree for pandas UDFs and Arrow transfers. pandas stays on 2.x:
# PySpark 4.2.0 warns it "does not yet fully support pandas >= 3.0.0".
RUN pip install --no-cache-dir \
      jupyterlab==4.6.3 \
      jupyterlab_server==2.28.0 \
      jupyter_server==2.21.0 \
      jupyter_server_terminals==0.5.4 \
      jupyter_client==8.10.0 \
      jupyter_core==5.9.1 \
      jupyter-events==0.12.1 \
      jupyter-lsp==2.3.1 \
      ipykernel==6.31.0 \
      ipython==9.17.1 \
      traitlets==5.16.1 \
      tornado==6.5.8 \
      pyzmq==27.2.0 \
      nbconvert==7.17.1 \
      nbformat==5.11.1 \
      nbclient==0.11.0 \
      notebook_shim==0.2.4 \
      pyspark==4.2.0 \
      py4j==0.10.9.9 \
      delta-spark==4.4.0 \
      numpy==2.5.3 \
      pandas==2.3.3 \
      pyarrow==25.0.1 \
      grpcio==1.83.1 \
      grpcio-status==1.83.1 \
      protobuf==7.36.1 \
      googleapis-common-protos==1.75.3 \
      zstandard==0.25.0 \
      kafka-python==3.0.11 \
      boto3==1.43.93

# Change to working directory and clone git repo
WORKDIR /home/jupyter

# Clone Ease with Apache Spark Repo to Start
RUN git clone https://github.com/subhamkharwal/ease-with-apache-spark.git

# Pre-fetch the Delta Lake 4.4.0 JARs (and their transitive delta-kernel deps)
# into the Ivy cache at build time. configure_spark_with_delta_pip() then
# resolves from this cache, so Delta works without internet access at runtime;
# on a cluster the driver ships these JARs to the executors.
RUN python3 -c "\
from delta import configure_spark_with_delta_pip; \
from pyspark.sql import SparkSession; \
b = SparkSession.builder.master('local[1]').appName('delta-prefetch'); \
s = configure_spark_with_delta_pip(b).getOrCreate(); \
print('Delta JARs cached for Spark', s.version); \
s.stop()"

# Fix Jupyter logging issue
RUN ipython profile create && \
    echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

# Start the container with root privilages
CMD ["python3", "-m", "jupyterlab", "--ip", "0.0.0.0", "--allow-root"]
