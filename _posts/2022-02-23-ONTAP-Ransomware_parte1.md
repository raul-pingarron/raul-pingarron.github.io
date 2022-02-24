---
layout: post
type: posts
title: Protección frente ciberataques mediante air-gapping en ONTAP (Introducción)
date: '2022-02-23T10:21:12.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
Los ataques de ransomware están a la orden del día y la ciber-resiliencia en un sistema de almacenamiento y gestión de la información es un factor determinante en la elección de toda solución. Esto aplica especialmente a aquellos sistemas en los que residen datos de usuario, datos no estructurados o semi-estructurados, y cualquier tipo de dato sensible. 
ONTAP de NetApp es uno de los sistemas operativos de almacenamiento pioneros en implantar una aproximación de tipo "nula confianza" en sus mecanismos para securizar el acceso y servicio del dato, y también es una referencia en la industria por sus funcionalidades adicionales de salvaguarda del dato que le confieren una ciber-resiliencia única en su clase.

---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2022%2F02%2F23%2FONTAP-Ransomware_parte1.html" target="_blank">here</a>.

---   

En este post vamos a tratar de algunas de estas funcionalidades, y en el siguiente post se expondrá su correspondiente caso de aplicación práctica. En concreto, de cómo implementar una estrategia para el respaldo de la información que almacene los *backups* en otra ubicación física distinta de donde se encuentra el sistema de producción (*backups off-site*) y, donde además, estos respaldos de la información sean inmutables, imborrables,  de fácil y rápida recuperación y eficientes en espacio. Es decir, una aproximación basada en un **air-gap lógico** para el sistema de respaldo y recuperación rápida de la información. De esta manera, si se sufre un ciber-ataque y éste consigue cifrar todo el contenido de los datos y, además, eliminar los snapshots del sistema primario o principal, se podrá poner remedio de manera rápida y eficaz recuperando los datos desde el sistema secundario de respaldo (el air-gap lógico).

Esta estrategia de securización del backup/restore de la información mediante un air-gapping lógico suele combinarse en paralelo con una estrategia de recuperación frente a desastres, donde la ubicación secundaria (centro de respaldo) recibe una réplica íntegra y sincronizada periódicamente del sistema de producción, estando disponible en todo momento para resumir la producción en caso de fallo del sistema de producción del centro principal.

Un diagrama general a alto nivel de la estrategia completa sería el siguiente:

<p align="center">
   <a href="/images/posts/ONTAP-ransomware_01.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware_01.jpg"></a>
</p>   


Esta aproximación se apoya en las siguientes funcionalidades de ONTAP:

- **Snapshots de ONTAP**: son copias de seguridad inmutables (no se pueden modificar), eficientes en espacio (solo almacenan los cambios) y que, además, no impactan en el rendimiento (se pueden mantener hasta 1024 snapshots por volumen en ONTAP, y un clúster de ONTAP puede tener cientos de miles de snapshots sin verse impactado su rendimiento por la utilización de los mismos).
- **SnapMirror de ONTAP**: tecnología de replicación en modo síncrono o asíncrono de volúmenes de datos o SVMs (incluyendo los datos y la configuración íntegra del servicio) que mantiene las eficiencias, y que permite una recuperación rápida y sencilla con RTO y RPO adaptable a las necesidades y las circunstancias.
- **SnapVault de ONTAP**: es la solución de backup a disco nativo de ONTAP, basada en la tecnología de incrementales para siempre de SnapMirror, y que permite enviar copias de seguridad basadas en snapshots a un destino secundario. SnapVault mantiene las eficiencias y permite realizar respaldos y recuperaciones de la información muy rápidos, eliminando o acortando considerablemente las ventanas de backup, utilizando un sistema de almacenamiento secundario muy efectivo en coste y con un porcentaje muy pequeño de la capacidad, comparándolo con la capacidad que requieren los sistemas tradicionales de copia de seguridad. La restauración de los datos puede hacerse con un simple comando o clic de ratón directamente desde el destino al origen, o a cualquier otro nuevo origen, permitiendo la recuperación completa a nivel de volumen o granular a nivel de fichero o LUN.
- **SnapLock de ONTAP**: es la solución de ONTAP que permite crear volúmenes inmutables e imborrables para evitar que su contenido, incluyendo los snapshots, pueda ser modificado o eliminado hasta un fecha de expiración asignada, que puede llegar a los 100 años. SnapLock incluye una modalidad denominada *Compliance* (SLC) que se apoya en el modelo de "administrador no fiable" de manera que el contenido de un volumen SLC marcado como WORM nunca puede ser alterado o modificado ni siquiera por el propio administrador de almacenamiento (incluyento personal de NetApp); sólo podrá ser eliminado una vez que expire su periodo de retención. Adicionalmente, con SLC no se permite ninguna operación por parte del administrador que pueda comprometer los datos en WORM, no solo protegiendo a nivel de ficheros, y snapshots, sino también a nivel de volumen, agregado y discos. Mencionar que SnapLock Compliance (SLC) está certificado bajo cumplimiento de las normas SEC Rule 17a-4, FINRA, HIPAA, CFTC así como los requerimientos de la GDPR que requieren el uso de almacenamiento no borrable. 


## SnapVault con SnapLock

La implementación del *air-gap lógico* se basa en el empleo de la funcionalidad de SnapLock (Compliance en el caso que nos ocupa) junto con SnapVault, donde la réplica de tipo *vault* se realiza directamente contra un volumen SnapLock que reside en un clúster ONTAP en otra ubicación secundaria. En paralelo, y según se ha mencionado anteriormente, el origen en el sistema de producción mantiene otra réplica de tipo *mirror* o Disaster Recovery contra otro destino o clúster de DR; esto es lo que se conoce como un despliegue de SnapMirror en fan-out, es decir, de un mismo origen salen dos réplicas hacia dos sistemas distintos. 
De esta manera se tienen dos sistemas aislados: uno para DR tradicional y otro como backup off-site inmutable e imborrable (logical Air Gap). 

A partir de la **versión 9.10.1 de ONTAP** ya no es necesario crear un agregado de SnapLock dedicado para albergar el volumen de destino de SnapVault. De esta manera, volúmenes no SnapLock y volúmenes SnapLock pueden convivir en el mismo agregado simplificando la arquitectura y aportando más flexibilidad.

Con la solución de SnapVault con SnapLock se crea una relación de SnapVault entre un volumen origen y un volumen SnapLock de destino, de manera que los snapshots se irán replicando al destino según una política definida y estarán protegidos frente al borrado durante un determinado periodo de retención.
El periodo de retención por defecto del volumen SnapLock destino es el que determinará el periodo de retención frente al borrado o rotado para los snapshots transmitidos y que residen en el destino, es decir, que la fecha de expiración WORM del volúmen de SnapLock es la que va a determinar en última instancia el periodo de retención de los snapshots en el destino por encima de la política de snapmirror definida para la relación de vault.   
La siguiente figura describe el comportamiento (haz clic para verla más grande):

<p align="center">
   <a href="/images/posts/ONTAP-ransomware_02.jpg" target="_blank"><img src="/images/posts/ONTAP-ransomware_02.jpg"></a>
</p>   

En otras palabras: en cada actualización o transferencia de SnapVault se intentan eliminar los snapshots antiguos según su etiqueta de snapmirror para mantener el periodo de retención definido por la política; sin embargo, dado que estos snapshots están en un volumen SnapLock y pueden tener una fecha de expiración WORM futura, no podrán ser eliminados por este mecanismo por lo que se irán acumulando en el volumen destino. Así, por ejemplo, para el caso en el que se haya establecido una política de SnapVault que retiene 15 copias diarias de snapshots en el volumen de destino de SnapVault con SnapLock, si el período de expiración WORM del volumen SnapLock se ha fijado en 30 días, al transferir es decimosexto snapshot, el snapshot más antiguo no se elimina. Pasados 31 días, la transferencia de ese snapshot número 31 provocará la eliminación del snapshot más antiguo y, por tanto, su rotación.


Si quieres continuar leyendo el siguiente post con el caso de aplicación práctica <a href="https://raul-pingarron.github.io/2022/02/24/ONTAP-Ransomware_parte2.html" target="_blank">haz clic aquí</a>.


## Enlaces de interés

En el Technical Report <a href="https://www.netapp.com/media/7334-tr4572.pdf" target="_blank">*The NetApp solution for ransomware*</a> se puede obtener más información sobre toda las funcionalidades de ciber-resiliencia de ONTAP destinadas a la protección, detección y remediación de ciber-ataques como los producidos por el ransomware.

En el Technical Report <a href="https://www.netapp.com/media/6158-tr4526.pdf" target="_blank">*Compliant WORM storage using NetApp SnapLock*</a> se puede obtener más información sobre la funcionalidades SnapLock de ONTAP.

En este otro enlace se recopilan <a href="https://security.netapp.com/resources/" target="_blank">todos los recursos relacionados con ciber-seguridad</a> en ONTAP.

Las certificaciones de seguridad de NetApp se pueden encontrar en <a href="https://security.netapp.com/certs/" target="_blank">este enlace</a>.


