# PySpark Jupyter Lab Notebook

Jupyter Lab Notebook with root access.
EaseWithApacheSpark notebooks provided to start with.

##To build image from the Dockerfile:

docker build --tag easewithdata/pyspark-jupyter-lab .

##To create container from image

docker run -d --name jupyter-lab easewithdata/pyspark-jupyter-lab
