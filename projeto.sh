#!/bin/bash


function listar_arquivos(){
	ls > conteudo_cliente.txt
	conteudo_cliente=$(cat conteudo_cliente.txt)
	userip=$(head -n 1 userips.txt)
        sshpass -p $senha ssh $userip 'ls > lists.txt'
	sshpass -p $senha scp $userip:/home/ifpb/lists.txt /home/ifpb/projeto/projetoscript/
	conteudo=$(cat lists.txt)
	array=("${conteudo[@]}" "${conteudo_cliente[@]}")
	yad --width=900 --height=900 --list --title "Arquivos" --column "Arquivos do Servidor"	--column "Arquivos do Cliente" "${array[@]}" 
	if [[ $1 -eq 2 ]];then
		submenu
	fi
}

function verifica_copia(){
	userip=(head -n 1 userips.txt)
	arq_origem=$2
	destino=$3
	md5_origem=$(md5sum "$arq_origem" | awk '{print $1}')
	md5_copia=$(sshpass -p ifpb ssh "$user_ip" "cd $destino && md5sum $arq_origem" | awk '{print $1}')
	if [[ "$md5_origem" == "$md5_copia" ]]; then
		yad --title "Verificação por md5" --text "Cópia bem sucedida!"
	else
		yad --title "Verificação por md5" --text "Cópia bem sucedida!"
	fi
}

function salvarip(){
	userips=$(cat userips.txt)
	userip=$(yad --title "Iniciando conexão SSH" --text "Digite o USER@IP do servidor" --entry $userips --editable)
	if [[ -n $userip ]]; then
		if [[ -e userips.txt ]]; then
			mv userips.txt userips_tmp.txt
			echo "$userip" > userips.txt
			cat userips_tmp.txt >> userips.txt
			rm userips_tmp.txt
		else
			echo "$userip" > userips.txt
		fi
	fi
	submenu
}

function instalarssh(){
	echo "$senha" | sudo -S apt-get install openssh-server && yad --text "Sucesso!" || yad --text "Fail"
menu
}

function verificarssh(){
	if dpkg -l | grep -q openssh-server; then
		yad --text "Máquina já possui SSH"
	else	
		yad --text "Máquina não possui SSH, por favor instale" \
		--button="Instalar SSH":0 \
		--button="Fechar":1
		opcao=$?
		case $opcao in
			0) instalarssh ;;
			1) exit 0 ;;
		esac
	fi
menu
}

function scp_s_c(){
	listar_arquivos 1
	archive=$(yad --title "Que arquivo deseja copiar?" --entry)
	ipuser=$(head -n 1 userips.txt)
	caminhodoservidor=$(yad --title "Digite o caminho do arquivo" --entry)
	caminhodocliente=$(yad --title "Digite para onde quer copiar" --entry)
	sshpass -p $senha scp $ipuser:$caminhodoservidor$archive $caminhodocliente && verifica_copia 1 $archive $caminhodoservidor
}

function scp_c_s(){
	listar_arquivos 1
	archive=$(yad --title "Que arquivo deseja copiar?" --entry)
	ipuser=$(head -n 1 userips.txt)
	caminhodoservidor=$(yad --title "Digite o caminho para onde quer copiar" --entry)
	sshpass -p $senha scp $archive $ipuser:$caminhodoservidor && verifica_copia 2 $archive $caminhodoservidor
}

function submenu(){
	yad --form --center --width=300 --title="Menu de Cópia" \
		--button="Copia Servidor -> Cliente":0 \
		--button="Copia Cliente -> Servidor":1 \
		--button="Verificar Lista de Arquivos":2 \
		--buttons-layout=center --on-top \
		--text="Selecione a Cópia desejada"
	opcao=$?
	case $opcao in
		0) scp_s_c  ;;
		1) scp_c_s  ;;
		2) listar_arquivos 2 ;;
		*) yad --text "Opção Inválida" ;;
	esac
}

function menu(){
	yad --form --center --width=300 --title="Menu" \
		--button="Verificar servidor SSH":0 \
		--button="Instalar servidor SSH":1 \
		--button="Iniciar Transferência de Arquivos":2 \
		--buttons-layout=center \
		--on-top \
		--text="Interface de Transferência de Arquivos SCP" \
		--windw-icon="dialog-question" \
		--image="dialog.question" \
		--image-on-top
	opcao=$?
	case $opcao in
		0) verificarssh ;;
		1) instalarssh ;;
		2) salvarip ;;
		*) yad --text "Opção Inválida" ;; 
	esac
}
senha=$(yad --title "Digite a senha root para continuar" --entry)
menu
