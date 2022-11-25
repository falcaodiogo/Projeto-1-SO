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
pid=0                   # Guarda o pid do processo que está a ser analisado


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

for pid in $(ps -eo pid | tail -n +2); do
    processID[$pid]=$pid
done

# Append array with rchar values
for pid in $(ps -eo pid | tail -n +2); do
    rchar_array[$pid]=$(sudo cat /proc/$pid/io | grep rchar | cut -d " " -f 2)
    # echo "AQUI2"
done

# Append array with wchar values
for pid in $(ps -eo pid | tail -n +2); do
    wchar_array[$pid]=$(sudo cat /proc/$pid/io | grep wchar | cut -d " " -f 2)
    # echo "AQUI3"
done

# Append array with process info
for pid in $(ps -eo pid | tail -n +2); do
    infoData[$pid]="$(ps -p $pid -o comm=) $(ps -p $pid -o user=) $(ps -p $pid -o pid=) $(ps -p $pid -o start=) $(ps -p $pid -o etime=)"
done

# print process info
for pid in ${processID[@]}; do
    echo ${infoData[$pid]}
done

# print char values
for pid in ${processID[@]}; do
    echo "rchar: ${rchar_array[$pid]} wchar: ${wchar_array[$pid]}"
done

exit 0