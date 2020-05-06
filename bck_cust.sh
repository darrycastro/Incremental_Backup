#!/bin/bash
#

# Filename: bck_cust.sh
# Description: Backup Incremental de correo eléctronico
# Author: Darry Castro
# Website: https://aripagua.com
# -------------------

#Se crea Variable
dia=`date +%A-%d-%B-%Y`
before="$(date +%s)"
before2="$(date +%s)"
echo "- Inicio de Respaldo en Caliente el $dia  --> `date +%T`"

# Se toma toda la informacion del Servidor
#echo "aripagua.com" > /tmp/vps.txt

mysql root_cwp -B -N -s -e "SELECT username,domain FROM user WHERE backup='on'" | while read -r username domain
do

echo $domain >> /tmp/vps1.txt

done

# Se ordena la lista de usuarios totales en orden alfabético
sort -o /tmp/vps.txt -u /tmp/vps.txt

# Validar tamaño de Disponibilidad en el disco
tamano_d=$(echo `df |grep simfs |awk '{print $4}'`)

# Validar tamano de Ocupabilidad en el disco backup al 50 porciento minimo
tamano_f=$(echo `df |grep simfs |awk '{print $3}'`)
tamano_f=$(($tamano_f / 14))

# Valida el Factor para Optimizar el Archivado
tamano_a=$(echo `ls -lr1 /backup/mail/ |grep - |wc -l`)
tamano_v=$(echo `du -s /backup/mail/* |grep - |awk '{print $1}' |paste -sd'+' |bc -l`)
tamano_v=$(($tamano_v / $tamano_a))

# Validar tamaño del Archivo a Borrar
tamano_f=$(($tamano_f + $tamano_v + 10000000))
echo "  Disco   :  Archivo"
i=$(echo `ls /backup/mail/ |grep - |wc -l`)
i=$(($i + 2))

while [ $tamano_d -le $tamano_f ]; do
    i=$(($i - 1))    
    carpeta=`date -d "$i day ago" +%d-%m-%Y`
    echo "Liberando Espacio en el Disco quitando la carpeta $carpeta"
    #rm -rf /backup/mail/$carpeta

    # Validar tamaño de Disponibilidad en el disco
    tamano_d=$(echo `df |grep simfs |awk '{print $4}'`)
    echo "$tamano_d : $tamano_f"
done

echo "$tamano_d : $tamano_f : Tamano adecuado para el Backup Paso 1"

# Validar tamaño de la Base de Datos
tamano=$(echo `wc -l /tmp/vps.txt` |awk -F " " '{print $1}')
tamano=$(($tamano / 1))

echo -e "tamaño $tamano"

cat /tmp/vps.txt |
while read line; do

  carpeta=`date +%d-%m-%Y`
  subcarpeta=$(echo $line)
  backupdir="/backup/mail/$carpeta/$subcarpeta"
  backupdir1="/backup/mail/Full/$subcarpeta"
  archivo_tgz="${backupdir}/${subcarpeta}.tgz"
  snapshot_incr="${backupdir}/${subcarpeta}.snar"
  snapshot_full="${backupdir1}/${subcarpeta}.snar"

  # Creacion de Carpetas para su respaldo
  if [ ! -d $backupdir ]; then
	  mkdir -p $backupdir
    echo -e "Creando la carpeta Automaticamente, $backupdir \t \t No Existe, "
    mkdir -p $backupdir1
    echo -e "Creando la carpeta Automaticamente, $backupdir1 \t \t No Existe, "
  fi

  # Verificacion de Snapshot Flull
  if [ ! -f ${snapshot_full} ]; then
    ionice -c 3 nice -n +19 tar -cvzf ${backupdir1}/${subcarpeta}.tgz -g ${snapshot_full} /var/vmail/${subcarpeta}
    echo -e "Creando la Snapshot Automaticamente, ${snapshot_full} \t \t No Existe, "
  fi

  # Verificacion de Snapshot Incremental
  if [ ! -f ${archivo_tgz} ]; then
    ionice -c 3 nice -n +19 tar -cvzf ${archivo_tgz} -g ${snapshot_full} /var/vmail/${subcarpeta}
    echo -e "Creando la Snapshot Automaticamente, ${snapshot_incr} \t \t No Existe, "
  fi

  
done

after="$(date +%s)"
elapsed="$(expr $after - $before2)"
hours=$(($elapsed / 3600))
elapsed=$(($elapsed - $hours * 3600))
minutes=$(($elapsed / 60))
seconds=$(($elapsed - $minutes * 60))
echo "- Duración del Respaldo en Caliente: $hours horas $minutes minutos $seconds segundos"
