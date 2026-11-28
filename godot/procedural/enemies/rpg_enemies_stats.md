# Procedural Enemy Stats

Base stats from the resources in `res://procedural/enemies`.

| name | level | max_hit_points | damage | armor | max_number | time_limit | arithmetic |
|---|---:|---:|---:|---:|---:|---:|---|
| Gelber Schleim | 1 | 2 | 1 | 0 | 20 | 30 | Addition |
| Cyan Schleim | 2 | 4 | 1 | 0 | 40 | 30 | Addition, subtraction |
| Magenta Schleim | 3 | 6 | 2 | 0 | 80 | 30 | Addition, subtraction |
| Grüner Schleim | 4 | 8 | 2 | 0 | 100 | 30 | Addition, subtraction, multiplication |
| Schleim | 5 | 10 | 3 | 0 | 100 | 30 | Addition, subtraction, multiplication |
| Roter Schleim | 6 | 12 | 4 | 0 | 100 | 30 | Addition, subtraction, multiplication, division |
| Skelett (`skeleton_swordless`) | 3 | 4 | 1 | 0 | 100 | 30 | Addition, subtraction, multiplication, division |
| Skelett (`skeleton`) | 5 | 4 | 2 | 0 | 1000 | 20 | Addition, subtraction, multiplication, division |

Omitted values use the `EnemyStats` defaults: `damage = 1`, `armor = 0`, and `max_number = 100`.
