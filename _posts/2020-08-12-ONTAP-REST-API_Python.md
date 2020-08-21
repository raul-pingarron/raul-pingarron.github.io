---
layout: post
type: posts
title: Accediendo a la REST API de ONTAP con Python
date: '2020-08-12T20:36:40.000+01:00'
author: Raul Pingarron
tags:
- DevOps
---
Este post es la continuación del anterior (Primeros pasos con la REST API de ONTAP) y en él vamos a ver de una manera más programática como acceder a la REST API de ONTAP a través de la librería para Python. Ello nos va a permitir automatizar, desplegar e integrar sistemas de almacenamiento ONTAP de NetApp dentro de la infraestructura hardware y software existente.  
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2020%2F08%2F12%2FONTAP-REST-API_Python.html" target="_blank">here</a>.

---   

La librería de Python para la API REST de ONTAP se encuentra publicada en el repositorio oficial de paquetes de python <a href="https://pypi.org/" target="_blank">PyPi.org</a> y además se integra en la mayoría de los IDEs de Python (la imagen siguiente muestra la integración dentro de PyCharm).

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_Python1.jpg">
</p>   
<p align="center">
  <img src="/images/posts/ONTAP_REST-API_Python1-1.jpg">
</p>   

Entre los elementos diferenciadores de la librería de Python para la API REST de ONTAP destacaría los siguientes:

- Gestión de la conexión: almacena las credenciales para reutilizarlas en cada una de las operaciones.
- Procesamiento asíncrono de las peticiones y monitorización del progreso de las peticiones en background a través de su correspondiente *job ID*.
- Gestión de las excepciones: la respuesta incluye los errores y excepciones.


Al igual que con la REST API, hay que tener en cuenta que las operaciones sobre determinados recursos u objetos puede que necesiten del ID del objeto y no su nombre; por ejemplo cualquier operación sobre un volumen (como crear un snapshot) requiere del UUID del volúmen y no vale especificar el nombre. Para ello tenemos que obtener el UUID mediante una función o método (mas adelante pondré un ejemplo).


## Instalación de la librería Python

La instalación es muy sencilla ya que se realiza a través del instalador de paquetes de Python (PiP) 




