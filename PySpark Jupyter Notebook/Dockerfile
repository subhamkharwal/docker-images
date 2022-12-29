# Base Python 3.10 image
FROM python:3.10

# Expose Port
EXPOSE 8888 4040

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# Install OpenJDK
RUN apt-get update && \
    apt-get install -y  default-jdk && \
    apt-get install -y ant && \
    apt-get clean;
    
# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME

# Install Jupyter Lab and PySpark
RUN pip install jupyterlab
RUN pip install pyspark==3.3.0

# Change to working directory and clone git repo
WORKDIR /jupyter

# Clone Ease with Apache Spark Repo to Start
RUN git clone https://github.com/subhamkharwal/ease-with-apache-spark.git

CMD ["python3", "-m", "jupyterlab", "--ip", "0.0.0.0", "--allow-root"]