package com.d20charactersheet.mathdungeon

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.atomic.AtomicBoolean

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
