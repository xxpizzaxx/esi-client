# esi-client

This repository ties together [swagger-codegen-blazescala](https://github.com/andimiller/swagger-codegen-blazescala/) with swagger-codegen and the EVE ESI definition, building an http4-based API client for the EVE Online ESI API

# Getting Started


This project ties together a few libraries you'll want a passing familiarity with, Scalaz is a popular library for functional programming in Scala. http4s is a library for functional-style HTTP on Scala, and the rest should be easy enough.

## Using sbt to set up a basic project and messing around with Ammonite REPL

[Ammonite-REPL](http://www.lihaoyi.com/Ammonite/#Ammonite-REPL) is a pretty great Scala repl, we're going to use it alongside sbt, the standard scala build tool.


### Making our project

As is tradition, let's make a build.sbt

```bash
andi@kyubey eveapi-demo > cat > build.sbt
name := "eveapi-demo"
version := "1.0"
scalaVersion := "2.11.8"
resolvers += Resolver.jcenterRepo
libraryDependencies += "eveapi" %% "esi-client" % "0.4.0"
```

And let's install the sbt-ammonite plugin, so we can launch our repl

```bash
andi@kyubey eveapi-demo > mkdir ~/.sbt/0.13/plugins
andi@kyubey eveapi-demo > cat > ~/.sbt/0.13/plugins/amm.sbt                                                                                                                                                     <
resolvers += Resolver.sonatypeRepo("releases")
addSbtPlugin("com.github.alexarchambault" %% "sbt-ammonite" % "0.1.2")
```

And let's launch the repl and import the project!

```scala
andi@kyubey eveapi-demo > sbt ammonite:run
...package resolution goes here... 
[info] Done updating.
[info] Running ammonite.repl.Main
Loading...
Welcome to the Ammonite Repl 0.6.0
(Scala 2.11.8 Java 1.8.0_111)
@ import eveapi.esi.client.EsiClient, argonaut._, Argonaut._, ArgonautShapeless._, argonautCodecs.ArgonautCodecs._
import eveapi.esi.client.EsiClient, argonaut._, Argonaut._, ArgonautShapeless._, argonautCodecs.ArgonautCodecs._
```

We need the EsiClient class, and argonaut so it can parse JSON, ArgonautShapeless lets it infer codecs, and we bring in a few of the library's codecs for DateTimes.

Let's start out with something simple, looking up a character

```scala
@ val esi = new EsiClient()
esi: EsiClient = eveapi.esi.client.EsiClient@17b2e5d0
@ esi.character.getCharactersCharacterId(90758388)
res2: scalaz.concurrent.Task[scalaz.\/[esi.character.getCharactersCharacterIdErrors, eveapi.esi.model.Get_characters_character_id_ok]] = scalaz.concurrent.Task@597ce106
@ res2.run
res3: scalaz.\/[esi.character.getCharactersCharacterIdErrors, eveapi.esi.model.Get_characters_character_id_ok] = \/-(Get_characters_character_id_ok(37, 2011-05-18T19:36:00Z, 13, 98040755, "I fly internet spaceships.<br><br>Sometimes I even program things.", "female", "Lucia Denniard", 4, Some(-1.4869757F)))
```

As you can see, using the endpoint gave us a Task with a \\/ inside, this is called a disjunction, our left side is the errors, and the right side is Ok.

When we call .run on it, it makes the HTTP request, and returns a successful disjunction with the model in it with our result

So how do we work with that? what if we want the name?

```scala
@ res2.run.map{x => x.name}
res4: scalaz.\/[esi.character.getCharactersCharacterIdErrors, String] = \/-("Lucia Denniard")
```

so we can run that same res2 object as many times as we want, and it'll make the HTTP request each time, this time we got a successful disjunction with just the name in.
