#!/bin/bash
set +x

USUARIO=${USUARIO:=leslie}
CHANNEL=${CHANNEL:='emacs'}
MSG=${MSG:="Olá, welcome, bienvenido, hertzlich willkommen"}
SERVER=$1

if [[ $SERVER -eq 0 ]] ; then

    SERVER="https://chathml.my-rocket-chat-install.br"

else

# comente aqui pra baixo para ir para homologação
    SERVER="https://chat.my-rocket-chat-install.br"
fi 

read -sp "Password: " PASSWD
CREDS=$( curl -s -H "Content-type:application/json" \
    	  ${SERVER}/api/v1/login \
    	  -d "{ \"user\": \"$USUARIO\", \"password\": \"$PASSWD\" }" \
    	 | jq '. | .data | {userId,authToken}' \
     )

USERID=$(echo $CREDS| cut -f 1 -d , | cut -f 4 -d \")
AUTHTOKEN=$(echo $CREDS| cut -f 2 -d, | cut -f 4 -d \")

ROOMID=$(
    curl -s -H "X-Auth-Token: $AUTHTOKEN" \
	 -H "X-User-Id: $USERID" \
	 ${SERVER}/api/v1/rooms.info?roomName=${CHANNEL}  | jq '.room._id' | sed 's/"//g'
      )

#echo $ROOMID

while read MSG
do
    M=$(echo "$MSG")
    curl -s -H "X-Auth-Token: $AUTHTOKEN" \
	 -H "X-User-Id: $USERID" \
	 -H "Content-type:application/json" \
	 ${SERVER}/api/v1/chat.postMessage \
	 -d "{ \"channel\": \"#${CHANNEL}\", \"text\": \"${M}\" }" \
	| jq '. | { canal: .channel, Mensagem: .message.msg, "Data e hora": .message.ts, "Enviado por": .message.u.username }'
    sleep 1


    curl  -s "${SERVER}/api/v1/rooms.upload/${ROOMID}" \
	  -F "file=@$HOME/tmp/rc/Message.wav;type=audio/wav"  \
	  -F "msg=Mensagem de Oh Oh do ICQ" \
	  -F "description=Oh Oh" \
	  -H "X-Auth-Token: $AUTHTOKEN" \
	  -H "X-User-Id: $USERID"  \
	| jq '. | { Mensagem: .message.msg, Filename: .message.file.name, Sucesso: .success} '
    
    curl  -s "${SERVER}/api/v1/rooms.upload/${ROOMID}" \
	  -F "file=@$HOME/tmp/rc/user-handbook.pdf;type=application/pdf"  \
	  -F "msg=User Handbook" \
	  -F "description=PDF de Livro do Usuário" \
	  -H "X-Auth-Token: $AUTHTOKEN" \
	  -H "X-User-Id: $USERID"  \
	| jq '. | { Mensagem: .message.msg, Filename: .message.file.name, Sucesso: .success} '

    curl  -s "${SERVER}/api/v1/rooms.upload/${ROOMID}" \
	  -F "file=@$HOME/tmp/rc/rammstein.mp3;type=audio/mpeg"  \
	  -F "msg=Rammstein" \
	  -F "description=Rammstein -- Ramstein.mp3" \
	  -H "X-Auth-Token: $AUTHTOKEN" \
	  -H "X-User-Id: $USERID"  \
	| jq '. | { Mensagem: .message.msg, Filename: .message.file.name, Sucesso: .success} '

    curl  -s "${SERVER}/api/v1/rooms.upload/${ROOMID}" \
	  -F "file=@$HOME/tmp/rc/Apresentacao_2019.odp;type=application/vnd.oasis.opendocument.presentation"  \
	  -F "msg=Apresentação Openshift 2019" \
	  -F "description=Apresentação do openshift" \
	  -H "X-Auth-Token: $AUTHTOKEN" \
	  -H "X-User-Id: $USERID"  \
	| jq '. | { Mensagem: .message.msg, Filename: .message.file.name, Sucesso: .success} '

    curl -s -H "X-Auth-Token: $AUTHTOKEN" \
	 -H "X-User-Id: $USERID" \
	 -H "Content-type:application/json" \
	 ${SERVER}/api/v1/chat.postMessage \
	 -d "{
  \"alias\": \"Gruggy\",
  \"avatar\": \"http://res.guggy.com/logo_128.png\",
  \"channel\": \"#${CHANNEL}\",
  \"emoji\": \":smirk:\",
  \"text\": \"Sample message\",
  \"attachments\": [
    {
      \"audio_url\": \"http://www.w3schools.com/tags/horse.mp3\",
      \"author_icon\": \"https://avatars.githubusercontent.com/u/850391?v=3\",
      \"author_link\": \"https://rocket.chat/\",
      \"author_name\": \"Bradley Hilton\",
      \"collapsed\": false,
      \"color\": \"#ff0000\",
      \"fields\": [
        {
          \"short\": true,
          \"title\": \"Test\",
          \"value\": \"Testing out something or other\"
        },
        {
          \"short\": true,
          \"title\": \"Another Test\",
          \"value\": \"[Link](https://google.com/) something and this and that.\"
        }
      ],
      \"image_url\": \"https://www.confianca.com.br/media/catalog/product/cache/1/image/9df78eab33525d08d6e5fb8d27136e95/1/1/114520-7.jpg.jpg\",
      \"message_link\": \"https://google.com\",
      \"text\": \"Yay for Manga!\",
      \"thumb_url\": \"http://individual.icons-land.com/IconsPreview/3D-Food/PNG/128x128/Berry_Strawberry.png\",
      \"title\": \"Attachment Example\",
      \"title_link\": \"https://www.youtube.com/watch?v=9i_9hse_Y08\",
      \"title_link_download\": true,
      \"ts\": \"2020-12-09T16:53:06.761Z\",
      \"video_url\": \"http://www.w3schools.com/tags/movie.mp4\"
    }
  ]
}" | jq '.'
    
done < book.txt
