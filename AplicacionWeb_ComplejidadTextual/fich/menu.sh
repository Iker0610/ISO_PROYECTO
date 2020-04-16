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
#            7) CREAR ENTORNO VIRTUAL PYTHON 3            #
###########################################################

function crearEntornoVirtualPython3()
{
	#Post: This function creates a new Python3 environment in /var/www/html/erraztest
	#			This way the application is able to have its own Python library versions
	#			regardless the ones that are installed (or not) in the system


	# TODO(¿?): CHECK IF VIRTUALENV IS ALREADY INSTALLED AND/OR CREATED

	# Install the virtualenv
	echo "instalando el entorno virtual..."
	sudo apt-get install python-virtualenv virtualenv

	# Create a new virtual environment for Python3 in the folder: /var/www/html/erraztest
	echo "creando entorno virtual en /var/www/html/erraztest/env..."
	sudo virtualenv /var/www/html/erraztest/python3envmetrix --python=python3
}


###########################################################
#      8) INSTALL PACKAGES IN THE VIRTUAL ENVIRONMENT     #
###########################################################

function instalarPaquetesEntornoVirtualPythonyAplicacion()
{
	# TODO: Show errors, permissions, file ownership ... 

	########## INSTALL PACKAGES ##########

	sudo su # Change to "root" mode

	# Install necesary Ubuntu packages - (in the virtualenv or in system¿?)
	apt install dos2unix 		# Install dos2unix
	apt install python3-pip   	# Install pip

	# Install python packages in the virtual env. via PIP

	# Activate the virtual environment
	cd /var/www/html/erraztest/python3envmetrix 	# Move to the virtualenv folder
	source bin/activate								# Activate the environment executing activate (script)

	# Install python packages with PIP inside the virtual environment
	pip install numpy
	pip install nltk
	pip install argparse

	# Deactivate the virtual environment
	deactivate


	########## INSTALL AND TEST APLICATION ##########
	
	# Copy application files to /var/www/html/erraztest/
	cp index.php /var/www/html/erraztest/
	cp webprocess.sh /var/www/html/erraztest/
	cp complejidadtextual.py /var/www/html/erraztest/
	cp processing.gif /var/www/html/erraztest/

	# Copy english.doc.txt for test
	cp  english.doc.txt /var/www/html/erraztest/textos

	# Give file ownership to www-data (user and group)
	chown -R www-data:www-data /var/www 

	# Test the application as www-data user
	su - www-data -s /bin/bash			# Change to 'www-data' user and run bash as shell
	cd /var/www/html/erraztest			# Change folder to /var/www/html/erraztest
	./webprocess.sh textos/english.doc.txt		# Execute 'webprocess.sh' script
}


###########################################################
#               9) VISUALIZAR APLICACIÓN                  #
###########################################################

function visualizarAplicacion()
{
	# (I don't know if is just this or...)
	firefox http://127.0.0.1:8080/index.php
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
			7) crearEntornoVirtualPython3;;
			8) instalarPaquetesEntornoVirtualPythonyAplicacion;;
            9) visualizarAplicacion;;
			10) viendoLogs;;
			11) gestionarLogs;;
			12) fin;;
			*) ;;

	esac 
done 

echo "Fin del Programa" 
exit 0 
