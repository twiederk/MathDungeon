package com.d20charactersheet.mathdungeon

import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicBoolean

fun main() = runBlocking {
    // Rechteckige Karte (Wände '#', Boden '.')
    val raw = listOf(
        "###########",
        "#.........#",
        "###########"
    )
    val map = raw.map { it.toCharArray() }.toMutableList()

    var playerX = 1
    var playerY = 1
    val running = AtomicBoolean(true)

    fun render() {
        // ANSI: Cursor home + clear screen (funktioniert in modernen Konsolen)
        print("\u001b[H\u001b[2J")
        val sb = StringBuilder()
        for (y in map.indices) {
            for (x in map[y].indices) {
                if (x == playerX && y == playerY) sb.append('@') else sb.append(map[y][x])
            }
            sb.append('\n')
        }
        sb.append("Bewege mit W/A/S/D. Drücke Q zum Beenden.\n")
        print(sb.toString())
    }

    fun tryMove(dx: Int, dy: Int) {
        val nx = playerX + dx
        val ny = playerY + dy
        if (ny in map.indices && nx in map[ny].indices && map[ny][nx] != '#') {
            playerX = nx
            playerY = ny
        }
    }

    // Renderer-Job
    val renderJob = launch(Dispatchers.Default) {
        while (running.get()) {
            render()
            delay(100) // Frame-Takt
        }
    }

    // Input-Job (blockierend auf System.`in`, deshalb auf IO-Dispatcher)
    val inputJob = launch(Dispatchers.IO) {
        val inStream = System.`in`
        while (running.get()) {
            val b = inStream.read()
            if (b == -1) break
            // Ignoriere Zeilenumbruch-Bytes
            if (b == 10 || b == 13) continue
            when (b.toChar().lowercaseChar()) {
                'w' -> tryMove(0, -1)
                's' -> tryMove(0, 1)
                'a' -> tryMove(-1, 0)
                'd' -> tryMove(1, 0)
                'q' -> running.set(false)
            }
        }
    }

    // Warte bis beendet
    inputJob.join()
    running.set(false)
    renderJob.cancelAndJoin()

    println("Programm beendet.")
}