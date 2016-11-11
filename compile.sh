if [ ! -f swagger-codegen-cli-2.2.1.jar ]; then
  wget http://jcenter.bintray.com/io/swagger/swagger-codegen-cli/2.2.1/swagger-codegen-cli-2.2.1.jar
fi


function generate {
  java -jar swagger-codegen-cli-2.2.1.jar generate -i ./esi-archive/$1/swagger.json -l async-scala -o client-$1 -t ./swagger-codegen-blazescala --api-package eveapi.esi.api --invoker-package eveapi.esi.client --model-package eveapi.esi.model --additional-properties clientName=EsiClient  --artifact-id esi-client --group-id eveapi
  cp blazescala/*.scala client-$1/src/main/scala/
}

generate latest
generate legacy
generate dev
