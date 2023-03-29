#!/bin/bash

#OPIS
#Skrypt do monitorowania ilosci wolnego miejsca na dysku
#Po podaniu argumentu skrypt zaproponuje dzialanie, gdy ilosc wolnego miejsca spadnie ponizej wpisanego jako argument poziomu (poziom podawany w %)
#Dostepne dzialania, to przeniesienie plikow zaproponowanych wedlug kryterium na nosnik USB typu hotswap, usuniecie zaproponowanych plikow lub anulowanie aktualnej operacji
#Mozna rowniez oczywiscie zignorowac prosbe o podjecie dzialania, ktora pojawi sie ponownie przy nastepnym skanowaniu, ktore odbywa sie co 1 min
#Skrypt monitoruje dysk ciagle, jednakze mozna go oczywiscie zatrzymac kombinacja Ctrl+C, nie powoduje to bledow w skrypcie
#Z pozyskanych przeze mnie informacji wynika, ze unix nie zawsze zapisuje date utworzenia pliku, zatem jako kryterium wyboru plików do przetwarzania wykorzystana zostala zapisywana data modyfikacji pliku
#W wiekszosci skryptu nazwy zmiennych i funkcji zostaly ustalone, tak zby zastapic potrzebne do zrozumienia komentarze i poprawic czytelnosc kodu
#Autor: Maciej Krzysztof Piasecki

#GLOBALS
wymaganeMiejsce=10 #wartosc w %
potrzebneBajty=0
bajtyDoUsuniecia=0
usbName="notset"
usbMount="notset"

#COLORCODES
RESETCOLOR='\033[0m'
BRED='\033[1;31m'
BLRED='\033[1;91m'
BLINK='\033[5m'
UNDERLINE='\033[4m'
INVERTED='\033[7m'
BLBLUE='\033[94;1m'
BLGREEN='\033[1;92m'
BLYELLOW='\033[1;93m'
BLMAGENTA='\033[1;95m'
BLCYAN='\033[1;96m'

#FUNCTIONS
function zapiszWartoscGraniczna () {
	local t=${1//%} #Wartosc argumentu 1 z usunietym symbolem "%" o ile taki zostal podany
	if [[ $t -lt 10 ]] || [[ $t -gt 100 ]]; then
		echo -e "${BRED}Wprowadzono niepoprawna wartosc graniczna do monitorowania${BLINK}!"
		echo -e "${RESETCOLOR}${BRED}Uruchom skrypt ponownie z poprawna wartoscia do monitorowania${BLINK}!${RESETCOLOR}"
		echo -e "${RESETCOLOR}${BRED}Poprawna wartosc powinna byc w przedziale ${INVERTED}<10;100> ${RESETCOLOR}${BRED}[%]${RESETCOLOR}"
		exit 1
	else
		wymaganeMiejsce=$t
	fi
}
function pobierzWolneMiejsceWProcentach () {
	echo $((100-$(df --output=pcent /home/$USER | tail -1 | cut -b -3)))
}
function pokazWolneMiejsce () {
	echo -e "${BLCYAN}${INVERTED}==================================[HD GUARD]==================================${RESETCOLOR}"
	echo -ne "${BLBLUE}Monitorowany dysk: ${BLYELLOW}"; df --output=source /home/$USER | tail -1
	echo -ne "${BLBLUE}Monitorowana partycja: ${BLYELLOW}"; df --output=file /home/$USER | tail -1
	echo -e "${BLBLUE}Wartosc graniczna: ${BLYELLOW}${wymaganeMiejsce}%"
	if [[ $(pobierzWolneMiejsceWProcentach) -lt $wymaganeMiejsce ]]; then
		echo -e "${BLBLUE}Wolne jeszcze: ${BLRED}$(pobierzWolneMiejsceWProcentach)%${RESETCOLOR}"
	else
		echo -e "${BLBLUE}Wolne jeszcze: ${BLGREEN}$(pobierzWolneMiejsceWProcentach)%${RESETCOLOR}"
	fi
}
function znajdzUSB () {
	while true; do
		local usb
		#Sprawdzenie czy podpiety jest jakis nosnik
		if [[ $(lsblk -lI 8 --output=HOTPLUG,NAME,MOUNTPOINT | awk '$1 > 0 && $3 != ""' | wc -l) -le 1 ]]; then
			echo -e "${BLMAGENTA}Nie znaleziono nosnika USB!"
			echo -e "${BLMAGENTA}Aby wybrac nosnik podlacz go do systemu i upewnij sie ze jest zamontowany, nastepnie kliknij ${BLYELLOW}ENTER"
			echo -e "${BLMAGENTA}Aby anulowac operacje nacisnij ${BLYELLOW}cokolwiek innego"
			local innerChoice
			echo -en "${BLBLUE}Twoj wybor: "
			read -n 1 innerChoice
			printf "\n"
			if [[ $? == 0 ]] && [[ $innerChoice == "" ]]; then
				continue
			else
				return 1
			fi
		fi
		#Znalezienie i obsluga 
		usb=$(lsblk -lI 8 --output=HOTPLUG,NAME,MOUNTPOINT | awk '$1 > 0 && $3 != ""' | tail -n 1)
		usbName=$(echo "$usb" | awk '{print $2}')
		usbMount=$(echo "$usb" | cut -c 14-)
		echo -e "${BLBLUE}Znaleziono nastepujacy nosnik USB: "
		echo -e "${BLBLUE}Nazwa: ${BLYELLOW}$usbName"
		echo -e "${BLBLUE}Mountpoint: ${BLYELLOW}$usbMount"
		echo -en "${BLYELLOW}Czy to na ten dysk mam przeniesc pliki? (y/n): "
		local choice
		read -n 1 choice
		printf "\n"
		if [[ $choice == "n" ]]; then
			echo -e "${BLMAGENTA}Zaproponowany nosnik odrzucony - powod: ${BLYELLOW}wybor uzytkownika"
			echo -e "${BLMAGENTA}Aby wybrac nowy nosnik wyjmij wszystkie aktualnie wlozone i podlacz inny, nastepnie kliknij ${BLYELLOW}ENTER"
			echo -e "${BLMAGENTA}Aby anulowac operacje nacisnij ${BLYELLOW}cokolwiek innego"
			local innerChoice
			echo -en "${BLBLUE}Twoj wybor: "
			read -n 1 innerChoice
			printf "\n"
			if [[ $? == 0 ]] && [[ $innerChoice == "" ]]; then
				continue
			else
				return 1
			fi
		elif [[ $choice == "y" ]]; then
			echo -e "${BLBLUE}Wybrales nosnik o parametrach: "
			echo -e "${BLBLUE}Nazwa: ${BLYELLOW}$usbName"
			echo -e "${BLBLUE}Mountpoint: ${BLYELLOW}$usbMount"
			return 0
		else
			echo -e "${BLRED}${INVERTED}Podano nieprawidlowa opcje!${RESETCOLOR}"
			echo -e "${BLMAGENTA}Zrozpoczynam szukanie USB ponownie..."
		fi
	done
}
function checkUSBSpace () {
	if [[ $(lsblk -lb --output=NAME,FSAVAIL | grep "$usbName" | awk '{print $2}') -lt $bajtyDoUsuniecia ]]; then
		echo "False"
	else
		echo "True"
	fi
}
function przeniesPlikiNaUSB () {
	local listaPlikow=$(cat "/tmp/.proponowanePlikiDoUsuniecia.txt" | tail -n +2)
	while read -r plik; do
		local nazwaPliku=$(echo "$plik" | awk 'BEGIN{FS="\t"; OFS="\t"} {print $1}')
		local sciezkaPliku=$(echo "$plik" | awk 'BEGIN{FS="\t"; OFS="\t"} {print $3}')
		echo -en "${BLCYAN}Rozpoczeto przenoszenie $nazwaPliku${BLCYAN}... ${RESETCOLOR}"
		mv "$sciezkaPliku" "$usbMount"
		if [[ $? == 0 ]]; then
			echo -e "${BLGREEN}UKONCZONO"
		else
			echo -e "${BLRED}BLAD (Kod bledu: ${INVERTED}$?${RESETCOLOR}${BLRED})${RESETCOLOR}"
		fi
	done <<< $listaPlikow
	echo -e "${BLBLUE}${INVERTED}Zakonczono przenoszenie wybranych plikow.${RESETCOLOR}"
	echo -e "${BLMAGENTA}Powracam do monitorowania...${RESETCOLOR}"
	echo -e "${BLMAGENTA}Nastepne skanowanie za ${BLYELLOW}1 min${RESETCOLOR}"
}
function przeniesNaUSB () {
	while true; do
		znajdzUSB
		#Sprawdzenie czy znaleziono USB poprawnie
		if [[ $? == 1 ]]; then
			echo -e "${BLMAGENTA}Operacja anulowana - powod: ${BLYELLOW}wybor uzytkownika"
			echo -e "${BLMAGENTA}Powracam do normalnego skanowania..."
			echo -e "${BLMAGENTA}Nastepne przypomnienie za ${BLYELLOW}1 min${RESETCOLOR}"
		else
			if [[ $(checkUSBSpace) == "False" ]]; then
				echo -e "${BRED}${INVERTED}Wybrany nosnik USB nie posiada wystarczajaco miejsca!${RESETCOLOR}"
				echo -e "${BLMAGENTA}Podepnij nowy nosnik z wystarczajaca iloscia miejsca i nacisnij ${BLYELLOW}ENTER${BLMAGENTA}, aby rozpoczac wyszukiwanie ponownie"
				echo -e "${BLMAGENTA}Aby anulowac operacje nacisnij ${BLYELLOW}cokolwiek innego"
				local innerChoice
				echo -en "${BLBLUE}Twoj wybor: "
				read -n 1 innerChoice
				printf "\n"
				if [[ $? == 0 ]] && [[ $innerChoice == "" ]]; then
					continue
				else
					echo -e "${BLMAGENTA}Operacja anulowana - powod: ${BLYELLOW}wybor uzytkownika"
					echo -e "${BLMAGENTA}Powracam do normalnego skanowania..."
					echo -e "${BLMAGENTA}Nastepne przypomnienie za ${BLYELLOW}1 min${RESETCOLOR}"
					return 1
				fi
			else
				przeniesPlikiNaUSB
				break
			fi
		fi
	done
}
function usunPliki () {
	local listaPlikow=$(cat "/tmp/.proponowanePlikiDoUsuniecia.txt" | tail -n +2)
	while read -r plik; do
		local nazwaPliku=$(echo "$plik" | awk 'BEGIN{FS="\t"; OFS="\t"} {print $1}')
		local sciezkaPliku=$(echo "$plik" | awk 'BEGIN{FS="\t"; OFS="\t"} {print $3}')
		echo -en "${BLCYAN}Rozpoczeto usuwanie $nazwaPliku${BLCYAN}... ${RESETCOLOR}"
		rm "$sciezkaPliku"
		if [[ $? == 0 ]]; then
			echo -e "${BLGREEN}UKONCZONO"
		else
			echo -e "${BLRED}BLAD (Kod bledu: ${INVERTED}$?${RESETCOLOR}${BLRED})${RESETCOLOR}"
		fi
	done <<< $listaPlikow
	echo -e "${BLBLUE}${INVERTED}Zakonczono usuwanie wybranych plikow.${RESETCOLOR}"
	echo -e "${BLMAGENTA}Powracam do monitorowania...${RESETCOLOR}"
	echo -e "${BLMAGENTA}Nastepne skanowanie za ${BLYELLOW}1 min${RESETCOLOR}"
}
function obliczPotrzebneBajty () {
	local wymaganeProcentDoZwolnienia=$((wymaganeMiejsce - $(pobierzWolneMiejsceWProcentach)))
	local ileBajtowToProcent=$(($(df -k --output=source,size /home/$USER | tail -1 | awk '{print $2}')*1024/100))
	echo $((wymaganeProcentDoZwolnienia*ileBajtowToProcent))
}
function wyswietlProponowanePliki() {
	potrzebneBajty=$(obliczPotrzebneBajty)
	local pliki=$(find /home/$USER ! -name '.*' -type f -writable -printf "%T@\t%f\t%p\t%s\t%Tx\t%TH:%TM:%TS\t%M\n" | sort -nr | grep -v '.*/\..*' | awk 'BEGIN{FS="\t"; OFS="\t"} {print $2,$4,$3}')
	bajtyDoUsuniecia=0
	echo -en "${BLYELLOW}NAZWA\tWIELKOSC\tSCIEZKA${RESETCOLOR}\n" > /tmp/.proponowanePlikiDoUsuniecia.txt
	while read -r line; do
		((bajtyDoUsuniecia += $(echo "$line" | awk 'BEGIN{FS="\t"; OFS="\t"} {print $2}')))
		if ((bajtyDoUsuniecia >= potrzebneBajty)); then
			echo "$line" >> /tmp/.proponowanePlikiDoUsuniecia.txt
			break
		else
			echo "$line" >> /tmp/.proponowanePlikiDoUsuniecia.txt
		fi
	done <<< $pliki
	echo -e "${BLBLUE}Znaleziono nastepujace pliki, ktore moga pomoc zwolnic pamiec: "
	cat "/tmp/.proponowanePlikiDoUsuniecia.txt" | column -t -s "$(printf '\t')"
}
function wyczyscPartycje () {
	echo -e "${BLBLUE}Wybrales opcje: ${BLYELLOW}czyszczenia partycji"
	wyswietlProponowanePliki
	while true; do
		echo -e "${BLBLUE}Wybierz jedna z ponizszych opcji zwolnienia pamieci wpisujac ${BLYELLOW}1 ${BLBLUE}lub ${BLYELLOW}2"
		echo -e "${BLBLUE}Ewentualnie anuluj operacje wpisujac ${BLYELLOW}3"
		echo -e "1) usun zaproponowane pliki"
		echo -e "2) przenies zaproponowane pliki na nosnik USB"
		echo -e "3) anuluj czyszczenie partycji"
		local choice
		echo -en "${BLBLUE}Twoj wybor: "
		read -n 1 choice
		printf "\n${RESETCOLOR}"
		if [[ $choice == "1" ]]; then
			usunPliki
			break
		elif [[ $choice == "2" ]]; then
			przeniesNaUSB
			break
		elif [[ $choice == "3" ]]; then
			echo -e "${BLMAGENTA}Ostrzezenie odrzucone - powod: ${BLYELLOW}uzytkownik anulowal czyszczenie partycji"
			echo -e "${BLMAGENTA}Powracam do normalnego skanowania..."
			echo -e "${BLMAGENTA}Nastepne przypomnienie za ${BLYELLOW}1 min${RESETCOLOR}"
			break
		else
			echo -e "${BLRED}${INVERTED}Wybrano nieobslugiwana opcje!"
			echo -e "${BLRED}${INVERTED}Wybierz opcje z listy!${RESETCOLOR}"
			continue
		fi
	done
	rm "/tmp/.proponowanePlikiDoUsuniecia.txt"
}
function zaproponujDzialanie () {
	echo -e "${BLRED}${INVERTED}Przekroczono monitorowana ilosc wolnego miejsca na dysku${RESETCOLOR}"
	while true; do
		echo -ne "${BLRED}${INVERTED}Czy chcesz rozpoczac czyszczenie partycji? (y/n):${RESETCOLOR}${BLRED} "
		local choice
		read -n 1 -t 60 choice
		printf "\n"
		printf "${RESETCOLOR}"
		if [[ -z "$choice" ]]; then
			echo -e "${BLMAGENTA}Ostrzezenie zignorowane - powod: ${BLYELLOW}brak wyboru opcji w okreslonym limicie czasu"
			echo -e "${BLMAGENTA}Powracam do normalnego skanowania..."
			echo -e "${BLMAGENTA}Nastepne przypomnienie za ${BLYELLOW}1 min${RESETCOLOR}"
			return 142
		elif [[ $choice == "n" ]]; then
			echo -e "${BLMAGENTA}Ostrzezenie odrzucone - powod: ${BLYELLOW}wybor uzytkownika"
			echo -e "${BLMAGENTA}Powracam do normalnego skanowania..."
			echo -e "${BLMAGENTA}Nastepne przypomnienie za ${BLYELLOW}1 min${RESETCOLOR}"
			return 1
		elif [[ $choice == "y" ]]; then
			wyczyscPartycje
			return 0
		else
			echo -e "${BLRED}${INVERTED}Wybrana opcja nie istnieje!"
			echo -e "${BLRED}${INVERTED}Wybierz opcje ponownie.${RESETCOLOR}"
			continue
		fi
	done
}

#ALGORITHM
if [[ $# -lt 1 ]]; then
	echo -e "${BRED}Uzycie: hdguard.sh <wartosc graniczna miejsca na dysku z przedzialu ${INVERTED}<10;100>${RESETCOLOR}${BRED} do monitorowania wyrazona w %>${RESETCOLOR}"
	exit 1
else
	zapiszWartoscGraniczna $1
fi
while true; do
	pokazWolneMiejsce
	if [[ $(pobierzWolneMiejsceWProcentach) -lt $wymaganeMiejsce ]]; then
		zaproponujDzialanie
	fi
	sleep 60
done
