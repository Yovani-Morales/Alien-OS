#!/bin/bash

# Create by: Yovany Black Hat

# Colors
black="\e[0;30m"
darkGray="\e[1;30m"
red="\e[0;31m"
lightRed="\e[1;31m"
green="\e[0;32m"
lightGreen="\e[1;32m"
coffee="\e[0;33m"
yellow="\e[1;33m"
blue="\e[0;34m"
blueTwo="\e[1;34m"
purple="\e[0;35m"
lightPurple="\e[1;35m"
lightBlue="\e[0;36m"
lightBlueTwo="\e[1;36m"
gray="\e[0;37m"
white="\e[1;37m"
endColour="\033[0m\e[0m"

msg="${lightGreen}[${lightRed}*${lightGreen}]${endColour}"
msg2="${lightGreen}[${lightRed}x${lightGreen}]${endColour}"


function banner() {
	source /Alien/banners/logo.sh
}


# Function to install the necessary packages.
function install_packages() {
	banner
	echo -e "\n${msg}${lightGreen} Actualizando repositorios...${endColour}"
	apt-get update && apt-get upgrade -y


	banner
	echo -e "\n${msg}${lightGreen} Instalando sudo...${endColour}"
	apt-get install sudo -y


	banner
	echo -e "\n${msg}${lightGreen} Instalando el paquete wget...${endColour}"
	apt-get install wget -y


	banner
	echo -e "\n${msg}${lightGreen} Instalando Xfce4...${endColour}"
	apt-get install xfce4 -y
	apt-get install xfce4-terminal -y
	#apt-get install xfe -y


	banner
	echo -e "\n${msg}${lightGreen} Instalando TigerVNC...${endColour}"
	apt-get install tigervnc-standalone-server -y
	apt-get install dbus-x11 -y


	banner
	echo -e "\n${msg}${lightGreen} Todos los paquetes se instalaron correctamente.${endColour}"
	sleep 1.5
}


# Function for user creation and password assignment.
function users() {
	banner
	chmod 4755 /bin/su
	echo -e "\n${msg}${lightGreen} Establecer contraseña para Root.${endColour}"
	echo -e "${msg}${lightGreen} La contraseña se ocultara, solo ingresa y luego precione enter.\n${endColour}"
	passwd


	echo -e "\n\n${msg}${lightGreen} Creando usuario.${endColour}"
	echo -e "${msg}${lightGreen} Ingrese un nombre de usuario solo en minusculas.${endColour}"
	echo -e -n "${msg}${lightGreen} nombre de usuario${lightRed}:${green} "
	read username
	echo -e "${endColour}"


	# Almacena el nombre de usuario en la rootfs
	echo -e "$username" > "/etc/details-distro/username.txt"


	# Obtenemos el nombre de la distribución
	distro_name=`cat /etc/details-distro/distro_name.txt`
	local directory_name="distro-${distro_name}"


	echo -e "$username" > "/Alien/users/$directory_name/username.txt"
	adduser $username
	echo -e "\n${msg}${lightGreen} Añadiendo a ${username} al archivo sudoers.${endColour}"
	echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers
	sleep 1.5

}


# Function to configure vnc server.
function configure_vnc(){
	#local username=`cat /Alien/users/${distro_name}/alien_${user}.txt`
	banner
	echo -e "\n\n${msg}${lightGreen} Configurando TigerVNC...${endColour}"
	sleep 1.5

	# Elimina el archivo /etc/profile.d/alien-install.sh
	rm /etc/profile.d/alien-install.sh


	echo -e "${msg}${lightGreen} Configure una contraseña para el Servidor VNC\n${endColour}"
	su -l $username -c vncpasswd


	echo -e "\n${msg}${lightGreen} Escribiendo /home/${username}/.vnc/xstartup...${endColour}"
	cp /Alien/TigerVNC/xstartup /home/$username/.vnc/
	chmod 777 /home/$username/.vnc/xstartup
	sleep 1.5


	#Copiando el directorio vnc y el archivo xstartup.
	echo -e "${msg}${lightGreen} Escribiendo /root/.vnc/xstartup...${endColour}"
	cp -r /home/$username/.vnc/ /root
	sleep 1.5


	echo -e "${msg}${lightGreen} Escribiendo /usr/local/bin/start-vnc...${endColour}"
	cp /Alien/TigerVNC/start-vnc /usr/local/bin
	chmod +x /usr/local/bin/start-vnc
	sleep 1.5


	echo -e "${msg}${lightGreen} Escribiendo /usr/local/bin/stop-vnc...${endColour}"
	cp /Alien/TigerVNC/stop-vnc /usr/local/bin
	chmod +x /usr/local/bin/stop-vnc
	sleep 1.5


	/bin/su $username -l
}


install_packages
users
configure_vnc
