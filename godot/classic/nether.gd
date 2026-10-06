class_name Nether
extends WorldLevel


func _ready():
	super._ready()
	AchievementManager.track_nether_visit()	
