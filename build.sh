if [ ! -d blazescala ]; then
  git clone https://github.com/andimiller/swagger-codegen-blazescala blazescala
fi
if [ ! -d swagger-codegen ]; then
  git clone https://github.com/swagger-api/swagger-codegen
fi
if [ ! -f swagger-codegen/modules/swagger-codegen-cli/target/swagger-codegen-cli.jar ]; then
  cd swagger-codegen
  mvn package
  cd ..
fi
java -jar swagger-codegen/modules/swagger-codegen-cli/target/swagger-codegen-cli.jar generate -i https://esi.tech.ccp.is/latest/swagger.json -l async-scala -o client -t blazescala --api-package eveapi.esi.api --invoker-package eveapi.esi.client --model-package eveapi.esi.model --additional-properties clientName=EsiClient  --artifact-id esi-client --group-id eveapi
cp blazescala/*.scala client/src/main/scala/
