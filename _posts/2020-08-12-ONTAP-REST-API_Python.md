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

La librería de Python para la API REST de ONTAP se encuentra publicada en el repositorio oficial de paquetes de python <a href="https://pypi.org/" target="_blank">PyPi.org</a>.
La documentación y la última versión están disponibles en <a href="https://pypi.org/project/netapp-ontap/" target="_blank">https://pypi.org/project/netapp-ontap/</a>.   
Además, la API REST de ONTAP se integra en la mayoría de los IDEs de Python (la imagen siguiente muestra la integración dentro de PyCharm).

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

La instalación es muy sencilla ya que se realiza a través del instalador de paquetes de Python (PiP), tan solo se requiere una versión de Python igual o superior a la 3.5. La instalación resolverá también las dependencias que hay con las librerías `requests` y `marshmallow`. 

```pascal
pip install netapp-ontap
```

La última versión a fecha de hoy es la 9.7.3, en mi caso tengo una versión anterior:

```pascal
$ pip show netapp-ontap
Name: netapp-ontap
Version: 9.7.2
Summary: A library for working with ONTAP's REST APIs simply in Python
```

Así que la voy a actualizar:
```pascal
$ pip install --upgrade netapp-ontap
Collecting netapp-ontap
  Downloading netapp_ontap-9.7.3-py3-none-any.whl (898 kB)
     |████████████████████████████████| 898 kB 683 kB/s
Installing collected packages: netapp-ontap
    Successfully uninstalled netapp-ontap-9.7.2
Successfully installed netapp-ontap-9.7.3
```
Para más información visitar la página con el <a href="https://pypi.org/project/netapp-ontap/#history" target="_blank">historial de versiones</a>.


## Establecer conexión con la API REST del clúster ONTAP

Lo primero que es necesario hacer es establecer una conexión con la API REST del clúster de ONTAP.
El módulo `config`de la librería nos permite crear una conexión y almacenar sus credenciales para ser utilizada como la conexión por defecto para todas las llamadas. Según la documentación:

```programming
netapp_ontap.config CONNECTION: Optional[HostConnection] = None
 This netapp_ontap.host_connection.HostConnection object, if set, 
 is used as the default connection for all library operations 
 if no other connection is set at a more specific level
```
Así que vamos a ver un ejemplo simple de cómo hacerlo:

```python
from netapp_ontap import NetAppRestError, config, HostConnection

def establece_conexion(cluster: str, usuario: str, passwd: str) -> None:
    config.CONNECTION = HostConnection(
        cluster, username=usuario, password=passwd, verify=False,
    )

def main() -> None:
    cluster = "10.10.10.10"
    usuario_api = "admin"
    pasguord = "mi_pasgüord"
    svm = "SVM-TEST"

    establece_conexion(cluster, usuario_api, pasguord)

if __name__ == "__main__":
    main()
```


## Obtener el UUID de un volumen

Como he mencionado antes, hay operaciones sobre determinados recursos u objetos que necesitan del ID del mismo y no admiten su nombre. 
Un caso son las operaciones contra volúmenes, como crear un snapshot o listar los snapshots de un determinado volumen.
El siguiente ejemplo que voy a mostrar listará los snaphots de un determinado volumen, por lo que primeramente necesitamos crear una función que obtenga el UUID del volumen en función de su nombre y el SVM al que pertenece.
Lo primero es importar el módulo de la librería para gestionar volúmenes, para ello añadiríamos lo siguiente a nuestro programa anterior:

```python
from netapp_ontap.resources import Volume
```
Y ahora, en nuestro programa anterior creamos una nueva función para nuestro propósito:

```python
def devuelve_uid_vol(nombre_svm, nombre_volumen):
    try:
        for volumen in Volume.get_collection(
                **{"svm.name": nombre_svm}, **{"name": nombre_volumen}, fields="uuid"):
            return volumen.uuid
    except NetAppRestError as error:
        print("Por favor, INTRODUZCA EL NOMBRE DEL VOLUMEN!\n" + error.http_err_response.http_response.text)
```

Vamos por partes:

- Con el método `get_collection` aplicado al objeto de tipo `Volume` se obtiene la lista de UUIDs que pertenecen a un SVM especificado; para no impactar en el rendimiento este "fetch" es perezoso ya que solo se ejecuta cuando se itera sobre el resultado como es el caso del ejemplo que he puesto. Este método toma como argumento **kwargs parejas clave/valor que se pueden utilizar como parámetros de consulta, como en nuestro caso que hemos pasado tres parejas para delimitar la consulta.
- Utilizamos el módulo `NetAppRestError` para el manejo de errores y excepciones: si la respuesta HTTP devuleve un código 400 o superior la librería devuelve una excepción y podemos dar visibilidad de qué tipo de error se trata.

Y lo único que necesitaríamos dentro de nuestro cuerpo principal del programa sería:

```python
    uid_vol = devuelve_uid_vol(svm, nbre_vol)
```

Notar que el método `get_collection` de la API lo vamos a poder aplicar sobre distintos objetos para iterar sobre ellos y obtener (GET) sus elementos, 

## Obtener detalles y elementos de un objeto

Como hemos visto antes, podemos aplicar el método `get_collection` de la API sobre distintos objetos para iterar sobre ellos y obtener sus elementos.
A continuación algunos ejemplos aplicados al objeto de tipo `Volume` ejecutados directamente desde el intérprete de Python.

Lo primero es crear la conexión con las credenciales e importar los módulos necesarios:

```programming
>>> from netapp_ontap import NetAppRestError, config, HostConnection
>>> from netapp_ontap.resources import Volume
>>> config.CONNECTION = HostConnection("1.1.1.1", username="admin", password="XYZ", verify=False)
````
Ahora iteramos sobre todos los volúmenes del sistema con el método anterior y almacenamos en una lista solo los valores nombre del volumen, agregado contenedor, SVM al que pertenecen y su tamaño:

```programming
>>> volumenes = list(Volume.get_collection(fields="name,aggregates.name,svm.name,size"))
>>> volumenes[0]
Volume({'name': 'share1_unix', 'aggregates': [{'name': 'aggr_nodo01_SAS15K'}], 'size': 2314987372544, 'uuid': '0c6c5035-95ef-11ea-a5f4-00a098b68ab0', '_links': {'self': {'href': '/api/storage/volumes/0c6c5035-95ef-11ea-a5f4-00a098b68ab0'}}, 'svm': {'name': 'svm-demos'}})
>>>
>>> for i in range(len(volumenes)):
...    print("VOLUMEN "+volumenes[i].name+":"+"\n  " \
...    +"Agregado: "+volumenes[i].aggregates[0].name+"\n  " \
...    +"SVM: "+volumenes[i].svm.name+"\n  " \
...    +"Tamaño: "+str(volumenes[i].size)+" bytes")
...
VOLUMEN oVirt_NFS_01:
  Agregado: aggr_nodo02_DATOS
  SVM: infrastructure
  Tamaño: 2199023255552 bytes
VOLUMEN mysqltest01_backups:
  Agregado: aggr_nodo01_SAS15K
  SVM: svm-demos
  Tamaño: 553475170304 bytes
VOLUMEN mssqltest01_sysDB:
  Agregado: aggr_nodo01_DATOS
  SVM: svm-demos
  Tamaño: 279172874240 bytes

```
Otro ejemplo simple para listar los volúmenes y su UUID de determinado SVM sería:

```programming
>>> for volumen in Volume.get_collection(**{"svm.name": "svm-demos"}):
...     print (volumen.name, volumen.uuid)
...
svmdemos_root 1592737d-945a-11ea-a5f4-00a098b68ab0
mysqltest01_backups 3d334ae0-9528-11ea-a5f4-00a098b68ab0
mssqltest01_sysDB 7f9babaf-945b-11ea-a5f4-00a098b68ab0
````

Para finalizar con los ejemplos vamos a terminar nuestro código inicial para crear una función que nos liste los snapshots de un determinado volumen.
Para ello importamos también el módulo de gestión de snapshots de la librería:

```python
from netapp_ontap.resources import Volume, Snapshot
```
Y añadimos la nueva función:

```python
def lista_snapshots(nombre_vol, vol_uuid) -> None:
    try:
        print()
        print("Listado de Snapshots para el volumen << %s >>" % nombre_vol)
        print()
        for snapshot in Snapshot.get_collection(vol_uuid):
            print(" - " + snapshot.name)
    except NetAppRestError as error:
        print("Volumen inexistente!\n " + error.http_err_response.http_response.text)
        print("   --- por favor, especifique un volumen valido ---")
    print("\n")
```

En vista a lo anteriore, el cuerpo principal del programa quedaría así:

```python
def main() -> None:
    cluster = "10.10.10.10"
    usuario_api = "admin"
    pasguord = "mi_pasgüord"
    svm = "SVM-TEST"
    nombre_vol = "vol1"

    establece_conexion(cluster, usuario_api, pasguord)
    uid_vol = devuelve_uid_vol(svm, nombre_vol)
    lista_snapshots(nombre_vol, uid_vol)

if __name__ == "__main__":
    main()
```
En el <a href="https://github.com/raul-pingarron/Ejemplos_ONTAP_RestAPI/blob/master/lista_snaps.py" target="_blank">siguiente enlace</a> tenéis un ejemplo de código mas completo para listar los snapshots de un volúmen pasando como argumento al programa el nombre del volumen sobre el que nos interesa sacar la lista de snaps.

## ¿Hay más ejemplos?

¡SI!, además de los que he dejado en mi repositorio, que son muy básicos, NetApp mantiene un repositorio muy completo con muy buenos ejemplos para multitud de necesidades. 

<a href="https://github.com/NetApp/ontap-rest-python/tree/master/examples/python_client_library" target="_blank">Echa un vistazo aquí</a>.