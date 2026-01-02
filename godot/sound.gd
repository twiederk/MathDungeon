extends Node

@export var pickup_potion : AudioStream
@export var pickup_sword : AudioStream
@export var dog_bark: AudioStream

@onready var audio_stream_player = $AudioStreamPlayer


func play(sound_stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0):
	audio_stream_player.pitch_scale = pitch_scale
	audio_stream_player.volume_db = volume_db
	audio_stream_player.stream = sound_stream
	audio_stream_player.play()
