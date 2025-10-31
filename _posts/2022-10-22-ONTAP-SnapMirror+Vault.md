---
layout: post
type: posts
title: SnapMirror y SnapVault en ONTAP 9
date: '2022-10-22T19:12:55.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
Este artículo está dedicado a las tecnologías de recuperación ante desastres (conocida como SnapMirror) y de respaldo remoto a disco (denominada SnapVault) de ONTAP. En él veremos cómo funcionan y se configuran y qué particularidades y diferencias existen entre ambas. El artículo está basado en ONTAP 9, por lo que el lector que esté familiarizado con Data ONTAP 7 (7-Mode) encontrará diferencias y mejoras sustanciales, ya que estas tecnologías han formado parte del sistema operativo de almacenamiento ONTAP de NetApp desde tiempos cercanos a su origen, pero han ido evolucionando y mejorando con el tiempo, ampliándose también sus capacidades.
  
---
To read a (bad) English Google-translated version of this post click <a href="https://translate.google.com/translate?hl=&sl=es&tl=en&u=https%3A%2F%2Fraul-pingarron.github.io%2F2021%2F05%2F22%2FONTAP-SnapMirror+Vault.html" target="_blank">here</a>.

---   

### POST EN CONSTRUCCIÓN

Como su nombre indica, SnapMirror crear una réplica o espejo de los datos en otro sistema de almacenamiento ONTAP desde el que puede seguir sirviendo datos en caso de catástrofe en el sitio primario. 
SnapVault es una tecnología de vaulting diseñada para replicar snapshots (backups de ONTAP) a disco en otro sistema de almacenamiento secundario ONTAP, de esta manera, un destino de SnapVault conservará los snapshots del sistema de origen elegidos durante un periodo de retención mucho más largo.

Aunque se verá más adelante, con ONTAP 9 ambas tecnologías utilizan el mismo motor de replicación y, en realidad, SnapVault puede considerarse como una política de replicación específica de SnapMirror.
En cualquier caso, los datos se replican a nivel de volumen utilizando una transferencia de datos lógica e incremental a nivel de bloque que garantiza que sólo los bloques de datos que han cambiado se envían a la réplica de destino.

### POST EN CONSTRUCCIÓN
