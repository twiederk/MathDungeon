class_name Nether
extends ClassicWorld


func _ready():
	super._ready()
	AchievementManager.track_nether_visit()	
