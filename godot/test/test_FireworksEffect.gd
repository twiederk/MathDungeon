extends GutTest

const FIREWORKS_EFFECT_SCENE = preload("res://gui/fireworks_effect.tscn")

var fireworks_effect: FireworksEffect


func before_each():
	fireworks_effect = add_child_autofree(FIREWORKS_EFFECT_SCENE.instantiate())


func after_each():
	fireworks_effect = null
	GameSession.reset()


func test_a_rank_starts_all_bursts():
	# act
	fireworks_effect._on_highscore_rank_changed(1)
	
	# assert
	for burst: GPUParticles2D in fireworks_effect.bursts.get_children():
		assert_true(burst.emitting)


func test_no_rank_does_not_start_the_bursts():
	# act
	fireworks_effect._on_highscore_rank_changed(HighscoreManager.NO_RANK)
	
	# assert
	for burst: GPUParticles2D in fireworks_effect.bursts.get_children():
		assert_false(burst.emitting)
