extends Spatial

var count = 0
var msgs = [
	{"type": "SystemInfoReport", "payload": JSON.print({"graphicsDeviceName":"Mocked","graphicsDeviceVersion":"Mocked","graphicsMemorySize":512,"processorType":"n/a","processorCount":1,"systemMemorySize":256}) },
	{"type": "ControlEvent", "payload": JSON.print({"eventType":"ActivateRenderingACK"})},
]

func button_pressed():
	Server.send(msgs[count])
	count = (count + 1) % msgs.size()

func _ready():
	# warning-ignore: return_value_discarded
	get_node("Control/Button").connect("pressed", self, "button_pressed")
	pass # Replace with function body.


