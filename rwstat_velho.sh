# Trabalho Prático 1 - SO
# Realizado por:
#       Diogo Falcão, Nº108712, PX
#       Jośe Gameiro, Nº108840, PX


#!/bin/bash 
declare -A processID    # Array que guarda os pids
declare -A rchar_array  # Array que guarda os rchar
declare -A wchar_array  # Array que guarda os wchar
declare -A infoData     # Array que guarda os dados de cada processo


# Variáveis globais
numProcesses="null"     # Número de processos  
reverse=0               # Encontra-se desativado, caso o utilizador ative, esta variável passa a ter o valor 1
order=0                 # Por defeito, a ordenação é feita por ordem alfabética
comm=". *"              # Caso o utilizador não insira nenhum argumento do tipo '-c' irá guardar todos os processos
user="*"                # Caso o utilizador não insira nenhum argumento do tipo '-u' irá guardar todos os utilizadores
start_date=0            # Guarda a data de início da execução do script
end_date=$(date +%s)    # Guarda a data de fim da execução do script 
exec_time=${@: -1}      # Guarda o último argumento (número de segundos a analisar)
total=0                 # Guarda o número de vezes que foram inseridos comandos errados


while getopts ":c:s:e:u:m:M:p:r:w" opt; do   # Percorrer todos os argumentos
    case $opt in
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

        c)
            comm={$OPTARG}                   # Guarda o comando
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


shift $((OPTIND -1))    # Remove os argumentos já analisados


# Verifica se o último argumento está presente
if [[ $# == 0 ]] ; then
    echo "ERRO: o último argumento tem de ser obrigatoriamente o número de segundos que pretende analisar." 
    set -e
fi

# Verifica se o último argumento é o número de segundos a analisar
if ! [[ $exec_time =~ $rexp ]] ; then
    echo "ERRO: o último argumento tem de ser obrigatoriamente o número de segundos que pretende analisar."
    set -e
fi

# Verifica se a data de início é menor que a data de fim
if [[ $start_date > $end_date ]] ; then
    echo "ERRO: A data de início não pode ser superior à data de fim."
    set -e
fi

# Verifica se o número de processos é válido
if [[ $total > 1 ]] ; then
    echo "ERRO: Foram inseridos comandos errados."
    set -e
fi

# SEMPRE VERDADEIRO ?
# Verifica se o último argumento é o número de segundos a analisar
if [[ "$exec_time"=~[0-9] ]] ; then
    echo "ERRO: O último argumento tem de ser obrigatoriamente o número de segundos que pretende analisar."
    set -e
fi

index=0


for i in $(ls -a | grep -Eo "[0-9]{1,5}"); do     # Irá agrupar os números no comando ls e percorrer os elementos um a um
    if [[ -f "$i/status" && -f "$i/io" && -f "$i/comm" ]] ; then   # O comando -f irá verificar se o ficheiro a que se quer aceder existe, se não existir avnça para o próximo processo
        if [[ -r "$i/status" && -r "$i/io" && -r "$i/comm" ]] ; then  # O comando -r irá verificar se é permito aceder ao ficheiro pretendido
            if $(cat $i/io | grep -q 'rchar\|wchar'); then   # Verifica se existem as informações de rchar e wchar

                n_Command = $(cat $i/comm)  # Guarda o nome do comando do processo
                n_User = $(ps -o user = -p $i)  # Guarda o nome do utilizador do processo
                start_date = $(ps -o lstart = -p $i)  # Guarda a data de início do processo
                start_date = $(date + "%b %d %H:%M" -d "$start_date")  # Formatação da data de início do processo
                date_seconds = $(date --date = "$start_date" + "%s")  # Guarda a data de início do processo em segundos

                if [[ ($n_Command =~ $comm) && ($n_User == $user) && ($date_seconds > $start_date) && ($date_seconds < $end_date)]] ; then  # Verifica se o comando, o utilizador, a data de início e a data de fim são válidos
                    if ! [[ "${processID[@]}" =~ "$i" ]] ; then  # Verifica se o processo já foi analisado
                        processID[$index] = $i  # Guarda o ID do processo
                        index = $((index + 1))  # Incrementa o index
                    fi
                fi
            fi
        fi
    fi
done

index=0

# Percorre array vazio !
for PID in ${processID[@]}; do  # Ao percorrer os processos irá guardar todos os valores de rchars e wchars
    var_1 = $(cat $PID/io | grep 'rchar')
    var_2 = $(cat $PID/io | grep 'wchar') 
    rchar = ${var_1 // [!0-9] /}
    wchar = ${var_2 // [!0-9] /}

    rchar_array[$index] = $rchar  # Guarda o valor de rchar
    wchar_array[$index] = $wchar  # Guarda o valor de wchar

    index = $((index + 1))
done

sleep $exec_time  # Faz o programa esperar o número de segundos que o utilizador inseriu

index=0

# Percorre array vazio !
for PID in ${processID[@]}; do

    # COMM -------------------------------------------
    comm = $(cat $PID/comm | "" "_")  # Guarda o nome do comando do processo

    # USER -------------------------------------------
    user = $(ps -o user = -p $PID)  # Guarda o nome do utilizador do processo

    # RCHAR & WCHAR ----------------------------------
    rchar = ${rchar_array[$index]}
    wchar = ${wchar_array[$index]}  
    index = $((index + 1))

    # RATER $ RATEW ----------------------------------
    var_1 = $(cat $PID/io | grep 'rchar')
    var_2 = $(cat $PID/io | grep 'wchar')
    rchar_new = ${var_1 // [!0-9] /}
    wchar_new = ${var_2 // [!0-9] /}

    rater = $($rchar_new - $rchar)
    rater = $( echo "scale = 2; $rater / $exec_time" | bc -l)  # Calcula o rater
    rater = ${rater/#./0.}      # Caso o rater seja .x, irá colocar 0.x sendo x um número qualquer

    ratew = $($wchar_new - $wchar)
    ratew = $( echo "scale = 2; $ratew / $exec_time" | bc -l)  # Calcula o ratew
    ratew = ${ratew/#./0.}

    # -------------------------------------------------

    infoData+=($comm $user $PID $rchar $wchar $rater $ratew $date)  # Guarda todos os dados

done


# Para que serve?
# if [[ $numProcesses > ${#processID[@]} ]]; then
#     echo "ERRO : O número de processos é superior ao número de processos que existem."
#     exit 1
# elif [[ "$numProcesses" == "null" ]]; then
#     numProcesses = ${#processID[@]}  # Caso o utilizador não tenha inserido o número de processos, irá mostrar todos os processos
# fi

























# Impressão dos Dados

if [[ $numProcesses != 0 ]] ; then
    printf "%-30s %-20s %-10s %-10s %-10s %-10s %-10s %-10s \n" "COMM" "USER" "PID" "RCHAR" "WCHAR" "RATER" "RATEW" "DATE"  # Impressão do cabeçalho
else
    echo "AVISO: Nenhum processo válido encontrado"  # Caso não existam processos válidos
    exit 1
fi

#------------------------------------------------------------------------------------------------------------

# # ARRAYS VAZIOS!
# echo "${infoData[@]}" 
# echo "${rchar_array[@]}"
# echo "${wchar_array[@]}"
# echo "${processID[@]}"

# pid=$(ps -fe | grep '[p]rocess' | awk '{print $2}')
# if [[ -n $pid ]]; then
#     echo $pid
#     #kill $pid
# else
# echo "Does not exist"
# fi

# ps acxho user,pid,%cpu,cmd | sort -k3 -nr | head -n 5 | awk '{print $1,$2,$3,$4}' | column -t


# # Forma mais simplificada?
# for ((i = 0; i < $numProcesses; i++)); do
#     printf "%-30s %-20s %-10s %-10s %-10s %-10s %-10s %-10s \n" "${infoData[$index]} ${infoData[$((index + 1))]} ${infoData[$((index + 2))]} ${infoData[$((index + 3))]} ${infoData[$((index + 4))]} ${infoData[$((index + 5))]} ${infoData[$((index + 6))]} ${infoData[$((index + 7))]}"  # Impressão dos dados
#     index = $((index + 8))
# done


#------------------------------------------------------------------------------------------------------------


# Original
if [[ $order -ne 1 && $reverse -eq 0 ]]; then
    printf "%-30s %-20s %-10s %-10s %-10s %-10s %-10s \n" ${infoData[@]} | sort ${order} | head -n ${numProcesses}  
elif [[ $order -ne 1 && $reverse -eq 1 ]]; then
    printf "%-30s %-20s %-10s %-10s %-10s %-10s %-10s \n" ${infoData[@]} | sort ${order} | head -n ${numProcesses}
elif [[ $order -eq 1 && $reverse -eq 1 ]]; then
    printf "%-30s %-20s %-10s %-10s %-10s %-10s %-10s \n" ${infoData[@]} | sort ${order} | head -n ${numProcesses}
else
    printf "%-30s %-20s %-10s %-10s %-10s %-10s %-10s \n" ${infoData[@]} | sort ${order} | head -n ${numProcesses}
fi

exit 0