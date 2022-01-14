@tool
extends Node3D


signal received_event(scene)

const COMPONENT = preload("res://interfaces/component.gd")
const EVENT = preload("res://interfaces/event.gd")
const PROTO = preload("res://server/engineinterface.gd")
const WAYPOINT = preload("res://ui/waypoint/waypoint.tscn")
const parcel_size = 16

var peer = null
var global_scene
var id


var current_index = -1
var entities = {"0": get_node(".")}
var components: Dictionary

@onready var json = JSON.new()

func create(msg, p_peer, is_global):
	id = msg.payload.id
	global_scene = is_global

	peer = p_peer

	if msg.payload.name != "DCL Scene":
		if msg.payload.contents.size() > 0:
			ContentManager.load_contents(msg.payload)

	if msg.payload.contents.size() > 0:
		transform.origin = Vector3(msg.payload.basePosition.x, 0, msg.payload.basePosition.y) * parcel_size

	# TODO: this should be called after all contents are loaded
	await get_tree().create_timer(2).timeout
	var response = {"eventType":"SceneReady", "payload": {"sceneId": id}}
	Server.send({"type": "ControlEvent", "payload": json.stringify(response)}, peer)


func message(scene_msg):
	#print(scene_msg.to_string())

	if scene_msg.has_createEntity():
		#print("create entity ", scene_msg.get_createEntity().get_id())
		var entity_id = scene_msg.get_createEntity().get_id()
		entities[entity_id] = Node3D.new()
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
		var classid = scene_msg.get_componentCreated().get_classid()
		var c_id = scene_msg.get_componentCreated().get_id()
		var c_name = scene_msg.get_componentCreated().get_name()
		match classid:
			DCL_BoxShape._classid:
				components[c_id] = DCL_BoxShape.new(c_name, self, c_id)

			DCL_SphereShape._classid:
				components[c_id] = DCL_SphereShape.new(c_name, self, c_id)

			DCL_PlaneShape._classid:
				components[c_id] = DCL_PlaneShape.new(c_name, self, c_id)

			DCL_Material._classid:
				components[c_id] = DCL_Material.new(c_name, self, c_id)

			DCL_GLTFShape._classid:
				components[c_id] = DCL_GLTFShape.new(c_name, self, c_id)

			DCL_AudioSource._classid:
				components[c_id] = DCL_AudioSource.new(c_name, self, c_id)

			DCL_AudioClip._classid:
				components[c_id] = DCL_AudioClip.new(c_name, self, c_id)

			DCL_VideoClip._classid:
				components[c_id] = DCL_VideoClip.new(c_name, self, c_id)

			DCL_VideoTexture._classid:
				components[c_id] = DCL_VideoTexture.new(c_name, self, c_id)

			DCL_NFTShape._classid:
				components[c_id] = DCL_NFTShape.new(c_name, self, c_id)
			_:
				printt("**** Unimplemented component creation", classid)
				components[c_id] = DCL_Component.new(c_name, self, c_id)

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

		var classid = scene_msg.get_updateEntityComponent().get_classId()
		var data = scene_msg.get_updateEntityComponent().get_data()
		var entity_id = scene_msg.get_updateEntityComponent().get_entityId()

#		print("update component in entity %s -> %s" % [
#			entity_id,
#			data ])

		# check this classid in engineinterface.proto (line 24)
		match classid:
			DCL_UUIDCallback._classid:
				DCL_UUIDCallback.update_component_in_entity(data, entities[entity_id], self)
				emit_signal("received_event", self)

			DCL_Transform._classid:
				DCL_Transform.update_component_in_entity(data, entities[entity_id], self)

			DCL_TextShape._classid:
				DCL_TextShape.update_component_in_entity(data, entities[entity_id], self)

			DCL_AnimationState._classid:
				DCL_AnimationState.update_component_in_entity(data, entities[entity_id], self)

			DCL_AudioSource._classid:
				DCL_AudioSource.update_component_in_entity(data, entities[entity_id], self)

			DCL_AudioClip._classid:
				DCL_AudioClip.update_component_in_entity(data, entities[entity_id], self)

			_:
				printt("**** Unimplemented component update", classid)

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
	src_node.get_parent().remove_child(src_node)
	dest_node.add_child(src_node)


#func _input(event):
#	if has_meta("events"):
#		for e in get_meta("events"):
#			e.check(event)


func _get_configuration_warning():
	return "" if peer == null else "Scene is currently connected to a peer." +\
			"\nRemoving the DebuggerDump off the tree will completely detach this scene from it."
