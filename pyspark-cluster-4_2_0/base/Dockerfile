# Shared base for spark-master and spark-worker.
#
# Uses the SAME Python image as the Jupyter driver (python:3.12.14-trixie).
# PySpark requires the driver and executors to run the same Python minor
# version; mismatched versions fail as soon as a Python UDF or RDD op runs.
FROM python:3.12.14-trixie

LABEL maintainer="Ease With Data <easewithdata@gmail.com> (Original 3.3.0 version published by bde20200)"

ENV ENABLE_INIT_DAEMON=false
ENV INIT_DAEMON_BASE_URI=http://identifier/init-daemon
ENV INIT_DAEMON_STEP=spark_master_init

ENV BASE_URL=https://archive.apache.org/dist/spark
ENV SPARK_VERSION=4.2.0
ENV HADOOP_VERSION=3

# Spark 4.2 runs on Java 17/21/25. Debian 13 (trixie) ships OpenJDK 21 (LTS).
# procps provides `ps`, which the Spark launch scripts rely on.
RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-21-jdk-headless procps curl wget && \
    rm -rf /var/lib/apt/lists/*

# TARGETARCH is set automatically by buildx ("amd64" or "arm64") and matches
# Debian's JVM directory naming, so this image builds for both architectures.
ARG TARGETARCH
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH}
RUN test -d "$JAVA_HOME" || { echo "JAVA_HOME not found: $JAVA_HOME"; exit 1; }

COPY wait-for-step.sh /
COPY execute-step.sh /
COPY finish-step.sh /
RUN chmod +x /wait-for-step.sh /execute-step.sh /finish-step.sh

WORKDIR /
RUN wget -q ${BASE_URL}/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      && tar -xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark \
      && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Executors need the same numeric stack as the driver for pandas UDFs and
# Arrow-based transfers. Keep these pins identical to jupyter/Dockerfile.
# pandas stays on 2.x: PySpark 4.2.0 warns it "does not yet fully support
# pandas >= 3.0.0" and recommends pandas < 3.0.0.
RUN pip install --no-cache-dir \
      numpy==2.5.3 \
      pandas==2.3.3 \
      pyarrow==25.0.1

ENV PYSPARK_PYTHON=/usr/local/bin/python3

# Fix the value of PYTHONHASHSEED
# Note: this is needed when you use Python 3.3 or greater
ENV PYTHONHASHSEED=1
