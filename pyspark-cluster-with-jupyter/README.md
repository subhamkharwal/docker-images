# Spark Cluster v3.3.0

Apache Spark Cluster with 1 master and 2 worker nodes.

#### Once build is complete
    docker compose up

#### Note:
If you are running in issue with following error:

`ln: failed to create symbolic link 'python': File Exists`

Please suppress the commands at line 17, 28 and 40 of the docker-compose.yml

You can run those commands manually once the containers are created by logging in master and worker nodes with docker exec command.


##### To setup PySpark Cluster with 2 worker, 1 master and 1 history server
Follow the below instructions carefully 👇🏻
- Clone or Download the docker images repository from `https://github.com/subhamkharwal/docker-images`
- Open CMD prompt (on Windows) or Terminal (on Mac) and move the cloned/downloaded folder
- Change to folder `pyspark-cluster-with-jupyter` and run command `docker compose up`
- The above command would setup a group of containers with 1 Jupyter Lab, 1 Master node, 2 worker nodes and 1 history server
- Run all the containers, go into the logs of Jupyter Lab container in Docker Desktop and copy the token from the URL which looks like `http://127.0.0.1:8888/lab?token=c23436751add815d6fce10071c3958aac7b4f8ebbcf05255`
- Open Jupyter Lab on url `https://localhost:8888`, paste the token and setup a new password.
- [IMPORTANT] Make sure to place your file to read or write your files to location `/data/<your path>` in order to work with cluster. (/data is important, this path is mounted across the cluster to access files or data)
- To see all your data files after execution, run the below command
```shell
%%sh
ls -ltr /data/
```
