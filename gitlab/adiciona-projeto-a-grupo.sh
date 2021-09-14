#!/bin/bash
set +x

SERVER='http://gitlab.my-installation'

#PRIVATETOKEN='my-private-token'
#GRUPO='my-group'
#PROJETO='my-project'
BLOQUEIA_BRANCHES_EVO="true"

# se vc usa um prefixo para os grupos
GROUPPREFIX=""
VISIBILITY="internal"
LFS="true"


#
# Cria grupo e projeto com base no valor informado
#

PROJECTNAME=$(echo ${PROJETO} | tr '[:upper:]' '[:lower:]')

VALIDANOME=$(echo $PROJECTNAME | grep -e "^[a-z0-9][-a-z0-9]*[a-z0-9]$")
if [[ "$VALIDANOME"x == ""x ]]; then
    echo "Não são permitidos alguns caracteres no nome do projeto";
    echo "O campo nome deve ser formado por uma string: \"^[a-z0-9][-a-z0-9]*[a-z0-9]$\""
    exit 109
fi

#
# Verificações - grupo já existe e usuários informados
#

# Grupo já Existe, se sim, saia.
# Testa se o grupo já existe
function retorna_id_grp() {
    ID=0;
    # {"id":499,"name":"carteirada"}
    local GROUP=$1;
    curl -s  --header "Private-Token: ${PRIVATETOKEN}" \
    -G ${SERVER}/api/v4/groups?search=${GROUP} | \
    jq -c '.[]| { id, name } ' | { \
      while read -r line ; do \
         i=$(echo $line | cut -d : -f 3 | sed 's/}//g'| sed 's/"//g' ); \
         if [ "$i"x == "$GROUP"x ]; then \
            ID=$(echo $line | cut -d : -f 2 | cut -f 1 -d , ); \
            break; \
         fi ; \
      done ; \
      echo $ID ;\
     }
}


#
# Recebe id do grupo e nome do projeto
# Retorna id do projeto caso exista e 0 caso contrário
#

function retorna_id_projeto_dentro_do_grupo() {
 # GET /groups/:id/projects
    ID=0
    local GROUPID=$1
    local PROJ=$2;

    curl -s  --header "Private-Token: ${PRIVATETOKEN}" \
	 -G ${SERVER}/api/v4/groups/${GROUPID}/projects?simple=true  | \
	jq -c '.[]| { id, name } ' | { \
        while read -r line ; do \
           i=$(echo $line | cut -d : -f 3 | sed 's/}//g'| sed 's/"//g' ); \
           if [ "$i"x == "$PROJ"x ]; then \
              ID=$(echo $line | cut -d : -f 2 | cut -f 1 -d , ); \
              break; \
           fi ; \
        done ; \
        echo $ID ;\
       }
}


#
# Testa se o grupo já existe
#

GROUPNAME="${GROUPPREFIX}${GRUPO}"
GROUPID=$(retorna_id_grp ${GROUPNAME});
if ! [[ $GROUPID -ne 0 ]] ; then
    echo "O grupo informado " $GROUPNAME "NÃO EXISTE -- Crie primeiro usando o script de criação de grupo e projeto"
    echo "O grupo informado " $GROUPNAME "NÃO EXISTE -- Crie primeiro usando o script de criação de grupo e projeto"
    echo "O grupo informado " $GROUPNAME "NÃO EXISTE -- Crie primeiro usando o script de criação de grupo e projeto"
    exit 99
fi


#
# Verifica se o projeto já existe. Se não existir, continue
#

PRJEXISTS=$(retorna_id_projeto_dentro_do_grupo ${GROUPID} ${PROJECTNAME});
if [[ $PRJEXISTS -ne 0 ]] ; then
    echo "O projeto informado " ${PROJETO} "já existe com o nome " ${PROJECTNAME} " e id " ${PRJEXISTS}
    exit 99
fi


#
# cria projeto
#

# aqui preciso recuperar do id do grupo
NAMESPACEID=""
NAMESPACEID=$GROUPID


if [ "${NAMESPACEID}"x != ""x ] ; then
    RETCRIAPROJETO=$( \
        curl \
           --silent --show-error --header "Private-Token: ${PRIVATETOKEN}"\
            --data "name=${PROJECTNAME}&namespace_id=${NAMESPACEID}&visibility=${VISIBILITY}&lfs_enabled=${LFS}"\
            ${SERVER}/api/v4/projects )
    echo "Projeto Criado "
    echo $RETCRIAPROJETO | jq  ' { "Nome do Projeto" : .name, "Grupo e Projeto": .path_with_namespace } ' | sed 's/{//;s/}//'
    sleep 2s
else
  echo "Não foi possível criar o projeto " ${PROJECTNAME} " dentro do grupo com id " ${NAMESPACEID}
  exit 98
fi

# recuperar o id do projeto recém criado que será usado para operações no projeto
PROJECTID=""
PROJECTID=$(echo $RETCRIAPROJETO | jq '.id')


###
# Quando acrescento o usuário ao grupo, ele terá as mesmas permissões no projeto
# https://youtu.be/4TWfh1aKHHw?t=177
###


PAYLOAD=$(cat << 'JSON'
 {
   "branch": "master",
   "commit_message": ".gitignore",
   "actions": [
     {
       "action": "create",
       "file_path": ".gitignore",
       "content": ""
     }
   ]
 }
JSON
)

echo "Criando .gitignore no branch master:" ;

curl \
    --silent --show-error \
    --request POST \
    --header "Private-Token: ${PRIVATETOKEN}" \
    --header "Content-Type: application/json" --data "$PAYLOAD"\
    ${SERVER}/api/v4/projects/${PROJECTID}/repository/commits | jq '{short_id, message}'

sleep 2s;

echo "Verificando proteção de push no master" ;
# verifica se o master tem algum tipo de proteção
MASTERPROTEGIDO=$(curl \
		      --silent --show-error \
		      --request GET \
		      --header "Private-Token: ${PRIVATETOKEN}" \
		      ${SERVER}/api/v4/projects/${PROJECTID}/protected_branches | jq -c '.[]| {name}' | grep -c 'master'
	       )
if [[ $MASTERPROTEGIDO -gt 0 ]] ; then

    echo "Removendo proteção de push" ;
    curl \
	--silent --show-error \
	--request DELETE \
	--header "Private-Token: ${PRIVATETOKEN}" \
	${SERVER}/api/v4/projects/${PROJECTID}/protected_branches/master

    echo ""
fi

if [[ "$BLOQUEIA_BRANCHES_EVO"x == "false"x  ]] ; then

    sleep 2s;
    echo "Atribuindo permissões de escrita no branch master para Desenvolvedores (push access level)" ;

    curl \
	--silent --show-error \
	--request POST\
	--header "Private-Token: ${PRIVATETOKEN}" \
	"${SERVER}/api/v4/projects/${PROJECTID}/protected_branches?name=master&push_access_level=30&merge_access_level=30&unprotect_access_level=40" | jq '.push_access_levels[] | .access_level_description'

    sleep 2s;

else

    echo "Protegendo branches Master e Hotfix e permitindo merge para Developers" ;
    # https://docs.gitlab.com/ee/api/protected_branches.html
    # 0  => No access
    # 30 => Developer access
    # 40 => Maintainer access
    # 60 => Admin access

    # master
    echo -n "Push no branch master -> "
    curl \
	--silent --show-error \
	--request POST\
	--header "Private-Token: ${PRIVATETOKEN}" \
	"${SERVER}/api/v4/projects/${PROJECTID}/protected_branches?name=master&push_access_level=40&merge_access_level=30&unprotect_access_level=40" | jq '.push_access_levels[] | .access_level_description'

    # hotfix
    echo -n "Push no branch hotfix -> "
    curl \
	--silent --show-error \
	--request POST\
	--header "Private-Token: ${PRIVATETOKEN}" \
	"${SERVER}/api/v4/projects/${PROJECTID}/protected_branches?name=hotfix&push_access_level=40&merge_access_level=30&unprotect_access_level=40" | jq '.push_access_levels[] | .access_level_description'

fi

echo -n "Verifique o projeto criado no endereço: "

curl \
    --silent --show-error \
    --request GET \
    --header "Private-Token: ${PRIVATETOKEN}" \
    ${SERVER}/api/v4/projects/${PROJECTID} | jq '.http_url_to_repo'



#
# Usuários no Grupo
#

echo "Usuários existentes no grupo e com permissão no novo projeto"

curl -s  --header "Private-Token: ${PRIVATETOKEN}" \
     -G ${SERVER}/api/v4/groups/${GROUPID}/members | \
    jq -c '.[]| { name } ' | \
    cut -f 4 -d \" | \
    sed -e 's/^/ + /'
