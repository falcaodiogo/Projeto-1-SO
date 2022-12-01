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
declare -a process_info
declare -a information

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



# Verificação se "s" é o ultimo argumento
if [ "$seconds" != "${@: -1}" ]; then
    echo "ERRO: O argumento do tipo inteiro e positivo tem de ser o último"
    exit 1
fi

while getopts ":c:s:e:u:m:M:p:rw" opt; do   # Percorrer todos os argumentos
    case $opt in
        c)
            comm_opt=$OPTARG                  # Guarda o comando
            option="-c"
        ;;

        s)  
            # Data mínima
            minDate=$OPTARG
            # Guarda a data mínima em segundos
            sDate_seconds=$(date -d "$minDate" +%s)
            option="-s"
        
        ;;

        e)
            option="-e"
            eDate=$OPTARG                  # Guarda a data de fim
            eDate_seconds=$(date -d "$eDate" +%s)      # Guarda a data de fim em segundos
        ;;

        u)
            user_opt=$OPTARG                   # Guarda o utilizador
            option="-u"

        ;;

        m)
            minPID=$OPTARG                 # Guarda o PID mínimo
            option="-m"

        ;;

        M)
            if ! [[ $OPTARG =~ $rexp ]] ; then       # Verifica do argumento, este tem de ser um número inteiro positivo
                echo "Erro!! O argumento do '-M' tem de ser um número positivo!!"
                exit 1
            fi
            maxPID=$OPTARG                 # Guarda o PID máximo

        ;;

        p)
            numProcesses=$OPTARG           # Guarda o número de processos
            #verifica se existem 2 númereos 
            if [ $# -lt 2 ]; then
                echo "Erro!! O argumento do '-p' tem de ser um número positivo!!"
                exit 1
            fi
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

sleep $seconds
count=0
#------------------------------------------------------------------------------------------
for pid in $(ps -eo pid | tail -n +2); do   # Percorre todos os processos
    # verifica se o processo existe
    if ps -p $pid > /dev/null; then 
        # Verifica se temos permissão para aceder ao processo
        if [[ -r "/proc/$pid/io" ]] ; then
            # Verifica se existem as informações rchar e wchar
            if $(cat /proc/$pid/io | grep -q 'rchar\|wchar'); then  

                # pid
                processID=$pid

                # rchar
                rchar=$(cat /proc/$pid/io | grep rchar | cut -d " " -f 2) 

                # wchar
                wchar=$(cat /proc/$pid/io | grep wchar | cut -d " " -f 2)
                
                # rater
                rchar_new=$(cat /proc/$pid/io | grep 'rchar')   #novo rchar
                rchar_new=${rchar_new//[!0-9]/}   # var_1//[^0-9]/ substitui tudo o que não for um número por nada

                rater=$( echo "scale=2;($rchar_new-$rchar)/$seconds"|bc -l)  #rater = rchar_new - rchar / tempo de execução (s)

                # ratew
                wchar_new=$(cat /proc/$pid/io | grep 'wchar')
                wchar_new=${wchar_new//[!0-9]/}  
                ratew=$( echo "scale=2;($wchar_new-$wchar)/$seconds"|bc -l)

                # command
                comm=$(ps -p $pid -o comm | tail -n +2)
                
                # user
                user=$(ps -p $pid -o user | tail -n +2)
            
                # start_time
                
                sdate=$(ps -p $pid -o lstart | tail -n +2)
                dates_seconds[$count]=$(date -d"$sdate" +%s) # Guarda a data em segundos
                date=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M" )

                # Adicionar a um array as informações todas
                process_info[$count]="$comm $user $processID $rchar $wchar $rater $ratew $date"
                count=$(($count+1))
            fi
        fi
    fi
done
# ------------------------------------------------------------------------------------------

# Opção -c
if [[ $option -eq "-c" ]] ; then
    for i in "${!process_info[@]}" ; do
        aux=${process_info[i]}
        commands=$aux[0]   # Vai buscar o comando
        first_char=${commands:0:1}
        # Comparação de um comando com uma expressão regular
		if [[ ! $first_char =~ $comm_opt ]] ; then    # Irá retirar todos os processos(mais as suas informações) que forem diferentes da expressão regular que o utilizador inseriu 
            unset process_info[$i]
        fi
    done
fi

# # Opção -u
if [[ $option -eq "-u" ]] ; then
    for i in "${!process_info[@]}" ; do
        aux=(${process_info[i]})
        user=$aux[1]
        if [[ $user != $user_opt ]] ; then
            unset process_info[$i]
        fi
    done
fi

# Opção -s 
# if [[ $option -eq "-s" ]] ; then
#     for i in "${!dates_seconds[@]}" ; do
#         echo "${dates_seconds[i]}"
#         if ((${dates_seconds[i]} < $sDate_seconds)) ; then
#             unset process_info[$i]
#         fi
#     done
# fi

# Opção -e
if [[ $option -eq "-e" ]] ; then
    for i in "${!dates_seconds[@]}" ; do
        if [[ ${dates_seconds[i]} -gt $eDate_seconds ]] ; then
            unset process_info[$i]
        fi
    done
fi

# Opção -m
# if [[ $option -eq "-m" ]] ; then
#     echo "${process_info[2]}"
#     for i in "${!process_info[@]}" ; do
#         aux=(${process_info[i]})
#         pids=$aux[2]
#         if [[ ${pids[i]} -gt $minPID ]] ; then
#             unset process_info[$i]
#         fi
#     done
# fi

# Opção -M
# if [[ $option -eq "-M" ]] ; then
#     for i in "${!processID[@]}"; do
#         if [[ ${processID[i]} -lt $maxPID ]]; then
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
    for ((i=0; i<=$max; i++)) ; do
        # se o array for null, não imprime nada
        information=${process_info[i]}
        if [[ ${information[0]} == "" ]]; then
            continue
        fi
        printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %3s %3s %5s \n" ${information[0]} ${information[1]} ${information[2]} ${information[3]} ${information[4]} ${information[5]} ${information[6]} ${information[7]}
        if [[ $(($i+1)) -eq $numProcesses ]]; then
            break
        fi
    done
else
    echo "AVISO: Nenhum processo válido encontrado" 
    exit 1
fi

exit 0