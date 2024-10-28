#!/bin/bash

HORAINICIAL=$(date +%T)

USUARIO=$(id -u)
LOG="/var/log/$(basename $0)"

if [ "$USUARIO" != "0" ]; then
    echo "O script deve ser executado como root. Use 'sudo -i' para mudar para o usuário root e execute novamente."
    exit 1
fi

clear

echo -n "Verificando e instalando dependências... "
for name in snapd; do
    if dpkg -s $name &> /dev/null; then
        echo "$name já está instalado, reinstalando..."
        apt-get install --reinstall -y $name &>> $LOG
    else
        echo "$name não está instalado, instalando..."
        apt-get install -y $name &>> $LOG
    fi
done

echo "Dependências verificadas e instaladas com sucesso."

echo "Verificando se as portas 3000 e 27017 estão em uso..."

if nc -vz 127.0.0.1 3000 &> /dev/null; then
    echo "A porta 3000 está em uso. Parando o serviço..."
    fuser -k 3000/tcp
fi

if nc -vz 127.0.0.1 27017 &> /dev/null; then
    echo "A porta 27017 está em uso. Parando o serviço..."
    fuser -k 27017/tcp
fi

echo "Portas verificadas e livres. Continuando com o script..."

echo "Início do script $(basename $0) em: $(date +%d/%m/%Y-%H:%M)" &>> $LOG

echo "Adicionando repositórios..."
add-apt-repository universe -y &>> $LOG
add-apt-repository multiverse -y &>> $LOG
echo "Repositórios adicionados com sucesso."

echo "Atualizando listas de pacotes..."
apt-get update &>> $LOG
echo "Listas atualizadas com sucesso."

echo "Atualizando o sistema..."
apt-get -y upgrade &>> $LOG
echo "Sistema atualizado com sucesso."

echo "Removendo pacotes desnecessários..."
apt-get -y autoremove &>> $LOG
echo "Pacotes desnecessários removidos com sucesso."

echo "Instalando o Rocket.Chat..."
snap install rocketchat-server &>> $LOG
echo "Rocket.Chat instalado com sucesso."

echo "Verificando portas do Rocket.Chat e MongoDB..."
netstat -an | grep '3000\|27017'
echo "Portas verificadas com sucesso."

HORAFINAL=$(date +%T)
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")

echo "Instalação do Rocket.Chat feita com sucesso!"
echo "Tempo gasto para execução do script $(basename $0): $TEMPO"
echo "Pressione <Enter> para concluir o processo."

echo "Fim do script $(basename $0) em: $(date +%d/%m/%Y-%H:%M)" &>> $LOG
read

exit 0
