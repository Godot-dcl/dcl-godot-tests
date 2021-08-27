extends Spatial

var socket

var msgs = [
	{"type":"SystemInfoReport", "payload": JSON.print({"graphicsDeviceName":"AMD Radeon Pro 5500M OpenGL Engine","graphicsDeviceVersion":"OpenGL ES 3.0 (WebGL 2.0 (OpenGL ES 3.0 Chromium))","graphicsMemorySize":512,"processorType":"n/a","processorCount":1,"systemMemorySize":256}) },
	{"type": "AllScenesEvent", "payload": JSON.print({"eventType":"cameraModeChanged","payload":{"cameraMode":0}})},
	{"type": "ControlEvent", "payload": JSON.print({"eventType":"SceneReady","payload":{"sceneId":"dcl-gs-avatars"}})},
	{"type": "SetScenesLoadRadius", "payload": JSON.print({"newRadius":4.0}) },
	{"type": "SetBaseResolution", "payload": JSON.print({"baseResolution":1080}) },
	{"type":"ApplySettings","payload":"{\"voiceChatVolume\":1.0,\"voiceChatAllowCategory\":0}"},
	{"type": "ControlEvent", "payload": JSON.print({"eventType":"ActivateRenderingACK"})},
]
var count = 0

func send():
	if count >= msgs.size():
		return
	socket.send(msgs[count])
	count += 1

func message(type, payload):
	return
	if type == "CreateGlobalScene":
		var response = {"eventType":"SceneReady", "payload": {"sceneId": payload.id}}
		socket.send({"type": "ControlEvent", "payload": JSON.print(response)})

func _ready():
	socket = get_node("socket")
	get_node("button").connect("pressed", self, "send")

