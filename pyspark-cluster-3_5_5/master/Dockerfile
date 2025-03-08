FROM easewithdata/pyspark-base_3_5_5

LABEL maintainer="Ease With Data <easewithdata@gmail.com> (Original 3.3.0 version published by bde20200)"

COPY master.sh /

ENV SPARK_MASTER_PORT 7077
ENV SPARK_MASTER_WEBUI_PORT 8080
ENV SPARK_MASTER_LOG /spark/logs

EXPOSE 8080 7077 6066

CMD ["/bin/bash", "/master.sh"]