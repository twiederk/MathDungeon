package com.d20charactersheet.mathdungeon

import org.jline.terminal.Attributes
import kotlinx.coroutines.*
import org.jline.terminal.TerminalBuilder
import java.util.concurrent.atomic.AtomicBoolean


fun main() = runBlocking {

    val running = AtomicBoolean(true)
    val world = World()

    // --- Player ---
    val player = world.createEntity()
    world.positions[player] = Position(1, 1)
    world.renderables[player] = Renderable('@')
    world.velocities[player] = Velocity(0, 0)

    // --- Monster ---
    val rat = world.createEntity()
    world.positions[rat] = Position(4, 1)
    world.renderables[rat] = Renderable('R')

    val goblin = world.createEntity()
    world.positions[goblin] = Position(4, 3)
    world.renderables[goblin] = Renderable('G')

    // --- Terminal Setup ---
    val terminal = TerminalBuilder.builder()
        .system(true)
        .jna(true)
        .build()

// direkt nach Terminal-Erzeugung
    var savedAttributes: Attributes? = null

    fun enterRaw() {
        // enterRawMode() gibt die vorherigen Attribute zurück
        savedAttributes = terminal.enterRawMode()
        // sicherstellen, dass Echo im Spiel ausgeschaltet ist
        try {
            terminal.echo(false)
        } catch (_: Throwable) { /* falls nicht unterstützt, ignorieren */ }
        print("\u001b[?25l") // Cursor ausblenden
        System.out.flush()
    }

    fun exitRaw() {
        // alte Attribute wiederherstellen (inkl. Echo)
        savedAttributes?.let {
            try {
                terminal.setAttributes(it)
            } catch (_: Throwable) { /* falls nicht unterstützt, ignorieren */ }
            savedAttributes = null
        } ?: run {
            // Fallback: Echo wieder einschalten, falls setAttributes nicht verfügbar war
            try {
                terminal.echo(true)
            } catch (_: Throwable) { /* ignorieren */ }
        }
        print("\u001b[?25h") // Cursor einblenden
        System.out.flush()
    }


    enterRaw()
    val reader = terminal.reader()

    // --- Systeme ---
    val renderSystem = RenderSystem(world, dungeon)
    val movementSystem = MovementSystem(world, dungeon)
    val collisionSystem = CollisionSystem(world, player, rat, goblin)
    val inputSystem = InputSystem(world, player, reader, running)

    while (true) {

        // Reset Quiz-Flag
        world.ratQuiz = false

        // --- Render Loop ---
        val renderJob = launch(Dispatchers.Default) {
            while (running.get() && !world.ratQuiz) {
                movementSystem.update()
                collisionSystem.update()
                renderSystem.render()
                delay(50)
            }
        }

        // --- Input Loop ---
        val inputJob = launch(Dispatchers.IO) {
            inputSystem.run()
        }

        // --- Warten bis entweder Quit oder Quiz ---
        while (running.get() && !world.ratQuiz) {
            delay(20)
        }

        // --- Fall 1: Quit ---
        if (!running.get()) {
            renderJob.cancelAndJoin()
            inputJob.cancelAndJoin()
            break
        }

        // --- Fall 2: Quiz ausgelöst ---
        if (world.ratQuiz || world.goblinQuiz) {

            // Loops stoppen
            renderJob.cancelAndJoin()
            inputJob.cancelAndJoin()

            // Raw-Mode verlassen
            exitRaw()

            // --- QUIZPHASE ---
            println()
            println("Du bist mit dem Monster kollidiert!")
            println("Beantworte die Aufgabe, um weiterzugehen.")

            var ok = false
            while (!ok) {
                if (world.ratQuiz) {
                    println("Was ist 1 + 1?")
                } else if (world.goblinQuiz) {
                    println("Was ist 2 * 3?")
                }
                print("Was ist 1 + 1? ")
                var answer = readLine()

//                println("Du hast eingegeben: [${answer}]")
//                println("ASCII Codes: " + answer?.map { it.code })

                // Eingabe bereinigen (Pfeiltasten etc. entfernen)
                if (answer?.get(0)?.code == 91) {
                    answer = answer.substring(2)
                }

                if (answer?.trim()?.isEmpty() == true) {
                    continue
                }

                if (world.ratQuiz && answer == "2") {
                    println("Richtig! Du darfst weitergehen.")
                    ok = true
                    // Monster als besiegt markieren und aus der Anzeige entfernen
                    world.defeated.add(rat)
                    world.renderables.remove(rat)
                    world.positions.remove(rat)
                    world.ratQuiz = false
                } else if (world.goblinQuiz && answer == "6") {
                    println("Richtig! Du darfst weitergehen.")
                    ok = true
                    // Monster als besiegt markieren und aus der Anzeige entfernen
                    world.defeated.add(goblin)
                    world.renderables.remove(goblin)
                    world.positions.remove(goblin)
                    world.goblinQuiz = false
                } else {
                    println("Leider falsch, versuch es nochmal. $answer ist nicht korrekt.")
                }
            }

            // --- zurück ins Spiel ---
            enterRaw()
        }
    }

    // --- Spielende ---
    exitRaw()
    terminal.close()
    println("Programm beendet.")
}
