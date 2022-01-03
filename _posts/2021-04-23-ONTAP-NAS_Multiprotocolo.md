---
layout: post
type: posts
title: NAS Multiprotocolo con ONTAP (Parte 1)
date: '2021-04-23T19:12:23.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
Si alguna vez te has preguntado cómo funciona el acceso multiprotocolo NAS en ONTAP, o bien estás buscando una solución NAS multiprotocolo, puede que este post, eminentemente teórico, sea lo que andabas buscando...  
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2021%2F04%2F23%2FONTAP-NAS_Multiprotocolo.html" target="_blank">here</a>.

---   

Generalmente hablado, un entorno NAS multiprotocolo es aquel que facilita el acceso al mismo conjunto de datos por parte de clientes con sistemas operativos distintos (Windows y variantes de UNIX) que utilizan también protocolos NAS distintos. De esta manera, si el sistema de almacenamiento NAS soporta multiprotocolo, una vez que el usuario ha sido autenticado y posee los permisos adecuados a nivel de *share* CIFS o *export* NFS, y permisos a nivel de fichero/directorio, éste podrá acceder a los datos desde un host UNIX utilizando NFS o desde un equipo Windows utilizando CIFS/SMB.

Entre las ventajas principales de utilizar esta aproximación figuran la posibilidad de controlar permisos y gestionar el control de acceso de manera agnóstica al protocolo, así como poder centralizar la gestión de identidades en un entono NAS.

Los retos más importantes que ha de solucionar cualquier implementación NAS multiprotocolo son: 
- la gestión de las distintas semánticas de seguridad.
- la correlación o mapeo de usuarios entre los usuarios de los distintos mundos (usuarios UNIX/NFS y usuarios Windows/SMB).

El principal problema es que SMB y NFS utilizan distintas semánticas de seguridad: Windows utiliza ACLs de NTFS (o de Windows) mientras que NFS utiliza “bits-de-modo” de tipo SysV o ACLs de NFS (distintas a las de Windows). Además, incluso dentro del mundo UNIX/NFS, las ACLs de NFS no se corresponden con los permisos que utilizan los bits-de-modo (RWX/777), especialmente cuando se están empleando ACLs específicas para permisos especiales. 
<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_01.jpg">
</p>   

Para solucionar esta problemática, ONTAP implementa el concepto de “**Estilo de Seguridad**” (Security Style) que permite especificar qué tipo de semántica de seguridad se utilizará para los ficheros y directorios del volumen, de manera que solo se aplica un tipo de permisos con independencia del protocolo de acceso al dato. Además de esto, ONTAP construye dinámicamente una "*credencial unificada*", mediante la correlación o **mapeo de usuarios**, que permite que los usuarios tengan el mismo tipo de acceso tanto si acceden desde CIFS/SMB como si acceden desde NFS. Es decir, que si la ACL de Windows o los bits-de-modo SysV permiten el acceso el usuario, éste podrá acceder al fichero con independencia del protocolo; en caso contrario se le denegará el acceso.


## El Estilo de Seguridad (Security Style)

Es importante dejar claro que el Estilo de Seguridad sólo determina dos cosas: (1) el tipo de permisos que ONTAP utiliza para controlar el acceso a los datos y (2) qué tipo de cliente puede modificar estos permisos. 
Los FlexVols y FlexGroups admiten los siguientes estilos de seguridad:
 - UNIX
 - NTFS
 - MIXED
 
La siguiente tabla resume, para cada tipo de Estilo de Seguridad, el tipo de permisos o semántica de seguridad que heradan los ficheros y directorios de un volumen, así como qué tipo de cliente puede modificar permisos:

|  Estilo de Seguridad | Semántica de permisos | Clientes que pueden modificar permisos | 
|---|---|---|
| UNIX | bits-de-modo SysV <br> o<br>ACLs NFS | cliente NFS |
| NTFS | ACLs Windows (NTFS) | cliente SMB |
| MIXED | bits-de-modo SysV <br> o<br>ACLs NFS <br>o<br>ACLs Windows (NTFS) | clientes NFS <br>o<br> SMB |


El estilo de seguridad MIXED suele llevar a confusión, así que otra aclaración importante es que cuando el estilo de seguridad es MIXED, los permisos efectivos dependen del tipo de cliente que modificó los permisos por última vez, ya que los usuarios establecen el estilo de seguridad de forma individual. Es decdir: si el último cliente que modificó los permisos fue un cliente NFSv3, los permisos son bits del modo UNIX NFSv3; si el último cliente fue un cliente NFSv4, los permisos son ACLs NFSv4; si el último cliente fue un cliente SMB, los permisos son ACLs NTFS de Windows.


## El Mapeo de Usuarios

Una vez que el usuario se ha autenticado, es necesario determinar qué permisos le aplican en función del Estilo de Seguridad del recurso al que intenta acceder. Cuando el usuario (cliente) gestiona una semántica de seguridad o permisos distinta a la del estilo de seguridad del recurso que se accede, ONTAP intenta construirle una credencial que represente los permisos mapeando su nombre de usuario con un nombre de usuario correspondiente existente.
Así, en ONTAP:
- Para volúmenes con Estilo de Seguridad NTFS: si el cliente accede por NFS (donde se gestionan permisos en formato bits-de-modo de SysV, por ejemplo), será necesario realizar un mapeo de su usuario UNIX a un usuario Windows existente (local o en el AD). Si no es posible realizar ese mapeo (es decir, no hay definida una regla de mapeo explícito para este ese usuario UNIX contra un usuario Windows), ONTAP intenta realizar un mapeo implícito (es decir, ONTAP intenta encontrar un usuario Windows en su SAM local o en el Dominio o AD que coincida con el nombre del usuario UNIX). Si no es posible realizar el mapeo, ONTAP intentará el mapeo al usuario de Windows por defecto, si este se ha configurado (por defecto no está configurado). En caso contrario, al usuario se le deniega el acceso ya que no hay posibilidad realizar ningún mapeo de usuario.
	
- Para volúmenes con Estilo de Seguridad UNIX: si el cliente que accede por SMB/CIFS (donde se gestionan permisos en formato de ACL de Windows-NTFS) será necesario realizar un mapeo de su usuario Windows a un usuario UNIX existente (local o en el LDAP/NIS). Si no es posible realizar el mapeo explícito de usuario (no hay una regla explícita de mapeo definida), se utiliza el mapeo implícito (ONTAP intenta encontrar un usuario UNIX en DB local de usuarios o en el LDAP, o en el NIS, cuyo nombre coincida con el nombre del usuario de Windows en minúsculas). Si no es posible realizar el mapeo, entonces al usuario Windows se le mapea por defecto a un usuario anónimo (“pcuser” en ONTAP, con UID 65534, que corresponde con el “nobody” en clientes UNIX), si este ha sido configurado. En caso contrario el mapeo fallará y se le denegará acceso al usuario.


Para que este mapeo funcione, ONTAP se apoya en fuentes de búsqueda de usuarios para ambos protocolos: 
- para NFS se pueden utilizar búsquedas locales (usuarios locales UNIX en ONTAP), o bien a través de LDAP o NIS
- para SMB se pueden utilizar búsquedas locales (usuarios locales SMB/CIFS en ONTAP), o bien a través de Directorio Activo (AD).

El orden de búsqueda de las fuentes se puede cambiar en ONTAP modificando el correspondiente valor del ns-switch; por defecto el valor está fijado a "files" (que realidad no son ficheros locales en ONTAP sino información que reside en la base de datos del clúster). En la mayoría de las ocasiones suele ser más recomendable utilizar un LDAP externo para la gestión de identidades y modificar el ns-switch para que primero se busque del LDAP y dejar el "files" local como segunda opción como mecanismo de seguridad (en caso de la conectividad a todos los servidores LDAP configurados falle, al menos se podrá seguir consultando de los usuarios locales).
Ejemplo: 
```pascal
::> vserver services name-service ns-switch modify -vserver <nombre-svm> -database namemap -sources ldap,files
```

Las siguientes imágenes pueden ayudar a entender qué ocurre por debajo (haz clic en ellas para verlas en resolución completa):

<p align="center">
  <a href="/images/posts/NAS_Multiprotocolo_03.jpg" target="_blank"><img src="/images/posts/NAS_Multiprotocolo_03.jpg"></a>
</p>   


Cuando un usuario NFS se conecta a ONTAP se consulta la export policy para verificar el acceso del host y el root-squash. ONTAP obtiene información de uid y gid de la cabecera RPC (la cabecera RPC de NFSv4 suele contener username@iddomain para la identidad). Es por ello que es necesaria una búsqueda (local o remota) del nombre de usuario que corresponde a ese UID.

<p align="center">
  <a href="/images/posts/NAS_Multiprotocolo_02.jpg" target="_blank"><img src="/images/posts/NAS_Multiprotocolo_02.jpg"></a>
</p>   

Cuando un usuario CIFS/SMB se conecta, ONTAP obtiene directamente el username de la trama CIFS/SMB.



## Enlaces de interés

En <a href="https://docs.netapp.com/us-en/ontap/nfs-admin/commands-manage-local-unix-users-reference.html" target="_blank">este enlace</a> se puede obtener más información sobre los usuarios y grupos locales de UNIX en ONTAP.


En <a href="https://docs.netapp.com/us-en/ontap/smb-admin/local-users-groups-concepts-concept.html" target="_blank">este otro enlace</a> se puede obtener más información sobre los usuarios y grupos locales de SMB/CIFS en ONTAP.

Información sobre cómo crear mapeos explícitos a través del CLI: <a href="https://docs.netapp.com/us-en/ontap/smb-admin/create-name-mapping-task.html" target="_blank">https://docs.netapp.com/us-en/ontap/smb-admin/create-name-mapping-task.html</a>

Información sobre cómo crear mapeos explícitos a través del GUI (System Manager): <a href="https://docs.netapp.com/us-en/ontap-sm-classic/online-help-96-97/reference_name_mapping_window.html#name-mappings" target="_blank">https://docs.netapp.com/us-en/ontap-sm-classic/online-help-96-97/reference_name_mapping_window.html#name-mappings</a>

Información sobre cómo configurar el usuario anónimo por defecto para el mapeo si los mapeos fallan: <a href="https://docs.netapp.com/us-en/ontap/smb-admin/configure-default-user-task.html" target="_blank">https://docs.netapp.com/us-en/ontap/smb-admin/configure-default-user-task.html</a>

