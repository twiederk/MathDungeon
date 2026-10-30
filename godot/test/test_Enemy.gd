extends GutTest


const ENEMY_SCENE = preload("res://enemies/enderman.tscn")

var enemy: Enemy


func before_each():
	enemy = add_child_autofree(ENEMY_SCENE.instantiate())
	watch_signals(enemy)


func after_each():
	enemy = null


func test_nonlethal_damage_does_not_emit_defeated():
	# arrange
	enemy.hit_points = enemy.stats.get_max_hit_points()

	# act
	enemy.hurt(1)

	# assert
	assert_signal_not_emitted(enemy, "defeated")


func test_lethal_damage_emits_defeated():
	# arrange
	enemy.hit_points = enemy.stats.get_max_hit_points()

	# act
	enemy.hurt(100)

	# assert
	assert_signal_emitted(enemy, "defeated")


func test_lethal_damage_plays_death_sound():
	# arrange
	enemy.hit_points = enemy.stats.get_max_hit_points()

	# act
	enemy.hurt(100)

	# assert
	assert_has(_played_sound_streams(), enemy.stats.death_sounds[0])


func test_nonlethal_damage_plays_hurt_sound():
	# arrange
	var hurt_sound := AudioStreamWAV.new()
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.hurt_sounds = [hurt_sound]
	enemy.hit_points = enemy.stats.get_max_hit_points()

	# act
	enemy.hurt(1)

	# assert
	assert_has(_played_sound_streams(), hurt_sound)


func _played_sound_streams() -> Array:
	var streams: Array = []
	for player: AudioStreamPlayer in Sound.sound_players:
		streams.append(player.stream)
	return streams
