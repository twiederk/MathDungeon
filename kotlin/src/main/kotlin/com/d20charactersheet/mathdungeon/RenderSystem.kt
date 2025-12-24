package com.d20charactersheet.mathdungeon

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
