---
layout: post
type: posts
title: Protección frente ciberataques mediante air-gapping en ONTAP (Caso Práctico)
date: '2022-02-24T16:10:00.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
Este post, continuación del anterior, expone el caso de aplicación práctica mediante la implementación de una solución basada en un **air-gap lógico** para el sistema de respaldo y recuperación rápida de la información con tecnología ONTAP. De esta manera, si se sufre un ciber-ataque y éste consigue cifrar todo el contenido de los datos y, además, eliminar los snapshots del sistema primario o principal, se podrá poner remedio de manera rápida y eficaz recuperando los datos desde el sistema secundario de respaldo en el air-gap.

---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2022%2F02%2F24%2FONTAP-Ransomware_parte2.html" target="_blank">here</a>.

---   

Como vimos en el anterior post, el diagrama general a alto nivel de la estrategia completa sería el siguiente (haz clic para verla más grande):

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_01.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_01.jpg"></a>
</p>   

Como se puede observar en la imagen, se trata de un despliegue de SnapMirror en fan-out, es decir, de un mismo origen salen dos réplicas hacia dos sistemas distintos: uno para DR tradicional, que utiliza SVM-DR de SnapMirror, y otro como backup off-site inmutable e imborrable (logical Air Gap), que es el que utiliza SnapVault con SnapLock.

En este post solo vamos a tratar la configuración de esta segunda pata del fan-out, es decir, de la configuración de SnapVault con SnapLock.

## Pasos

Se asume que en el clúster de producción se tiene definida una política de snapshot que está aplicada al volumen origen (primario). Esta política tiene definidas etiquetas de snapmirror (horario, diario, semanal) para los snapshots, y serán utilizadas por SnapVault para identificar estos snapshots y replicarlos al destino.
En nuestro caso, se desea mantener un periodo de retención corto para los snapshots en el clúster de producción (primario), así que se define una retención en la política local de snapshots de 8 horarios, 7 diarios y 2 semanales. 

Por ejemplo:

```pascal
cluster-prd::> snapshot policy create -vserver svm_test -policy 8h7d2w -enabled true -schedule1 hourly -count1 8 -snapmirror-label1 horario -schedule2 daily -count2 7 -snapmirror-label2 diario -schedule3 weekly -count3 2 -snapmirror-label3 semanal

cluster-prd::> snapshot policy show -vserver svm_test -policy 8h7d2w

                  Vserver: svm_test
     Snapshot Policy Name: 8h7d2w
  Snapshot Policy Enabled: true
             Policy Owner: vserver-admin
                  Comment: -
Total Number of Schedules: 3
    Schedule               Count     Prefix                 SnapMirror Label
    ---------------------- -----     ---------------------  -------------------
    hourly                     8     hourly                 horario
    daily                      7     daily                  diario
    weekly                     2     weekly                 semanal

cluster-prd::> volume modify -vserver svm_test -volume raul_fp -snapshot-policy 8h7d2w
```
Y, por supuesto, también se asume que ya hay establecida una relación de cluster-peering y de SVM peering entre el sistema primario y el air-gap lógico (cluster-sv)

#### **(1) Inicializar el Compliance Clock**

Se pone en funcionamiento el reloj compliance (a prueba de manipulaciones) de los nodos que conforman en clúster ONTAP que se utilizará como air-gap lógico (cluster-sv), para ello:

```pascal
cluster-sv::> snaplock compliance-clock initialize -node nodo-01
cluster-sv::> snaplock compliance-clock initialize -node nodo-02

cluster-sv::> snaplock compliance-clock show
Node                ComplianceClock Time
------------------- -----------------------------------
nodo-01     Wed Feb 24 17:46:53 CET 2022 +01:00
nodo-02     Wed Feb 24 17:46:52 CET 2022 +01:00
2 entries were displayed.
```
   
   
#### **(2) Crear el volumen de destino SnapLock en el air-gap (cluster-sv)**

Como el clúster ONTAP que se va a utilizar como air-gap lógico tiene una versión 9.10.1, no es necesario crear un agregado de SnapLock dedicado para albergar el volumen de destino de SnapVault. A partir de esta versión 9.10.1, volúmenes no SnapLock y volúmenes SnapLock pueden convivir en el mismo agregado simplificando la arquitectura.
Para crear un volumen SnapLock de tipo Compliance solo hay que especificar la opción `-snaplock-type` como `compliance :

```pascal
cluster-sv::> volume create -vserver svm_SVSLC -volume raul_fp_SVSLC -aggregate aggr1_n02 -size 120g -type DP -snaplock-type compliance
```
   
   
#### **(3) Cambiar el periodo de expiración del volumen SLC**

Este paso **es importante** ya que si el destino de SnapVault es un volumen SLC, cabe recordar que el periodo de expiración por defecto de todo volumen SnapLock Compliance se fija a 30 años. Por tanto, si no se establece manualmente otro periodo de expiración antes de inicializar la relación de SnapVault, este será el periodo de retención de los snapshots en el destino de SnapVault según se mencionó en el anterior post.
La recomendación es establecer manualmente un periodo de expiración WORM para volumen SLC en destino, que sea acorde con el periodo de retención de snapshots que se necesite, **antes de inicializar la relación de SnapVault**. Para ello:

```pascal
cluster-sv::> volume snaplock modify -vserver svm_SVSLC -volume raul_fp_SVSLC -default-retention-period 31days

cluster-sv::> volume snaplock show -vserver svm_SVSLC -fields default-retention-period,type

vserver        volume        type       default-retention-period
-------------- ------------- ---------- ------------------------
svm_SVSLC      raul_fp_SVSLC compliance 31 days

```
   
#### **(4) Crear una política de SnapMirror (vault) que determine qué snapshots se replican**

En nuestro caso particular se desea mantener en el destino de SnapVault backups basados en snapshot durante un mayor periodo de retencion que en el primario. En concreto se van a retener 48 snapshots horarios (2 días), 31 diarios (un mes), 52 semanales (un año) y 24 mensuales (dos años) en el destino de SnapVault. Dado que la política de snapshots en el primario no crea snapshots con etiquetas mensuales, tendremos que crear una regla adicional en la política de SnapVault que contenga un schedule o planificación a tal efecto.
Además, como el volumen es de tipo SLC y hemos establecido un periodo de expiración de 31 días, garantizaremos que en caso de un ataque interno malintencionado en el air-gap, al menos tendremos 31 días de snapshots que no habrán podido ser borrados de ninguna manera (y, por supuesto tampoco modificados). 


```pascal
cluster-sv::> snapmirror policy create -vserver svm_SVSLC -policy Backup_SnapVault -type vault -tries 10

cluster-sv::> snapmirror policy add-rule -vserver svm_SVSLC -policy Backup_SnapVault -snapmirror-label horario -keep 48

cluster-sv::> snapmirror policy add-rule -vserver svm_SVSLC -policy Backup_SnapVault -snapmirror-label diario -keep 31

cluster-sv::> snapmirror policy add-rule -vserver svm_SVSLC -policy Backup_SnapVault -snapmirror-label semanal -keep 54

cluster-sv::> snapmirror policy add-rule -vserver svm_SVSLC -policy Backup_SnapVault -snapmirror-label mensual -keep 24 -schedule monthly
Warning: The "-schedule" parameter is not a transfer schedule and will not transfer Snapshot copies with the SnapMirror label "mensual" from the source. Specifying the "-schedule"
         parameter will enable independent scheduled Snapshot copy creation on the destination with SnapMirror label "mensual".
Do you want to continue? {y|n}: y

cluster-sv::> snapmirror policy show -vserver svm_SVSLC
Vserver Policy             Policy Number         Transfer
Name    Name               Type   Of Rules Tries Priority Comment
------- ------------------ ------ -------- ----- -------- ----------
svm_SVSLC Backup_SnapVault vault    4    10  normal  -
  SnapMirror Label: horario                            Keep:      48
                    diario                                        31
                    semanal                                       54
                    mensual                                       24
                                                 Total Keep:     157
```


#### **(5) Crear la relación de SnapMirror (vault) entre el volumen primario y el volumen destino de SnapVault con SnapLock**

Nótese que, para nuestro caso concreto, el schedule de la relación de SnapMirror (planificación de actualizaciones periódicas de la réplica en busca de cambios) coincide con la planificación de snapshots en el primario; es decir, en el volumen origen se crean snapshots cada hora, dia y semana (con sus correspondientes etiquetas de SnapMirror) y por lo tanto interesa actualizar la relación cada hora para que se replique el snapshot horario. Si el schedule de la relación tuviese actualizaciones más largas en el tiempo (por ejemplo 1 día), habría que esperar hasta esa actualización (diaria) para que se repliquen todos los snapshots horarios previos que han quedado pendientes de sincronizarse.

```pascal
cluster-sv::> snapmirror create -destination-path svm_SVSLC:raul_fp_SVSLC -source-path svm_test:raul_fp -type xdp -policy Backup_SnapVault -schedule hourly

cluster-sv::> snapmirror initialize -destination-path svm_SVSLC:raul_fp_SVSLC

cluster-sv::> snapmirror show -destination-path svm_SVSLC:raul_fp_SVSLC:*
```

Una vez que la relación esté inicializada el mecanismo funcionará sin intervención o gestión adicional.

Pasado un tiempo comprobamos los snapshots en el volumen origen (primario):

```pascal
cluster-prd::> snapshot show -vserver svm_test -volume raul_fp -fields snapmirror-label,size
vserver  volume  snapshot size    snapmirror-label
-------- ------- -------- ------- ----------------
svm_test raul_fp snap.1   11.25MB -
svm_test raul_fp snap.2   633.7MB -
svm_test raul_fp daily.2022-02-24_0010 260KB diario
svm_test raul_fp hourly.2022-02-24_1105 176KB horario
svm_test raul_fp hourly.2022-02-24_1205 184KB horario
svm_test raul_fp hourly.2022-02-24_1305 184KB horario
svm_test raul_fp hourly.2022-02-24_1405 180KB horario
svm_test raul_fp hourly.2022-02-24_1505 180KB horario
svm_test raul_fp hourly.2022-02-24_1605 188KB horario
svm_test raul_fp hourly.2022-02-24_1705 180KB horario
svm_test raul_fp hourly.2022-02-24_1805 176KB horario
svm_test raul_fp vserverdr.0.542165ac-9557-11ec-a53b-00a0b8c1e88f.2022-02-24_173000 160KB sm_created
12 entries were displayed.
```

Y comprobamos los snapshots en el volumen destino de SnapVault con SnapLock en el air-gap lógico:


```pascal
cluster-sv::> snapshot show -vserver svm_SVSLC -volume raul_fp_SVSLC
                                                                 ---Blocks---
Vserver  Volume   Snapshot                                  Size Total% Used%
-------- -------- ------------------------------------- -------- ------ -----
svm_SVSLC raul_fp_SVSLC
                  hourly.2022-02-23_2005                   212KB     0%    0%
                  hourly.2022-02-23_2105                   196KB     0%    0%
                  hourly.2022-02-23_2205                   208KB     0%    0%
                  hourly.2022-02-23_2305                   212KB     0%    0%
                  hourly.2022-02-24_0005                   204KB     0%    0%
                  daily.2022-02-24_0010                    196KB     0%    0%
                  hourly.2022-02-24_0105                   196KB     0%    0%
                  hourly.2022-02-24_0205                   196KB     0%    0%
                  hourly.2022-02-24_0305                   196KB     0%    0%
                  hourly.2022-02-24_0405                   196KB     0%    0%
                  hourly.2022-02-24_0505                   196KB     0%    0%
                  hourly.2022-02-24_0605                   196KB     0%    0%
                  hourly.2022-02-24_0705                   204KB     0%    0%
                  hourly.2022-02-24_0805                   204KB     0%    0%
                  hourly.2022-02-24_0905                   196KB     0%    0%
                  hourly.2022-02-24_1005                   196KB     0%    0%
                  hourly.2022-02-24_1105                   196KB     0%    0%
                  hourly.2022-02-24_1205                   196KB     0%    0%
                  hourly.2022-02-24_1305                   196KB     0%    0%
                  hourly.2022-02-24_1405                   196KB     0%    0%
                  hourly.2022-02-24_1505                   204KB     0%    0%
                  hourly.2022-02-24_1605                   212KB     0%    0%
                  hourly.2022-02-24_1705                   196KB     0%    0%
                  hourly.2022-02-24_1805                   144KB     0%    0%
24 entries were displayed.
```

Así podremos comprobar que las retenciones funcionan.

Y, por último, comprobamos que, aún siendo administradores con todos los privilegios sobre el air-gap, no podemos borrar manualmente los snapshots del destino de SnapVault (al menos no hasta que haya expirado su perido de retención WORM de SnapLock):

```pascal
clusterlabDR::*> snapshot delete -vserver svm_raul_SVSLC -volume raul_fp_SVSLC -snapshot * -force

Error: command failed on vserver "svm_raul_SVSLC" volume "raul_fp_SVSLC" snapshot "hourly.2022-02-23_2005": Failed to delete snapshot "hourly.2022-02-23_2005" of volume "raul_fp_SVSLC" on Vserver
       "svm_raul_SVSLC". Reason: Illegal operation on Snapshot locked by SnapLock.

Warning: Do you want to continue running this command? {y|n}: y

Error: command failed on vserver "svm_raul_SVSLC" volume "raul_fp_SVSLC" snapshot "hourly.2022-02-23_2105": Failed to delete snapshot "hourly.2022-02-23_2105" of volume "raul_fp_SVSLC" on Vserver
       "svm_raul_SVSLC". Reason: Illegal operation on Snapshot locked by SnapLock.
[...]
```

### ¿Cómo recuperarse frente a un ataque de ransomware?

Imaginemos que se ha sufrido un ataque de ransomware y que éste ha cifrado el contenido de uno de los volúmenes del sistema de producción (primario).    
A través del GUI de ONTAP veremos los clásicos indicadores: demasiada actividad anormal de modificaciones en ficheros en todas las carpetas durante un corto periodo de tiempo, y el contenido de los ficheros cifrado.

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_02.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_02.jpg"></a>
</p>   

Además, el ataque ha borrado también los snapshots locales y, por tanto, no existen puntos de recuperación inmediatos:

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_03.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_03.jpg"></a>
</p>   

Por suerte el volumen estaba protegido en el air-gap lógido y SnapVault nos permite directamente restaurar el volumen completo desde el destino de SnapVault con SnapLock en el air-gap, donde los snapshots permanecen a buen recaudo.

La restauración se puede hacer a través de la linea de comando utilizando el comando `snapmirror restore -source-path -destination-path source-snapshot`, pero también se puede hacer desde el GUI de ONTAP.   
Para ello, vamos a la pestaña de Snapmirror (local or Remote) del volumen afectado en el sistema primario y veremos la relación existente de SnapVault:

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_04.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_04.jpg"></a>
</p>  


Al hacer clic sobre ella se nos abre el GUI del destino de SnapVault en el air-gap lógico:

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_05.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_05.jpg"></a>
</p>  

Haciendo clic en la relación de SnapVault desde donde queremos recuperar, se abre una ventana emergente con la opción de "Restore":

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_06.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_06.jpg"></a>
</p>  

En nuestro caso particular recuperaremos a un nuevo volumen en el mismo sistema primario de producción. También es posible realizar la recuperación a otro volúmen de otro SVM que estuviese aislado para tareas de recuperación e investigación forense sobre el ataque sufrido.
Como puede observarse, el GUI ofrece la opción de elegir desde qué snapshot en destino realizar la recuperación:

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_07.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_07.jpg"></a>
</p>  

La recuperación es rápida y vendrá muy determinada por la línea de comunicación entre el origen y el destino. Minutos despúes veremos que se ha podido recuperar todo el contenido afectado sobre un nuevo volumen:

<p align="center">
   <a href="/images/posts/ONTAP-ransomware2_08.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware2_08.jpg"></a>
</p>  

