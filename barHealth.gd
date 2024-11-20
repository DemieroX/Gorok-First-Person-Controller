extends ProgressBar

func _process(_delta):
	value = get_parent().hp
