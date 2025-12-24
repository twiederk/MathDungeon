package com.d20charactersheet.mathdungeon

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
