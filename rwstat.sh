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
declare -a dates
declare -a dates_seconds

# Variáveis globais
numProcesses="null"     # Número de processos  
reverse=0               # Encontra-se desativado, caso o utilizador ative, esta variável passa a ter o valor 1
order=0                 # Por defeito, a ordenação é feita por ordem alfabética
comm_opt=". *"          # Caso o utilizador não insira nenhum argumento do tipo '-c' irá guardar todos os processos
user_opt="*"                # Caso o utilizador não insira nenhum argumento do tipo '-u' irá guardar todos os utilizadores
start=$(date +%s)              # Guarda a data de início da execução do script
end=$(date +%s)    # Guarda a data de fim da execução do script 
seconds=${@: -1}              # Tempo de execuçaõ (s)
total=0                 # Guarda o número de vezes que foram inseridos comandos errados
pid=0                   # Guarda o pid do processo que está a ser analisado


while getopts ":c:s:e:u:m:M:p:r:w" opt; do   # Percorrer todos os argumentos
    case $opt in
        c)
            comm_opt=$OPTARG                  # Guarda o comando
            comm="-c"
        ;;

        s)  
            sDate_opt={$OPTARG}               # Guarda a data de início
            sDate_opt=$(date --date="$sDate_opt" "+%s")    # Guarda a data de início em segundos
            option="-s"
        ;;

        e)
            option="-e"
            eDate_opt=$OPTARG                  # Guarda a data de fim
            eDate_opt=$(date -d "$eDate_opt" + "%s")      # Guarda a data de fim em segundos
        ;;

        u)
            user_opt={$OPTARG}                   # Guarda o utilizador
            option="-u"
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
                echo "Erro!! O argumento do '-M' tem de ser um número positivo!!"
                exit 1
            fi
            maxPID=$OPTARG                 # Guarda o PID máximo

        ;;

        p)
            numProcesses={$OPTARG}           # Guarda o número de processos
            if ! [[ $numProcesses =~ $rexp ]] ; then       # Verifica do argumento, este tem de ser um número inteiro positivo
                echo "Erro!! O argumento do '-p' tem de ser um número positivo!!"
                exit 1
                
            fi
        ;;

        r)
            reverse=1                      # Ativa a ordenação reversa
        ;;

        w)
            order=1                        # Ativa a ordenação por write values

        ;;

        *)
            echo "Erro!! Argumento(s) inválido(s)!!"
            exit 1
        ;;
    esac
done


# Verificação se "s" é um número inteiro positivo -> s é o numero de segundos
if ! [[ "$seconds" =~ ^[0-9]+$ && $seconds != 0 ]]; then
    echo "ERRO: É obrigatório ter um argumento do tipo inteiro e positivo"
    exit 1
fi


sleep $seconds

count=0
for pid in $(ps -eo pid | tail -n +2); do   # Percorre todos os processos
    # verifica se o processo existe
    if ps -p $pid > /dev/null; then 
        # Verifica se temos permissão para aceder ao processo
        if [[ -r "/proc/$pid/io" ]] ; then
            # Verifica se existem as informações rchar e wchar
            if $(cat /proc/$pid/io | grep -q 'rchar\|wchar'); then  

                # pid
                processID[$count]=$pid

                # rchar
                rchar_array[$count]=$(cat /proc/$pid/io | grep rchar | cut -d " " -f 2) 

                # wchar
                wchar_array[$count]=$(cat /proc/$pid/io | grep wchar | cut -d " " -f 2)
                
                # rater
                rchar=${rchar_array[$count]}    #rchar original

                rchar_new=$(cat /proc/$pid/io | grep 'rchar')   #novo rchar
                rchar_new=${rchar_new//[!0-9]/}   # var_1//[^0-9]/ substitui tudo o que não for um número por nada

                rater=$( echo "scale=2;($rchar_new-$rchar)/$seconds"|bc -l)  #rater = rchar_new - rchar / tempo de execução (s)
                rater_array[$count]=${rater/#./0.}


                # ratew
                wchar=${wchar_array[$count]}

                wchar_new=$(cat /proc/$pid/io | grep 'wchar')
                wchar_new=${wchar_new//[!0-9]/}  

                ratew=$( echo "scale=2;($wchar_new-$wchar)/$seconds"|bc -l)
                ratew_array[$count]=${ratew/#./0.}


                # command
                comm[$count]=$(ps -p $pid -o comm | tail -n +2)
                
                # user
                user[$count]=$(ps -p $pid -o user | tail -n +2)
            
                # start_time
                start_date=$(ps -p $pid -o lstart | tail -n +2)
                dates_seconds[$count]=$start_date
                dates[$count]=$(date --date="$start_date" "+%b %d %H:%M" )

                # end_time
                count=$(($count+1))
            fi
        fi
    fi
done


# Opção -c
if [[ $option=="-c" ]]; then
    for i in "${!comm[@]}"; do
        command=(${comm[i]})
        first_char=${command:0:1}
        # Comparação de um comando com uma expressão regular
        
		if [[ ! $first_char =~ $comm_opt ]]; then    # Irá retirar todos os processos(mais as suas informações) que forem diferentes da expressão regular que o utilizador inseriu 
			unset comm[i]   
            unset user[i]
            unset processID[i]
            unset rchar_array[i]
            unset wchar_array[i]
            unset rater_array[i]
            unset ratew_array[i]
            unset dates[i]
		fi
	done
fi

# # Opção -u
# if [[ $option=="-u" ]] ; then
#     if [[ $user_opt != "${!user[@]}" ]] ; then   # Verifica se o utilizador inserido existe
#         echo "ERRO: O utilizador não existe"
#         exit 1
#     fi
#     for i in "${!user[@]}" ; do
#         if [[ ! $user[i]==$user_opt ]] ; then
#             unset comm[i]   
#             unset user[i]
#             unset processID[i]
#             unset rchar_array[i]
#             unset wchar_array[i]
#             unset rater_array[i]
#             unset ratew_array[i]
#             unset dates[i]
#         fi
#     done
# fi

# # Opção -s
# if [[ $option=="-s" ]] ; then
#     echo "Bacalhau"
#     for i in "${!dates_seconds[@]}" ; do
#         if [[ $dates_seconds[i] -ge $sDate_opt ]] ; then
#             unset comm[i]   
#             unset user[i]
#             unset processID[i]
#             unset rchar_array[i]
#             unset wchar_array[i]
#             unset rater_array[i]
#             unset ratew_array[i]
#             unset dates[i]
#         fi
#     done
# fi
max=$(($count))

# Impressão de dados

if [[ $numProcesses != 0 ]] ; then
    printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"  # Impressão do cabeçalho
    for ((i=0; i<$max ; i++)); do
        # se o array for null, não imprime nada
        if [[ ${comm[i]} == ""  || ${user[i]} == "" ]]; then
            continue
        fi
        # AH só uma cena que eu descobri ontem o operador =~ é para ver se uma string é igual a uma expressão
        printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "${comm[$i]}" "${user[$i]}" "${processID[$i]}" "${rchar_array[$i]}" "${wchar_array[$i]}" "${rater_array[$i]}" "${ratew_array[$i]}" "${dates[$i]}"
    done
else
    echo "AVISO: Nenhum processo válido encontrado" 
    exit 1
fi

exit 0