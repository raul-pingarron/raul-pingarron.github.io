---
layout: post
type: posts
title: How to use a different version of Python in Spark
date: '2019-04-06T23:55:00.000+02:00'
author: Raul Pingarron
tags:
- BigData
---
![PySpark logo](/images/posts/pyspark.jpeg)  
The latest Spark2 versions are capable of running Python 2.7+ or 3.4+ code (Python 2.6 support was removed from Spark 2.2.0).
In some situations, PySpark uses Python 2.7 in both the driver and the workers, as this is usually the default Python version that is shipped in most enterprise Linux distributions.

What if we want to use a different Python version in Spark?.

Fortunately, it is possible to install and use multiple versions of Python in Spark. It is as simple as deploying the required version of Python in both the node that runs the *driver* program, as well as in the *master* node and in all the *executor* nodes, and then use a Spark environment variable to specify which version to use.

To deploy the required Python version we can, for example, install Anaconda3 on the node where we have installed the Spark client as well as on all the Spark *executor* nodes in our cluster (in this case I have installed Anaconda3 on all the nodes under `/opt/anaconda3`). 
The installation instructions for a multi-user Anaconda installation in Linux are <a href="https://docs.anaconda.com/anaconda/install/multi-user/" target="_blank">here.</a>

To tell Spark that we will use the Python3 version shipped with Anaconda3, we simply have to set the environment variable `PYSPARK_PYTHON` in the client node that submits the Spark job (the node where the `spark-submit` is executed from, or where the PySpark Shell is invoqued from). 

This can easily be achieved by adding the following to the `.bashrc`of the user's profile:   

```bash
export PYSPARK_PYTHON="/opt/anaconda3/bin/python3"
```

For more information take a look at the official Spark documentation <a href="https://spark.apache.org/docs/latest/configuration.html#environment-variables" target="_blank">here.</a>

Following our example, once Anaconda3 is installed in the required nodes and environment variable is set, we can check the result by starting the PySpark shell (you can do a `source .bashrc` before to reload the user's profile):

![PySpark logo](/images/posts/PySpark_shell.jpg)  

