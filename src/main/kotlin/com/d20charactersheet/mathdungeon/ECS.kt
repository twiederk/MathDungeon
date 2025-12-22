package com.d20charactersheet.mathdungeon

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
    val monster = world.createEntity()
    world.positions[monster] = Position(4, 1)
    world.renderables[monster] = Renderable('M')

    // --- Terminal Setup ---
    val terminal = TerminalBuilder.builder()
        .system(true)
        .jna(true)
        .build()

    fun enterRaw() {
        terminal.enterRawMode()
        print("\u001b[?25l") // Cursor ausblenden
        System.out.flush()
    }

    fun exitRaw() {
        print("\u001b[?25h") // Cursor einblenden
        System.out.flush()
        // JLine verlässt Raw-Mode automatisch beim Schließen,
        // aber für das Quiz nutzen wir einfach stdin.
    }

    enterRaw()
    val reader = terminal.reader()

    // --- Systeme ---
    val renderSystem = RenderSystem(world, dungeon)
    val movementSystem = MovementSystem(world, dungeon)
    val collisionSystem = CollisionSystem(world, player, monster)
    val inputSystem = InputSystem(world, player, reader, running)

    var gameRunning = true

    while (gameRunning) {

        // Reset Quiz-Flag
        world.quizRequested = false

        // --- Render Loop ---
        val renderJob = launch(Dispatchers.Default) {
            while (running.get() && !world.quizRequested) {
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
        while (running.get() && !world.quizRequested) {
            delay(20)
        }

        // --- Fall 1: Quit ---
        if (!running.get()) {
            renderJob.cancelAndJoin()
            inputJob.cancelAndJoin()
            gameRunning = false
            break
        }

        // --- Fall 2: Quiz ausgelöst ---
        if (world.quizRequested) {

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
                print("Was ist 1 + 1? ")
                val answer = readLine()

                if (answer == "2") {
                    println("Richtig! Du darfst weitergehen.")
                    ok = true
                } else {
                    println("Leider falsch, versuch es nochmal.")
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
