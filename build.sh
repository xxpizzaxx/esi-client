if [ ! -d blazescala ]; then
  git clone https://github.com/andimiller/swagger-codegen-blazescala blazescala
fi
if [ ! -f swagger-codegen-cli-2.2.1.jar ]; then
  wget http://jcenter.bintray.com/io/swagger/swagger-codegen-cli/2.2.1/swagger-codegen-cli-2.2.1.jar
fi
java -jar swagger-codegen-cli-2.2.1.jar generate -i https://esi.tech.ccp.is/latest/swagger.json -l async-scala -o client -t blazescala --api-package eveapi.esi.api --invoker-package eveapi.esi.client --model-package eveapi.esi.model --additional-properties clientName=EsiClient  --artifact-id esi-client --group-id eveapi
cp blazescala/*.scala client/src/main/scala/
