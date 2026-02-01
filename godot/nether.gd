class_name Nether
extends Main


func _ready():
	super._ready()
	AchievementManager.track_nether_visit()	
