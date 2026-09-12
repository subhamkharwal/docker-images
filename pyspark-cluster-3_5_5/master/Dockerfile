# Base tag is overridable so the multi-arch build can chain onto the matching
# multi-arch spark-base instead of the older amd64-only 3.5.5 image.
ARG BASE_TAG=3.5.5
FROM easewithdata/spark-base:${BASE_TAG}

LABEL maintainer="Ease With Data <easewithdata@gmail.com> (Original 3.3.0 version published by bde2020)"

COPY master.sh /

ENV SPARK_MASTER_PORT 7077
ENV SPARK_MASTER_WEBUI_PORT 8080
ENV SPARK_MASTER_LOG /spark/logs

EXPOSE 8080 7077 6066

# Download Spark Connect JAR
RUN wget https://repo1.maven.org/maven2/org/apache/spark/spark-connect_2.12/3.5.5/spark-connect_2.12-3.5.5.jar
RUN mv spark-connect_2.12-3.5.5.jar /spark/jars/

CMD ["/bin/bash", "/master.sh"]