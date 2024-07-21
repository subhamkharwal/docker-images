# Base Python 3.7.10 image
FROM python:3.7.10

# Expose Port
EXPOSE 8888 4040

# Change shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Install OpenJDK
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get clean;
    
# Fix certificate issues
RUN apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Insatall nano & vi
RUN apt-get install -y nano && \
    apt-get install -y vim;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME

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
RUN pip install jupyterlab
RUN pip install pyspark==3.3.0
RUN pip install kafka-python==2.0.2
RUN pip install delta-spark==2.2.0
RUN pip install boto3

# Change to working directory and clone git repo
WORKDIR /home/jupyter

# Clone Ease with Apache Spark Repo to Start
RUN git clone https://github.com/subhamkharwal/ease-with-apache-spark.git

# Fix Jupyter logging issue
RUN ipython profile create
RUN echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

# Start the container with root privilages
CMD ["python3", "-m", "jupyterlab", "--ip", "0.0.0.0", "--allow-root"]
