extends GutTest


const GOLEM_SCENE = preload("res://enemies/chasing_iron_golem.tscn")
const PLAYER_SCENE = preload("res://classic/player.tscn")

var golem: ChasingIronGolem
var player: Player


func before_each():
	golem = add_child_autofree(GOLEM_SCENE.instantiate())
	player = add_child_autofree(PLAYER_SCENE.instantiate())


func after_each():
	golem = null
	player = null


func test_stays_friendly_when_villager_dies_far_away():
	# arrange
	var far_away_position := golem.global_position + Vector2(golem.aggro_radius + 1.0, 0)

	# act
	golem.on_villager_defeated(far_away_position, player)

	# assert
	assert_eq(golem.state, ChasingIronGolem.State.FRIENDLY)


func test_turns_hostile_when_villager_dies_nearby():
	# arrange
	var nearby_position := golem.global_position + Vector2(golem.aggro_radius - 1.0, 0)

	# act
	golem.on_villager_defeated(nearby_position, player)

	# assert
	assert_eq(golem.state, ChasingIronGolem.State.HOSTILE)
	assert_eq(golem.target, player)


func test_stays_hostile_on_second_villager():
	# arrange
	golem.state = ChasingIronGolem.State.HOSTILE
	var far_away_position := golem.global_position + Vector2(golem.aggro_radius + 1.0, 0)

	# act
	golem.on_villager_defeated(far_away_position, player)

	# assert
	assert_eq(golem.state, ChasingIronGolem.State.HOSTILE)


func test_forwards_defeated_from_nested_enemy():
	# arrange
	watch_signals(golem)

	# act
	golem.enemy.hurt(100)

	# assert
	assert_signal_emitted(golem, "defeated")


func test_calms_down_when_player_escapes():
	# arrange
	golem.state = ChasingIronGolem.State.HOSTILE
	golem.target = player
	player.global_position = golem.global_position + Vector2(golem.calm_down_distance + 1.0, 0)

	# act
	golem._physics_process(0.0)

	# assert
	assert_eq(golem.state, ChasingIronGolem.State.FRIENDLY)
