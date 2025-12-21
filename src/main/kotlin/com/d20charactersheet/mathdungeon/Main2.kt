package com.d20charactersheet.mathdungeon

import kotlinx.coroutines.*
import org.jline.terminal.TerminalBuilder
import java.util.concurrent.atomic.AtomicBoolean

fun main() = runBlocking {

    // --- Dungeon Map ---
    val raw = listOf(
        "###########",
        "#.........#",
        "###########"
    )
    val map = raw.map { it.toCharArray() }.toMutableList()

    var playerX = 1
    var playerY = 1
    val running = AtomicBoolean(true)

    val dungeonHeight = map.size + 1

    // --- Terminal Setup (JLine) ---
    val terminal = TerminalBuilder.builder()
        .system(true)
        .jna(true)
        .build()

    terminal.enterRawMode()
    val reader = terminal.reader()

    fun render() {
        // Cursor nach oben bewegen
        print("\u001b[${dungeonHeight}A")

        val sb = StringBuilder()
        for (y in map.indices) {
            for (x in map[y].indices) {
                if (x == playerX && y == playerY) sb.append('@') else sb.append(map[y][x])
            }
            sb.append('\n')
        }
        sb.append("Bewege mit W/A/S/D oder Pfeiltasten. Q beendet.\n")
        print(sb.toString())
        System.out.flush()
    }

    fun tryMove(dx: Int, dy: Int) {
        val nx = playerX + dx
        val ny = playerY + dy
        if (ny in map.indices && nx in map[ny].indices && map[ny][nx] != '#') {
            playerX = nx
            playerY = ny
        }
    }

    // --- Render Loop ---
    val renderJob = launch(Dispatchers.Default) {
        // Erstmal initial zeichnen
        repeat(dungeonHeight) { println() }
        while (running.get()) {
            render()
            delay(50)
        }
    }

    // --- Input Loop ---
    val inputJob = launch(Dispatchers.IO) {
        while (running.get()) {
            val ch = reader.read()

            when (ch) {
                // WASD
                'w'.code, 'W'.code -> tryMove(0, -1)
                's'.code, 'S'.code -> tryMove(0, 1)
                'a'.code, 'A'.code -> tryMove(-1, 0)
                'd'.code, 'D'.code -> tryMove(1, 0)

                // Pfeiltasten (ANSI Escape Sequence)
                27 -> { // ESC
                    val next1 = reader.read()
                    if (next1 == 91) { // '['
                        when (reader.read()) {
                            65 -> tryMove(0, -1) // Up
                            66 -> tryMove(0, 1)  // Down
                            67 -> tryMove(1, 0)  // Right
                            68 -> tryMove(-1, 0) // Left
                        }
                    }
                }

                // Quit
                'q'.code, 'Q'.code -> running.set(false)
            }
        }
    }

    inputJob.join()
    running.set(false)
    renderJob.cancelAndJoin()

    terminal.close()
    println("Programm beendet.")
}
