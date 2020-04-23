#!/bin/bash

##Instalacion y Mantenimiento de una Aplicacion Web
#Importar funciones de otros ficheros
############################################################
#                 0)DESINSTALAR 
#############################################################
function desinstalar()
{
sudo service apache2 stop
sudo apt-get update
#Then uninstall Apache2 and its dependent packages. Use purge option instead of remove with apt-get command. The former option will try to remove dependent packages, as well as any configuration files created by them. In addition, use autoremove option as well, to remove any other dependencies that were installed with Apache2, but are no longer used by any other package.
sudo apt-get purge apache2 apache2-utils apache2-data
#paquetes sugeridos: apache2-doc apache2-suexec-pristine | apache2-suexec-custom
sudo apt-get purge php libapache2-mod-php*
#
sudo apt-get autoremove
sudo rm -rf /var/www/html/*
}

###########################################################
#                  1) INSTALL APACHE                     #
###########################################################
function apacheInstall()
{
	aux=$(aptitude show apache2 | grep "State: installed")
	aux2=$(aptitude show apache2 | grep "Estado: instalado")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then 
 	  echo "instalando ..."
 	  sudo apt-get install apache2
	else
   	  echo "apache ya estaba instalado"
    
	fi 
}

###########################################################
#                     10) Visualizar Logs                 #
###########################################################

function viendoLogs()
{
	
	archivo=/var/log/apache2/error.log #Save the path to the errors
	
	if [ test -e $archivo -a test -s &archivo ] #if the file error.log exists and its size isn't 0
	then
	  tail $archivo #print the last 10 lines of the file
	else
	  echo "El archivo no existe" #print "The file does not exist"
	fi
		
}

###########################################################
#       11) Controlar los intentos de conexión de ssh      #
###########################################################

function gestionarlogs()
{

touch /tmp/logscomprimidos.txt
touch /tmp/logs.txt
touch /tmp/logsfail.txt
touch /tmp/logsok.txt


archivoscomprimidos = "/tmp/logscomprimidos.txt"
archivoslogs = "/tmp/logs.txt"

cat /var/log/auth.log > $archivoslogs
cat /var/log/auth.log.0 > $archivoslogs
zcat ls auth.log.*.gz > $archivoscomprimidos

cat $archivoslogs | grep "sshd" | grep "Failed password" |tr ' '|tr ' ' '@' > /tmp/logsfail.txt #guardamos los fails en logsfail.txt separados por @
cat $archivoscomprimidos | grep "sshd" | grep "Failed password" |tr ' '|tr ' ' '@' > /tmp/logsfail.txt
cat $archivoslogs | grep "sshd" | grep "Accepted password" |tr ' '|tr ' ' '@' > /tmp/logsok.txt #guardamos los accepted en logsok.txt separados por @
cat $archivoscomprimidos | grep "sshd" | grep "Accepted password" |tr ' '|tr ' ' '@' > /tmp/logsok.txt

echo "Los intentos de conexion por ssh, hoy, esta semana y este mes han sido: \n"

for linea in `less /tmp/logsfail.txt`
do
usuario=`echo $linea | cut -d "@" -f9`#separado por @ solo seleccionar el field 9
fecha=`echo $linea | cut -d "@" -f1,2,3`
echo "Status: [fail] Accaunt name: $usuario Date: $fecha\n"
done

for linea in `less /tmp/logsok.txt`
do
usuario=`echo $linea | cut -d "@" -f9`#separado por @ solo seleccionar el field 9
fecha=`echo $linea | cut -d "@" -f1,2,3`
echo "Status: [accept] Accaunt name: $usuario Date: $fecha\n"
done
rm /tmp/logscomprimidos.txt
rm /tmp/logs.txt
rm /tmp/logsfail.txt
rm /tmp/logsok.txt
}


###########################################################
#                     12) SALIR                          #
###########################################################

function fin()
{
	echo -e "¿Quieres salir del programa?(S/N)\n"
        read respuesta
	if [ $respuesta == "N" ] 
		then
			opcionmenuppal=0
		fi	
}

### Main ###
opcionmenuppal=0
while test $opcionmenuppal -ne 12
do
	#Muestra el menu
        echo -e "0 Desinstalar\n"
	echo -e "1 Instala Apache \n"
	echo -e "2 Testea el servicio Web Apache \n"
        echo -e "3 Crear Virtual Host \n" 
        echo -e "4 Testea el virtual host \n" 
	echo -e "5 Instala el modulo php \n"
	echo -e "6 Testea PHP\n"
        echo -e "7 Creando un entorno virtual para Python3 \n"
	echo -e "8 Instala los paquetes necesarios, para la aplicación en el entorno virtual de python \n"
	echo -e "9 Instala la aplicacion \n"
        echo -e "10 Visualiza la aplicación \n"
        echo -e "11 Viendo los logs y errores de Apache \n"
        echo -e "11 Controla los intentos de conexión de ssh \n"
	echo -e "12 Exit \n"
	read -p "Elige una opcion:" opcionmenuppal
	case $opcionmenuppal in
                        0) desinstalar;;
			1) apacheInstall;;
			2) webApacheTest;;
                        3) createvirtualhost;;
                        4) webVirtualApacheTest;;
			5) phpInstall;;
			6) phpTest;;
			7) creandoEntornoVirtualPython3;;
			8) instalandoPaquetesEntornoVirtualPythonyAplicacion;;
                      	9) visualizandoAplicacion;;
			10) viendoLogs;;
			11) gestionarLogs;;
			12) fin;;
			*) ;;

	esac 
done 

echo "Fin del Programa" 
exit 0 
