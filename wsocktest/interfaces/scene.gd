tool
extends Spatial


signal received_event(scene)

const COMPONENT = preload("res://interfaces/component.gd")
const EVENT = preload("res://interfaces/event.gd")
const PROTO = preload("res://server/engineinterface.gd")
const parcel_size = 16

var peer = null
var global_scene
var id


var current_index = -1
var entities = {"0": get_node(".")}
var components : Dictionary


func create(msg, p_peer, is_global):
	id = msg.payload.id
	global_scene = is_global

	peer = p_peer

	if msg.payload.name != "DCL Scene":
		ContentManager.load_contents(self, msg.payload)

	if msg.payload.contents.size() > 0:
		transform.origin = Vector3(msg.payload.basePosition.x, 0, msg.payload.basePosition.y) * parcel_size


func contents_loaded():
	var response = {"eventType":"SceneReady", "payload": {"sceneId": id}}
	Server.send({"type": "ControlEvent", "payload": JSON.print(response)}, peer)


func message(scene_msg):
	#print(scene_msg.to_string())

	if scene_msg.has_createEntity():
		#print("create entity ", scene_msg.get_createEntity().get_id())
		var entity_id = scene_msg.get_createEntity().get_id()
		entities[entity_id] = Spatial.new()
		entities[entity_id].name = entity_id
		add_child(entities[entity_id])

	if scene_msg.has_removeEntity():
		pass#print("remove entity ", scene_msg.get_removeEntity().get_id())

	if scene_msg.has_setEntityParent():
#		print("setEntityParent %s -> %s" % [
#			scene_msg.get_setEntityParent().get_parentId(),
#			scene_msg.get_setEntityParent().get_entityId() ])
		reparent(
			scene_msg.get_setEntityParent().get_entityId(),
			scene_msg.get_setEntityParent().get_parentId()
		)

	if scene_msg.has_componentCreated():
		#print("component created ", scene_msg.get_componentCreated().get_name())
		components[scene_msg.get_componentCreated().get_id()] = COMPONENT.new(
			scene_msg.get_componentCreated().get_name()
		)

	if scene_msg.has_componentDisposed():
		pass#print("component disposed ", scene_msg.get_componentDisposed().get_id())

	if scene_msg.has_componentRemoved():
		pass#print("component removed ", scene_msg.get_componentRemoved().get_name())

	if scene_msg.has_componentUpdated():
#		print("component updated %s -> %s" % [
#			scene_msg.get_componentUpdated().get_id(),
#			scene_msg.get_componentUpdated().get_json() ])
		components[scene_msg.get_componentUpdated().get_id()].update(
			scene_msg.get_componentUpdated().get_json()
		)

	if scene_msg.has_attachEntityComponent():
		#print("attach component to entity %s -> %s" % [
#			scene_msg.get_attachEntityComponent().get_entityId(),
#			scene_msg.get_attachEntityComponent().get_id() ])

		components[scene_msg.get_attachEntityComponent().get_id()].attach_to(
			entities[scene_msg.get_attachEntityComponent().get_entityId()]
		)

	if scene_msg.has_updateEntityComponent():

		var data = scene_msg.get_updateEntityComponent().get_data()
		if data.left(1) in ["[", "{"]:
			print("update component in entity %s -> %s" % [
				scene_msg.get_updateEntityComponent().get_entityId(),
				scene_msg.get_updateEntityComponent().get_data() ])
			var entity = entities[scene_msg.get_updateEntityComponent().get_entityId()]
			var parsed = JSON.parse(data).result
			if parsed.has("uuid"):
				if has_meta("events"):
					get_meta("events").append(EVENT.new(id, entity, parsed))
				else:
					set_meta("events", [EVENT.new(id, entity, parsed)])

			emit_signal("received_event", self)
		else:
			var buf = Marshalls.base64_to_raw(data)

			var comp = PROTO.PB_Transform.new()
			var err = comp.from_bytes(buf)
			if err == PROTO.PB_ERR.NO_ERRORS:
				var entity_id = scene_msg.get_updateEntityComponent().get_entityId()
				var rot = comp.get_rotation()
				var pos = comp.get_position()
				var sca = comp.get_scale()

				var q = Quat(
					rot.get_x(),
					rot.get_y(),
					rot.get_z(),
					rot.get_w()
				)
				entities[entity_id].transform = Transform(q).scaled(Vector3(sca.get_x(), sca.get_y(), sca.get_z()))
				entities[entity_id].transform.origin = Vector3(pos.get_x(), pos.get_y(), pos.get_z())
			else:
				push_warning("****** error decoding PB_Transform payload %s" % err)

	if scene_msg.has_sceneStarted():
		pass#print("scene started ", id)

	if scene_msg.has_openNFTDialog():
		pass#print("open NFT dialog %s %s" % [
#			scene_msg.get_openNFTDialog().get_assetContractAddress(),
#			scene_msg.get_openNFTDialog().get_tokenId()
#		])

	if scene_msg.has_query():
		pass#print("query ", scene_msg.get_query().get_payload())


func reparent(src, dest):
	var src_node = entities[src]
	var dest_node = entities[dest]
	remove_child(src_node)
	dest_node.add_child(src_node)


func _input(event):
	if has_meta("events"):
		for e in get_meta("events"):
			e.check(event)


func _get_configuration_warning():
	return "" if peer == null else "Scene is currently connected to a peer." +\
			"\nRemoving the DebuggerDump off the tree will completely detach this scene from it."
