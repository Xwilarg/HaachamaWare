extends Control

const is_demo = false
var playing_op
var HP = 4
var speed = 1 setget set_speed
var difficulty = 1# setget set_difficulty
var minigames_played = 0
var won = true
var won_boss = false
# var minigames moved to Global.gd
var goal_timer = 0
var last_minigame = ""

func set_speed(x):
	speed=x
	difficulty=pow(speed,0.33)#sqrt(speed)
#func set_difficulty(x):
#	difficulty=x
#	speed=difficulty*difficulty

func _ready():
	playing_op = true
	$OP/AnimationPlayer.play("OP")
	$Pot/Pot/AnimationPlayer.play("OP")
	var _i = $Pot/Pot/AnimationPlayer.connect("animation_finished",self,"anim_finish")
#	initial_start_minigame_timer = 0
	if Global.mods["Distraction"]:
		self.add_child(Global.get_instance("res://Scenes/Distraction.tscn"))
	if Global.mods["InvColors"]:
		self.add_child(Global.get_instance("res://Scenes/ColorInvert.tscn"))
	if Global.mods["InvControls"]:
		Global.set_controls_inverted(true)

func anim_finish(name):
	if name=="OP":
		$OP.queue_free()
		playing_op = false
#		$Pot/Pot/AnimationPlayer.play("Good")

func win():
	if Global.mods["LTW"]:
		_penalize()
	else:
		_win()

func penalize():
	if Global.mods["LTW"]:
		_win()
	else:
		_penalize()

func _win():
	if minigames_played > 0 and (minigames_played%20)==0 and Global.disabled_minigames==[]:
		won_boss = true
	won = true

func _penalize():
	HP-=1
	won=false

func end_minigame():
	if won:
		$Pot/Pot/AnimationPlayer.play("GoodTransition")
	else:
		$Pot/Pot/AnimationPlayer.play("BadTransition")
	increment_minigames_played()

func increment_minigames_played():
	minigames_played+=1
	if fmod(minigames_played,2.5)<=0.5:
		speed_up() #Speed up!!!

func speed_up():
	self.speed += 1
	$Pot/Pot/AnimationPlayer.speedup=true
	#Speed up fail/win
	if Global.mods["SpeedUpPot"]:
		$Pot/Pot/AnimationPlayer.playback_speed=self.difficulty
		$Pot/Pot/Good1.pitch_scale=self.difficulty
		$Pot/Pot/Bad1.pitch_scale=self.difficulty

func start_minigame():
	var minigames_group = get_tree().get_nodes_in_group("Minigame")
	if len(minigames_group)>0:
		unload_minigame()
	var mgfilename
	if minigames_played > 0 and (minigames_played%20)==0 and Global.disabled_minigames==[]:
		mgfilename = Global.boss_minigames[randi()%len(Global.boss_minigames)]
	else:
		var mgl = Global.minigames.duplicate()
		if len(Global.minigames)>1:
			if mgl.has(last_minigame):
				mgl.erase(last_minigame)
		mgfilename = mgl[randi()%len(mgl)]
	var mg = Global.get_instance(mgfilename)
	self.add_child_below_node($MinigameGoesHere,mg)
	last_minigame=mgfilename
	$Goal.text=mg.goal
	goal_timer=0.4
	$Goal.show()

func unload_minigame():
	var minigames_group = get_tree().get_nodes_in_group("Minigame")
#	assert(len(minigames_group)==1)
	for minigame_in_group in minigames_group:
		minigame_in_group.queue_free()

func _process(delta):
	var mgp = str(minigames_played)
	if len(mgp)==1:
		mgp="0"+mgp
	$Pot/Pot/MinigamesPlayed.text=mgp
	if goal_timer>0:
		var x = clamp(goal_timer*10,2,4)
		$Goal.rect_scale=Vector2(x,x)
		goal_timer-=delta
	$Goal.visible=goal_timer>0
#	if initial_start_minigame_timer<15.3:
#		initial_start_minigame_timer+=delta
#		if initial_start_minigame_timer>=15.3:
#			start_minigame()
