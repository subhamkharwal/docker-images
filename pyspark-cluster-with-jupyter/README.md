# Spark Cluster v3.3.0

Apache Spark Cluster with 1 master and 2 worker nodes. PySpark Jupyter Lab (pyspark-jupyter-lab) image needs to build up.

### To start the cluster and create containers
    docker compose build
#### Once build is complete
    docker compose up

#### Note:
If you are running in issue with following error:

`ln: failed to create symbolic link 'python': File Exists`

Please suppress the commands at line 17, 28 and 40 of the docker-compose.yml

You can run those commands manually once the containers are created by logging in master and worker nodes with docker exec command.
