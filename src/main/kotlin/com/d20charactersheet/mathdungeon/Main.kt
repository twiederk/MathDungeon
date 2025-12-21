package com.d20charactersheet.mathdungeon

import kotlinx.coroutines.*

fun main() = runBlocking {
    println("Starte Prozess...")

    // Animation im Hintergrund starten
    val animationJob = launchAnimation()

    // Simuliere eine Aufgabe (z.B. Datenbank-Abfrage oder API-Call)
    delay(3000)

    // Animation stoppen
    animationJob.cancelAndJoin()

    println("\rFertig!          ") // \r setzt den Cursor an den Zeilenanfang
}

fun CoroutineScope.launchAnimation() = launch(Dispatchers.Default) {
    val frames = listOf("|", "/", "-", "\\")
    var i = 0

    try {
        while (isActive) {
            // \r kehrt zum Zeilenanfang zurück, ohne eine neue Zeile zu beginnen
            print("\rLade ${frames[i % frames.size]} ")
            i++
            delay(250) // Geschwindigkeit der Drehung
        }
    } catch (e: CancellationException) {
        // Job wurde beendet
    }
}