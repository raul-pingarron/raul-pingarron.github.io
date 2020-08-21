---
layout: post
type: posts
title: Accediendo a la REST API de ONTAP con Python
date: '2020-08-12T20:36:40.000+01:00'
author: Raul Pingarron
tags:
- DevOps
---
Este post es la continuación del anterior (Primeros pasos con la REST API de ONTAP) y en él vamos a ver de una manera más programática como acceder a la REST API de ONTAP a través de la librería para Python.   
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2020%2F07%2F29%2FONTAP-REST-API.html" target="_blank">here</a>.

---   

La arquitectura REST (Representational State Transfer) apareció en el año 2000 ofreciendo una alternativa sencilla y más abierta a las tecnologías existentes basadas en RPCs o SOAP. El hecho de utilizar el protocolo HTTP hace que esta tecnología permita compartir información de manera muy flexible entre una gran variedad de tipos de clientes (PCs, móviles, tabletas, etc.), servidores y software. Tanto es así que a día de hoy se ha convertido en un estándar de facto para implementar APIs o funcionalidades de intercambio de mensajes o datos utilizando un formato estandarizado y abierto (generalmente XML o JSON) entre distinto software. Por este motivo NetApp decidió apostar hace años e invertir en desarrollo de REST APIs para sus productos.   


<p align="center">
  <img width="582" height="176" src="/images/posts/ONTAP_REST-API.jpg">
</p>   

## ¿Cómo funciona la API de ONTAP?
Como cualquier otra API que sea RESTful:  el servidor (en este caso corriendo en ONTAP) mantiene una lista de sus recursos con su estado y sus operaciones y expone sus datos a los clientes a través de un esquema de direccionamiento bien definido (URIs o URLs). Además, estos recursos se exponen generalmente bajo una estructura jerárquica (parecida a las carpetas o directorios de un sistema de ficheros). 
Para el intercambio de solicitudes y respuestas a los recursos expuestos, el cliente y el servidor utilizan métodos HTTP (POST, GET, PUT y DELETE) que permiten operaciones CRUD (Crear, Leer, Actualizar y Borrar). Otra de las ventajas de utilizar HTTP es que no tiene estado ya que cada petición contiene toda la información necesaria para ser ejecutada siendo independiente de otras, lo que evita mantener sesiones.
Por último, los datos se transmiten dentro del cuerpo de cada solicitud/respuesta HTTP en formato estructurado, generalmente utilizando JSON ya que éste permite representar estructuras de datos simples en texto plano (y además es también un estándar de la industria).


La REST API de ONTAP aparece en la versión 9.6; hasta entonces se venía utilizando desde hace muchos años una API propietaria (denominada ZAPI) para la que hay disponible un completo SDK. La ZAPI seguirá conviviendo durante un tiempo más en nuevas versiones de ONTAP para matener compatibilidad y soporte a desarrollos existentes.


## ¿Cómo acceder a la API de ONTAP?
El acceso se puede realizar utilizando el Cluster Management LIF, o el Node Management LIF, o incluso el SVM Management LIF. Además, hay que tener en cuenta que todo el tráfico entre el cliente y el LIF de ONTAP utilizado para la conexión está encriptado (generalmente por TLS, según la configuración de ONTAP).

Acceder a la API es tan sencillo como apuntar por HTTPS a la IP del LIF en cuestión añadiendo `/api`. Además la API está versionada por lo que si quisiésemos acceder a una versión específica utilizaríamos `/api/v1`. En el siguiente ejemplo vamos a obtener la versión de ONTAP que corre un clúster haciendo un GET (implícito) a `https://<cluster_mgmt_ip_address>/api/cluster?fields=version`

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_1.jpg">
</p>  

La API de ONTAP tiene los recursos divididos en 16 categorías (Cloud, Cluster, Networking, SVM, SAN, NAS, Storage, etc.) y en este caso hemos accedido a la categoria "cluster" que contiene recursos como "jobs", "licensing", "metrics", "nodes", etc. Para ver la descripción de las distintas categorías y sus recursos lo mejor es consultar la documentación de la API, que además es muy detallada.

**¿Dónde está la documentación de la API?**

La documentación completa está en <a href="https://docs.netapp.com/ontap-9/topic/com.netapp.nav.api/home.html" target="_blank">https://docs.netapp.com/ontap-9/topic/com.netapp.nav.api/home.html</a>.
No obstante, también es posible acceder a la documentación online de la API desde el própio clúster de ONTAP a través de su interfaz de gestión web `https://<cluster_mgmt_ip_address>/docs/api`:  

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_2.jpg">
</p>  


## El interface Swagger 
Una de las formas mas sencillas y visuales para acceder a la REST API de ONTAP y realizar operaciones CRUD es a través del interface Swagger que proporciona la gestión Web del clúster de ONTAP. Lo único necesario para ello es autenticarse haciendo clic en el botón de "login" y utilizar la operación correspondiente dentro de la categoría de recursos necesaria.
Por ejemplo, para listar los volúmenes de un determinado SVM de nuestro clúster iremos a la categoría `STORAGE` y desplegamos la operación `GET /storage/volumes` en el interfaz Swagger. 

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_3-1.jpg">
</p>  

Hacemos clic sobre `Try it out` para habilitar la utilización de parámetros sobre los recursos:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_3-2.jpg">
</p>  

Filtramos por el nombre del SVM del que queremos listar los volúmenes existentes:


<p align="center">
  <img src="/images/posts/ONTAP_REST-API_3-3.jpg">
</p>  

Y ejecutamos la llamada de la API:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_3-4.jpg">
</p>  

Una de las cosas muy útiles que nos va a devolver el interfaz es la llamada a la API que tendríamos que utilizar si quisiésemos operar con CURL, junto a la URL/URI completa para la petición que acabamos de hacer:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_3-5.jpg">
</p> 

Por último, nos devuelve la información solicitada en JSON y nos permite descargarnos el fichero correspondiente:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_3-6.jpg">
</p> 


## ONTAP System Manager es API-aware 

A partir de la versión 9.7 de ONTAP, System Manager se ha construido por completo de manera nativa a partir de la API REST de ONTAP y el usuario puede ver las llamadas a la API que System Manager va haciendo en cada movimiento a través de la GUI. Esto ayuda al usuario a entender estas llamadas a la API y es especialmente útil para usar como ejemplo durante el desarrollo de scripts.   
Tan solo hay que hacer clic sobre el icono que muestra el log de las llamadas a la API que el GUI va haciendo por detrás:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_4-1.jpg">
</p> 

Esta funcionalidad junto con el interfaz Swagger son de mucha utilidad de cara a abordar un uso programático de la API, ya que nos van a facilitar la comprensión de las llamadas, sus opciones y los datos que se devuelven.

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_4-2.jpg">
</p> 

