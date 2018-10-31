if [ ! -d swagger-codegen-blazescala ]; then
  git clone https://github.com/andimiller/swagger-codegen-blazescala
fi
if [ ! -f swagger-codegen-cli-2.2.1.jar ]; then
  wget http://jcenter.bintray.com/io/swagger/swagger-codegen-cli/2.2.1/swagger-codegen-cli-2.2.1.jar
fi
cat swagger-codegen-blazescala/client.header.mustache swagger-codegen-blazescala/*.scala swagger-codegen-blazescala/client.footer.mustache > swagger-codegen-blazescala/client.mustache
java -jar swagger-codegen-cli-2.2.1.jar generate -i https://esi.tech.ccp.is/latest/swagger.json -l async-scala -o client -t ./swagger-codegen-blazescala --api-package eveapi.esi.api --invoker-package eveapi.esi.client --model-package eveapi.esi.model --additional-properties clientName=EsiClient  --artifact-id esi-client --group-id eveapi
./scalafmt -i -f client --config scalafmt.conf
