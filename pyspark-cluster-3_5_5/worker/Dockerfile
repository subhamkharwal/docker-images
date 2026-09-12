# Base tag is overridable so the multi-arch build can chain onto the matching
# multi-arch spark-base instead of the older amd64-only 3.5.5 image.
ARG BASE_TAG=3.5.5
FROM easewithdata/spark-base:${BASE_TAG}

LABEL maintainer="Ease With Data <easewithdata@gmail.com> (Original 3.3.0 version published by bde2020)"

COPY worker.sh /

ENV SPARK_WORKER_WEBUI_PORT 8081
ENV SPARK_WORKER_LOG /spark/logs
ENV SPARK_MASTER "spark://spark-master:7077"

EXPOSE 8081

CMD ["/bin/bash", "/worker.sh"]