package com.d20charactersheet.mathdungeon

class CollisionSystem(
    private val world: World,
    private val player: Entity,
    private val monster: Entity
) {
    fun update() {
        val p = world.positions[player] ?: return
        val m = world.positions[monster] ?: return

        if (p.x == m.x && p.y == m.y && !world.quizRequested) {
            world.quizRequested = true
        }
    }
}
