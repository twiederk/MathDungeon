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

    // --- Terminal Setup ---
    val terminal = TerminalBuilder.builder()
        .system(true)
        .jna(true)
        .build()

    terminal.enterRawMode()
    print("\u001b[?25l") // Cursor verstecken
    val reader = terminal.reader()

    // --- Double Buffer ---
    var lastFrame = ""

    fun buildFrame(): String {
        val sb = StringBuilder()

        sb.append("\u001b[H")       // Cursor Home
        sb.append("\u001b[2J")      // Clear Screen

        for (y in map.indices) {
            for (x in map[y].indices) {
                if (x == playerX && y == playerY) sb.append('@')
                else sb.append(map[y][x])
            }
            sb.append('\n')
        }
        sb.append("Bewege mit W/A/S/D oder Pfeiltasten. Q beendet.\n")

        return sb.toString()
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
        while (running.get()) {
            val frame = buildFrame()

            if (frame != lastFrame) {
                print(frame)
                System.out.flush()
                lastFrame = frame
            }

            delay(16) // ~60 FPS, aber nur bei Änderungen wird gezeichnet
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

                // Pfeiltasten
                27 -> {
                    val next1 = reader.read()
                    if (next1 == 91) {
                        when (reader.read()) {
                            65 -> tryMove(0, -1)
                            66 -> tryMove(0, 1)
                            67 -> tryMove(1, 0)
                            68 -> tryMove(-1, 0)
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

    print("\u001b[?25h") // Cursor wieder einblenden
    terminal.close()
    println("Programm beendet.")
}
