---
layout: post
type: posts
title: NAS Multiprotocolo con ONTAP (Parte 2)
date: '2021-04-30T16:03:42.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
En este post, continuación del anterior, vamos a ver algún ejemplo práctico sencillo de acceso NAS multiprotocolo. Es posible obtener más información y detalles sobre el funcionamiento del acceso multiprotocolo NAS en ONTAP, así como las mejores prácticas al respecto, en el Technical Report <a href="https://www.netapp.com/pdf.html?item=/media/27436-tr-4887.pdf" target="_blank">TR-4887</a> que NetApp tiene publicado, y que es excelente.  
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2021%2F04%2F30%2FONTAP-NAS_Multiprotocolo_parte2.html" target="_blank">here</a>.

---   

Las recomendaciones más generales para implementar una solución NAS con acceso multiprotocolo en ONTAP consisten en:
- Elegir uno u otro estilo de seguridad (UNIX o NTFS) según qué tipo de usuario (Windows o UNIX) necesite poder cambiar permisos, así como  en función de la granularidad en el control de acceso y permisos que se necesite. Una opción muy común consiste en utilizar el estilo de seguridad NTFS y configurar el mapeo de usuarios de UNIX a Windows, ya que las ACLs de Windows permiten un control bastante granular que los permisos de tipo SysV y, además, se gestionan mediante GUI.
- Aunque se pueden realizar mapeos explícitos para tener reglas de mapeo para usuarios que no tienen el mismo nombre UNIX que Windows, lo más sencillo es que los nombres de ambos mundos tengan una equivalencia uno a uno.
- La manera mas simple de gestionar el mapeo de usuarios es utilizar el modo implícito y utilizar un servicio de nombres de tipo LDAP; de hecho puede ser una elección lógica utilizar un Directorio Activo de Windows para alojar identidades UNIX también; de esta manera el usuario DOMINIO\usuario se mapea a usuario en UNIX y viceversa.

Es importante reseñar que el modo “mixto” significa que el fichero puede tener una ACL Windows o un permiso UNIX en un determinado momento, pero siempre es o uno u otro. El modo “mixto” solo debe de utilizarse cuando el entorno requiera la capacidad cambiar permisos tanto por parte de clientes NFS como de clientes SMB y esto puede resultar particularmente peligroso en algunas situaciones. Hay que tener en cuenta que cuando se produzca el cambio de estilo de seguridad, la ACL anterior se pierde o se resetea (ejemplo: se cambia de NTFS a UNIX y luego de vuelta a NTFS, pero las entradas adicionales no estándar que se habían incluido en la ACL original de NTFS se han perdido).

## Ejemplo: acceso de clientes UNIX a recursos con Estilo de Seguridad NTFS

Se parte de un volumen con Estilo de Seguridad NTFS (ACLs de Windows) y gestión de permisos bajo Directorio Activo. El volumen tiene creado un share CIFS/SMB con el mismo nombre (vol_win) y, adicionalmente, el volumen también se exporta por NFS, según se observa en la siguiente imagen:

<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p2_01.jpg">
</p>   

```pascal
::> vol show -vserver svm_raul_02 -volume vol_win -fields security-style,junction-path
vserver     volume  security-style junction-path
----------- ------- -------------- -------------
svm_raul_02 vol_win ntfs           /vol_win
```

Como se puede observar, la ACL a nivel de carpeta compartida (share) tiene "Everyone/Full Control":

```pascal
::> vserver cifs share show -vserver svm_raul_02 -share-name vol_win -fields acl,path
vserver     share-name path     acl
----------- ---------- -------- -------------------------
svm_raul_02 vol_win    /vol_win "Everyone / Full Control"
```

<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p2_03.jpg">
</p>   

Sin embargo los permisos a nivel de ACL NTFS solo permiten el control total al grupo local DEMOLAB\desarrollo:

```pascal
::> vserver security file-directory show -vserver svm_raul_02 -path /vol_win

                Vserver: svm_raul_02
              File Path: /vol_win
      File Inode Number: 64
         Security Style: ntfs
        Effective Style: ntfs
. . .
                   ACLs: NTFS Security Descriptor
                         Control:0x9504
                         Owner:DEMOLAB\desarrollo
                         Group:BUILTIN\Administrators
                         DACL - ACEs
                           ALLOW-DEMOLAB\desarrollo-0x1f01ff-OI|CI                           
```
<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p2_02.jpg">
</p>   

Por otra parte, se quiere permitir el acceso a la información de este volumen a un **usuario local** de un servidor linux, accediendo a través de un punto de montaje NFS. Este usuario local del servidor linux es:

```pascal
[root@muerdecables ~]# id unix-dev1
uid=3001(unix-dev1) gid=3010(desarrollo) grupos=3010(desarrollo)
```

Según lo expuesto en el post anterior, para facilitar el acceso multiprotocolo en esta situación, será necesario:

#### (1) Crear un usuario/grupo local unix en el SVM de ONTAP

Para ello se mantiene el mismo UID del usuario local en el servidor linux. Si se emplea la línea de comando de ONTAP entonces:

```pascal
::> vserver services unix-group create -vserver svm_raul_02 -name desarrollo -id 3010

::> vserver services unix-user create -vserver svm_raul_02 -user unix-dev1 -id 3001 -primary-gid 3010
```
Alternativamente, se puede utilizar el GUI de ONTAP (System Manager); la correspondiente opción se encuentra dentro de las propiedades del SVM:
<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p2_04.jpg">
</p>   


#### (2) Crear un usuario en Directorio Activo contra el que mapear el usuario de unix

También es posible reutilizar un usuario existente con otro nombre, configurando el mapeo explícito correspondiente en ONTAP.
En este ejemplo se crea un usuario nuevo con el mismo nombre que el usuario de unix, y se le hace miembro del grupo DEMOLAB\desarrollo para que tenga los permisos de acceso necesarios:

<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p2_05.jpg">
</p>   

#### (3) Montar el volumen por NFS y verificar acceso y permisos

En este ejemplo se monta el volumen en un punto de montaje temporal utilizando la versión 3 de NFS. Para ello:

```pascal
[root@muerdecables ~]# mkdir /mnt/vol_win

[root@muerdecables ~]# mount -o nfsvers=3 svm_raul_02:/vol_win /mnt/vol_win
```
Llegados a este punto, accedemos al punto de montaje con el usuario "unix-dev" (con el usuario "root" local fallará; la explicación más adelante):

```pascal
[root@muerdecables ~]# su - unix-dev1

[root@muerdecables ~]# cd /mnt/vol_win; ls -lh
total 867M
drwx------ 2 unix-dev1 desarrollo 4.0K Jan 19 08:32 carpeta1
drwx------ 2 raul      hadoop     4.0K Jan 19 08:12 carpeta2
-rwx------ 1 raul      hadoop     818M Jan 18 22:03 Data8317.csv
-rwx------ 1 unix-dev1 desarrollo  11M Jan 19 08:08 dataset1.json
-rwx------ 1 unix-dev1 desarrollo    0 Jan 18 21:59 enterprise-survey-2018.csv
-rwx------ 1 raul      hadoop     4.2M Jan 19 08:10 ent_survey-2018.csv
-rwx------ 1 raul      hadoop      12M Jan 19 08:11 price-indexes_03-20.csv
-rwx------ 1 unix-dev1 desarrollo   34 Jan 19 07:58 prueba.txt
-rwx------ 1 unix-dev1 desarrollo  20M Jan 19 08:09 trade-indexes_03-20.csv
```

Por otro lado, acceder desde un cliente Windows al share y crear un fichero de prueba:

<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p2_06.jpg">
</p>   

Verificar desde el cliente linux:

```pascal
[unix-dev1@muerdecables vol_win]$ ls -lh
total 867M
drwx------ 2 unix-dev1 desarrollo 4.0K Jan 19 08:32 carpeta1
drwx------ 2 raul      hadoop     4.0K Jan 19 08:12 carpeta2
-rwx------ 1 raul      hadoop     818M Jan 18 22:03 Data8317.csv
-rwx------ 1 unix-dev1 desarrollo  11M Jan 19 08:08 dataset1.json
-rwx------ 1 unix-dev1 desarrollo    0 Jan 18 21:59 enterprise-survey-2018.csv
-rwx------ 1 raul      hadoop     4.2M Jan 19 08:10 ent_survey-2018.csv
-rwx------ 1 raul      hadoop      12M Jan 19 08:11 price-indexes_03-20.csv
-rwx------ 1 raul      hadoop        0 Jan 19 08:56 prueba_desde_windows.txt
-rwx------ 1 unix-dev1 desarrollo   34 Jan 19 07:58 prueba.txt
-rwx------ 1 unix-dev1 desarrollo  20M Jan 19 08:09 trade-indexes_03-20.csv
```

Comprobamos que, desde el servidor linux, el usuario unix-dev1 puede crear nuevos ficheros e incluso editar el creado desde el equipo Windows (no olvidar que los permisos a nivel de ACL NTFS permiten el control total para el grupo "desarrollo" al que pertenece el usuario DEMOLAB\unix-dev, que es el que ONTAP mapea implícitamente).

```pascal
[unix-dev1@muerdecables vol_win]$ touch prueba_desde_linux.txt
[unix-dev1@muerdecables vol_win]$ echo 'HOLA desde linux con el usuario unix-dev1' >> prueba_desde_windows.txt
[unix-dev1@muerdecables vol_win]$ tail prueba_desde_windows.txt
HOLA desde linux con el usuario unix-dev1

[unix-dev1@muerdecables vol_win]$ ls -lh
total 867M
drwx------ 2 unix-dev1 desarrollo 4.0K Jan 19 08:32 carpeta1
drwx------ 2 raul      hadoop     4.0K Jan 19 08:12 carpeta2
-rwx------ 1 raul      hadoop     818M Jan 18 22:03 Data8317.csv
-rwx------ 1 unix-dev1 desarrollo  11M Jan 19 08:08 dataset1.json
-rwx------ 1 unix-dev1 desarrollo    0 Jan 18 21:59 enterprise-survey-2018.csv
-rwx------ 1 raul      hadoop     4.2M Jan 19 08:10 ent_survey-2018.csv
-rwx------ 1 raul      hadoop      12M Jan 19 08:11 price-indexes_03-20.csv
-rwx------ 1 unix-dev1 desarrollo    0 Jan 19 09:03 prueba_desde_linux.txt
-rwx------ 1 raul      hadoop       42 Jan 19 09:04 prueba_desde_windows.txt
-rwx------ 1 unix-dev1 desarrollo   34 Jan 19 07:58 prueba.txt
-rwx------ 1 unix-dev1 desarrollo  20M Jan 19 08:09 trade-indexes_03-20.csv
```
   
   
## Algunos comandos útiles

Para comprobar ACLs y permisos en un fichero, directorio, qtress o volumen, desde el CLI de ONTAP:

```pascal
::> vserver security file-directory show -vserver svm_raul_02 -path /vol_win/carpeta1

                Vserver: svm_raul_02
              File Path: /vol_win/carpeta1
      File Inode Number: 96
         Security Style: ntfs
        Effective Style: ntfs
         DOS Attributes: 10
 DOS Attributes in Text: ----D---
Expanded Dos Attributes: -
           UNIX User Id: 3001
          UNIX Group Id: 3010
         UNIX Mode Bits: 777
 UNIX Mode Bits in Text: rwxrwxrwx
                   ACLs: NTFS Security Descriptor
                         Control:0x8404
                         Owner:DEMOLAB\unix-dev1
                         Group:DEMOLAB\desarrollo
                         DACL - ACEs
                           ALLOW-DEMOLAB\desarrollo-0x1f01ff-OI|CI (Inherited)
```

Para comprobar los permisos efectivos de un usuario sobre un fichero, directorio, qtree, desde el CLI de ONTAP:

```pascal
::> file-directory show-effective-permissions -vserver svm_raul_02 -unix-user-name unix-dev1 -path /vol_win
  (vserver security file-directory show-effective-permissions)

                        Vserver: svm_raul_02
              Windows User Name: DEMOLAB\unix-dev1
                 Unix User Name: unix-dev1
                      File Path: /vol_win
                CIFS Share Path: -
          Effective Permissions:
                                 Effective File or Directory Permission: 0x1f01ff
                                 	Read
                                 	Write
                                 	Append
                                 	Read EA
                                 	Write EA
                                 	Execute
                                 	Delete Child
                                 	Read Attributes
                                 	Write Attributes
                                 	Delete
                                 	Read Control
                                 	Write DAC
                                 	Write Owner
                                 	Synchronize
```

Es posible comprobar las sesiones SMB/CIFS abiertas y los usuarios que las han abierto con este comando:

```pascal
::> vserver cifs session show -fields windows-user,unix-user -vserver svm_raul_02
node            vserver      windows-user          unix-user
--------------- -----------  --------------------- ---------
clusterlabDR-01 svm_raul_02  DEMOLAB\Administrator root
clusterlabDR-02 svm_raul_02  DEMOLAB\raul          raul
```

Análogamente, para mostrar los clientes NFS conectados, se emplea este comando:

```pascal
::> vserver nfs connected-clients show -vserver svm_raul_02

     Node: clusterlabDR-01
  Vserver: svm_raul_02
  Data-Ip: 10.67.217.29
Client-Ip      Protocol Volume    Policy   Idle-Time    Local-Reqs Remote-Reqs
-------------- -------- --------- -------- ------------ ---------- ----------
10.67.217.120  nfs3     vol_win   default  35m 17s      0          56437

     Node: clusterlabDR-02
  Vserver: svm_raul_02
  Data-Ip: 10.67.217.30
Client-Ip      Protocol Volume    Policy   Idle-Time    Local-Reqs Remote-Reqs
-------------- -------- --------- -------- ------------ ---------- ----------
10.67.217.127  nfs3     vol_win   default  26m 7s       35673      0

```

Es posible conocer a qué usuario va a realizar ONTAP el mapeo y qué credenciales tendrá con el siguiente comando:

```pascal
::> set adv -conf off; vserver services access-check authentication show-creds -vserver svm_raul_02 -unix-user-name unix-dev1 -list-id true; set adm

 UNIX UID: 3001 (unix-dev1) <> Windows User: S-1-5-21-3852288448-55268370-1133 (DEMOLAB\unix-dev1 (Windows Domain User))

 GID: 3010 (desarrollo)
 Supplementary GIDs:
  3010  (desarrollo)

 Primary Group SID: S-1-5-21-3852288448-136526790-1131   DEMOLAB\desarrollo (Windows Domain group)

 Windows Membership:
  S-1-5-21-3852288448-55268370-1131   DEMOLAB\desarrollo (Windows Domain group)
  S-1-5-21-3852288448-55268370-513   DEMOLAB\Domain Users (Windows Domain group)
  S-1-5-32-545   BUILTIN\Users (Windows Alias)
 User is also a member of Everyone, Authenticated Users, and Network Users

 Privileges (0x2080):
  SeChangeNotifyPrivilege
```


### Por defecto, el usuario root de UNIX no puede acceder a un volumen NTFS
Cuando se configura el acceso multiprotocolo en ONTAP desde un recurso con Estilo de Seguridad NTFS a través de NFS, es necesario decidir cómo tratar el acceso del usuario root. Hay dos opciones: (1) mapear el usuario root a un usuario Windows convencional y gestionar su acceso según las ACLs NTFS que apliquen a ese usuario Windows, y (2) indicarle a ONTAP que ignore las ACLs NTFS y que le permita acceso total al usuario root. 

Si no se realiza ninguna configuración al efecto, se denegará el acceso al usuario root. Continuando con nuestro anterior ejemplo, se tendrá lo siguiente:

```pascal
[root@muerdecables ~]# ls -al /mnt/vol_win/
ls: no se puede abrir el directorio /mnt/vol_win/: Permiso denegado
[root@muerdecables ~]# cd /mnt/vol_win/
-bash: cd: /mnt/vol_win/: Permiso denegado
```

Si se desea que ONTAP ignore las ACLs NTFS y que  permita acceso total al usuario root, hay que configurar el SVM con la siguiente opción:

```pascal
::> vserver nfs modify -vserver svm_raul_02 -ignore-nt-acl-for-root enabled
```
Y el usuario root de unix/linux tendrá acceso.   


### Algunos comandos UNIX generan un warning sobre un fichero de swap existente
Hay algunas utilidades del mundo UNIX (vi, vim, emacs, zip, gzip, compress, etc.) que utilizan ficheros temporales o de intercambio para su operación. Durante la creación de este tipo de ficheros, el código de la utilidad en cuestión verifica atributos e intenta establecer permisos para el fichero de intercambio.
Como se ha mencionado en el anterior post de este blog, un cliente NFS no puede cambiar permisos de un recurso con Estilo de Seguridad NTFS (solo un cliente Windows puede) y por tanto se genera este error.

Para evitar esta molestia es posible configurar la siguiente opción para que ONTAP no genere errores al cliente NFS/UNIX cuando este intente cambiar permisos NTFS:


```pascal
::> set adv -conf off; vserver nfs modify -vserver svm_raul_02 -ntfs-unix-security-ops ignore; set adm
```


## Enlaces de interés

Enlace a la KB de NetApp: <a href="https://kb.netapp.com/Advice_and_Troubleshooting/Data_Storage_Software/ONTAP_OS/Understanding_name-mapping_in_a_multiprotocol_environment" target="_blank">*Understanding name-mapping in a multiprotocol environment*</a>.

Enlace a la KB de NetApp: <a href="https://kb.netapp.com/Advice_and_Troubleshooting/Data_Storage_Software/ONTAP_OS/How_to_create_and_understand_vserver_name-mapping_rules_in_clustered_Data_ONTAP" target="_blank">*How to create and understand vserver name-mapping rules in clustered Data ONTAP*</a>.


