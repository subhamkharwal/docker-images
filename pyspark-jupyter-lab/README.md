# PySpark Jupyter Lab Notebook - Python v3.10

Jupyter Lab Notebook with root access.
EaseWithApacheSpark notebooks provided to start with.

### To build image from the Dockerfile:
    docker build --tag easewithdata/pyspark-jupyter-lab .

### To create container from image
    docker run -d -p 8888:8888 -p 4040:4040 --name jupyter-lab easewithdata/pyspark-jupyter-lab
