extends Node

@export var pickup_potion : AudioStream
@export var pickup_sword : AudioStream
@export var pickup_helmet : AudioStream
@export var dog_bark: AudioStream
@export var victory: AudioStream

@onready var sound_players = get_children()


func play(sound_stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0):
	for sound_player: AudioStreamPlayer in sound_players:
		if not sound_player.playing:
			sound_player.pitch_scale = pitch_scale
			sound_player.volume_db = volume_db
			sound_player.stream = sound_stream
			sound_player.play()
			return
	print("Too many sounds playing at once")
