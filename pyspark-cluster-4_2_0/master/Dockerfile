# When built through docker-bake.hcl this reference is redirected to the local
# base build, so master can be built and tested before spark-base is published.
FROM easewithdata/spark-base:4.2.0

LABEL maintainer="Ease With Data <easewithdata@gmail.com> (Original 3.3.0 version published by bde2020)"

COPY master.sh /

ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER_WEBUI_PORT=8080
ENV SPARK_MASTER_LOG=/spark/logs

# Spark 4 bundles Spark Connect (jars/spark-connect_2.13-4.2.0.jar), so the
# separate connect JAR download used for 3.5.5 is no longer needed.
EXPOSE 8080 7077 6066 15002

CMD ["/bin/bash", "/master.sh"]
