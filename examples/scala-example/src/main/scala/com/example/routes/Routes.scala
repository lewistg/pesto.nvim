package com.example.routes

import cats.effect.*
import org.http4s.*
import org.http4s.dsl.io.*
import org.http4s.implicits.*

object Routes {
  val helloService = HttpRoutes.of[IO] {
    case GET -> Root =>
      Ok(s"hello")
  }.orNotFound
}
