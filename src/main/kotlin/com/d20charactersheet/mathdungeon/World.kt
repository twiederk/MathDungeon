package com.d20charactersheet.mathdungeon

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


