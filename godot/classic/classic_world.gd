class_name ClassicWorld
extends WorldLevel


func _ready() -> void:
	super._ready()
	_setup_player_portrait()


func _setup_player_portrait() -> void:
	var classic_player := player as ClassicPlayer
	var portrait: Portrait = CharacterManager.current.portrait
	classic_player.apply_portrait(portrait.texture)
