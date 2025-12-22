package com.d20charactersheet.mathdungeon

import kotlinx.coroutines.*
import org.jline.terminal.TerminalBuilder
import java.util.concurrent.atomic.AtomicBoolean

// --- ECS Grundtypen ---

typealias Entity = Int

class World {

    private var nextEntityId = 0

    // Component-Storage
    val positions = mutableMapOf<Entity, Position>()
    val renderables = mutableMapOf<Entity, Renderable>()
    val blockers = mutableSetOf<Entity>()
    val velocities = mutableMapOf<Entity, Velocity>()

    fun createEntity(): Entity = nextEntityId++
}

// --- Components ---

data class Position(var x: Int, var y: Int)
data class Velocity(var dx: Int, var dy: Int)
data class Renderable(val char: Char, val layer: Int = 0) // layer falls du mal sortieren willst

// --- Dungeon Map ---

val rawMap = listOf(
    "###########",
    "#.........#",
    "###########"
)

val dungeon = rawMap.map { it.toCharArray() }.toMutableList()

fun isBlocked(x: Int, y: Int, dungeon: List<CharArray>): Boolean {
    if (y !in dungeon.indices) return true
    if (x !in dungeon[y].indices) return true
    return dungeon[y][x] == '#'
}

// --- Render System ---

class RenderSystem(
    private val world: World,
    private val dungeon: List<CharArray>
) {
    private var lastFrame = ""

    fun render() {
        val sb = StringBuilder()

        // Clear Screen + Cursor Home
        sb.append("\u001b[H")
        sb.append("\u001b[2J")

        val height = dungeon.size
        val width = dungeon[0].size

        val charBuffer = Array(height) { y ->
            CharArray(width) { x ->
                dungeon[y][x]
            }
        }

        // Entities einzeichnen
        for ((entity, pos) in world.positions) {
            val renderable = world.renderables[entity] ?: continue
            if (pos.y in 0 until height && pos.x in 0 until width) {
                charBuffer[pos.y][pos.x] = renderable.char
            }
        }

        // Frame zusammenbauen
        for (y in 0 until height) {
            for (x in 0 until width) {
                sb.append(charBuffer[y][x])
            }
            sb.append('\n')
        }

        sb.append("Bewege mit W/A/S/D oder Pfeiltasten. Q beendet.\n")

        val frame = sb.toString()

        // ✅ Double Buffering: Nur zeichnen, wenn sich etwas geändert hat
        if (frame != lastFrame) {
            print(frame)
            System.out.flush()
            lastFrame = frame
        }
    }
}

// --- Movement System ---

class MovementSystem(
    private val world: World,
    private val dungeon: List<CharArray>
) {
    fun update() {
        for ((entity, vel) in world.velocities) {
            val pos = world.positions[entity] ?: continue

            if (vel.dx == 0 && vel.dy == 0) continue

            val nx = pos.x + vel.dx
            val ny = pos.y + vel.dy

            if (!isBlocked(nx, ny, dungeon)) {
                pos.x = nx
                pos.y = ny
            }

            // Velocity nach Bewegung zurücksetzen
            vel.dx = 0
            vel.dy = 0
        }
    }
}

// --- Input System ---

class InputSystem(
    private val world: World,
    private val player: Entity,
    private val reader: java.io.Reader,
    private val running: AtomicBoolean
) {

    suspend fun run() = withContext(Dispatchers.IO) {
        val vel = world.velocities[player] ?: Velocity(0, 0).also { world.velocities[player] = it }

        while (running.get()) {
            val ch = reader.read()

            when (ch) {
                // WASD
                'w'.code, 'W'.code -> { vel.dy = -1; vel.dx = 0 }
                's'.code, 'S'.code -> { vel.dy = 1; vel.dx = 0 }
                'a'.code, 'A'.code -> { vel.dx = -1; vel.dy = 0 }
                'd'.code, 'D'.code -> { vel.dx = 1; vel.dy = 0 }

                // Pfeiltasten (ESC [ A/B/C/D)
                27 -> {
                    val next1 = reader.read()
                    if (next1 == 91) {
                        when (reader.read()) {
                            65 -> { vel.dy = -1; vel.dx = 0 } // Up
                            66 -> { vel.dy = 1; vel.dx = 0 }  // Down
                            67 -> { vel.dx = 1; vel.dy = 0 }  // Right
                            68 -> { vel.dx = -1; vel.dy = 0 } // Left
                        }
                    }
                }

                // Quit
                'q'.code, 'Q'.code -> running.set(false)
            }
        }
    }
}

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

    // --- Render Loop ---
    val renderJob = launch(Dispatchers.Default) {
        while (running.get()) {
            movementSystem.update()
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
