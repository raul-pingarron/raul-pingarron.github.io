---
layout: post
type: posts
title: NAS Multiprotocolo con ONTAP (Parte 3)
date: '2021-05-07T18:21:12.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
Este post, el último de la serie dedicado al acceso NAS multiprotocolo en ONTAP, trata el uso de Directorio Activo como LDAP para proporcionar un servicio de identidades centralizado tanto para el mundo UNIX/Linux como para el mundo Windows. Como ya se mencionó en anteriores entradas, en la mayoría de las ocasiones suele ser más recomendable utilizar un servicio de identidades externo para la gestión de usuarios y configurar ONTAP como cliente suyo de manera que no haya que gestionar usuarios locales, ni en ONTAP, ni en los clientes NFS UNIX/Linux.
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2021%2F05%2F07%2FONTAP-NAS_Multiprotocolo_parte3.html" target="_blank">here</a>.

---   

Microsoft implementó LDAPv3 como almacén de directorio de identidades en las versiones de Directorio Activo de Windows 2000/2003. Ya que la implementación de LDAP de Microsoft está basada en estándares, es posible utilizar los servicios de LDAP que ofrece el Directorio Activo para almacenar información de usuarios y grupos de UNIX. De esta manera es posible unificar el servicio de directorio y el almacén de identidades tanto para clientes Windows como UNIX. A partir de Windows 2008 R2, el Directorio Activo incorporaba, además, las extensiones de esquema UNIX de forma predeterminada, por lo que no es necesario realizar ninguna modificación adicional en el esquema como podría ocurrir con las versiones antiguas.
El LDAP del Directorio activo seguirá respondiedo por los puertos estándar, esto es, por el TCP 389 o TCP 636 (seguro), y adicionalmente también responderá al tráfico LDAP por el puerto TCP 3268 o 3269 que son los del servicio de Global Catalog y Secure Global Catalog respectivamente.


## Configuración de ONTAP como cliente LDAP del Directorio Activo

Se puede obtener información más detallada sobre la configuración de LDAP en ONTAP en <a href="https://www.netapp.com/us/media/tr-4835.pdf" target="_blank">este documento</a>.


### Paso 1: Identificar el esquema LDAP a utilizar

Antes de configurar ONTAP como cliente de LDAP es necesario identificar los nombres de los atributos que emplea el servicio de LDAP para identificar a los usuarios. Esta correlación se refleja en una plantilla de esquema que utilizará ONTAP, de manera que si se utiliza un esquema incorrecto las consultas que realice ONTAP al servidor LDAP fallarán.   

Por defecto ONTAP tiene varias plantillas de esquema y lo más práctico es copiar el esquema a partir del MS-AD-BIS predefinido (que es de solo lectura) y modificarlo según sea necesario. Esta plantilla utiliza las siguientes correlaciones:

```pascal
::> vserver services name-service ldap client schema show -schema MS-AD-BIS

                                           Vserver: clusterlabDR
                                   Schema Template: MS-AD-BIS
                                           Comment: Schema based on AD IDMU
                RFC 2307 posixAccount Object Class: User
                  RFC 2307 posixGroup Object Class: Group
                 RFC 2307 nisNetgroup Object Class: nisNetgroup
                            RFC 2307 uid Attribute: uid
                      RFC 2307 uidNumber Attribute: uidNumber
                      RFC 2307 gidNumber Attribute: gidNumber
                RFC 2307 cn (for Groups) Attribute: cn
             RFC 2307 cn (for Netgroups) Attribute: name
                   RFC 2307 userPassword Attribute: unixUserPassword
                          RFC 2307 gecos Attribute: name
                  RFC 2307 homeDirectory Attribute: unixHomeDirectory
                     RFC 2307 loginShell Attribute: loginShell
                      RFC 2307 memberUid Attribute: memberUid
              RFC 2307 memberNisNetgroup Attribute: memberNisNetgroup
              RFC 2307 nisNetgroupTriple Attribute: nisNetgroupTriple
              Enable Support for Draft RFC 2307bis: true
       RFC 2307bis groupOfUniqueNames Object Class: group
                RFC 2307bis uniqueMember Attribute: Member
Data ONTAP Name Mapping windowsToUnix Object Class: User
  Data ONTAP Name Mapping windowsAccount Attribute: sAMAccountName
   Data ONTAP Name Mapping windowsToUnix Attribute: sAMAccountName
   No Domain Prefix for windowsToUnix Name Mapping: true
                               Vserver Owns Schema: true
                   RFC 2307 nisObject Object Class: nisObject
                     RFC 2307 nisMapName Attribute: nisMapName
                    RFC 2307 nisMapEntry Attribute: nisMapEntry
```
Será necesario verificar en el GUI/MMC de "Active Directory Users and Computers", que los usuarios y grupos creados tengan definidos los atributos POSIX de UNIX, según la RFC 2307. Esto se puede verificar a través de la pestaña de edición de atributos del usuario o grupo, anotando los atributos empleados. Generalmente se utilizan los campos  `uid` o `name` o `sAMAccountName` para el nombre del usuario, el campo `uidNumber` para el ID del usuario UNIX, el `gidNumber` para el ID del grupo primario de UNIX, y adicionalmente los campos `loginShell`, `unixHomeDirectory`, etc.

Estos serían algunos de los atributos POSIX de UNIX definidos para el usuario "raul" del Directorio Activo:
<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p3_01.png">
</p>   

Estos serían algunos de los atributos POSIX de UNIX definidos para el grupo "hadoop" del Directorio Activo:
<p align="center">
  <img src="/images/posts/NAS_Multiprotocolo_p3_02.png">
</p>   


Para copiarnos la plantilla de esquema de tipo MS-AD-BIS a un nuevo esquema modificable:


```pascal
::> vserver services name-service ldap client schema copy -schema MS-AD-BIS -new-schema-name DEMOLAB-AD
```

Para modificar la correlación de campos en el esquema a utilizar por el cliente LDAP de ONTAP:

```pascal
::> vserver services name-service ldap client schema modify -schema DEMOLAB-AD -uid-attribute sAMAccountName

::> vserver services name-service ldap client schema show -schema DEMOLAB-AD
                                          Vserver: clusterlabDR
                                   Schema Template: DEMOLAB-AD
                                           Comment:
                RFC 2307 posixAccount Object Class: User
                  RFC 2307 posixGroup Object Class: Group
                 RFC 2307 nisNetgroup Object Class: nisNetgroup
                            RFC 2307 uid Attribute: sAMAccountName
                      RFC 2307 uidNumber Attribute: uidNumber
                      RFC 2307 gidNumber Attribute: gidNumber
                RFC 2307 cn (for Groups) Attribute: cn
             RFC 2307 cn (for Netgroups) Attribute: name
                   RFC 2307 userPassword Attribute: unixUserPassword
                          RFC 2307 gecos Attribute: name
                  RFC 2307 homeDirectory Attribute: unixHomeDirectory
                     RFC 2307 loginShell Attribute: loginShell
                      RFC 2307 memberUid Attribute: memberUid
              RFC 2307 memberNisNetgroup Attribute: memberNisNetgroup
              RFC 2307 nisNetgroupTriple Attribute: nisNetgroupTriple
              Enable Support for Draft RFC 2307bis: true
       RFC 2307bis groupOfUniqueNames Object Class: group
                RFC 2307bis uniqueMember Attribute: Member
Data ONTAP Name Mapping windowsToUnix Object Class: User
  Data ONTAP Name Mapping windowsAccount Attribute: sAMAccountName
   Data ONTAP Name Mapping windowsToUnix Attribute: sAMAccountName
   No Domain Prefix for windowsToUnix Name Mapping: true
                               Vserver Owns Schema: true
 Maximum groups supported when RFC 2307bis enabled: 256
                   RFC 2307 nisObject Object Class: nisObject
                     RFC 2307 nisMapName Attribute: nisMapName
                    RFC 2307 nisMapEntry Attribute: nisMapEntry

```

Para comprobar que se está utilizando el esquema correcto es posible realizar un volcado de los atributos de un usuario del LDAP del Directorio Activo con el siguiente comando de PowerShell:

```powerShell
PS> Get-ADUser -Identity raul -properties *
```
   
   
### Paso 2: Crear una configuración de cliente LDAP
Esta será la configuración que utilizará ONTAP como cliente LDAP para conectarse y poder consultar al servicio de LDAP del Directorio Activo. La configuración se apoyará en el esquema definido y configurado en el paso anterior.
Esta configuración puede asignarse a un SVM en particular, o también puede asignarse al clúster para que esté disponible para todos los SVMs.   
Si se va a crear una configuración de cliente LDAP para ONTAP donde se utilice el Directorio Activo, es preferible especificar la opción `-ad-domain` ya que permite encontrar el DC más cercano y utilizar los propios registros DNS SRV del AD para descubrir los servidores.


Ejemplo:


```pascal
::> vserver services ldap client create -client-config DEMOLAB_LDAP -ad-domain demolab.es -schema DEMOLAB-AD -port 389 -query-timeout 3 -min-bind-level sasl -base-dn DC=demolab,DC=es -bind-as-cifs-server true 

::> ldap client show -client-config DEMOLAB_LDAP

                                  Vserver: clusterlabDR
                Client Configuration Name: DEMOLAB_LDAP
                         LDAP Server List: -
            (DEPRECATED)-LDAP Server List: -
                  Active Directory Domain: demolab.es
       Preferred Active Directory Servers: -
Bind Using the Vserver's CIFS Credentials: true
                          Schema Template: DEMOLAB-AD
                         LDAP Server Port: 389
                      Query Timeout (sec): 3
        Minimum Bind Authentication Level: sasl
                           Bind DN (User): -
                                  Base DN: DC=demolab,DC=es
                        Base Search Scope: subtree
                                  User DN: -
                        User Search Scope: subtree
                                 Group DN: -
                       Group Search Scope: subtree
                              Netgroup DN: -
                    Netgroup Search Scope: subtree
               Vserver Owns Configuration: true
      Use start-tls Over LDAP Connections: false
           Enable Netgroup-By-Host Lookup: false
                      Netgroup-By-Host DN: -
                   Netgroup-By-Host Scope: subtree
                  Client Session Security: none
                    LDAP Referral Chasing: false
                  Group Membership Filter:
                         Is LDAPS Enabled: false
                      Try Channel Binding: true

```

### Paso 3: Aplicar una configuración de cliente LDAP y habilitar el cliente LDAP en el SVM
Para ello, utilizando la configuración anteriormente creada, se ejecuta el siguiente comando

```pascal
::> ldap create -vserver svm_raul_02 -client-config DEMOLAB_LDAP

Warning: "LDAP" is not present as a name service source in any of the name service databases, however, a valid LDAP configuration was found for Vserver "svm_raul_02". Either configure "LDAP" as a name service source using the "vserver services name-service ns-switch" command or remove the "LDAP" configuration from the Vserver "svm_raul_02" using the "vserver services name-service ldap delete" command.

::> ldap show -vserver svm_raul_02

                         Vserver: svm_raul_02
       LDAP Client Configuration: DEMOLAB_LDAP

```

Y, por último, será necesario modificar el orden de resolución (ns-switch) del SVM para que inicie la consulta contra el LDAP en primera instancia. 
Para ello se utiliza el siguiente comando:

```pascal
::> vserver services name-service ns-switch modify -vserver svm_raul_02 -database passwd,group,netgroup,namemap -sources ldap,files
```



### Verificaciones finales
Para verificar si la configuración establecida en ONTAP para el LDAP es funcional se pueden utilizar los siguientes comandos:   


```pascal
::> ldap check -vserver svm_raul_02

                  Vserver: svm_raul_02
Client Configuration Name: DEMOLAB_LDAP
              LDAP Status: up
      LDAP Status Details: Successfully connected to LDAP server "10.67.216.2".
   LDAP DN Status Details: All the configured DNs are available.
```


```pascal
::> set diag -conf off; getxxbyyy gethostbyname -node  clusterlabDR-02 -vserver svm_raul_02 -hostname muerdecables.demolab.es; set adm

  (vserver services name-service getxxbyyy gethostbyname)
Host name: muerdecables.demolab.es
Canonical name: muerdecables.demolab.es
IPv4: 10.67.217.120
```

```pascal
::> set diag -conf off; diag secd connections test -node clusterlabDR-01 -vserver svm_raul_02; set adm

 NETLOGON Connection
Service Configured: true
Connection test Result: Successful

 LSA Connection
Service Configured: true
Connection test Result: Successful

 AD LDAP Connection
Service Configured: true
Connection test Result: Successful

 LDAP Connection
Service Configured: true
Connection test Result: Successful

Connection Manager test completed
```


```pascal
::> set adv -conf off; vserver services access-check authentication show-creds -node clusterlabDR-01 -vserver svm_raul_02 -unix-user-name raul; set adm

 UNIX UID: raul <> Windows User: DEMOLAB\raul (Windows Domain User)

 GID: hadoop
 Supplementary GIDs:
  hadoop
  root

 Primary Group SID: DEMOLAB\desarrollo (Windows Domain group)

 Windows Membership:
  DEMOLAB\Domain Users (Windows Domain group)
  DEMOLAB\Usuarios (Windows Domain group)
  DEMOLAB\hadoop (Windows Domain group)
  DEMOLAB\desarrollo (Windows Domain group)
  Service asserted identity (Windows Well known group)
  BUILTIN\Users (Windows Alias)
 User is also a member of Everyone, Authenticated Users, and Network Users

 Privileges (0x2080):
  SeChangeNotifyPrivilege
```


```pascal
::> set adv -conf off; getxxbyyy getpwbyname -node clusterlabDR-01 -vserver svm_raul_02 -username raul -show-source true -use-cache false; set adm

  (vserver services name-service getxxbyyy getpwbyname)
Source used for lookup: LDAP
pw_name: raul
pw_passwd:
pw_uid: 9999
pw_gid: 2001
pw_gecos:
pw_dir: /home/raul
pw_shell: /bin/bash
```

```pascal
::> set diag -conf off; diag secd name-mapping show -node clusterlabDR-01 -vserver svm_raul_02 -direction unix-win -name raul; set adm


'raul' maps to 'DEMOLAB\raul'
```
   


## ANEXO: Configurar clientes Linux contra el LDAP del AD
Para configurar clientes Linux de manera que utilicen el Directorio Activo como LDAP se utiliza, generalmente, el SSSD. En el caso de clientes RHEL\CentOS, la integración con AD es directa si se utilizan dominios o bosques con nivel funcional desde Windows Server 2008 a Windows Server 2016. 

**Importante**: SSSD permite la integración con Directorio Activo de dos maneras:   
 - (1) mapeando automáticamente IDs POSIX (id mapping): esto es, SSSD utiliza el SID del usuario del AD para generar artificialmente su ID POSIX (UID/GID).   
 - (2) utilizando los atributos POSIX definidos en el AD.

Si hay clientes que utilizan otro SW distinto a SSSD en el entorno, la recomendación es utilizar los atributos POSIX definidos explícitamente en el AD; este será el caso del cliente LDAP de ONTAP que no soporta el primer método.

Por tanto en el caso de ONTAP se utilizará la segunda aproximación y, para cada usuario, se crearán y definirán los atributos POSIX de UNIX mínimos según la RFC-2307 ("uid", "uidNumber", "gidNumber", "loginShell", "unixHomeDirectory", etc) y se deshabilitará el ID mapping en la configuración del servicio SSSD de los clientes.


Ejemplo para RHEL8/CentOS8:

```pascal
# dnf install samba-common-tools realmd oddjob oddjob-mkhomedir sssd adcli krb5-workstation
```


```pascal
# realm discover -v demolab.es

 * Resolving: _ldap._tcp.demolab.es
 * Performing LDAP DSE lookup on: 10.67.216.2
 * Successfully discovered: demolab.es
demolab.es
  type: kerberos
  realm-name: DEMOLAB.ES
  domain-name: demolab.es
  configured: kerberos-member
  server-software: active-directory
  client-software: sssd
  required-package: oddjob
  required-package: oddjob-mkhomedir
  required-package: sssd
  required-package: adcli
  required-package: samba-common-tools
  login-formats: %U
  login-policy: allow-realm-logins
```

```pascal
# realm join -v --automatic-id-mapping=no demolab.es
Password for Administrator:
```

```pascal
# realm list

demolab.es
  type: kerberos
  realm-name: DEMOLAB.ES
  domain-name: demolab.es
  configured: kerberos-member
  server-software: active-directory
  client-software: sssd
  required-package: oddjob
  required-package: oddjob-mkhomedir
  required-package: sssd
  required-package: adcli
  required-package: samba-common-tools
  login-formats: %U@demolab.es
  login-policy: allow-realm-logins
```

La configuración del `/etc/sssd/sssd.conf` en este ejemplo es la siguiente:

```powerShell
[sssd]
domains = demolab.es
config_file_version = 2
services = nss, pam

[domain/demolab.es]
ad_domain = demolab.es
krb5_realm = DEMOLAB.ES
realmd_tags = manages-system joined-with-adcli
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = False
use_fully_qualified_names = False
fallback_homedir = /home/%u@%d
access_provider = ad
full_name_format = %1$
```

En este caso particular se ha configurado SSSD para que sea capaz de resolver nombres cortos del AD, de lo contrario se tendrá que utilizar siempre el formato "usuario@fqdn" o "DOMINIO\usuario" en lugar de "usuario". Esto aplica a casos donde solo haya un único dominio, sin embargo, si se tiene un entorno con varios dominios es mejor utilizar el formato largo para evitar conflictos en el caso de que exista el mismo nombre de usuario en varios dominios.



#### Comprobaciones finales
```pascal
# id raul
uid=9999(raul) gid=2001(hadoop) groups=2001(hadoop),3010(desarrollo)

# id raul@demolab.es
uid=9999(raul) gid=2001(hadoop) groups=2001(hadoop),3010(desarrollo)
```


```pascal
# ldapsearch -h 10.67.216.2 -p 389 -x -b 'dc=demolab,dc=es' -s sub '(uid=raul)' -D 'DEMOLAB\Administrator' -W
Enter LDAP Password:

# extended LDIF
#
# LDAPv3
# base <dc=demolab,dc=es> with scope subtree
# filter: (uid=raul)
# requesting: ALL
#

# raul, Users, demolab.es
dn: CN=raul,CN=Users,DC=demolab,DC=es
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: raul
sn: Pingarron
description: Usuario con attrs POSIX
givenName: Raul
distinguishedName: CN=raul,CN=Users,DC=demolab,DC=es
[...]
displayName: raul
uSNCreated: 59913
memberOf: CN=hadoop,CN=Users,DC=demolab,DC=es
memberOf: CN=Usuarios,DC=demolab,DC=es
memberOf: CN=Domain Users,CN=Users,DC=demolab,DC=es
uSNChanged: 463212
name: raul
[...]
sAMAccountName: raul
sAMAccountType: 805306368
userPrincipalName: raul@demolab.es
[...]
uid: raul
uidNumber: 9999
gidNumber: 2001
unixHomeDirectory: /home/raul
loginShell: /bin/bash

# search reference
ref: ldap://demolab.es/CN=Configuration,DC=demolab,DC=es

# search result
search: 2
result: 0 Success
```