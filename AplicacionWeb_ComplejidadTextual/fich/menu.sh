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
	cd /etc/apache2/sites-available
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
