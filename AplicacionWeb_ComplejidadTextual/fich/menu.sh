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
#     2) Activar y testear el servicio web Apache         #
###########################################################

function webApacheTest()
{
	# 1. Comunicar si el servicio web apache ya está arrancado y sino arrancarlo	
	aux=$(service apache2 status | grep "Active: active")
	if [ -z "$aux" ]
	then 
 	  echo "Starting apache ..."
 	  sudo service apache2 start
	  echo "Apache started"
	else
   	  echo "Apache is already running"
    	fi 
	sleep 1

	# 2. Testear si el servicio apache2 está escuchando por el puerto 80 

	# 2.1 Instala el paquete que contiene netstat en caso de no estar instalado.
	aux=$(dpkg -s net-tools | grep "installed")
	# dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed" => returns 1 (installed) or 0 (not installed)
	if [ -z "$aux" ]
	then 
 	  echo "Installing net-tools ..."	#contains the netstat command
 	  sudo apt-get install net-tools
	  echo "net-tools successfully installed"
	else
   	  echo "net-tools is already installed"
    	fi 
	sleep 1

	#2.2 Saber el puerto por que está escuchando Apache/ Testear si el puerto está 80
	puerto=$(sudo netstat -anp | grep apache| grep "0 :::80")
	if [ ! -z "$puerto" ]
	then 
 	  echo "Apache is listening to port 80..."		
	  echo "To check if the default page “index.html” which is located in /var/www/html is displayed correctly, open the navigation with firefox http://127.0.0.1 o firefox http://localhost"
	  echo "Opening Firefox..."
	  firefox http://127.0.0.1
	else
   	  echo "Apache is not listening to port 80. Something went wrong"
    	fi 
	sleep 1
	
}

###########################################################
#         3) Crea un virtual host en el puerto 8080       #
###########################################################

function createvirtualhost()
{
	# Step 1: Create the directory that will host the website
	sudo mkdir /var/www/html/erraztest

	# Step 2: Create the configuration file for the new virtual host

	# 2.1 Use the default config and edit it afterwards
	sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/erraztest.conf

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

	# 2.2.2 Update the reference to the root directory to make sure it points to the right place
	#	regexp:\/var\/www\/html
	#	replacement: \/var\/www\/html\/erraztest
	sudo sed -i "s/\/var\/www\/html/\/var\/www\/html\/erraztest/g" /etc/apache2/sites-available/erraztest.conf

	# 2.2.3 Add a new section with some basic guidelines among which we have enabled the mod_rewrite module, necessary for rewriting urls 
	#       (see Tutorial at https://blog.ahierro.es/como-configurar-virtual-hosts-en-apache-y-ubuntu/)
	#	regexp:<\/VirtualHost>
	#	replacement: \<Directory \/var\/www\/html\/erraztest\>\nOptions Indexes FollowSymLinks MultiViews\nAllowOverride All\nOrder allow,deny\nallow from all\n<\/Directory>\n<\/VirtualHost>\n
	sudo sed -i "s/<\/VirtualHost>/\<Directory \/var\/www\/html\/erraztest\>\nOptions Indexes FollowSymLinks MultiViews\nAllowOverride All\nOrder allow,deny\nallow from all\n<\/Directory>\n<\/VirtualHost>\n/g" /etc/apache2/sites-available/erraztest.conf
	
	# Step 3: Open the proper port in Apache by editing the /etc/apache2/ports.conf file (if it is not yet opened)
	aux=$(grep "Listen 8080" /etc/apache2/ports.conf)
	if [ -z "$aux" ]
	then 
 	  echo "Open port 8080 in Apache ..."
 	  sudo sed -i "s/Listen 80/Listen 80\nListen 8080/g" /etc/apache2/ports.conf
	  echo "Port 8080 successfully opened"
	else
   	  echo "Apache is already listening to port 8080"
    	fi 
	sleep 1

	# Step 4: Enable the new virtualhost

	# 4.1 Create a symbolic link of the config in the sites-available directory in the sites-enabled directory (with a2ensite)
	sudo a2ensite erraztest.conf
	
	# 4.2 Restart Apache	
	sudo service apache2 restart
	
}

###########################################################
#         4) Testea el virtual host                       #
###########################################################

function webVirtualApacheTest()
{
	# Step 1: Copy the default page index.html located in /var/www/html into /var/www/html/erraztest.
	sudo cp /var/www/html/index.html /var/www/html/erraztest/index.html
	
	# Step 2: Check if Apache is listening to port 8080 
	puerto=$(sudo netstat -anp | grep apache| grep "0 :::8080")
	if [ ! -z "$puerto" ]
	then 
 	  echo "Apache is listening to port 8080..."		
	else
   	  echo "Apache is not listening to port 8080. Something went wrong"
    	fi 
	sleep 1

	# Step 3: To check if the default page “index.html” which is located in /var/www/html/erraztest is displayed correctly, open the navigation with "firefox http://127.0.0.1:8080 "
	echo "Opening Firefox..."
	firefox http://127.0.0.1:8080
}

###########################################################
#                     5) INSTALL PHP                      #
###########################################################

function phpInstall(){

	aux=$(aptitude show php | grep "State: installed")
	aux2=$(aptitude show php | grep "Estado: instalado")
	
	aux3=$aux$aux2
	
	
	if [ -z "$aux3" ]
	then
		echo "Installing..."
		sudo apt install php libapache2-mod-php
		sudo apt install php-cli
		sudo apt install php-cgi
		#sudo apt install php-mysql ?
		#sudo apt install php-pgsql ?
		#Verify if the files exist
		echo "Verifying files..."
		if [ ! -d /etc/apache2/mods-enabled/php7.2.conf ] && [ ! -d /etc/apache2/mods-enabled/php7.2.load ]
		then
			#Enable the module php
			a2enmod php7.2
		fi
		
		#Restart Apache2
		echo "Restarting apache..."
		sudo systemctl restart apache2.service
		
		echo "Installed"
	else
		echo "PHP is already installed"
	fi
}

###########################################################
#                     6) TEST PHP                         #
###########################################################

function phpTest(){

	echo "Creando fichero test.php..."
	sudo touch /var/www/html/erraztest/test.php
	echo "Introducimos el siguiente código:"
	echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/erraztest/test.php
	
	#test.php y index.html:
	
	#Nos aseguranmos que tienen el mismo propietario
	echo "Comprobando propietarios..."
	propietarioHTML=$(stat --format %U /var/www/html/erraztest/index.html)
	sudo chown $propietarioHTML /var/www/html/erraztest/test.php
	
	#Nos aseguramos que tienen los mismos permisos:
	echo "Comprobando permisos..."
	permisosHTML=$(stat --format %a /var/www/html/erraztest/index.html)
	sudo chmod $permisosHTML /var/www/html/erraztest/test.php
	
	#Abrimos el test.php con el navegador
	echo "Abriendo con firefox..."
	firefox http://127.0.0.1:8080/test.php
	
}

###########################################################
#            7) CREAR ENTORNO VIRTUAL PYTHON 3            #
###########################################################

function crearEntornoVirtualPython3()
{
	# Post:	This function creates a new Python3 environment in /var/www/html/erraztest
	#	This way the application is able to have its own Python library versions
	#	regardless the ones that are installed (or not) in the system


	# Install the virtualenv
	echo "Instalando el entorno virtual..."
	sudo apt-get install python-virtualenv virtualenv
	echo "Entono virtual instalado"

	# Create a new virtual environment for Python3 in the folder: /var/www/html/erraztest
	echo "creando entorno virtual en /var/www/html/erraztest/env..."
	sudo virtualenv /var/www/html/erraztest/python3envmetrix --python=python3
	echo "Entono virtual creado en /var/www/html/erraztest/env"
}


###########################################################
#      8) INSTALL PACKAGES IN THE VIRTUAL ENVIRONMENT     #
###########################################################

function instalarPaquetesEntornoVirtualPythonyAplicacion()
{
	########## INSTALL PACKAGES ##########

	# Install necesary Ubuntu packages
	echo 'Instalando pip y dos2unix'
	sudo apt install dos2unix 	# Install dos2unix
	sudo apt install python3-pip   	# Install pip
	echo 'Insalación completada'

    # Give file ownership to www-data (user and group)
    sudo chown -R www-data:www-data /var/www

	# Install python packages in the virtual env. via PIP
	# 1- Activate the virtual environment
	# 2- Install packages
	# 3- Deactivate virtualenv

	sudo su www-data -s /bin/bash <<'EOF'
	echo 'Activando el entorno virtual'
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
	sudo cp index.php /var/www/html/erraztest/
	sudo cp webprocess.sh /var/www/html/erraztest/
	sudo cp complejidadtextual.py /var/www/html/erraztest/
	sudo cp processing.gif /var/www/html/erraztest/

	# Copy english.doc.txt for test
	sudo cp -r textos /var/www/html/erraztest/

    # Give file ownership to www-data (user and group)
    sudo chown -R www-data:www-data /var/www

	echo 'Aplicación instalada correctamente'

	# Test the application as www-data user
	sudo su www-data -s /bin/bash -c /var/www/html/erraztest/webprocess.sh /var/www/html/erraztest/textos/english.doc.txt
 }


###########################################################
#               9) VISUALIZAR APLICACIÓN                  #
###########################################################

function visualizarAplicacion()
{
	firefox http://127.0.0.1:8080/index.php
}

###########################################################
#                     10) Visualizar Logs                 #
###########################################################

function viendoLogs()
{
	
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