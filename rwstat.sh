# Trabalho Prático 1 - SO
# Realizado por:
#       Diogo Falcão, Nº108712, P3
#       Jośe Gameiro, Nº108840, P3


#!/bin/bash 

# Verifica se o utilizador inseriu o tempo de execução
if [[ $# == 0 ]] ; then
    echo "ERRO: é necessário introduzir pelo menos um argumento obrigatório que é o tempo de execução em segundos"
    exit 1
fi

# Definição de Arrays
declare -a dates_seconds
declare -a process_info
declare -a information

# Variáveis globais
numProcesses="null"     # Número de processos  
reverse=1               # Por defeito, a ordenação é feita por ordem decrescente dos valores de rater
write_values=0          # Caso o utilizador insira a opção -w esta variável irá ser alterada para 1
seconds=${@: -1}        # Tempo de execuçaõ (s)

# Verificação do valor de seconds
if [[ ! $seconds =~ ^[0-9]+$ ]] ; then
    echo "ERRO: o último argumento tem de ser um número inteiro positivo"
    exit 1
fi


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

                # command
                comm=$(ps -p $pid -o comm | tail -n +2)

                # user
                user=$(ps -p $pid -o user | tail -n +2)

                # pid
                processID=$pid

                # rchar
                rchar=$(cat /proc/$pid/io | grep rchar | cut -d " " -f 2) 

                # wchar
                wchar=$(cat /proc/$pid/io | grep wchar | cut -d " " -f 2)
                
                # rater
                rchar_new=$(cat /proc/$pid/io | grep 'rchar') 
                rchar_new=${rchar_new//[!0-9]/}   # var_1//[^0-9]/ substitui tudo o que não for um número por nada

                rater=$( echo "scale=2;($rchar_new-$rchar)/$seconds"|bc -l)  #rater = rchar_new - rchar / tempo de execução (s)

                # ratew
                wchar_new=$(cat /proc/$pid/io | grep 'wchar')
                wchar_new=${wchar_new//[!0-9]/}  
                ratew=$( echo "scale=2;($wchar_new-$wchar)/$seconds"|bc -l)
            
                # date
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

validate=0
validate_args=0
while getopts ":c:s:e:u:m:M:p:rw" opt; do   # Percorrer todos os argumentos
    validate_args=$(($validate_args+1))    # Conta o número de argumentos inseridos pelo utilizador
    variables=$# # Número de argumentos
    case $opt in
        c)  # Opção -c
            comm_opt=$OPTARG

            validate_args=$(($validate_args+1))
            if [[ $validate_args -ge $((variables)) ]] ; then  # Verifica se o utilizador inseriu mais argumentos
                echo "ERRO: não se pode utilizar o argumento dos segundos para a opção -c"
                exit 1
            fi
            for i in "${!process_info[@]}" ; do
                aux=${process_info[i]}
                commands=${aux[0]}   # Vai buscar o comando
                first_char=${commands:0:1}
                # Comparação de um comando com uma expressão regular
		        if [[ ! $first_char =~ $comm_opt ]] ; then    # Irá retirar todos os processos(mais as suas informações) que forem diferentes da expressão regular que o utilizador inseriu 
                    unset process_info[$i]
                fi
            done
        ;;

        u)  # Opção -u
               
            validate_args=$(($validate_args+1))
            if [[ $validate_args -ge $((variables)) ]] ; then  # Verifica se o utilizador inseriu o argumento dos segundos para a opção -u
                echo "ERRO: não se pode utilizar o argumento dos segundos para a opção -u"
                exit 1
            fi
            user_opt=$OPTARG  
            for i in "${!process_info[@]}" ; do
                aux=(${process_info[i]})
                user=${aux[1]}
                if [[ $user != $user_opt ]] ; then
                    unset process_info[$i]
                fi
            done
        ;;

        s)  # Opção -s
            # Guarda a data mínima em segundos inserida pelo utilizador
            validate_args=$((validate_args+1))
			if [[ $validate_args -ge $((variables)) ]];then  # Verifica se o utilizador inseriu o argumento dos segundos
				echo "ERRO: não se pode utilizar o argumento dos segundos para a opção -s"
				exit 1
			fi
			min_Date=$(date -d "$OPTARG" +%s)
			if [[ -z $min_Date  ]];then	    # Verifica se a data inserida pelo utilizador é válida
                echo "ERRO: a data mínima inserida não é válida"
				exit 1
			fi
            for i in "${!dates_seconds[@]}" ; do
                if [[ ${dates_seconds[i]} -lt $min_Date ]] ; then
                   unset process_info[$i]
                fi
            done
        
        ;;

        e)  # Opção -e
            validate_args=$((validate_args+1))
            if [[ $validate_args -ge $((variables)) ]] ; then
                echo "ERRO: não se pode utilizar o argumento dos segundos para a opção -e"
                exit 1
            fi
            max_Date=$(date -d "$OPTARG" +%s)  # Guarda a data de fim em segundos inserida pelo utilizador
            # Verifica se a data inserida é válida
            if [[ -z "$max_Date" ]]; then
                echo "ERRO: A data máxima não é válida"
                exit 
            fi
            for i in "${!dates_seconds[@]}" ; do
                if [[ ${dates_seconds[i]} -gt $max_Date ]] ; then
                    unset process_info[$i]
                fi
            done
        ;;

        m)  # Opção -m
            # Verifica se o numero inserido é inteiro e positivo
            if [[ $OPTARG =~ ^[0-9]+$ ]] ; then
                minPID=$OPTARG
            else
                echo "ERRO: o argumento da opção -m não é um número inteiro positivo"
                exit 1
            fi
            for i in "${!process_info[@]}" ; do
                aux=(${process_info[i]})
                pid=${aux[2]}
                if [[ $pid -lt $minPID ]] ; then
                    unset process_info[$i]
                fi
            done


        ;;

        M)  # Opção -M
            if [[ $OPTARG =~ ^[0-9]+$ ]] ; then
                maxPID=$OPTARG
            else
                echo "ERRO: o argumento da opção -m não é um número inteiro positivo"
                exit 1
            fi
            for i in "${!process_info[@]}" ; do
                aux=(${process_info[i]})
                pid=${aux[2]}
                if [[ $pid -gt $maxPID ]] ; then
                    unset process_info[$i]
                fi
            done

        ;;

        p) # Opção -p
            
            validate_args=$((validate_args+1))
            if [[ $validate_args -ge $((variables)) ]] ; then  # Verifica se o utilizador inseriu mais argumentos depois do -p
                echo "ERRO: não se pode utilizar o argumento dos segundos para a opção -e"
                exit 1
            fi
            numProcesses=$OPTARG           # Guarda o número de processos
            if [[ $numProcesses -le 0 ]] ; then  # Verifica se o número de processos é válido
                echo "ERRO: o número de processos tem de ser maior que 0"
                exit 1
            fi
        ;;

        r)  
            reverse=1
            write_values=0
        ;;

        w)
            reverse=0
            write_values=1                        # Ativa a ordenação por write values
            column=7                     # Ativa a ordenação reversa
            IFS=$'\n' 
            process_info=($(sort -k $column -n -r<<<"${process_info[*]}")) # Ordena o array por ordem decrescente dos valores de ratew
            unset IFS

        ;;

        *)
            echo "ERRO: Argumento(s) inválido(s)"
            exit 1
        ;;
    esac
done



max=$(($count))

# Impressão de dados
if [[ $numProcesses != 0 ]] ; then
    printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %-10s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"  # Impressão do cabeçalho
    if [[ $write_values == 1 && $reverse == 0 ]] ; then
        for ((i=0; i<=$max; i++)) ; do
            information=(${process_info[i]})
            # se o valor do comando for null, não imprime nada
            if [[ ${information[0]} == "" ]]; then
                continue
            fi
            printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %3s %3s %5s \n" ${information[0]} ${information[1]} ${information[2]} ${information[3]} ${information[4]} ${information[5]} ${information[6]} ${information[7]} ${information[8]} ${information[9]} 
            # Para a opção -p parar de imprimir quandp chegar ao número de processos inserido pelo utilizador
            if [[ $(($i+1)) -eq $numProcesses ]] ; then
                break
            fi
        done
    else
        column=6                     
        IFS=$'\n' 
        process_info=$(sort -k $column -n -r<<<"${process_info[*]}")  # Ordena o array por ordem decrescente dos valores de rater
        unset IFS
        for ((i=0; i<=$max; i++)) ; do
            information=${process_info[i]}
            # se o valor do comando for null, não imprime nada
            if [[ ${information[0]} == "" ]] ; then
                continue
            fi
            printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %3s %3s %5s \n" ${information[0]} ${information[1]} ${information[2]} ${information[3]} ${information[4]} ${information[5]} ${information[6]} ${information[7]}
            # Para a opção -p parar de imprimir quandp chegar ao número de processos inserido pelo utilizador
            if [[ $(($i+1)) -eq $numProcesses ]] ; then
                break
            fi
        done  
        # printf "%-40s %-20s %-10s %-20s %-10s %-15s %-15s %3s %3s %5s \n" ${information[0]} ${information[1]} ${information[2]} ${information[3]} ${information[4]} ${information[5]} ${information[6]} ${information[7]}     
    fi
else
    echo "AVISO: Nenhum processo válido encontrado" 
    exit 1
fi

exit 0