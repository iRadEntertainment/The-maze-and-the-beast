extends PanelContainer


@onready var sl_master = %sl_master
@onready var sl_sfx = %sl_sfx
@onready var sl_music = %sl_music
@onready var sl_ambient = %sl_ambient


func _ready():
	sl_master.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	sl_sfx.value = db_to_linear(AudioServer.get_bus_volume_db(2))
	sl_music.value = db_to_linear(AudioServer.get_bus_volume_db(3))
	sl_ambient.value = db_to_linear(AudioServer.get_bus_volume_db(4))

func _on_sl_master_value_changed(val): AudioServer.set_bus_volume_db(0, linear_to_db(val))
func _on_sl_sfx_value_changed(val): AudioServer.set_bus_volume_db(2, linear_to_db(val))
func _on_sl_music_value_changed(val): AudioServer.set_bus_volume_db(3, linear_to_db(val))
func _on_sl_ambient_value_changed(val): AudioServer.set_bus_volume_db(4, linear_to_db(val))
