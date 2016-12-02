if [ ! -f swagger-codegen-cli-2.2.1.jar ]; then
  wget http://jcenter.bintray.com/io/swagger/swagger-codegen-cli/2.2.1/swagger-codegen-cli-2.2.1.jar
fi


function generate {
  java -jar swagger-codegen-cli-2.2.1.jar generate -i ./esi-archive/$1/swagger.json -l async-scala -o client-$1 -t ./swagger-codegen-blazescala --api-package eveapi.esi.api --invoker-package eveapi.esi.client --model-package eveapi.esi.model --additional-properties clientName=EsiClient  --artifact-id esi-client --group-id eveapi
  cp ./swagger-codegen-blazescala/*.scala client-$1/src/main/scala/
  mkdir client-$1/project/
  cp ./swagger-codegen-blazescala/*.sbt   client-$1/project/
  cp ./swagger-codegen-blazescala/*.scala client-$1/src/main/scala/
  echo "bintrayVcsUrl := Some(\"git@github.com:xxpizzaxx/esi-client.git\")" >> client-$1/build.sbt
  ./esi-client/scalafmt -i -f client-$1 --config scalafmt.conf
}

generate latest
generate legacy
generate dev

function compile {
  pushd .
  cat esi-version/number | sed 's/^/version in ThisBuild := "/g' | sed 's/$/"/g' > client-$1/version.sbt
  cd client-$1
  sbt compile
  popd
}

compile latest
compile legacy
compile dev

# load bintray credentials
mkdir -p ~/.bintray
echo $BINTRAY_CREDENTIALS | sed 's/>/\n/g' > ~/.bintray/.credentials
wc -l ~/.bintray/.credentials
cd client-latest
sbt publish

