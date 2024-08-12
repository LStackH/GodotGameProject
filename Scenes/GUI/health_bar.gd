extends ProgressBar

var parent
var max_value_amount
var min_value_amount

func _ready():
	parent = get_parent().get_parent().get_parent().get_parent().get_parent()
	max_value_amount = parent.health_max
	min_value_amount = parent.health_min
	

func _process(delta):
	self.value = parent.health_current * 100 / parent.health_max
	if parent.health_current != max_value_amount:
		self.visible = true
		if parent.health_current == min_value_amount:
			self.visible = false
	else:
		self.visible = false
