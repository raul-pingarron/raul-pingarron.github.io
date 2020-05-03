---
layout: post
type: posts
title: Cómo utilizar una versión distinta de Python en Spark
date: '2019-04-06T23:55:00.000+02:00'
author: Raul Pingarron
tags:
- BigData
---
![PySpark logo](/images/posts/pyspark.jpeg)
 Las últimas versiones de Spark 2 son capaces de ejecutar código de cualquier versión de Python igual o superior a 2.7 y 3.4 (el soporte para Python 2.6 fue eliminado a partir de Spark 2.2.0).
Por defecto, en algunas situaciones, PySpark utiliza los ejecutables binarios de Python 2.7 tanto en el driver como en los workers o ejecutores, ya que ésta suele ser la versión predeterminada de Python que se puede encontrar en bastantes de las distribuciones de sistemas operativos Linux con soporte empresarial.

 Pero ¿y si queremos utilizar otra versión distinta de Python en Spark?. 

Por suerte, en Spark es posible instalar y usar múltiples versiones de Python; es tan simple como desplegar la versión requerida de Python tanto en el servidor o nodo que ejecuta el programa *driver* como en el nodo *master* así como en todos nodos *workers* o *executors* y luego usar las variables de entorno de Spark para especificar qué versión usar.

 Para desplegar la versión requerida de Python podemos, por ejemplo, instalar Anaconda en el servidor o nodo donde tenemos instalado el cliente de Spark así como en todos los nodos que son *workers* o ejecutores de Spark en nuestro clúster (por ejemplo, podemos instalar Anaconda3 en todos los nodos implicados bajo `/opt/anaconda3`). Para indicar a Spark que esta nueva versión instalada de Python será la utilizada, simplemente hay que configurar o establecer la variable de entorno `PYSPARK_PYTHON` en el nodo cliente que envía el trabajo de Spark (desde donde se lanza el `spark-submit` o desde donde se arranca la Shell de PySpark). 
Esto se puede lograr fácilmente añadiendo lo siguiente al `.bashrc` del perfil del usuario:
    export PYSPARK_PYTHON="/opt/anaconda3/bin/python3"

Para más información echa un vistazo a la documentación oficial [aquí](https://spark.apache.org/docs/latest/configuration.html#environment-variables)

