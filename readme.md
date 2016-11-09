# esi-client

This repository ties together [swagger-codegen-blazescala](https://github.com/andimiller/swagger-codegen-blazescala/) with swagger-codegen and the EVE ESI definition, building an http4s-based API client for the EVE Online ESI API

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

### Turning it into a real application

Let's write a little program to look up a character's security status, with some error handling

```scala
andi@kyubey eveapi-demo > cat src/main/scala/Main.scala
import eveapi.esi.client.EsiClient, argonaut._, Argonaut._, ArgonautShapeless._, argonautCodecs.ArgonautCodecs._
import scalaz._, Scalaz._

object Main extends App {
  val client = new EsiClient()
  val result = client.character.getCharactersCharacterId(90758388).run
  val output = result match {
    case -\/(error) => s"unable to run, error: $error"
    case \/-(character) => s"${character.name}'s security status is ${character.security_status.getOrElse(0.0)}"
  }
  println(output)
  client.client.shutdown.run
}
```

and let's run it with sbt

```bash
andi@kyubey eveapi-demo > sbt run
[info] Loading global plugins from /home/andi/.sbt/0.13/plugins
[info] Set current project to eveapi-demo (in build file:/home/andi/workspace/eveapi-demo/)
[info] Compiling 1 Scala source to /home/andi/workspace/eveapi-demo/target/scala-2.11/classes...
[info] Running Main
Lucia Denniard's security status is -1.4869757
[success] Total time: 13 s, completed 08-Nov-2016 23:13:04
```


### Combining multiple requests

Let's say we want to get the active sovereignty campaigns on singularity, and fetch the information of all the defenders, combining the action into one Task

```scala
andi@kyubey eveapi-demo > cat > src/main/scala/Main.scala
import eveapi.esi.client.EsiClient, argonaut._, Argonaut._, ArgonautShapeless._, argonautCodecs.ArgonautCodecs._
import scalaz._, Scalaz._
import scalaz.concurrent.Task

object Main extends App {
  // make a normal client
  val client = new EsiClient()
  // get all the sovereignty campaigns from singularity
  val campaigns = client.sovereignty.getSovereigntyCampaigns(datasource=Some("singularity")).map{ res =>
    res.map { sov =>
      // if we got a successful result, let's get all the distinct alliances who have defensive timers
      val defenders = sov.flatMap{_.defender_id}.distinct
      // let's get their names and data
      val defenderNameTasks = defenders.map{id => client.alliance.getAlliancesAllianceId(id.toInt, datasource=Some("singularity"))}
      // we've got a list of tasks now, let's run them as a batch in parallel
      val defenderAlliancesTask = Task.gatherUnordered(defenderNameTasks)
      // let's attempt to run the jobs and aggregate them all together, coping with errors
      defenderAlliancesTask.attemptRun.map{x => x.flatMap(_.toOption)}.toList.flatten
    }
  }

  // now let's try and run the job
  campaigns.attemptRun match {
    case -\/(error) => println(s"we failed to get the sov data: $error")
    case \/-(alliances) => println(s"alliances currently defending timers are: $alliances")
  }

  // shut down our client's worker pool
  client.client.shutdown.run
}
```

and running it:
```bash
andi@kyubey eveapi-demo > sbt run
[info] Loading global plugins from /home/andi/.sbt/0.13/plugins
[info] Set current project to eveapi-demo (in build file:/home/andi/workspace/eveapi-demo/)
[info] Compiling 1 Scala source to /home/andi/workspace/eveapi-demo/target/scala-2.11/classes...
[info] Running Main
alliances currently defending timers are: \/-(List(Get_alliances_alliance_id_ok(Infinity Space.,2013-06-12T11:47:48Z,98229345,IN.SP), Get_alliances_alliance_id_ok(Brothers of Tangra,2013-02-28T06:07:31Z,98181032,B0T), Get_alliances_alliance_id_ok(Tactical-Retreat,2016-09-19T21:09:22Z,781729299,FLEE), Get_alliances_alliance_id_ok(DARKNESS.,2013-02-09T22:32:32Z,98173905,DARK.), Get_alliances_alliance_id_ok(The Volition Cult,2006-09-22T23:39:00Z,112702028,VOLT), Get_alliances_alliance_id_ok(La Ligue des mondes libres,2015-03-10T01:05:46Z,98201052,LLDML)))
[success] Total time: 19 s, completed 08-Nov-2016 23:37:33
```
