package com.d20charactersheet.mathdungeon

class CollisionSystem(
    private val world: World,
    private val player: Entity,
    private val monster: Entity
) {
    fun update() {
        val pPos = world.positions[player] ?: return
        val mPos = world.positions[monster] ?: return

        if (pPos.x == mPos.x && pPos.y == mPos.y) {
            println("\nDu bist mit dem Monster kollidiert!")
            println("Beantworte die Aufgabe, um weiterzugehen:")

            while (true) {
                print("Was ist 1 + 1? ")
                val answer = readLine()

                if (answer == "2") {
                    println("Richtig! Du darfst weitergehen.")
                    break
                } else {
                    println("Leider falsch. Versuch es nochmal.")
                }
            }
        }
    }
}
