# Trabalho Prático 1 - SO
# Realizado por:
#       Diogo Falcão, Nº108712, P3
#       Jośe Gameiro, Nº108840, P3


#!/bin/bash 


# Variáveis globais
numProcesses="null"     # Número de processos  
reverse=0               # Encontra-se desativado, caso o utilizador ative, esta variável passa a ter o valor 1
order=0                 # Por defeito, a ordenação é feita por ordem alfabética
comm=". *"              # Caso o utilizador não insira nenhum argumento do tipo '-c' irá guardar todos os processos
user="*"                # Caso o utilizador não insira nenhum argumento do tipo '-u' irá guardar todos os utilizadores
start_date=0            # Guarda a data de início da execução do script
end_date=$(date +%s)    # Guarda a data de fim da execução do script 
exec_time=${@: -1}      # Guarda o último argumento (número de segundos a analisar)
# VAI SERVIR PRA O SLEEP
total=0                 # Guarda o número de vezes que foram inseridos comandos errados
pid=0                   # Guarda o pid do processo que está a ser analisado


#---------------- Verificação do argumento obrigatório
if [[ "$exec_time" != 0 && "$exec_time" ==  ]]; then
    echo "BACAHAU"
else
    echo "ERRO: Argumento obrigatório em falta"
    exit 1
fi

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


# Falta fazer verificação do PID (erro inicial do script -> "ficheiro ou pasta inexistentes")

for pid in $(ps -eo pid | tail -n +2); do
    # verifica se o processo existe
    if ps -p $pid > /dev/null; then
        processID[$pid]=$pid
    fi
done

# Append array with rchar values
for pid in $(ps -eo pid | tail -n +2); do
    rchar_array[$pid]=$(sudo cat /proc/$pid/io | grep rchar | cut -d " " -f 2) || exit
    # echo "AQUI2"
done

# Append array with wchar values
for pid in $(ps -eo pid | tail -n +2); do
    wchar_array[$pid]=$(sudo cat /proc/$pid/io | grep wchar | cut -d " " -f 2) || exit
    # echo "AQUI3"
done

# Append array with process command
for pid in $(ps -eo pid | tail -n +2); do
    command[$pid]=$(ps -p $pid -o comm | tail -n +2)
done

# Append array with process user
for pid in $(ps -eo pid | tail -n +2); do
    user[$pid]=$(ps -p $pid -o user | tail -n +2)
done


###################
# Para calcular o tempo de execução do script (argumento)
# Append array with process start time
for pid in $(ps -eo pid | tail -n +2); do
    start[$pid]=$(ps -p $pid -o start | tail -n +2)
done

# Append array with process elapsed time
for pid in $(ps -eo pid | tail -n +2); do
    elapsed[$pid]=$(ps -p $pid -o etime | tail -n +2)
done

# # Append array with process end time
# for pid in $(ps -eo pid | tail -n +2); do
#     end[$pid]=$(date -d "${start[$pid]} ${elapsed[$pid]}" +%s)
# done
###################



# Impressão de dados

if [[ $numProcesses != 0 ]] ; then
    printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "COMM" "USER" "PID" "RCHAR" "WCHAR" "RATER" "RATEW" "DATE"  # Impressão do cabeçalho
    # impressão dos dados -> COMM, USER, PID, RCHAR, WCHAR, RATER, RATEW, DATE
    for pid in $(ps -eo pid | tail -n +2); do
        printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "${command[$pid]}" "${user[$pid]}" "${processID[$pid]}" "${rchar_array[$pid]}" "${wchar_array[$pid]}" "${rchar_array[$pid]}" "${wchar_array[$pid]}" "${start[$pid]}"
    done 
else
    echo "AVISO: Nenhum processo válido encontrado"  # Caso não existam processos válidos
    exit 1
fi



# Só para checar
# # print process info
# for pid in ${processID[@]}; do
#     echo ${infoData[$pid]}
# done

# # print char values
# for pid in ${processID[@]}; do
#     echo "rchar: ${rchar_array[$pid]} wchar: ${wchar_array[$pid]}"
# done


exit 0