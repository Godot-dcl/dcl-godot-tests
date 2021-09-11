extends Spatial

var socket

const proto = preload("res://engineinterface.gd")

var current_index = -1
var msgs = [
	{"type":"SystemInfoReport", "payload": JSON.print({"graphicsDeviceName":"Mocked","graphicsDeviceVersion":"Mocked","graphicsMemorySize":512,"processorType":"n/a","processorCount":1,"systemMemorySize":256}) },
	#{"type":"SystemInfoReport", "payload": JSON.print({"graphicsDeviceName":"AMD Radeon Pro 5500M OpenGL Engine","graphicsDeviceVersion":"OpenGL ES 3.0 (WebGL 2.0 (OpenGL ES 3.0 Chromium))","graphicsMemorySize":512,"processorType":"n/a","processorCount":1,"systemMemorySize":256}) },
	{"type": "AllScenesEvent", "payload": JSON.print({"eventType":"cameraModeChanged","payload":{"cameraMode":0}})},
	{"type": "ControlEvent", "payload": JSON.print({"eventType":"SceneReady","payload":{"sceneId":"dcl-gs-avatars"}})},
	{"type": "SetScenesLoadRadius", "payload": JSON.print({"newRadius":4.0}) },
	{"type": "SetBaseResolution", "payload": JSON.print({"baseResolution":1080}) },
	{"type":"ApplySettings","payload":"{\"voiceChatVolume\":1.0,\"voiceChatAllowCategory\":0}"},
	{"type": "ControlEvent", "payload": JSON.print({"eventType":"ActivateRenderingACK"})},
]

func send():
	current_index = (current_index + 1) % msgs.size()
	socket.send(msgs[current_index])

func message(msg):
	match msg.type:
		"CreateGlobalScene":
			var response = {"eventType":"SceneReady", "payload": {"sceneId": msg.payload.id}}
			socket.send({"type": "ControlEvent", "payload": JSON.print(response)})
		"SendSceneMessage":
			var scene_msg = proto.PB_SendSceneMessage.new()
			for buf in msg.payload:
				var err = scene_msg.from_bytes(buf)
				printt("error is ", err)
				printt("msg is ", scene_msg.to_string())

func _ready():
	socket = get_node("socket")
	get_node("button").connect("pressed", self, "send")
