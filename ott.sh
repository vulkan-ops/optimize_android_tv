#!/usr/bin/env bash
# Otimizações Android TV
# Por Tales A. Mendonça - talesam@gmail.com
# Agradecimento ao Bruno Gonçalvez Araujo, Rodrigo Carpes, @gr1m e Mesquita (@mickaelmendes50)
# https://developer.android.com/studio/command-line/adb
# https://adbshell.com/commands/adb-shell-pm-list-packages

# Versão do script
VER="v0.4.00"

# Definição de Cores
# Tabela de cores: https://misc.flogisoft.com/_media/bash/colors_format/256_colors_fg.png

# Cores degrade
RED001='\e[38;5;1m'		# Vermelho 1
RED009='\e[38;5;9m'		# Vermelho 9
CYA122='\e[38;5;122m'		# Ciano 122
CYA044='\e[38;5;44m'		# Ciano 44
ROX063='\e[38;5;63m'		# Roxo 63
ROX027='\e[38;5;27m'		# Roxo 27
GRE046='\e[38;5;46m'		# Verde 46
GRY247='\e[38;5;247m'		# Cinza 247
LAR208='\e[38;5;208m'		# Laranja 208
LAR214='\e[38;5;214m'		# Laranja 214
AMA226='\e[38;5;226m'		# Amarelo 226
BLU039='\e[38;5;44m'		# Azul 39
MAR094='\e[38;5;94m'		# Marrom 94
MAR136='\e[38;5;136m'		# Marrom 136

# Cores chapadas
CIN='\e[30;1m'			# Cinza
RED='\e[31;1m'			# Vermelho
GRE='\e[32;1m'			# Verde
YEL='\e[33;1m'			# Amarelo
BLU='\e[34;1m'			# Azul
ROS='\e[35;1m'			# Rosa
CYA='\e[36;1m'			# Ciano
NEG='\e[37;1m'			# Negrito
CUI='\e[40;31;5m'		# Vermelho pisacando, aviso!
STD='\e[m'			# Fechamento de cor

# --- Início Funções ---

# Separação com cor
separacao(){
	for i in {16..21} {21..16} ; do
		echo -en "\e[38;5;${i}m____\e[0m"
	done ; echo
}

# Função pause
pause(){
   read -p "$*"
}

# Verifica se está usando Termux
termux(){
	clear
	echo -e " ${NEG}Bem vindo(a) ao script OTT (Otimização TV TCL)${STD}"
	echo -e " ${NEG}Modelos compatíveis: RT51, RT41 e R51M.${STD}"
	separacao
	echo ""
	echo -e " ${BLU}*${STD} ${NEG}Baixando dependências para utilizar o script no Termux...${SDT}" && sleep 2
	pkg update -y -o Dpkg::Options::=--force-confold
	pkg install -y ncurses && pkg install -y android-tools && pkg install -y wget && pkg install -y fakeroot && clear
	if [ "$?" -eq "0" ]; then
		echo ""
		echo -e " ${GRE}*${STD} ${NEG}Instalação conluida com sucesso!${STD}"
		echo ""
		pause " Tecle [Enter] para se conectar a TV..." ; conectar_tv
	else
		echo ""
		echo -e " ${RED}*${STD} ${NEG}Erro ao baixar e instalar as dependências.\n Verifique sua conexão e tente novamente.${STD}" ; exit 0
	fi
}

# Conexão da TV
conectar_tv(){
	clear
	export ANDROID_NO_USE_FWMARK_CLIENT=1
	echo " Digite o endereço IP da sua TV que encontra no"
	echo -e " caminho abaixo e tecle ${NEG}[Enter]${STD} para continuar:"
	echo ""
	echo -e " ${AMA226}Configurações${STD}, ${AMA226}Preferências do dispositivo${STD},"
	echo -e " ${AMA226}Sobre${STD}, ${AMA226}Status${STD}."
	echo ""
	read IP

	ping -c 1 $IP >/dev/null
	# Testa se a TV está ligada com o modo depuração ativo
	if [ "$?" -eq "0" ]; then
		echo ""
		echo -e " ${LAR214}Conectando-se a sua TV...${STD}" && sleep 3
		fakeroot adb connect $IP >/dev/null
		if [ "$?" -eq "0" ]; then
			echo -e " ${GRE046}Conectado com sucesso a TV!${STD}" && sleep 3
			echo ""
			clear
			until fakeroot adb shell pm list packages -e 2>/dev/null; do
			#clear
				echo -e " ${CYA122}Apareceu a seguinte janela em sua TV:${STD}"
				echo -e " ${NEG}Permitir a depuração USB?${STD}"
				echo ""
				echo -e " ${CYA122}Marque a seguinte caixa:${STD}"
				echo -e " ${ROS}Sempre permitir a partir deste computador${STD}"
				echo -e " ${CYA122}Depois de marcar a caixa e der${STD} ${NEG}OK${STD}"
				echo ""
				pause " Tecle [Enter] para continuar..." ;
				# Testa se o humano marcou a opção na TV			
				fakeroot adb disconnect $IP 2>/dev/null && fakeroot adb connect $IP 2>/dev/null
				if [ "$(fakeroot adb connect $IP | cut -f1,2 -d" ")" = "already connected" ]; then
					menu_principal
				else
					echo ""
					echo -e " ${CYA}Não me engana, você ainda\n não marcou a opção na TV :-(\n Vou te dar outra chance!${STD}"
					echo ""
					pause " Ative a opção e tecle [Enter]"
				fi
			done
				menu_principal
		else
			echo -e " ${RED}*${STD} ${NEG}Erro! Falha na conexão, Verifique seu endereço de IP${STD}"
			pause " Tecle [Enter] para tentar novamente..." ; conectar_tv
		fi
	else
			echo -e " ${RED}*${STD} ${NEG}Erro! Falha na conexão, Verifique seu endereço de IP${STD}"
			pause " Tecle [Enter] para tentar novamente..." ; conectar_tv
	fi
}

# Remover apps RT51
rm_apps_rt51(){
	clear
	OIFS=$IFS
	IFS=$'\n'
	# Verifica se o arquivo existe
	if [ -e "rm_apps_rt51.list" ]; then
		for app_rm in $(cat rm_apps_rt51.list); do
			fakeroot adb shell pm disable-user --user 0 $app_rm >/dev/null
			if [ "$?" -eq "0" ]; then
				echo -e " ${BLU}*${STD} App ${CYA}$app_rm${STD} ${GRE046}desativado com sucesso!${STD}" && sleep 1
			else
				echo -e " ${RED}*${STD} App ${CYA}$app_rm${STD} já foi desativado ou não existe" && sleep 1
			fi
		done
	else
		# Baixar lista lixo dos apps
		echo -e " ${BLU}*${STD} ${NEG}Aguarde, baixando lista negra de apps...${STD}" && sleep 2
		wget https://raw.githubusercontent.com/mickaelmendes50/optimize_android_tv/master/apps-list/rm_apps_rt51.list && clear
		if [ -e "rm_apps_rt51.list" ]; then
			for app_rm in $(cat rm_apps_rt51.list); do
				fakeroot adb shell pm uninstall --user 0 $app_rm >/dev/null
				if [ "$?" -eq "0" ]; then
					echo -e " ${BLU}*${STD} App ${CYA}$app_rm${STD} ${GRE046}desativado com sucesso!${STD}" && sleep 1
				else
					echo -e " ${RED}*${STD} App ${CYA}$app_rm${STD} já foi desativado ou não existe" && sleep 1
				fi
			done
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro ao baixar a lista LIXO dos apps. Verifique sua conexão.${STD}"
			echo ""
		fi
	fi
	# Verifica se o arquivo existe
	if [ -e "rm_apps_rt51-uninstall.list" ]; then
		for app_rm in $(cat rm_apps_rt51-uninstall.list); do
			fakeroot adb shell pm uninstall --user 0 $app_rm >/dev/null
			if [ "$?" -eq "0" ]; then
				echo -e " ${BLU}*${STD} App ${CYA}$app_rm${STD} ${GRE046}removido com sucesso!${STD}" && sleep 1
			else
				echo -e " ${RED}*${STD} App ${CYA}$app_rm${STD} já foi removido ou não existe" && sleep 1
			fi
		done
	else
		# Baixar lista lixo dos apps
		echo -e " ${BLU}*${STD} ${NEG}Aguarde, baixando lista negra de apps...${STD}" && sleep 2
		wget https://raw.githubusercontent.com/mickaelmendes50/optimize_android_tv/master/apps-list/rm_apps_rt51-uninstall.list && clear
		if [ -e "rm_apps_rt51-uninstall.list" ]; then
			for app_rm in $(cat rm_apps_rt51-uninstall.list); do
				fakeroot adb shell pm uninstall --user 0 $app_rm >/dev/null
				if [ "$?" -eq "0" ]; then
					echo -e " ${BLU}*${STD} App ${CYA}$app_rm${STD} ${GRE046}removido com sucesso!${STD}" && sleep 1
				else
					echo -e " ${RED}*${STD} App ${CYA}$app_rm${STD} já foi removido ou não existe" && sleep 1
				fi
			done
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro ao baixar a lista LIXO dos apps. Verifique sua conexão.${STD}"
			echo ""
		fi
	fi
	echo ""
	pause " Tecle [Enter] para retornar ao menu principal..." ; menu_principal
IFS=$OIFS
}

# Remover apps RT41, R51M
rm_apps_rt41(){
	clear
	OIFS=$IFS
	IFS=$'\n'
	# Verifica se o arquivo existe
	if [ -e "rm_apps_rt41.list" ]; then
		for app_rm in $(cat rm_apps_rt41.list); do
			fakeroot adb shell pm uninstall --user 0 $app_rm >/dev/null
			if [ "$?" -eq "0" ]; then
				echo -e " ${BLU}*${STD} App ${CYA}$app_rm${STD} ${GRE046}removido com sucesso!${STD}" && sleep 1
			else
				echo -e " ${RED}*${STD} App ${CYA}$app_rm${STD} já foi removido ou não existe" && sleep 1
			fi
		done
	else
		# Baixar lista lixo dos apps
		echo -e " ${BLU}*${STD} ${NEG}Aguarde, baixando lista negra de apps...${STD}" && sleep 2
		wget https://raw.githubusercontent.com/mickaelmendes50/optimize_android_tv/master/apps-list/rm_apps_rt41.list && clear
		if [ -e "rm_apps_rt41.list" ]; then
			for app_rm in $(cat rm_apps_rt41.list); do
				fakeroot adb shell pm uninstall --user 0 $app_rm >/dev/null
				if [ "$?" -eq "0" ]; then
					echo -e " ${BLU}*${STD} App ${CYA}$app_rm${STD} ${GRE046}removido com sucesso!${STD}" && sleep 1
				else
					echo -e " ${RED}*${STD} App ${CYA}$app_rm${STD} já foi removido ou não existe" && sleep 1
				fi
			done
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro ao baixar a lista LIXO dos apps. Verifique sua conexão.${STD}"
			echo ""
		fi
	fi
	echo ""
	pause " Tecle [Enter] para retornar ao menu principal..." ; menu_principal
IFS=$OIFS
}

# Desativar/Ativar Apps - INICIO
COLS=$(tput cols)

enableApps() {
	tput clear
	
	OIFS=$IFS
	IFS=$'\n'
	
	apk_disabled="$(fakeroot adb shell pm list packages -d | cut -f2 -d:)"
	# Baixar lista de apps para serem desativados
	echo ""
	echo -e " ${BLU}*${STD} ${NEG}Aguarde, baixando lista de apps...${STD}" && sleep 1
	wget https://raw.githubusercontent.com/mickaelmendes50/optimize_android_tv/master/apps-list/apps_disable.list
	if [ -e "apps_disable.list" ]; then
		for apk_full in $(cat apps_disable.list); do
			apk="$(echo "$apk_full" | cut -f1 -d"|")"
			apk_desc="$(echo "$apk_full" | cut -f2 -d"|")"
			if [ "$(echo "$apk_disabled" | grep "$apk")" = "" ]; then
				echo -e "\n$(linha)\n"${NEG}" $apk_desc"${STD}"\n\"$apk\"\n Digite ${GRE046}S${STD}(Sim) para ${GRE046}ATIVAR${STD} ou ${GRY247}N${STD}(Não) para manter ${GRY247}DESATIVADO${STD}"
				pergunta_ativar
			fi
		done
	else
		echo ""
		echo -e " ${RED}*${STD} ${NEG}Erro ao baixar a lista de apps. Verifique sua conexão.${STD}"
		echo ""
		pause " Tecle [Enter] para retornar ao menu principal..." ; menu_principal
	fi
	IFS=$OIFS
}

pergunta_ativar() {
	read -p " [S/N]: " -e -n1 resposta
	echo -e "$(linha)\n"
	[[ $resposta != +(s|S|n|N) ]] && pergunta_ativar || resposta_ativar
}

resposta_ativar() {
	[[ "$resposta" =~ ^([Ss])$ ]] && { echo -e ""${LAR208}"Informação sobre o pacote${STD} ${CYA044}${apk}${STD}";fakeroot adb shell pm enable ${apk};}
}

disableApps() {
	tput clear
	
	OIFS=$IFS
	IFS=$'\n'
	
	apk_disabled="$(fakeroot adb shell pm list packages -d | cut -f2 -d:)"
	# Baixar lista de apps para serem desativados
	echo ""
	echo -e " ${BLU}*${STD} ${NEG}Aguarde, baixando lista de apps...${STD}" && sleep 1
	wget https://raw.githubusercontent.com/mickaelmendes50/optimize_android_tv/master/apps-list/apps_disable.list -O "apps_disable.list"
	if [ -e "apps_disable.list" ]; then
		for apk_full in $(cat apps_disable.list); do
			apk="$(echo "$apk_full" | cut -f1 -d"|")"
			apk_desc="$(echo "$apk_full" | cut -f2 -d"|")"
			if [ "$(echo "$apk_disabled" | grep "$apk")" = "" ]; then
				echo -e "\n$(linha)\n"${NEG}" $apk_desc"${STD}"\n\"$apk\"\n Digite ${GRY247}S${STD}(Sim) para ${GRY247}DESATIVAR${STD} ou ${GRE046}N${STD}(Não) para manter ${GRE046}ATIVO${STD}"
				pergunta_desativar
			fi
		done
	else
		echo ""
		echo -e " ${RED}*${STD} ${NEG}Erro ao baixar a lista de apps. Verifique sua conexão.${STD}"
		echo ""
		pause " Tecle [Enter] para retornar ao menu principal..." ; menu_principal
	fi
	IFS=$OIFS
}

pergunta_desativar() {
	read -p " [S/N]: " -e -n1 resposta
	echo -e "$(linha)\n"
	[[ $resposta != +(s|S|n|N) ]] && pergunta_desativar || resposta_desativar
}

resposta_desativar() {
	[[ "$resposta" =~ ^([Ss])$ ]] && { echo -e ""${LAR208}"Informação sobre o pacote${STD} ${CYA044}${apk}${STD}";fakeroot adb shell pm disable-user --user 0 ${apk};}
}

linha() {
	printf '%*s' "$COLS" '' | sed "s/ /_/g"
}
# Desativar/Ativar Apps - FIM

# Instalar Launcher Customizado
install_CustomLauncher() {
    echo ""
    echo -e " ${BLU}*${STD} ${NEG}Aguarde a instalação do ${1}...${STD}" && sleep 2

    # Baixa o Launcher selecionado (verificar versão no commit de upload mais recente)
    echo ""
    echo -e " ${BLU}*${STD} ${NEG}Baixando o ${1}...${STD}" && sleep 1
    wget "https://github.com/mickaelmendes50/optimize_android_tv/raw/master/prebuilt/${1}.apk" -O "${1}.apk"

    if [ "$?" -ne 0 ]; then
        pause " Erro ao baixar os arquivos, verifique a sua conexão. [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
    else
        # Instala o Launcher usando ADB
        echo ""
        echo -e " ${BLU}*${STD} ${NEG}Instalando ${1}...${STD}" && sleep 1
        fakeroot adb install -r "${1}.apk"

        if [ "$?" -eq "0" ]; then
            echo ""
            echo -e " ${GRE}*${STD} ${NEG}${1} instalado com sucesso!${STD}"

            # Ativando o Launcher
            echo ""
            echo -e " ${BLU}*${STD} ${NEG}Ativando o novo Launcher, aguarde...${STD}" && sleep 1

            fakeroot adb shell pm enable "${2}"
            if [ "$(fakeroot adb shell pm enable "${2}" | grep enable | cut -f5 -d " ")" = "enabled" ]; then
                echo ""
                echo -e " ${GRE}*${STD} ${NEG}${1} Home ativado com sucesso!${STD}"

                # Desativa o Launcher padrão
                echo ""
                echo -e " ${BLU}*${STD} ${NEG}Desativando launcher padrão...${STD}" && sleep 1
                fakeroot adb shell pm disable-user --user 0 com.google.android.tvlauncher
                if [ "$(fakeroot adb shell pm disable-user --user 0 com.google.android.tvlauncher | grep disabled-user | cut -f5 -d " ")" = "disabled-user" ]; then
                    echo ""
                    echo -e " ${GRE}*${STD} ${NEG}Launcher padrão desativado com sucesso!${STD}" && sleep 2
                else
                    pause " Falha ao desativar o launcher padrão, verifique a sua conexão. [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
                fi
            else
                pause " Falha ao ativar o ${1}, verifique a sua conexão. [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
            fi
        else
	    pause " Erro ao instalar o ${1}, verifique a sua conexão. [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
        fi
    fi
    pause " Tecle [Enter] para retornar ao menu." ; menu_InstallCustomLauncher "${1}" "${2}"
}

# Instalar e ativar Launcher ATV Pro TCL Mod + Widget
install_launcher(){
	# Remove versão do ATV PRO
	if [ "$(fakeroot adb shell pm list packages -u | cut -f2 -d: | grep ca.dstudio.atvlauncher.pro)" != "" ]; then
		echo ""
		echo -e " ${BLU}*${STD} ${NEG}Removendo versão do Launcher ATV PRO...${STD}" && sleep 1
		echo ""
		fakeroot adb shell pm uninstall --user 0 ca.dstudio.atvlauncher.pro
		if [ "$?" -eq "0" ]; then
			echo -e " ${GRE}*${STD} ${NEG}Launcher ATV PRO removido com sucesso!${STD}"
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro ao remover Launcher ATV PRO.${STD}"
			pause " Tecle [Enter] para continuar com a instalação..."
		fi
	fi

	# Remove versão do ATV FREE
	if [ "$(fakeroot adb shell pm list packages -u | cut -f2 -d: | grep ca.dstudio.atvlauncher.pro)" != "" ]; then
		echo ""
		echo -e " ${BLU}*${STD} ${NEG}Removendo versão do Launcher ATV FRE...${STD}" && sleep 1
		echo ""
		fakeroot adb shell pm uninstall --user 0 ca.dstudio.atvlauncher.free
		if [ "$?" -eq "0" ]; then
			echo -e " ${GRE}*${STD} ${NEG}Launcher ATV FREE removido com sucesso!${STD}"
		else
			echo -e " ${RED}*${STD} ${NEG}Erro ao remover Launcher ATV FREE.${STD}"
			pause " Tecle [Enter] para continuar com a instalação..."
		fi
	fi

	if [ "$(fakeroot adb shell pm list packages -u | cut -f2 -d: | grep com.tcl.home)" != "" ]; then
		if [ "$(fakeroot adb shell pm list packages -e | cut -f2 -d: | grep com.tcl.home)" = "" ]; then
			echo ""
			echo -e " ${BLU}*${STD} ${NEG}Ativando Launcher ATV PRO MOD...${STD}" && sleep 1
			fakeroot adb shell pm enable com.tcl.home
			if [ "$?" -eq "0" ]; then
				# Desativa o Launcher padrão
				fakeroot adb shell pm disable-user --user 0 com.google.android.tvlauncher
				if [ "$(fakeroot adb shell pm disable-user --user 0 com.google.android.tvlauncher | grep disabled-user | cut -f5 -d " ")" = "disabled-user" ]; then
					echo ""
					echo -e " ${GRE}*${STD} ${NEG}Launcher ATV PRO MOD ativo com sucesso!${STD}"
					echo ""
					echo -e " ${BLU}*${STD} ${NEG}Iniciando a nova Launcher ATV PRO MOD, aguarde...${STD}" && sleep 1
					fakeroot adb shell monkey -p com.tcl.home -c android.intent.category.LAUNCHER 1
					if [ "$?" -eq "0" ]; then
						echo ""
						echo -e " ${GRE}*${STD} ${NEG}Launcher ATV PRO MOD iniciado com sucesso!${STD}" && sleep 1
						echo ""
						echo -e " ${BLU}*${STD} ${NEG}Atualizando as permissões...${STD}"
						# Seta permissão para o widget
						fakeroot adb shell appwidget grantbind --package com.tcl.home --user 0
						if [ "$?" -eq "0" ]; then
							echo ""
							echo -e " ${GRE}*${STD} ${NEG}Permissões atualizadas com sucesso!${STD}"
						else
							pause " Erro ao ativar o Launcher, verifique sua conexão. Tecle [Enter] para continuar." ; menu_launcher
						fi
					else
						pause " Erro ao ativar o Launcher, verifique sua conexão. Tecle [Enter] para continuar." ; menu_launcher
					fi
				else
					pause " Erro ao ativar o Launcher, verifique sua conexão. Tecle [Enter] para continuar." ; menu_launcher
				fi
			else
				pause " Erro ao ativar Launcher ATV MOD. Tecle [Enter] para retornar ao menu" ; menu_launcher
			fi
		else
			echo ""
			echo -e " ${BLU}*${STD} ${NEG}Launcher ATV PRO MOD já está ativo.${STD}"
			pause " Tecle [Enter] para retornar ao menu" ; menu_launcher
		fi
	else
		echo ""
		echo -e " ${BLU}*${STD} ${NEG}Aguarde a instalação do novo Launcher ATV PRO MOD...${STD}" && sleep 2
		# Baixa o Launcher ATV PRO modificado e o Widget
		echo ""
		echo -e " ${BLU}*${STD} ${NEG}Baixando a versão mais recente do Launcher ATV PRO MOD e Widget...${STD}"
		wget https://cloud.talesam.org/s/YJ4st8xrbYAr5cD/download/tclhome.apk
		wget https://cloud.talesam.org/s/5c33tAF8ddyeXm7/download/chronus.apk && clear
		
		if [ "$?" -ne 0 ]; then
			pause " Erro ao baixar os arquivos, verifique a sua conexão. [Enter] para retornar ao menu" ; menu_launcher
		else
			echo ""
			echo -e " ${BLU}*${STD} ${NEG}Instalando o novo Launcher, aguarde...${STD}" && sleep 1
			fakeroot adb install -r tclhome.apk
			fakeroot adb install -r chronus.apk
			#if [ "$(fakeroot adb install -r tclhome.apk | grep "Success")" = "Success" && "$(fakeroot adb install -r chronus.apk | grep "Success")" = "Success" ]; then
			if [ "$?" -eq "0" ]; then
				echo ""
				echo -e " ${GRE}*${STD} ${NEG}Launcher ATV PRO MOD instalado com sucesso!${STD}"
				echo ""
				echo -e " ${BLU}*${STD} ${NEG}Ativando o novo Launcher, aguarde...${STD}" && sleep 1
				# Desativa o Launcher padrão
				fakeroot adb shell pm disable-user --user 0 com.google.android.tvlauncher
				if [ "$(fakeroot adb shell pm disable-user --user 0 com.google.android.tvlauncher | grep disabled-user | cut -f5 -d " ")" = "disabled-user" ]; then
					echo "Launcher ATV PRO MOD ativo com sucesso!"
					echo "Ativando a nova Launcher ATV PRO MOD..." && sleep 2
					fakeroot adb shell monkey -p com.tcl.home -c android.intent.category.LAUNCHER 1
					if [ "$?" -eq "0" ]; then
						echo ""
						echo -e " ${GRE}*${STD} ${NEG}Launcher ATV PRO MOD ativado com sucesso!${STD}"
						echo ""
						echo -e " ${BLU}*${STD} ${NEG}Abrindo Launcher ATV PRO MOD...${STD}" && sleep 1
					else
						pause " Erro ao ativar o Launcher ATV PRO, verifique sua conexão. Tecle [Enter] para continuar." ; menu_launcher
					fi
				else
					pause " Erro ao ativar o Launcher ATV PRO, verifique sua conexão. Tecle [Enter] para continuar." ; menu_launcher
				fi
				echo ""
				echo -e " ${BLU}*${STD} ${NEG}Atualizando as permissões...${STD}" && sleep 1
				# Seta permissão para o widget
				fakeroot adb shell appwidget grantbind --package com.tcl.home --user 0
				if [ "$?" -ne "0" ]; then
					pause " Erro ao setar permissões, verifique sua conexão. Tecle [Enter] para continuar." ; menu_launcher
				else
					echo -e " ${GRE}*${STD} ${NEG}Permissões atualizadas com sucesso!${STD}"
				fi
			else
				pause " Erro na instalação.. Tecle [Enter] para continuar." ; menu_launcher
			fi
		fi
	fi
	pause " Tecle [Enter] para retornar ao menu." ; menu_launcher
}

# Desativar o Launcher Customizado
disable_CustomLauncher(){

	if [ "$(fakeroot adb shell pm list packages -e | cut -f2 -d: | grep ${2})" != "" ]; then
		echo ""
		echo -e " ${GRE}*${STD} ${NEG}Ativando Launcher Padrão...${STD}" && sleep 2
		echo ""
		fakeroot adb shell pm enable com.google.android.tvlauncher
		if [ "$?" -eq "0" ]; then
			echo ""
			echo -e " ${CIN}*${STD} ${NEG}Desinstalando ${1}...${STD}" && sleep 2
			echo ""
			fakeroot adb shell pm uninstall --user 0 "${2}"
			if [ "$?" -eq "0" ]; then
				echo ""
				echo -e " ${CIN}*${STD} ${NEG}${1} desinstalado com sucesso!${STD}" && sleep 1
				echo ""
			else
				pause " Erro ao desinstalar o ${1}, verifique sua conexão. Tecle [Enter] para continuar." ; menu_InstallCustomLauncher "${1}" "${2}"
			fi
			fakeroot adb shell am start -n com.google.android.tvlauncher/.MainActivity
			if [ "$?" -eq "0" ]; then
				echo ""
				echo -e " ${GRE}*${STD} ${NEG}Configurado o Launcher padrão da Android TV com sucesso!${STD}"
				echo ""
			else
				echo ""
				echo -e " ${RED}*${STD} ${NEG}Erro abrir o Launcher padrão, verifique sua conexão.${STD}"
				echo ""
				pause " Tecle [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
			fi
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro ao desativar ${1}.${STD}"
			echo ""
			pause " Tecle [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
		fi
	else
		echo ""
		echo -e " ${ROS}*${STD} ${NEG}${1} ainda não instalado.${STD}"
		echo ""
	fi
	pause " Tecle [Enter] para retornar ao menu" ; menu_InstallCustomLauncher "${1}" "${2}"
}

# Instalar apps
install_App() {
	# Baixa o App
	echo ""
	echo -e " ${BLU}*${STD} ${NEG}Baixando o ${1}...${STD}" && sleep 1
	wget https://github.com/mickaelmendes50/optimize_android_tv/raw/master/prebuilt/"${1}".apk && clear
	if [ "$?" -ne 0 ]; then
		echo ""
		echo -e " ${RED}*${STD} ${NEG}Erro ao baixar o arquivo. Verifique sua conexão ou tente mais tarde.${STD}"
	else
		echo ""
		echo -e " ${BLU}*${STD} ${NEG}Instalando o ${1}, aguarde...${STD}"
		fakeroot adb install -r "${1}.apk"
		if [ "$?" -eq "0" ]; then
			echo ""
			echo -e " ${GRE}*${STD} ${NEG}${1} instalado com sucesso!${STD}"
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro na instalação.${STD}"
		fi
	fi
	pause "Tecle [Enter] para retonar ao menu" ; menu_InstallApps
}

# Gravação de tela
gravar_tela(){
	clear
	echo -e "${NEG}Gravação de tela da TV - *EXPERIMENTAL*${STD}"
	separacao
	echo ""
	echo -e " ${LAR214}Bem vindo a gravação de Tela da TV, esse${STD}"
	echo -e " ${LAR214}recurso é limitado a 3 minutos de gravação,${STD}"
	echo -e " ${LAR214}porém após terminar uma gravação outra se${STD}"
	echo -e " ${LAR214}inicia automaticamnte em outro arquivo com${STD}"
	echo -e " ${LAR214}mesmo nome, altera apenas o final, por exemplo:${STD}"
	echo -e " ${LAR214}gravacao-001.mp4, gravacao-002.mp4.${STD}"
	echo ""
	echo -e " Para parar a gravação tecle ${NEG}[CTRL + C]${STD}"
	echo ""
	# Testa se o diretório já existe, senão cria
	CAMINHO="/sdcard/ADB\ Recording"
	fakeroot adb shell mkdir -p $CAMINHO
	echo -e " ${NEG}O arquivo será gravado em:${STD}"
	echo -e " ${ROS}$CAMINHO${STD}"
	echo ""
	echo -e " ${ROX063}Digite um nome para o seu arquivo${STD}"
	echo " e tecle [Enter] para começar a gravar:"
	echo ""
	read REC
	for i in {000..999}; do
		echo -e " ${BLU}*${STD} ${NEG}Gravando vídeo $REC-${i}.mp4 ...${STD}"
		fakeroot adb shell screenrecord --bit-rate 100000000 --size 1280x720 "$CAMINHO/$REC-${i}.mp4"
		if [ "$?" -eq "0" ]; then
			echo ""
			echo -e " ${GRE}*${STD} ${NEG}Vídeo $REC-${i}.mp4 gravado com sucesso!${STD}"
		else
			echo ""
			echo -e " ${RED}*${STD} ${NEG}Erro ao gravar vídeo. Verifique sua conexão.${STD}"
			echo ""
			pause "Tecle enter [Enter] para retornar ao menu Principal." ; menu_principal
		fi
	done
}

# --- MENU ---
# Menu principal
menu_principal(){
	clear
	option=0
	until [ "$option" = "6" ]; do
		echo ""
		echo -e " ${CYA}OTMIZAÇÃO TV TCL PLATAFORMAS: RT41, RT51 e R51M ${STD}"
		echo -e " ${YEL}$VER${STD}"

		# Verifica o Status da TV, se está conectada ou não via ADB
		ping -c 1 $IP >/dev/null 2>&1
		if [ "$?" -ne 0 ]; then
			echo -e " ${NEG}Status:${STD} ${RED}Desconectado${STD} ${NEG}via adb${STD}"
		else
			if [ "$(fakeroot adb connect $IP | cut -f1 -d" " | grep -e connected -e already)" != "" ]; then
				echo -e " ${NEG}Status:${STD} ${GRE}Conectado${STD} ${NEG}via adb${STD}"
			else
				echo -e " ${NEG}Status:${STD} ${RED}Desconectado${STD} ${NEG}via adb.${STD}"
			fi
		fi
		echo ""
		echo -e " ${GRY247}Este script possui a finalidade de otimizar${STD}"
		echo -e " ${GRY247}o sistema Android TV, removendo e desativando${STD}"
		echo -e " ${GRY247}alguns apps e instalando outros.${STD}"
		echo ""
		echo ""
		echo -e " ${YEL}FAÇA UMA DOAÇÃO E AJUDE ESTE PROJETO!${STD}"
		echo -e " ${BLU}PIX:${STD} ${ROS}talesam@gmail.com (Tales)${STD}"
		echo -e " ${BLU}PIX:${STD} ${ROS}mesquita@aospa.co (Mesquita)${STD}"
		echo ""
		echo ""
		echo -e " ${BLU}1.${STD} ${RED009}Remover apps lixo (RT51)${STD}"
		echo -e " ${BLU}2.${STD} ${RED009}Remover apps lixo (RT41)${STD}"
		echo -e " ${BLU}3.${STD} ${GRY247}Desativar${STD}/${GRE046}Ativar apps${STD}"
		echo -e " ${BLU}4.${STD} ${BLU039}Instalar Launcher${STD}"
		echo -e " ${BLU}5.${STD} ${GRE046}Instalar novos apps${STD}"
		echo -e " ${BLU}6.${STD} ${AMA226}Gravar Tela da TV${STD} ${NEG}*EXPERIMENTAL*${STD}"
		echo -e " ${BLU}0.${STD} ${RED}Sair${STD}"
		echo ""
		read -p " Digite um número e tecle [Enter]: " option
		case "$option" in
			1 ) rm_apps_rt51 ;;
			2 ) rm_apps_rt41 ;;
			3 ) menu_EnableDisableApps ;;
			4 ) menu_SelectCustomLauncher ;;
			5 ) menu_InstallApps ;;
			6 ) gravar_tela ;;
			0 ) exit ; fakeroot adb disconnect $IP >/dev/null ;;
			* ) clear; echo -e " ${NEG}Por favor escolha${STD} ${ROS}1${STD}${NEG},${STD} ${ROS}2${STD}${NEG},${STD} ${ROS}3${STD}${NEG},${STD} ${ROS}4${STD}${NEG},${STD} ${ROS}5${STD},${STD} ${ROS}6${STD} ${NEG}ou${STD} ${ROS}0 para Sair${STD}"; 
		esac
	done
}

# Menu ativar/desativar apps
menu_EnableDisableApps() { 
	clear
	option=0
	until [ "$option" = "3" ]; do
		separacao
		echo -e " ${ROX027}Ativar e Desativar Apps${STD}"
		separacao
		echo ""
		echo -e " ${BLU}1.${STD} ${GRY247}Desativar apps${STD}"
		echo -e " ${BLU}2.${STD} ${GRE046}Ativar apps${STD}"
		echo -e " ${BLU}3.${STD} ${ROX063}Retornar ao Menu Principal${STD}"
		echo ""
		read -p " Digite um número:" option
		case $option in
			1 ) disableApps ;;
			2 ) enableApps ;;
			3 ) menu_principal ;;
			* ) clear; echo -e " ${NEG}Por favor escolha${STD} ${ROS}1${STD}${NEG},${STD} ${ROS}2${STD}${NEG},${STD} ${NEG}ou${STD} ${ROS}3${STD}${NEG}";
		esac
	done
}

# Menu Instalar e ativar/desativar Launcher ATV PRO MOD
menu_launcher(){ 
	clear
	option=0
	until [ "$option" = "3" ]; do
		separacao
		echo -e " ${ROX027}Launcher ATV PRO MOD${STD}"
		separacao
		echo ""
		echo -e " ${BLU}1.${STD} ${GRE046}Instalar e ativar Launcher${STD}"
		echo -e " ${BLU}2.${STD} ${GRY247}Desativar Launcher${STD}"
		echo -e " ${BLU}3.${STD} ${ROX063}Retornar ao Menu Principal${STD}"
		echo ""
		read -p " Digite um número:" option
		case $option in
			1 ) install_launcher ;;
			2 ) disable_CustomLauncher "ATV Pro MOD" "com.tcl.home";;
			3 ) menu_principal ;;
			* ) clear; echo -e " ${NEG}Por favor escolha${STD} ${ROS}1${STD}${NEG},${STD} ${ROS}2${STD}${NEG},${STD} ${NEG}ou${STD} ${ROS}3${STD}${NEG}";
		esac
	done
}

menu_SelectCustomLauncher() { 
	clear
	option=0
	until [ "$option" = "4" ]; do
		separacao
		echo -e " ${ROX027}Escolha o Launcher${STD}"
		separacao
		echo ""
		echo -e " ${BLU}1.${STD} ${BLU039}Launcher ATV Pro TCL Mod + Widget${STD}"
		echo -e " ${BLU}2.${STD} ${BLU039}GoogleTV${STD}"
		echo -e " ${BLU}3.${STD} ${BLU039}FLauncher${STD}"
		echo -e " ${BLU}4.${STD} ${BLU039}WolfLauncher${STD}"
		echo -e " ${BLU}0.${STD} ${ROX063}Retornar ao Menu Principal${STD}"
		echo ""
		read -p " Digite um número: " option
		case $option in
			1 ) menu_launcher;;
			2 ) ANDROID_VERSION=`fakeroot adb shell getprop ro.build.version.release`
				if [ "${ANDROID_VERSION}" -eq "9" ]; then
					menu_InstallCustomLauncher "GoogleTV-A9" "com.google.android.apps.tv.launcherx"
				else
					menu_InstallCustomLauncher "GoogleTV" "com.google.android.apps.tv.launcherx"
				fi;;
			3 ) menu_InstallCustomLauncher "FLauncher" "me.efesser.flauncher";;
			4 ) menu_InstallCustomLauncher "WolfLauncher" "com.wolf.firelauncher";;
			0 ) menu_principal ;;
			* ) clear; echo -e " ${NEG}Por favor escolha${STD} ${ROS}1${STD}${NEG}${STD} ${NEG}ou${STD} ${ROS}3${STD}${NEG}";
		esac
	done
}

menu_InstallCustomLauncher() { 
	clear
	option=0
	until [ "$option" = "3" ]; do
		separacao
		echo -e " ${ROX027}${1}${STD}"
		separacao
		echo ""
		echo -e " ${BLU}1.${STD} ${GRE046}Instalar/atualizar${STD}"
		echo -e " ${BLU}2.${STD} ${GRY247}Desinstalar${STD}"
		echo -e " ${BLU}3.${STD} ${ROX063}Retornar ao Menu Principal${STD}"
		echo ""
		read -p " Digite um número: " option
		case $option in
			1 ) install_CustomLauncher "${1}" "${2}";;
			2 ) disable_CustomLauncher "${1}" "${2}";;
			3 ) menu_principal ;;
			* ) clear; echo -e " ${NEG}Por favor escolha${STD} ${ROS}1${STD}${NEG},${STD} ${ROS}2${STD}${NEG},${STD} ${NEG}ou${STD} ${ROS}3${STD}${NEG}";
		esac
	done
}

# Menu instalar novos apps
menu_InstallApps() { 
	clear
	option=0
	until [ "$option" = "10" ]; do
		separacao
		echo -e " ${ROX027}Instalar Novos Apps${STD}"
		separacao
		echo ""
		echo -e " ${BLU}1.${STD} Aptoide TV - v5.1.2"
		echo -e " ${BLU}2.${STD} Deezer MOD - v3.0"
		echo -e " ${BLU}3.${STD} Spotify MOD - v1.12.0"
		echo -e " ${BLU}4.${STD} TV Bro - v1.6.1"
		echo -e " ${BLU}5.${STD} Smart Youtube Next - v12.50"
		echo -e " ${BLU}6.${STD} Send Files - v1.2.2"
		echo -e " ${BLU}7.${STD} Youcine - v1.1.2"
		echo -e " ${BLU}8.${STD} X-Plore - v4.27.65"
		echo -e " ${BLU}9.${STD} Launcher Setting (Trocar Launcher)"
		echo -e " ${BLU}0.${STD} ${ROX063}Retornar ao Menu Principal${STD}"
		echo ""
		read -p " Digite um número: " option
		case $option in
			1 ) install_App "Aptoide" ;;
			2 ) install_App "Deezer" ;;
			3 ) install_App "Spotify" ;;
			4 ) install_App "TV-Bro" ;;
			5 ) install_App "StubeNext" ;;
			6 ) install_App "SendFiles" ;;
			7 ) install_App "Youcine" ;;
			8 ) install_App "X-Plore" ;;
			9 ) install_App "LauncherSetting" ;;
			0 ) menu_principal ;;
			* ) clear; echo -e " ${NEG}Por favor escolha${STD} ${ROS}1${STD}${NEG},${STD} ${ROS}2${STD}${NEG},${STD} ${ROS}3${STD}${NEG},${STD} ${ROS}4${STD}${NEG},${STD} ${ROS}5${STD}${NEG},${STD} ${ROS}6${STD}${NEG},${STD} ${ROS}7${STD}${NEG},${STD} ${ROS}8${STD}${NEG},${STD} ${ROS}9${STD}${NEG},${STD} ${NEG}ou${STD} ${ROS}0 para sair${STD}";
		esac
	done
}

# Cria um diretório temporário e joga todos arquivos lá dentro e remove sempre ao entrar no script
rm -rf .tmp
mkdir .tmp
cd .tmp
# Chama o script inicial
termux
