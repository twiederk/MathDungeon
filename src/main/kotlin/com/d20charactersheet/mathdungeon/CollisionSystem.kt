package com.d20charactersheet.mathdungeon

class CollisionSystem(
    private val world: World,
    private val player: Entity,
    private val rat: Entity,
    private val goblin: Entity,
) {
    fun update() {
        val playerPos = world.positions[player] ?: return
        val ratPos = world.positions[rat] ?: return
        val goblinPosition = world.positions[goblin] ?: return
        println("Player Position: (${playerPos.x}, ${playerPos.y}), Rat Position: (${ratPos.x}, ${ratPos.y}), Goblin Position: (${goblinPosition.x}, ${goblinPosition.y})")

        if (playerPos.x == ratPos.x && playerPos.y == ratPos.y && !world.ratQuiz && rat !in world.defeated) {
            world.ratQuiz = true
            println("Kollision mit Ratte erkannt!")
        }

        if (playerPos.x == goblinPosition.x && playerPos.y == goblinPosition.y && !world.goblinQuiz && goblin !in world.defeated) {
            world.goblinQuiz = true
            println("Kollision mit Goblin erkannt!")
        }
    }
}
