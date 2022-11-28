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
            minDate=$(date --date="$minDate" "+%b %d %H:%M" )    # Guarda a data de início da execução do script
            if [ $? -ne 0 ]; then
                echo "Data de início inválida"
                exit 1
            fi
            option="-s"
        
        ;;

        e)
            option="-e"
            eDate_opt=$OPTARG                  # Guarda a data de fim
            eDate_opt=$(date -d "$eDate_opt" + "%s")      # Guarda a data de fim em segundos
        ;;

        u)
            user_opt=$OPTARG                   # Guarda o utilizador
            option="-u"

        ;;

        m)
            if ! [[ $OPTARG =~ $rexp ]] ; then       # Verifica do argumento, este tem de ser um número inteiro positivo
                echo "Erro: O argumento do '-m' tem de ser um número positivo."
                exit 1
            fi
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
                rater_array[$count]=$rater


                # ratew
                wchar=${wchar_array[$count]}

                wchar_new=$(cat /proc/$pid/io | grep 'wchar')
                wchar_new=${wchar_new//[!0-9]/}  

                ratew=$( echo "scale=2;($wchar_new-$wchar)/$seconds"|bc -l)
                ratew_array[$count]=$ratew


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
if [[ $option -eq "-c" ]]; then
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

# Opção -u
if [[ $option -eq "-u" ]] ; then
    for i in "${!rater_array[@]}"; do
        for i in "${!user[@]}"; do
            if [[ ${user[i]} != $user_opt ]]; then
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
    done
fi

Opção -s 
if [[ $option -eq "-s" ]] ; then
    for i in "${!dates[@]}"; do
        if [[ ${dates[i]} -gt $minDate ]]; then
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

Opção -m
if [[ $option -eq "-m" ]] ; then
    for i in "${!processID[@]}"; do
        if [[ ${processID[i]} -gt $minPID ]]; then
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

Opção -M
if [[ $option -eq "-M" ]] ; then
    for i in "${!processID[@]}"; do
        if [[ ${processID[i]} -lt $maxPID ]]; then
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

if [[ $option=="-s" ]] ; then
    echo "Bacalhau"
    for i in "${!dates_seconds[@]}" ; do
        if [[ $dates_seconds[i] -ge $sDate_opt ]] ; then
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

sort rater array in descending order

for i in ${!rater_array[@]} ; do
    for j in ${!rater_array[@]} ; do
        if [[ ${rater_array[i]} -gt ${rater_array[j]} ]] ; then
            temp=${rater_array[i]}
            rater_array[i]=${rater_array[j]}
            rater_array[j]=$temp

            temp=${ratew_array[i]}
            ratew_array[i]=${ratew_array[j]}
            ratew_array[j]=$temp

            temp=${rchar_array[i]}
            rchar_array[i]=${rchar_array[j]}
            rchar_array[j]=$temp

            temp=${wchar_array[i]}
            wchar_array[i]=${wchar_array[j]}
            wchar_array[j]=$temp

            temp=${comm[i]}
            comm[i]=${comm[j]}
            comm[j]=$temp

            temp=${user[i]}
            user[i]=${user[j]}
            user[j]=$temp

            temp=${processID[i]}
            processID[i]=${processID[j]}
            processID[j]=$temp

            temp=${dates[i]}
            dates[i]=${dates[j]}
            dates[j]=$temp
        fi
    done
done

max=$(($count))

# Impressão de dados

if [[ $numProcesses != 0 ]] ; then
    printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"  # Impressão do cabeçalho
    for ((i=0; i<$max ; i++)); do
        # se o array for null, não imprime nada
        if [[ ${comm[i]} == "" ]]; then
            continue
        fi
        # AH só uma cena que eu descobri ontem o operador =~ é para ver se uma string é igual a uma expressão
        printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "${comm[$i]}" "${user[$i]}" "${processID[$i]}" "${rchar_array[$i]}" "${wchar_array[$i]}" "${rater_array[$i]}" "${ratew_array[$i]}" "${dates[$i]}"
        if [[ $(($i+1)) -eq $numProcesses ]]; then
            break
        fi
    done
else
    echo "AVISO: Nenhum processo válido encontrado" 
    exit 1
fi

exit 0