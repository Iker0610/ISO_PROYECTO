#!/bin/bash

##Instalacion y Mantenimiento de una Aplicacion Web
#Importar funciones de otros ficheros

############################################################
#                      GLOBAL VARIABLES                    #
############################################################

# FULL PATH TO menu.sh
# Use this instead of relative paths to prevent bugs and make the code as safe as posible. (Do not use relative paths and try to avoid cd command )
# Example: bash ${EXE_PATH}/menu.sh
EXE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Colors for echo.
# Use: printf "${ERROR}THIS IS AN ERROR MESSAGE IN RED ${NC}this is a normal message on default color\n"
TITLE='\033[1;34m'
ERROR='\033[0;31mERROR- \033[0m'
OK='\033[0;32mOK- \033[0m'
WARNING='\033[0;33mAVISO- \033[0m'
NC='\033[0m' # No Color

############################################################
#                 0)DESINSTALAR 
#############################################################

function desinstalar()
{
    printf "${TITLE}0 Desinstalar${NC}\n\n\n"

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
    printf "${TITLE}1 Instalar Apache${NC}\n\n\n"

    # Check if apache was already installed
	aux=$(aptitude show apache2 | grep "State: installed")
	aux2=$(aptitude show apache2 | grep "Estado: instalado")
	aux3=$aux$aux2

	if [ -z "$aux3" ]
	then
 	  echo "Instalando ..."
 	  sudo apt-get install apache2 && printf "${OK} Instalación de Apache completada \n\n"
	else
   	  printf "${OK}Apache ya estaba instalado \n"
	fi
}


###########################################################
#     2) Activar y testear el servicio web Apache         #
###########################################################

function webApacheTest()
{
    printf "${TITLE}2 Testear el servicio Web Apache${NC}\n\n\n"

	# 1. Comunicar si el servicio web apache ya está arrancado y sino arrancarlo	
	aux=$(service apache2 status | grep "Active: active")

	if [ -z "$aux" ]
	then 
 	  echo "Starting apache ..."
 	  sudo service apache2 start && printf "${OK}Apache started \n\n"
	else
   	  printf "${OK}Apache is already running \n\n"
    fi
	sleep 1

	# 2. Testear si el servicio apache2 está escuchando por el puerto 80 

	# 2.1 Instalar el paquete que contiene netstat en caso de no estar instalado.
	aux=$(dpkg -s net-tools | grep "installed")
	# dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed" => returns 1 (installed) or 0 (not installed)
	if [ -z "$aux" ]
	then 
 	  echo "Installing net-tools ..."	#contains the netstat command
 	  sudo apt-get install net-tools && printf "${OK}net-tools successfully installed \n\n"
	else
   	  printf "${OK}net-tools is already installed \n\n"
    fi
	sleep 1

	#2.2 Saber el puerto por que está escuchando Apache/ Testear si el puerto está 80
	puerto=$(sudo netstat -anp | grep apache| grep "0 :::80")
	if [ ! -z "$puerto" ]
	then 
 	  printf "${OK}Apache is listening to port 80... \n\n"
	  printf "${WARNING}To check if the default page “index.html” which is located in /var/www/html is displayed correctly, firefox will be opened... \n\n"
	  echo "Abriendo Firefox..."
	  firefox http://127.0.0.1 || prinf "${ERROR}Parece que no se ha podido iniciar firefox... \n"
	else
   	  printf "${ERROR}Apache is not listening to port 80. Something went wrong.\nCheck the 1º option in order to check if apache is installed \n"
    fi
	sleep 1
}

###########################################################
#         3) Crea un virtual host en el puerto 8080       #
###########################################################

function createvirtualhost()
{
    printf "${TITLE}3 Crear Virtual Host${NC}\n\n\n"

	# Step 1: Create the directory that will host the website
	echo 'Creando directorio /var/www/html/erraztest'
	if [ ! -d "/var/www/html/erraztest" ]
	then
	    sudo mkdir /var/www/html/erraztest
	    if [ $? -eq 0 ]
	    then
            printf "${OK}El directorio ha sido creado correctamente. \n\n"
        else
            printf "${ERROR}No se ha podido crear el directorio. \n\n"
        fi
    else
        printf "${OK}El directorio ya existía. \n\n"
    fi

	# Step 2: Create the configuration file for the new virtual host
    echo "Creando el virtual host de Apache en el puerto 8080..."

    declare -i RESULT=0
	# 2.1 Use the default config and edit it afterwards
	sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/erraztest.conf
    RESULT+=$?

	# 2.2 	Adapt the new config files to our needs
	#	For editing a file by bash the sed command can be used, where sed is a stream editor 
	# 	In more detail, the sed's 'substitute' command can be used, which uses the following syntax: ‘s/regexp/replacement/flags’
	# 	=> Helpful flag: g (apply the replacement to all matches to the regexp, not just the first)
	#	=> -i: Edit files in place (long argument name: --in-place);  optional: saving backups with the specified extension.
	# 	=> Important: The characters have to be escaped, e.g. "new line" -> "\n" or "/" -> "\/"

	# 2.2.1 Change ": 80" to ": 8080" to indicate that we will access this virtualhost through this port
	#	regexp: 80
	#	replacement: 8080
	sudo sed -i "s/80/8080/g" /etc/apache2/sites-available/erraztest.conf
	RESULT+=$?

	# 2.2.2 Update the reference to the root directory to make sure it points to the right place
	#	regexp:\/var\/www\/html
	#	replacement: \/var\/www\/html\/erraztest
	sudo sed -i "s/\/var\/www\/html/\/var\/www\/html\/erraztest/g" /etc/apache2/sites-available/erraztest.conf
	RESULT+=$?

	# 2.2.3 Add a new section with some basic guidelines among which we have enabled the mod_rewrite module, necessary for rewriting urls 
	#	regexp:<\/VirtualHost>
	#	replacement: \<Directory \/var\/www\/html\/erraztest\>\nOptions Indexes FollowSymLinks MultiViews\nAllowOverride All\nOrder allow,deny\nallow from all\n<\/Directory>\n<\/VirtualHost>\n
	sudo sed -i "s/<\/VirtualHost>/\<Directory \/var\/www\/html\/erraztest\>\nOptions Indexes FollowSymLinks MultiViews\nAllowOverride All\nOrder allow,deny\nallow from all\n<\/Directory>\n<\/VirtualHost>\n/g" /etc/apache2/sites-available/erraztest.conf
	RESULT+=$?

	# Step 3: Open the proper port in Apache by editing the /etc/apache2/ports.conf file (if it is not yet opened)
	aux=$(grep "Listen 8080" /etc/apache2/ports.conf)
	if [ -z "$aux" ]
	then 
 	  echo "Abriendo puerto 8080 en Apache ..."
 	  sudo sed -i "s/Listen 80/Listen 80\nListen 8080/g" /etc/apache2/ports.conf && printf "${OK}Port 8080 successfully opened \n\n"
 	  RESULT+=$?
	else
   	  printf "${OK}Apache is already listening to port 8080 \n\n"
    fi
	sleep 1

	# Step 4: Enable the new virtualhost

	# 4.1 Create a symbolic link of the config in the sites-available directory in the sites-enabled directory (with a2ensite)
	sudo a2ensite erraztest.conf
	RESULT+=$?
	
	# 4.2 Restart Apache	
	sudo service apache2 restart
	RESULT+=c

    if [ ${RESULT} -eq 0 ]
    then
        printf "${OK}Se ha creado el virtual host correctamente. \n\n"
    else
        printf "${ERROR}Ha sucedido un problema en el proceso de creación del virtual host. \n\n"
    fi
}

###########################################################
#         4) Testea el virtual host                       #
###########################################################

function webVirtualApacheTest()
{
    printf "${TITLE}4 Testear el virtual host${NC}\n\n\n"

	# Step 1: Copy the default page index.html located in /var/www/html into /var/www/html/erraztest.
	sudo cp /var/www/html/index.html /var/www/html/erraztest/index.html || printf "${ERROR}No se ha podido copiar el index.html \n\n"
	
	# Step 2: Check if Apache is listening to port 8080 
	puerto=$(sudo netstat -anp | grep apache| grep "0 :::8080")
	if [ ! -z "$puerto" ]
	then 
 	  printf "${OK}Apache is listening to port 8080 \n\n"
	else
   	  printf "${ERROR}Apache is not listening to port 8080. Something went wrong \n\n"
    fi
	sleep 1

	# Step 3: To check if the default page “index.html” which is located in /var/www/html/erraztest is displayed correctly, open the navigation with "firefox http://127.0.0.1:8080 "
	printf "${WARNING}To check if the default page “index.html” which is located in /var/www/html/erraztest is displayed correctly, firefox will be opened... \n\n"
	echo "Abriendo Firefox..."
	firefox http://127.0.0.1:8080 || prinf "${ERROR}Parece que no se ha podido iniciar firefox... \n"
}

###########################################################
#                     5) INSTALL PHP                      #
###########################################################

function phpInstall()
{
    printf "${TITLE}5 Instalar el modulo php${NC}\n\n\n"

    # Se comprueba si PHP está instalado
	aux=$(aptitude show php | grep "State: installed")
	aux2=$(aptitude show php | grep "Estado: instalado")
	aux3=$aux$aux2

	if [ -z "$aux3" ]
	then
	    # Si no lo está se instala
		printf "Instalando PHP...\n\n"
		sudo apt install php libapache2-mod-php
		sudo apt install php-cli
		sudo apt install php-cgi

		#Verify if the files exist
		echo "Comprobando archivos..."
		if [ ! -d /etc/apache2/mods-enabled/php7.2.conf ] && [ ! -d /etc/apache2/mods-enabled/php7.2.load ]
		then
			#Enable the module php
			echo "Activando modulo PHP..."
			a2enmod php7.2 && printf "${OK}Modulo PHP activado \n\n"
        else
            printf "${ERROR}Los archivos requeridos para activar PHP no existen: /etc/apache2/mods-enabled/php7.2.conf y /etc/apache2/mods-enabled/php7.2.load \n\n"
		fi
		
		#Restart Apache2
		echo "Reiniciando Apache..."
		sudo systemctl restart apache2.service && printf "${OK}Apache reiniciado \n\n"

		echo "Fin de la instalación de PHP"
	else
		printf "${OK}PHP ya está instalado \n"
	fi
}

###########################################################
#                     6) TEST PHP                         #
###########################################################

function phpTest()
{
    printf "${TITLE}6 Testear PHP${NC}\n\n\n"

	echo "Creando fichero test.php..."
	sudo /bin/bash -c 'echo "<?php phpinfo(); ?>" >>/var/www/html/erraztest/test.php'

	# Se compruba que se haya creado el fichero
	if [ $? -eq 0 ]
    then
        printf "${OK}test.php creado correctamente \n\n"

        #test.php y index.html:
        #Nos aseguranmos que tienen el mismo propietario
        echo "Comprobando propietarios..."
        propietarioHTML=$(stat --format %U /var/www/html/erraztest/index.html)
        sudo chown $propietarioHTML /var/www/html/erraztest/test.php

        #Nos aseguramos que tienen los mismos permisos:
        echo "Comprobando permisos..."
        permisosHTML=$(stat --format %a /var/www/html/erraztest/index.html)
        sudo chmod $permisosHTML /var/www/html/erraztest/test.php

        echo ''

        #Abrimos el test.php con el navegador
        printf "${WARNING}Se abrirá Firefox para comprobar PHP... \n\n"
        echo "Abriendo con firefox..."
        firefox http://127.0.0.1:8080/test.php  || prinf "${ERROR}Parece que no se ha podido iniciar firefox... \n"

    else
        printf "${ERROR}No se ha podido crear test.php. \n"
    fi
}

###########################################################
#            7) CREAR ENTORNO VIRTUAL PYTHON 3            #
###########################################################

function crearEntornoVirtualPython3()
{
    printf "${TITLE}7 Crear un entorno virtual para Python3${NC}\n\n\n"

	# Post:	This function creates a new Python3 environment in /var/www/html/erraztest
	#	This way the application is able to have its own Python library versions
	#	regardless the ones that are installed (or not) in the system

    printf "${WARNING}Se empleará python3.6 en el entorno virtual si no se dispone de él se instalará"
	printf "${WARNING}Es posible que en el proceso se instalen dependencias adicionales necesarias"
	# Install the virtualenv
	echo "Instalando virtualenv para Python..."
	sudo apt-get install python-virtualenv virtualenv
	if [ $? -eq 0 ]
    then
        printf "${OK}Virtualenv instalado correctamente \n\n"

        # Create a new virtual environment for Python3 in the folder: /var/www/html/erraztest
        echo "Creando entorno virtual en /var/www/html/erraztest/env..."
        sudo virtualenv /var/www/html/erraztest/python3envmetrix --python=python3
        if [ $? -eq 0 ]
        then
            printf "${OK}Entono virtual creado en /var/www/html/erraztest/env \n"
        else
            printf "${ERROR}No se ha podido crear el entorno virtual en /var/www/html/erraztest/env \n"
        fi
    else
        printf "${ERROR}No se ha podido instalar virtualenv \n"
    fi
}


###########################################################
#      8) INSTALL PACKAGES IN THE VIRTUAL ENVIRONMENT     #
###########################################################

function instalarLibreriasPythonYAplicacion()
{
    printf "${TITLE}8 Instalar la aplicación y las librerias en el entorno virtual de python${NC}\n\n\n"

	########## INSTALL PACKAGES ##########

	# Install necesary Ubuntu packages: dos2unix and pip3
	echo 'Instalando pip y dos2unix...'
	sudo apt install dos2unix python3-pip	# Install dos2unix
	# Check if everything went OK
    if [ $? -eq 0 ]
    then
        printf "${OK}pip y dos2unix instalados correctamente en el sistema \n\n"

        # Give file ownership to www-data (user and group)
        sudo chown -R www-data:www-data /var/www

        # Install python packages in the virtual env. via PIP
        # 1- Activate the virtual environment
        # 2- Install packages
        # 3- Deactivate virtualenv

        sudo su www-data -s /bin/bash <<EOF
        echo 'Activando el entorno virtual...'
        source /var/www/html/erraztest/python3envmetrix/bin/activate
        echo 'Instalando librerías de python...'
        pip3 install numpy
        pip3 install nltk
        pip3 install argparse
        echo 'Instalación completada'
        echo 'Desactiando entorno virtual'
        deactivate
EOF

        ########## INSTALL AND TEST APLICATION ##########

        # Copy application files to /var/www/html/erraztest/
        echo 'Instalando aplicación en /var/www/html/erraztest/'
        sudo cp ${EXE_PATH}/index.php /var/www/html/erraztest/
        sudo cp ${EXE_PATH}/webprocess.sh /var/www/html/erraztest/
        sudo cp ${EXE_PATH}/complejidadtextual.py /var/www/html/erraztest/
        sudo cp ${EXE_PATH}/processing.gif /var/www/html/erraztest/

        # Copy english.doc.txt for test
        sudo cp -r textos /var/www/html/erraztest/

        # Give file ownership to www-data (user and group)
        sudo chown -R www-data:www-data /var/www

        echo 'Aplicación instalada correctamente'

        # Test the application as www-data user
        cd /var/www/html/erraztest/
        sudo su www-data -s /bin/bash -c ./webprocess.sh textos/english.doc.txt
        cd ${EXE_PATH}
    else
        printf "${ERROR}No se han podido efectuar las instalaciones apropiadas \n"
    fi
 }


###########################################################
#               9) VISUALIZAR APLICACIÓN                  #
###########################################################

function visualizarAplicacion()
{
    printf "${TITLE}9 Visualizar la aplicación${NC}\n\n\n"

    printf "${WARNING}Se abrirá Firefox para visualizar la aplicación... \n\n"
	echo "Abriendo con firefox..."
	firefox http://127.0.0.1:8080/index.php  || prinf "${ERROR}Parece que no se ha podido iniciar firefox... \n"
}

###########################################################
#                     10) Visualizar Logs                 #
###########################################################

function viendoLogs()
{
    printf "${TITLE}10 Ver los logs y errores de Apache${NC}\n\n\n"
	
	archivo=/var/log/apache2/error.log #Save the path to the errors
	
	if [ -s $archivo ]  #if the file error.log exists and its size isn't 0
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
    printf "${TITLE}11 Controlar los intentos de conexión de ssh${NC}\n\n\n"


    touch /tmp/logscomprimidos.txt
    touch /tmp/logs.txt
    touch /tmp/logsfail.txt
    touch /tmp/logsok.txt


    archivoscomprimidos="/tmp/logscomprimidos.txt"
    archivoslogs="/tmp/logs.txt"

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
    echo "Status: [fail] Account name: $usuario Date: $fecha\n"
    done

    for linea in `less /tmp/logsok.txt`
    do
    usuario=`echo $linea | cut -d "@" -f9`#separado por @ solo seleccionar el field 9
    fecha=`echo $linea | cut -d "@" -f1,2,3`
    echo "Status: [accept] Account name: $usuario Date: $fecha\n"
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
    printf "${TITLE}12 Salir${NC}\n\n\n"

	echo -e "¿Quieres salir del programa?(S/N)\n"
        read respuesta
	if [ $respuesta == "N" ] 
		then
			opcionmenuppal=0
		fi	
}

### Main ###
opcionmenuppal=0
printf "\n\n--------------------------------------\n\n"
printf "${TITLE} - Installador de la Aplicación Web - ${NC}"
printf "\n\n--------------------------------------\n\n"
while test $opcionmenuppal -ne 12
do
	#Muestra el menu
  	echo -e "0 Desinstalar \n"
	echo -e "1 Instalar Apache \n"
	echo -e "2 Testear el servicio Web Apache \n"
    echo -e "3 Crear Virtual Host \n" 
    echo -e "4 Testear el virtual host \n"
	echo -e "5 Instalar el modulo php \n"
	echo -e "6 Testear PHP \n"
    echo -e "7 Crear un entorno virtual para Python3 \n"
	echo -e "8 Instalar la aplicación y las librerias en el entorno virtual de python \n"
    echo -e "9 Visualizar la aplicación \n"
    echo -e "10 Ver los logs y errores de Apache \n"
    echo -e "11 Controlar los intentos de conexión de ssh \n"
	echo -e "12 Salir \n"
	read -p "Elige una opcion: " opcionmenuppal
	printf "\n\n----------------------------------------\n\n"
	case $opcionmenuppal in
          	0) desinstalar;;
			1) apacheInstall;;
			2) webApacheTest;;
            3) createvirtualhost;;
            4) webVirtualApacheTest;;
			5) phpInstall;;
			6) phpTest;;
			7) crearEntornoVirtualPython3;;
			8) instalarLibreriasPythonYAplicacion;;
            9) visualizarAplicacion;;
			10) viendoLogs;;
			11) gestionarLogs;;
			12) fin;;
			*) ;;
	esac
	printf "\n----------------------------------------\n\n\n"
done 

echo "Fin del Programa" 
exit 0 