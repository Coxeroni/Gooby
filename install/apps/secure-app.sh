#!/bin/bash

docker ps -q -f name=$APP > $TCONFIGS/checkapp
MENU="Secure App"
clear

if [ ! -s $TCONFIGS/checkapp ]; then

	NOTINSTALLED

else

	FILENAME=$APP.$MYDOMAIN
	cd $CONFIGS/Security

	# Menu Options

	NEWUSER(){
		clear
		read -p "Username to add: " USERNAME

		try_install() {
			dpkg -l "$1" | grep -q ^ii && return 1		# Package already installed
			echo
			echo Installing ${@}
			echo
			sudo apt -y install "$@"
			return 0
		}

		# Check to see if apache2-utils are installed.  If not, then install them.

		try_install apache2-utils

		echo

		if [[ -e ${FILENAME} ]]
		then							# File exists so append with new user
			echo Updating file ${FILENAME}
			echo Adding user ${USERNAME}
			htpasswd ${FILENAME} ${USERNAME}
		else							# Create file then create first user
			echo Creating file ${FILENAME}
			echo Adding user ${USERNAME}
			htpasswd -c ${FILENAME} ${USERNAME}
		fi

		cd $CURDIR
		docker stop $APP
		docker start $APP

		TASKCOMPLETE

		touch $TCONFIGS/checkapp; rm $TCONFIGS/checkapp
		PAUSE
	}

	RESTOREACCESS(){
		clear
		echo "Restoring unrestricted access to ${FILENAME}..."
		rm ${FILENAME}

		cd $CURDIR
		docker stop $APP
		docker start $APP

		TASKCOMPLETE

		touch $TCONFIGS/checkapp; rm $TCONFIGS/checkapp
		PAUSE
	}

	QUIT(){
		exit
	}

	# Display menu

	show_menus() {
		clear
		echo " ${CYAN}"
		MENUSTART

		if [ -f $FILENAME ]; then

			echo " Current users to access ${FILENAME}:"
			echo
			cat -s -n $FILENAME | cut -f1 -d":"

		else

			echo " You haven't added any passwords for ${FILENAME} yet"

		fi

		echo
		echo " ${CYAN}A${STD} - Add user to access ${FILENAME}"
		if [ -f $FILENAME ]; then echo " ${CYAN}R${STD} - Reset access to default (remove users)"; fi
		echo " ${WHITE}Z${STD} - EXIT to Main Menu"
		echo " ${CYAN}"
		MENUEND
	}

	# Read Choices

	read_options(){
		local choice
		read -n 1 -s -r -p "Choose option: " choice
		case $choice in
			[Aa]) NEWUSER ;;
			[Rr]) RESTOREACCESS ;;
			[Zz]) QUIT ;;
			*) echo "${LRED}Please select a valid option${STD}" && sleep 2
		esac
	}

	MENUFINALIZE

fi
