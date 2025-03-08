FROM easewithdata/pyspark-base_3_5_5

LABEL maintainer="Ease With Data <easewithdata@gmail.com> (Original 3.3.0 version published by bde20200)"

COPY worker.sh /

ENV SPARK_WORKER_WEBUI_PORT 8081
ENV SPARK_WORKER_LOG /spark/logs
ENV SPARK_MASTER "spark://spark-master:7077"

EXPOSE 8081

CMD ["/bin/bash", "/worker.sh"]