if [ ! -d blazescala ]; then
  git clone https://github.com/andimiller/swagger-codegen-blazescala blazescala
fi
if [ ! -f swagger-codegen-cli-2.3.1.jar ]; then
  wget http://jcenter.bintray.com/io/swagger/swagger-codegen-cli/2.3.1/swagger-codegen-cli-2.3.1.jar
fi
cat blazescala/client.header.mustache blazescala/*.scala blazescala/client.footer.mustache > blazescala/client.mustache
java -jar swagger-codegen-cli-2.3.1.jar generate -i https://esi.tech.ccp.is/latest/swagger.json -l scala -o client -t blazescala --api-package eveapi.esi.api --invoker-package eveapi.esi.client --model-package eveapi.esi.model --additional-properties clientName=EsiClient  --artifact-id esi-client --group-id eveapi
./scalafmt -i -f client --config scalafmt.conf
