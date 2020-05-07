---
layout: post
type: posts
title: How to run Jupyter Notebooks in Spark
date: '2019-04-26T23:55:00.000+02:00'
author: Raul Pingarron
tags:
- BigData
---
![PySpark logo](/images/posts/Pyspark_Jupyter.png)  
Jupyter Notebook is an open source web application that allows you to create and share documents containing live code, equations, visualizations and narrative text. The Jupyter notebooks are ideal for online and collaborative data analysis and typical use cases include data cleansing and transformation, numerical simulation, statistical modeling, data visualization, machine learning, and more.

Jupyter Notebook supports more than 40 programming languages (which are implemented inside the specific "kernel"); in fact, "Jupyter" is an acronym for Julia, Python and R. These three programming languages were the first languages that Jupyter supported, but today it also supports many other languages such as Java, Scala, Go, Perl, C/C++.
IPython is the default kernel and supports Python 3.5+.
Jupyter can also leverage Big Data frameworks and tools like Apache Spark; it can also be run in containerized environments (Docker, Kubernetes, etc.) to scale application development and deployment, isolate user processes, or simplify software life cycle management.

For more information take a look at Jupyter's <a href="https://jupyter.org/" target="_blank">official web site.</a>

There are some ways to run PySpark on a Jupyter Notebook:
1. Configure the PySpark driver to run on a Jupyter Notebook (and starting PySpark will open the Jupyter Notebook)
2. Load a conventional IPython kernel in Jupyter and use the findSpark library to make the Spark context available in Jupyter's kernel. This is often used to make PySpark available in an IDE for local development and testing. More information is available <a href="https://github.com/minrk/findspark" target="_blank">here.</a>
3. Use the SparkMagic package to work interactively with remote Spark clusters via Livy, Spark's REST API server. More information is available <a href="https://github.com/jupyter-incubator/sparkmagic" target="_blank">here.</a>  

This blog post focuses on the first option, which means that the PySpark driver will be executed by the Jupyter Notebook's kernel.

To do this, we will configure Jupyter to run Python over Spark (PySpark API) using a Hadoop/Spark cluster as the distributed processing backend. The same approach can be used with a Scala Jupyter kernel to run Notebooks in Spark's distributed mode. 

## STEP 1: Install Jupyter Notebook  
Instead of just installing the <a href="https://jupyter.org/install.html" target="_blank">classic Jupyter Notebook </a> we will install the Anaconda distribution since it also includes many data-science packages and simplifies a lot Python package management and deployment. 

The first thing is to download Anaconda from <a href="https://www.anaconda.com/products/individual" target="_blank">Anaconda's web site</a>. The recommendation is to download Anaconda for Python3 (Anaconda3). The next step is to install Anaconda3 following the <a href="https://docs.anaconda.com/anaconda/install/" target="_blank"> instructions </a>found here. 
The installation instructions for a multi-user Anaconda installation in Linux are <a href="https://docs.anaconda.com/anaconda/install/multi-user/" target="_blank">here.</a>
    
From your Linux shell you could simply do a:   

```bash
# wget https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh
```

And then etner the following to install Anaconda for Python 3.7:



