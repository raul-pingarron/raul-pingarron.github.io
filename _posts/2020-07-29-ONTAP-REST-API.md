---
layout: post
type: posts
title: Primeros pasos con la REST API de ONTAP
date: '2020-07-29T19:14:30.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
- DevOps
---
En este post hago una introducción a la REST API de ONTAP con algunos ejemplos prácticos y sencillos utilizando el interface Swagger que se incluye dentro del GUI de ONTAP. En un siguiente post trataré de una manera programática la REST API de ONTAP a través de la librería para Python que también está disponible. 
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2020%2F07%2F29%2FONTAP-REST-API.html" target="_blank">here</a>.

---   

La arquitectura REST (Representational State Transfer) apareció en el año 2000 ofreciendo una alternativa sencilla y más abierta a las tecnologías existentes basadas en RPCs o SOAP. El hecho de utilizar el protocolo HTTP hace que esta tecnología permita compartir información de manera muy flexible entre una gran variedad de tipos de clientes (PCs, móviles, tabletas, etc.), servidores y software. Tanto es así que a día de hoy se ha convertido en un estándar de facto para implementar APIs o funcionalidades de intercambio de mensajes o datos utilizando un formato estandarizado y abierto (generalmente XML o JSON) entre distinto software. Por este motivo NetApp decidió apostar hace años e invertir en desarrollo de REST APIs para sus productos.  

La REST API de ONTAP aparece en la versión 9.6; hasta entonces se venía utilizando desde hace muchos años una API propietaria (denominada ZAPI) para la que hay disponible un completo SDK. La ZAPI seguirá conviviendo durante un tiempo más en nuevas versiones de ONTAP para matener compatibilidad y soporte a desarrollos existentes.



<p align="center">
  <img width="582" height="176" src="/images/posts/ONTAP_REST-API.jpg">
</p>   

## ¿Cómo funciona la API de ONTAP?
Como cualquier otra API que sea RESTful:
1. El servidor (en este caso corriendo en ONTAP) mantiene una lista de sus recursos con su estado y sus operaciones y expone sus datos a los clientes a través de un esquema de direccionamiento bien definido (URIs o URLs). Además, estos recursos se exponen generalmente bajo una estructura jerárquica parecida a las carpetas o directorios de un sistema de ficheros. 
2. Para el intercambio de solicitudes y respuestas a los recursos expuestos, el cliente y el servidor utilizan métodos HTTP (POST, GET, PUT y DELETE) que permiten operaciones CRUD (Crear, Leer, Actualizar y Borrar). Otra de las ventajas de utilizar HTTP es que no tiene estado ya que cada petición contiene toda la información necesaria para ser ejecutada siendo independiente de otras, lo que evita mantener sesiones.
3. Los datos se transmiten dentro del cuerpo de cada solicitud/respuesta HTTP en formato estructurado, generalmente utilizando JSON ya que éste permite representar estructuras de datos simples en texto plano (y además es también un estándar de la industria). Por otra parte, toda respuesta HTTP viene acompañada también de un código de respuesta HTTP (el 200 significa "OK", el 400 indica una petición incorrecta, etc.). En el caso particular de la API de ONTAP, al producirse un error, se devuelve un objeto de tipo error dentro del cuerpo de la respuesta (este objeto también se presenta en formato JSON e incluye un código de error y un mensaje descriptivo del mismo).

Una de las características adicionales de la API REST de ONTAP es que utiliza contenido hipermedia y soporta HAL (HyperTest Application Language) lo que significa que dentro de la respuesta JSON se pueden incluir enlaces para añadir más información sobre el objeto en cuestión (vamos a ver un ejemplo de esto un poco mas abajo).

Por último, la API REST de ONTAP incluye el concepto de operaciones síncronas y asíncronas: por defecto las operaciones POST, PATCH y DELETE pueden tardar mas de 2 segundos y se consideran asíncronas y no bloqueantes. Las operaciones asíncronas se ejecutan utilizando *jobs* y siempre van a devolver dentro de su respuesta información sobre el *job* que está ejecutando la operación incluyendo un enlace HAL al recurso u objeto correspondiente dentro de la API.


## ¿Cómo acceder a la API de ONTAP?
El acceso se puede realizar utilizando el Cluster Management LIF, o el Node Management LIF, o incluso el SVM Management LIF. Además, hay que tener en cuenta que todo el tráfico entre el cliente y el LIF de ONTAP utilizado para la conexión está encriptado (generalmente por TLS, según la configuración de ONTAP).

Acceder a la API es tan sencillo como apuntar por HTTPS a la IP del LIF en cuestión añadiendo `/api`. Además la API está versionada por lo que si quisiésemos acceder a una versión específica utilizaríamos `/api/v1`.    
En el siguiente ejemplo vamos a obtener la versión de ONTAP que corre un clúster haciendo un GET (implícito) a `https://<cluster_mgmt_ip_address>/api/cluster?fields=version` como muestra la siguiente imagen:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_1.jpg">
</p>  

Esta petición ha desencadenado el siguiente intercambio de información:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_comms.jpg">
</p>  

Veamos otro simple ejemplo para listar los *jobs* existentes en el clúster mediante `/api/cluster/jobs`:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_1-1.jpg">
</p>  

Según he indicado anteriormente podemos ver que la respuesta contiene un enlace HAL (el valor del objeto "self" contenido en "_links").
Si abrimos este enlace HAL podremos obtener los detalles de ese job en particular y de la operación que se solicitó:

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_1-2.jpg">
</p>  


La API de ONTAP tiene los recursos divididos en 16 categorías (`cloud`, `cluster`, `networking`, `SVM`, `SAN`, `NAS`, `storage`, etc.) y en este caso hemos accedido a la categoria `cluster` que a su vez contiene recursos como `/jobs`, `/metrics`, `/nodes`, etc. Para ver la descripción de las distintas categorías y sus recursos lo mejor es consultar la documentación de la API, que además es muy detallada.


**¿Dónde está la documentación de la API?**

La documentación completa está en <a href="https://docs.netapp.com/ontap-9/topic/com.netapp.nav.api/home.html" target="_blank">https://docs.netapp.com/ontap-9/topic/com.netapp.nav.api/home.html</a>.
No obstante, también es posible acceder a la documentación online de la API desde el própio clúster de ONTAP a través de su interfaz de gestión web `https://<cluster_mgmt_ip_address>/docs/api`:  

<p align="center">
  <img src="/images/posts/ONTAP_REST-API_2.jpg">
</p>  


## El interface Swagger 
Una de las formas mas sencillas y visuales para acceder a la REST API de ONTAP y realizar operaciones CRUD es a través del interface Swagger que proporciona la gestión Web del clúster de ONTAP. Lo único necesario para ello es autenticarse haciendo clic en el botón de "login" y utilizar la operación correspondiente dentro de la categoría de recursos necesaria.
Por ejemplo, para listar los volúmenes de un determinado SVM de nuestro clúster iremos a la categoría `storage` y desplegamos la operación **GET /storage/volumes** en el interfaz Swagger. 

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

Una de las cosas muy útiles que nos va a devolver el interfaz es la llamada a la API que tendríamos que utilizar si quisiésemos operar con **CURL**, junto a la URL/URI completa para la petición que acabamos de hacer:

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

