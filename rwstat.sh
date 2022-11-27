# Trabalho Prático 1 - SO
# Realizado por:
#       Diogo Falcão, Nº108712, P3
#       Jośe Gameiro, Nº108840, P3


#!/bin/bash 

# Definição de Arrays
declare -a rchar_array   
declare -a wchar_array   
declare -a rater_array   
declare -a ratew_array   
declare -a comm          
declare -a user          
declare -a start_date   

# Variáveis globais
numProcesses="null"     # Número de processos  
reverse=0               # Encontra-se desativado, caso o utilizador ative, esta variável passa a ter o valor 1
order=0                 # Por defeito, a ordenação é feita por ordem alfabética
comm_opt=". *"          # Caso o utilizador não insira nenhum argumento do tipo '-c' irá guardar todos os processos
user_opt="*"                # Caso o utilizador não insira nenhum argumento do tipo '-u' irá guardar todos os utilizadores
start_d=0            # Guarda a data de início da execução do script
end_date=$(date +%s)    # Guarda a data de fim da execução do script 
exec_time=${@: -1}      # Guarda o último argumento (número de segundos a analisar)
total=0                 # Guarda o número de vezes que foram inseridos comandos errados
pid=0                   # Guarda o pid do processo que está a ser analisado

# Verificação se o argumento é um número inteiro positivo
if ! [[ "$exec_time" =~ ^[0-9]+$ && $exec_time != 0 ]]; then
    echo "ERRO: O último argumento tem de ser obrigatoriamente o número de segundos que pretende analisar."
    exit 1
fi

while getopts ":c:s:e:u:m:M:p:r:w" opt; do   # Percorrer todos os argumentos
    case $opt in
        c)
            comm_opt={$OPTARG}                   # Guarda o comando
            option="-c"
        ;;

        p)
            numProcesses={$OPTARG}           # Guarda o número de processos
            if ! [[ $numProcesses =~ $rexp ]] ; then       # Verifica do argumento, este tem de ser um número inteiro positivo
                echo "Erro: O argumento do '-p' tem de ser um número positivo."
                exit 1
                
            fi
        ;;

        u)
            user={$OPTARG}                   # Guarda o utilizador
        ;;

        s) 
            sDate={$OPTARG}                  # Guarda a data de início
            if date -d "$sDate" > /dev/null 2>&1; then     # Verifica se a data é válida
                start_date = $(date -d "$sDate" + "%s")    # Guarda a data de início em segundos
            else
                echo "Erro: A data de início não é válida."
                exit 1
            fi
        ;;
        
        e)
            eDate=$OPTARG                  # Guarda a data de fim
            if date -d "$eDate" > /dev/null 2>&1; then     # Verifica se a data é válida
                end_date = $(date -d "$eDate" + "%s")      # Guarda a data de fim em segundos
            else
                echo "Erro: A data de fim não é válida."
                exit 1
            fi
        ;;

        r)
            reverse=1                      # Ativa a ordenação reversa
        ;;

        w)
            order=1                        # Ativa a ordenação por write values

        ;;

        m)
            if ! [[ $OPTARG =~ $rexp ]] ; then       # Verifica do argumento, este tem de ser um número inteiro positivo
                echo "Erro: O argumento do '-m' tem de ser um número positivo."
                exit 1
            fi
            minPID=$OPTARG                 # Guarda o PID mínimo

        ;;

        M)
            if ! [[ $OPTARG =~ $rexp ]] ; then       # Verifica do argumento, este tem de ser um número inteiro positivo
                echo "Erro: O argumento do '-M' tem de ser um número positivo."
                exit 1
            fi
            maxPID=$OPTARG                 # Guarda o PID máximo

        ;;

        *)
            echo "Erro: Argumento(s) inválido(s)."
            exit 1
        ;;
    esac
done

count=0
# Falta fazer verificação do PID (erro inicial do script -> "ficheiro ou pasta inexistentes"  E "sem permissão")
for pid in $(ps -eo pid | tail -n +2); do   # Percorre todos os processos
    # verifica se o processo existe
    if ps -p $pid > /dev/null; then 
        # Verifica se temos permissão para aceder ao processo
        if [[ -r "/proc/$pid/io" ]] ; then
            # Verifica se existem as informações rchar e wchar
            if $(cat /proc/$pid/io | grep -q 'rchar\|wchar'); then  

                # PID --------------------------------------------------------------------------
                processID[$count]=$pid

                # READB e WRITEB ---------------------------------------------------------------
                rchar_array[$count]=$(cat /proc/$pid/io | grep rchar | cut -d " " -f 2) 
                wchar_array[$count]=$(cat /proc/$pid/io | grep wchar | cut -d " " -f 2)
                
                # RATER e RATEW -----------------------------------------------------------------
                rchar=${rchar_array[$count]}
                wchar=${wchar_array[$count]}

                var_1=$(cat /proc/$pid/io | grep 'rchar')
                var_2=$(cat /proc/$pid/io | grep 'wchar')

                rchar_new=${var_1//[!0-9]/}   # Vai buscar o valor de rchar
                wchar_new=${var_2//[!0-9]/}    

                rater="$(($rchar_new-$rchar))"
                rater=$( echo "scale=2;$rater/$exec_time"|bc -l)  # Calcula o rater
                rater=${rater/#./0.}      # Caso o rater seja .x, irá colocar 0.x sendo x um número qualquer
                rater_array[$count]=$rater

                ratew="$(($wchar_new-$wchar))"
                ratew=$( echo "scale=2;$ratew/$exec_time"|bc -l)  # Calcula o ratew
                ratew=${ratew/#./0.}
                ratew_array[$count]=$ratew

                # COMMAND -----------------------------------------------------------------------
                comm[$count]=$(ps -p $pid -o comm | tail -n +2)
                
                # USER --------------------------------------------------------------------------
                user[$count]=$(ps -p $pid -o user | tail -n +2)
            
                # STARTTIME ---------------------------------------------------------------------
                start_date=$(ps -p $pid -o lstart | tail -n +2)
                start_date[$count]=$(date --date="$start_date" "+%b %d %H:%M" )

                # COUNT -------------------------------------------------------------------------
                count=$(($count+1))
            fi
        fi
    fi
done


# Caso o utilizador tenha introduzido o argumento -c para filtrar os processos através de uma expressão regular

if [ $option=="-c" ]; then
    echo "$comm_opt"
    for i in "${!comm[@]}"; do
        command=(${comm[i]})
		if ! [[  $command =~ $comm_opt ]];then    # Irá retirar todos os processos(mais as suas informações) que forem diferentes da expressão regular que o utilizador inseriu 
			unset comm[i]   
            unset user[i]
            unset processID[i]
            unset rchar_array[i]
            unset wchar_array[i]
            unset rater_array[i]
            unset ratew_array[i]
            unset start_date[i]
		fi
	done
fi

max=$(($count))

# Impressão de dados

if [[ $numProcesses != 0 ]] ; then
    printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"  # Impressão do cabeçalho
    for ((i=0; i<$max; i++)); do
        printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "${comm[$i]}" "${user[$i]}" "${processID[$i]}" "${rchar_array[$i]}" "${wchar_array[$i]}" "${rater_array[$i]}" "${ratew_array[$i]}" "${start_date[$i]}"
    done
else
    echo "AVISO: Nenhum processo válido encontrado" 
    exit 1
fi


exit 0