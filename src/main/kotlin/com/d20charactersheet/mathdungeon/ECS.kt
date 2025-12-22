package com.d20charactersheet.mathdungeon

import kotlinx.coroutines.*
import org.jline.terminal.TerminalBuilder
import java.util.concurrent.atomic.AtomicBoolean

// --- ECS Grundtypen ---



fun main() = runBlocking {

    val running = AtomicBoolean(true)

    // --- World + Entities ---
    val world = World()

    val player = world.createEntity()
    world.positions[player] = Position(1, 1)
    world.renderables[player] = Renderable('@')
    world.velocities[player] = Velocity(0, 0)

    // --- Monster Entity ---
    val monster = world.createEntity()
    world.positions[monster] = Position(4, 1)
    world.renderables[monster] = Renderable('M')



    // --- Terminal Setup ---
    val terminal = TerminalBuilder.builder()
        .system(true)
        .jna(true)
        .build()

    terminal.enterRawMode()
    print("\u001b[?25l") // Cursor verstecken
    val reader = terminal.reader()

    // --- Systeme ---
    val renderSystem = RenderSystem(world, dungeon)
    val movementSystem = MovementSystem(world, dungeon)
    val inputSystem = InputSystem(world, player, reader, running)
    val collisionSystem = CollisionSystem(world, player, monster)

    // --- Render Loop ---
    val renderJob = launch(Dispatchers.Default) {
        while (running.get()) {

            movementSystem.update()
            collisionSystem.update()   // ✅ Hier prüfen wir die Kollision
            renderSystem.render()

            delay(50)
        }
    }


    // --- Input Loop ---
    val inputJob = launch {
        inputSystem.run()
    }

    inputJob.join()
    running.set(false)
    renderJob.cancelAndJoin()

    print("\u001b[?25h") // Cursor wieder einblenden
    terminal.close()
    println("Programm beendet.")
}
