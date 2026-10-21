# Feature: Chasing Iron Golem

## Problem

An `IronGolem` (`enemies/iron_golem.tscn`) is currently an ordinary, immobile `Enemy`: it sits in
the village and only starts a quiz when the player walks into its `DetectionArea`. There is no
connection between the golem and the villagers it is supposed to protect — the player can wipe out
the whole village right next to a golem without any consequence.

## Goal

An iron golem has two states:

- `FRIENDLY` — behaves exactly like today (stands still, starts a quiz on contact).
- `HOSTILE` — actively moves towards the player until it reaches him (which triggers the normal
  encounter/quiz), or until the player escapes far enough away.

A golem switches `FRIENDLY -> HOSTILE` when the player defeats a **villager or baby villager**
within its aggro radius. It switches back `HOSTILE -> FRIENDLY` when the player gets far enough
away.

## Decisions

Out of the discussed options the following combination was chosen:

| Aspect | Chosen approach |
|---|---|
| Identify a villager | Node group `villagers` on `villager.tscn` / `villager_baby.tscn` |
| Define "near" | Distance check against `aggro_radius` at the moment of defeat |
| Deliver the event | `WorldLevel._on_enemy_defeated()` notifies the golems |
| Movement | `CharacterBody2D` wrapper scene with real collision |

### Why a wrapper instead of making the golem itself move

`Enemy extends StaticBody2D`, so the golem node cannot both be an `Enemy` and a `CharacterBody2D`.
Real collision (walls, water, map borders, other enemies) was requested, which rules out moving a
`StaticBody2D` by assigning `global_position`. Changing `Enemy` to `CharacterBody2D` project-wide
would touch ~30 enemy scenes plus every `enemy: StaticBody2D` signal/parameter type in
`world_level.gd`, `quiz_dialog.gd` and `patrolling_enemy.gd` — out of scope.

Instead the golem gets the same shape `PatrollingEnemy` already uses: a mobile root node with a
nested `Enemy`. The root does the moving, the nested `Enemy` stays the thing that is passed to the
quiz, so all existing types and flows keep working.

### Why the group lives on the scene, not on `EnemyStats`

`villager.tscn` and `villager_baby.tscn` are the only two scenes involved and both already carry
their identity through their own stats resource. A `groups=["villagers"]` entry in the scene file
is a one-line change per scene and needs no change to `EnemyStats`, no resource migration and no
new `.uid` files.

### Why `WorldLevel` routes the event

`WorldLevel._setup_signals()` already connects `defeated` for every direct child of `Enemies`, and
`_on_enemy_defeated(enemy)` is called while the villager is still alive — `QuizDialog` only calls
`enemy.queue_free()` afterwards (`quiz/quiz_dialog.gd`). So `enemy.global_position` is still valid
there and no new autoload / signal bus is needed.

## Changes

### 1. `enemies/villager.tscn`, `enemies/villager_baby.tscn`

Mark the root node as a villager:

```gdscript
[node name="Villager" type="StaticBody2D" groups=["villagers"]]
```

```gdscript
[node name="VillagerBaby" type="StaticBody2D" groups=["villagers"]]
```

Zombie villagers (`villager_zombie.tscn`, `villager_zombie_baby.tscn`) are **not** added to the
group — killing an undead villager must not enrage the golem.

### 2. `enemies/chasing_iron_golem.tscn` (new)

```
ChasingIronGolem   (CharacterBody2D, script chasing_iron_golem.gd, collision_layer = 2, collision_mask = 2)
├── CollisionShape2D   (CapsuleShape2D, height 28 — same shape the golem uses today)
└── IronGolem          (instance of enemies/iron_golem.tscn)
    └── CollisionShape2D   -> disabled = true
```

- `collision_layer = 2` keeps the player (`collision_mask = 2`) colliding with the golem.
- `collision_mask = 2` makes the golem itself collide with the tile map (`world_tiles.tres`
  `physics_layer_0/collision_layer = 2`), the `MapBorders` and the other enemies. Layer 1 (player)
  is deliberately **not** in the mask — the golem walks into the player, the `DetectionArea`
  triggers the encounter and `GameSession` disables the `Enemies` subtree while the quiz is open.
- The nested `IronGolem`'s own `CollisionShape2D` is disabled so there is no second, teleporting
  static collider at the same position. Its `Sprite2D` and `DetectionArea` stay active and move
  with the wrapper.

### 3. `enemies/chasing_iron_golem.gd` (new)

```gdscript
class_name ChasingIronGolem
extends CharacterBody2D

enum State { FRIENDLY, HOSTILE }

signal encountered(enemy: StaticBody2D, attack_type: Enemy.AttackType)
signal defeated(enemy: Enemy)

@export var aggro_radius: float = 220.0
@export var calm_down_distance: float = 500.0
@export var chase_speed: float = 240.0
@export var location: String = ""

@onready var enemy: Enemy = $IronGolem
@onready var sprite: Sprite2D = $IronGolem/Sprite2D

var state: State = State.FRIENDLY
var target: Player = null


func _ready() -> void:
	enemy.location = location
	enemy.encountered.connect(_on_enemy_encountered)
	enemy.defeated.connect(_on_enemy_defeated)


func _physics_process(_delta: float) -> void:
	if state != State.HOSTILE:
		return
	if target == null or not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) > calm_down_distance:
		_calm_down()
		return
	velocity = global_position.direction_to(target.global_position) * chase_speed
	move_and_slide()
	_update_sprite_direction(velocity.x)


# Called by WorldLevel whenever the player defeats a node in the "villagers" group.
func on_villager_defeated(villager_position: Vector2, player: Player) -> void:
	if state == State.HOSTILE:
		return
	if global_position.distance_to(villager_position) > aggro_radius:
		return
	state = State.HOSTILE
	target = player
	if is_inside_tree():
		Sound.play(Sound.golem_hostile)


func _calm_down() -> void:
	state = State.FRIENDLY
	target = null
	velocity = Vector2.ZERO


func _update_sprite_direction(horizontal_direction: float) -> void:
	if horizontal_direction > 0:
		sprite.flip_h = true
	elif horizontal_direction < 0:
		sprite.flip_h = false


func _on_enemy_encountered(a_enemy: StaticBody2D, attack_type: Enemy.AttackType) -> void:
	encountered.emit(a_enemy, attack_type)


func _on_enemy_defeated(a_enemy: Enemy) -> void:
	defeated.emit(a_enemy)
	queue_free()
```

- Both `encountered` and `defeated` are forwarded, so `WorldLevel._setup_signals()` picks the
  wrapper up through its existing `has_signal(...)` duck typing and loot still drops.
  (`PatrollingEnemy` only forwards `encountered` — that known gap is not fixed here.)
- `queue_free()` on the wrapper after `defeated` prevents an empty wrapper from being left behind
  once `QuizDialog` frees the nested `Enemy`.
- `aggro_radius` (220) is well below `calm_down_distance` (500) so the state cannot flip-flop.

### 4. `classic/world_level.gd`

```gdscript
func _on_enemy_defeated(enemy: Enemy) -> void:
	for item in loot_droper.drop_items(enemy, items_root):
		_register_item(item)
	if enemy.is_in_group("villagers"):
		_enrage_iron_golems(enemy.global_position)


func _enrage_iron_golems(villager_position: Vector2) -> void:
	for child in enemies_root.get_children():
		if child.has_method("on_villager_defeated"):
			child.on_villager_defeated(villager_position, player)
```

The position is read here, before `QuizDialog` frees the villager.

### 5. `classic/sound.gd` + `classic/sound.tscn`

Add one more stream slot:

```gdscript
@export var golem_hostile: AudioStream
```

and assign it in `sound.tscn`. There is no dedicated asset yet — until one is added, point it at
`res://enemies/hurt_enemy.mp3` (the only usable "creature" sound in the project) so the feature is
complete; swapping in a real golem roar later is a pure scene-file change.

### 6. `classic/overworld.tscn`

Replace the three `iron_golem.tscn` instances under `Enemies` with `chasing_iron_golem.tscn`,
keeping the positions:

| Node | Position | Villagers within 220 px |
|---|---|---|
| `IronGolem` | `(99, 1700)` | Villager, Villager2, Villager4, Villager5, Villager6, VillagerBaby |
| `IronGolem2` | `(182, 1828)` | Villager2, Villager3, Villager6, VillagerBaby2 |
| `IronGolem3` | `(1185, 2527)` | none — stays friendly, no behaviour change |

`enemies/iron_golem.tscn` itself stays unchanged and usable as a plain static enemy.

## Risks / Notes

- `_setup_locations()` uses `enemies_root.find_children("", "Enemy", true, false)` recursively, so
  the nested golem `Enemy` is still registered with `AchievementManager` — verify after the scene
  change that the golem achievement still unlocks.
- The chase is a straight-line steering behaviour, not pathfinding. A golem can get stuck behind a
  wall or in a dead end. Accepted: `move_and_slide` makes it slide along obstacles, and the player
  escaping is a valid outcome (`calm_down_distance`).
- While a quiz/dialog is open, `WorldLevel._on_simulation_running_changed()` disables the whole
  `Enemies` subtree, so the chase pauses automatically — no extra handling needed.
- At `chase_speed = 240` a walking player (200) is always caught; sprinting (280) escapes. Values
  are `@export`ed per instance for tuning.
- `GameSession`/`SaveManager` do not persist the hostile state; leaving and re-entering the level
  resets every golem to `FRIENDLY`. Accepted.
- Villagers are never wrapped in a `PatrollingEnemy` today. If that ever changes, `defeated` would
  not reach `WorldLevel` and the golem would not react.
- `procedural/enemy_generator.gd` spawns neither villagers nor golems, so procedural dungeons are
  unaffected.

## Tests (GUT, `test/`)

New `test/test_ChasingIronGolem.gd`:

- `test_stays_friendly_when_villager_dies_far_away` — act on `on_villager_defeated()` with a
  position beyond `aggro_radius`, assert `state == State.FRIENDLY`.
- `test_turns_hostile_when_villager_dies_nearby` — position inside `aggro_radius`, assert
  `state == State.HOSTILE` and `target` is the player.
- `test_stays_hostile_on_second_villager` — a far-away second kill must not reset an already
  hostile golem.
- `test_forwards_defeated_from_nested_enemy` — `watch_signals`, call `enemy.hurt(lethal)`, assert
  the wrapper re-emitted `defeated`.
- `test_calms_down_when_player_escapes` — set `HOSTILE`, move the player beyond
  `calm_down_distance`, run one physics frame, assert `state == State.FRIENDLY`.

Extend `test/test_WorldLevel.gd` (or add one) for the routing:

- defeating a node in the `villagers` group calls `on_villager_defeated` on a golem double;
- defeating a non-villager enemy does not.

Follow the repo conventions: arrange/act/assert comments, act result stored in a `var` before
asserting, no single-line ternaries. After adding the new `class_name`, run
`Godot_v4.7-stable_win64.exe --path . --headless --import` once, then `cmd /c "test_ING.bat < nul"`.
