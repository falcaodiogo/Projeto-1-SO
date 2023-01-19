# SO_A01

## Primeiro Trabalho Prático da Cadeira de Sistemas Operativos 
Projeto realizado por:
- José Gameiro (Nºmec 108840)
- Diogo Falcão (Nºmec 108712)

Nota: Ainda não atribuída

## Instruções de Execução
Para executar o programa é necessário executar o seguinte comando para dar permissão para executar:
```
chmod u=rwx rwstat.sh
```

Para correr basta executar o seguinte comando, passando como argumento um número inteiro qualquer:
```
./rwstat.sh <Número inteiro>
```
Sem este argumento não é possível executar o programa

Pode executar com outras opções que são as seguintes:

### Opção -c
Utiliza como argumento uma expressão regular e depois imprime os processos cujo nome contém essa expressão.
Comando:
```
./rwstat.sh -c "d.*" 10
```

### Opção -u
Utiliza com argumento o nome do utilizador do computador e imprime os processos que têm como utilizador o introduzido.
Comando:
```
./rwstat.sh -u user_name 10
```

### Opções -s e -c
Estas opções utilizam como argumentos duas datas e imprime os processos cujas datas estejam entre as duas introduzidas.
Comando:
```
./rwstat.sh -s "Dec 02 23:00" -e "Dec 02 23:13" 10
```

### Opções -m e -M
Estas opções utilizam como argumentos dois números inteiros e imprime os processos cujo PID pertença ao intervalo formado pelos dois inteiros introduzidos.
Comando:
```
./rwstat.sh -m 3000 -M 4000 10
```

### Opção -p
Esta opção tem como argumento um número inteiro e imprime o número de processos que foi introduzido.
Comando:
```
./rwstat.sh -p 20 10
```

### Opção -w
Esta opção não apresenta argumentos e imprime os processos ordenados de forma decrescente pelos valores de ratew.
Comando:
```
./rwstat.sh -w 10
```

### Opção -r
Esta opção não apresenta argumentos  e imprime os processos ordenados de forma decrescente conforme os valores de rater. Caso não seja introduzida nem esta opção nem a -w os processos irão aparecer ordenados conforme os valores de rater.
Comando:
```
./rwstat.sh -r 10
```





