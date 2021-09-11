const PROTO_VERSION = 3

#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2020, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"
const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PoolByteArray:
		var varint : PoolByteArray = PoolByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PoolByteArray:
		var bytes : PoolByteArray = PoolByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PoolByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PoolByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PoolByteArray, index : int) -> PoolByteArray:
		var result : PoolByteArray = PoolByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PoolByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PoolByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PoolByteArray) -> PoolByteArray:
		var result : PoolByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PoolByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PoolByteArray = pack_type_tag(type, field.tag)
		var data : PoolByteArray = PoolByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PoolByteArray = v.to_bytes()
						#if obj != null && obj.size() > 0:
						#	data.append_array(pack_length_delimeted(type, field.tag, obj))
						#else:
						#	data = PoolByteArray()
						#	return data
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PoolByteArray = field.value.to_utf8()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PoolByteArray = field.value.to_bytes()
					#if obj != null && obj.size() > 0:
					#	data.append_array(obj)
					#	return pack_length_delimeted(type, field.tag, data)
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PoolByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call_func()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PoolByteArray = PoolByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PoolByteArray = PoolByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PoolByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PoolByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PoolByteArray = PoolByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED && typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) && data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PoolByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += String(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + String(value)
		else:
			result += String(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(String(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED && typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) && data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class PB_Empty:
	func _init():
		var service
		
	var data = {}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_CreateEntity:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_RemoveEntity:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_SetEntityParent:
	func _init():
		var service
		
		_entityId = PBField.new("entityId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _entityId
		data[_entityId.tag] = service
		
		_parentId = PBField.new("parentId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _parentId
		data[_parentId.tag] = service
		
	var data = {}
	
	var _entityId: PBField
	func get_entityId() -> String:
		return _entityId.value
	func clear_entityId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_entityId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_entityId(value : String) -> void:
		_entityId.value = value
	
	var _parentId: PBField
	func get_parentId() -> String:
		return _parentId.value
	func clear_parentId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_parentId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_parentId(value : String) -> void:
		_parentId.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_ComponentRemoved:
	func _init():
		var service
		
		_entityId = PBField.new("entityId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _entityId
		data[_entityId.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
	var data = {}
	
	var _entityId: PBField
	func get_entityId() -> String:
		return _entityId.value
	func clear_entityId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_entityId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_entityId(value : String) -> void:
		_entityId.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Component:
	func _init():
		var service
		
		_transform = PBField.new("transform", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _transform
		service.func_ref = funcref(self, "new_transform")
		data[_transform.tag] = service
		
		_uuidCallback = PBField.new("uuidCallback", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _uuidCallback
		service.func_ref = funcref(self, "new_uuidCallback")
		data[_uuidCallback.tag] = service
		
		_box = PBField.new("box", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _box
		service.func_ref = funcref(self, "new_box")
		data[_box.tag] = service
		
		_sphere = PBField.new("sphere", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _sphere
		service.func_ref = funcref(self, "new_sphere")
		data[_sphere.tag] = service
		
		_plane = PBField.new("plane", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _plane
		service.func_ref = funcref(self, "new_plane")
		data[_plane.tag] = service
		
		_cone = PBField.new("cone", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _cone
		service.func_ref = funcref(self, "new_cone")
		data[_cone.tag] = service
		
		_cylinder = PBField.new("cylinder", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _cylinder
		service.func_ref = funcref(self, "new_cylinder")
		data[_cylinder.tag] = service
		
		_text = PBField.new("text", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _text
		service.func_ref = funcref(self, "new_text")
		data[_text.tag] = service
		
		_nft = PBField.new("nft", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _nft
		service.func_ref = funcref(self, "new_nft")
		data[_nft.tag] = service
		
		_containerRect = PBField.new("containerRect", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _containerRect
		service.func_ref = funcref(self, "new_containerRect")
		data[_containerRect.tag] = service
		
		_containerStack = PBField.new("containerStack", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _containerStack
		service.func_ref = funcref(self, "new_containerStack")
		data[_containerStack.tag] = service
		
		_uiTextShape = PBField.new("uiTextShape", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 27, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _uiTextShape
		service.func_ref = funcref(self, "new_uiTextShape")
		data[_uiTextShape.tag] = service
		
		_uiInputTextShape = PBField.new("uiInputTextShape", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 28, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _uiInputTextShape
		service.func_ref = funcref(self, "new_uiInputTextShape")
		data[_uiInputTextShape.tag] = service
		
		_uiImageShape = PBField.new("uiImageShape", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 29, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _uiImageShape
		service.func_ref = funcref(self, "new_uiImageShape")
		data[_uiImageShape.tag] = service
		
		_circle = PBField.new("circle", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 31, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _circle
		service.func_ref = funcref(self, "new_circle")
		data[_circle.tag] = service
		
		_billboard = PBField.new("billboard", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 32, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _billboard
		service.func_ref = funcref(self, "new_billboard")
		data[_billboard.tag] = service
		
		_gltf = PBField.new("gltf", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 54, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _gltf
		service.func_ref = funcref(self, "new_gltf")
		data[_gltf.tag] = service
		
		_obj = PBField.new("obj", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 55, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _obj
		service.func_ref = funcref(self, "new_obj")
		data[_obj.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 56, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _avatar
		service.func_ref = funcref(self, "new_avatar")
		data[_avatar.tag] = service
		
		_basicMaterial = PBField.new("basicMaterial", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 64, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _basicMaterial
		service.func_ref = funcref(self, "new_basicMaterial")
		data[_basicMaterial.tag] = service
		
		_texture = PBField.new("texture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 68, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _texture
		service.func_ref = funcref(self, "new_texture")
		data[_texture.tag] = service
		
		_audioClip = PBField.new("audioClip", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 200, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _audioClip
		service.func_ref = funcref(self, "new_audioClip")
		data[_audioClip.tag] = service
		
		_audioSource = PBField.new("audioSource", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 201, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _audioSource
		service.func_ref = funcref(self, "new_audioSource")
		data[_audioSource.tag] = service
		
	var data = {}
	
	var _transform: PBField
	func has_transform() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_transform() -> PB_Transform:
		return _transform.value
	func clear_transform() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_transform() -> PB_Transform:
		data[1].state = PB_SERVICE_STATE.FILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_transform.value = PB_Transform.new()
		return _transform.value
	
	var _uuidCallback: PBField
	func has_uuidCallback() -> bool:
		return data[8].state == PB_SERVICE_STATE.FILLED
	func get_uuidCallback() -> PB_UUIDCallback:
		return _uuidCallback.value
	func clear_uuidCallback() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_uuidCallback() -> PB_UUIDCallback:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		data[8].state = PB_SERVICE_STATE.FILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = PB_UUIDCallback.new()
		return _uuidCallback.value
	
	var _box: PBField
	func has_box() -> bool:
		return data[16].state == PB_SERVICE_STATE.FILLED
	func get_box() -> PB_BoxShape:
		return _box.value
	func clear_box() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_box() -> PB_BoxShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		data[16].state = PB_SERVICE_STATE.FILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_box.value = PB_BoxShape.new()
		return _box.value
	
	var _sphere: PBField
	func has_sphere() -> bool:
		return data[17].state == PB_SERVICE_STATE.FILLED
	func get_sphere() -> PB_SphereShape:
		return _sphere.value
	func clear_sphere() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_sphere() -> PB_SphereShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		data[17].state = PB_SERVICE_STATE.FILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = PB_SphereShape.new()
		return _sphere.value
	
	var _plane: PBField
	func has_plane() -> bool:
		return data[18].state == PB_SERVICE_STATE.FILLED
	func get_plane() -> PB_PlaneShape:
		return _plane.value
	func clear_plane() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_plane() -> PB_PlaneShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		data[18].state = PB_SERVICE_STATE.FILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = PB_PlaneShape.new()
		return _plane.value
	
	var _cone: PBField
	func has_cone() -> bool:
		return data[19].state == PB_SERVICE_STATE.FILLED
	func get_cone() -> PB_ConeShape:
		return _cone.value
	func clear_cone() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_cone() -> PB_ConeShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		data[19].state = PB_SERVICE_STATE.FILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = PB_ConeShape.new()
		return _cone.value
	
	var _cylinder: PBField
	func has_cylinder() -> bool:
		return data[20].state == PB_SERVICE_STATE.FILLED
	func get_cylinder() -> PB_CylinderShape:
		return _cylinder.value
	func clear_cylinder() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_cylinder() -> PB_CylinderShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		data[20].state = PB_SERVICE_STATE.FILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = PB_CylinderShape.new()
		return _cylinder.value
	
	var _text: PBField
	func has_text() -> bool:
		return data[21].state == PB_SERVICE_STATE.FILLED
	func get_text() -> PB_TextShape:
		return _text.value
	func clear_text() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_text() -> PB_TextShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		data[21].state = PB_SERVICE_STATE.FILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_text.value = PB_TextShape.new()
		return _text.value
	
	var _nft: PBField
	func has_nft() -> bool:
		return data[22].state == PB_SERVICE_STATE.FILLED
	func get_nft() -> PB_NFTShape:
		return _nft.value
	func clear_nft() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_nft() -> PB_NFTShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		data[22].state = PB_SERVICE_STATE.FILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = PB_NFTShape.new()
		return _nft.value
	
	var _containerRect: PBField
	func has_containerRect() -> bool:
		return data[25].state == PB_SERVICE_STATE.FILLED
	func get_containerRect() -> PB_UIContainerRect:
		return _containerRect.value
	func clear_containerRect() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_containerRect() -> PB_UIContainerRect:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		data[25].state = PB_SERVICE_STATE.FILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = PB_UIContainerRect.new()
		return _containerRect.value
	
	var _containerStack: PBField
	func has_containerStack() -> bool:
		return data[26].state == PB_SERVICE_STATE.FILLED
	func get_containerStack() -> PB_UIContainerStack:
		return _containerStack.value
	func clear_containerStack() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_containerStack() -> PB_UIContainerStack:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		data[26].state = PB_SERVICE_STATE.FILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = PB_UIContainerStack.new()
		return _containerStack.value
	
	var _uiTextShape: PBField
	func has_uiTextShape() -> bool:
		return data[27].state == PB_SERVICE_STATE.FILLED
	func get_uiTextShape() -> PB_UITextShape:
		return _uiTextShape.value
	func clear_uiTextShape() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_uiTextShape() -> PB_UITextShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		data[27].state = PB_SERVICE_STATE.FILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = PB_UITextShape.new()
		return _uiTextShape.value
	
	var _uiInputTextShape: PBField
	func has_uiInputTextShape() -> bool:
		return data[28].state == PB_SERVICE_STATE.FILLED
	func get_uiInputTextShape() -> PB_UIInputText:
		return _uiInputTextShape.value
	func clear_uiInputTextShape() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_uiInputTextShape() -> PB_UIInputText:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		data[28].state = PB_SERVICE_STATE.FILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = PB_UIInputText.new()
		return _uiInputTextShape.value
	
	var _uiImageShape: PBField
	func has_uiImageShape() -> bool:
		return data[29].state == PB_SERVICE_STATE.FILLED
	func get_uiImageShape() -> PB_UIImage:
		return _uiImageShape.value
	func clear_uiImageShape() -> void:
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_uiImageShape() -> PB_UIImage:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		data[29].state = PB_SERVICE_STATE.FILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = PB_UIImage.new()
		return _uiImageShape.value
	
	var _circle: PBField
	func has_circle() -> bool:
		return data[31].state == PB_SERVICE_STATE.FILLED
	func get_circle() -> PB_CircleShape:
		return _circle.value
	func clear_circle() -> void:
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_circle() -> PB_CircleShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		data[31].state = PB_SERVICE_STATE.FILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = PB_CircleShape.new()
		return _circle.value
	
	var _billboard: PBField
	func has_billboard() -> bool:
		return data[32].state == PB_SERVICE_STATE.FILLED
	func get_billboard() -> PB_Billboard:
		return _billboard.value
	func clear_billboard() -> void:
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_billboard() -> PB_Billboard:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		data[32].state = PB_SERVICE_STATE.FILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = PB_Billboard.new()
		return _billboard.value
	
	var _gltf: PBField
	func has_gltf() -> bool:
		return data[54].state == PB_SERVICE_STATE.FILLED
	func get_gltf() -> PB_GLTFShape:
		return _gltf.value
	func clear_gltf() -> void:
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_gltf() -> PB_GLTFShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		data[54].state = PB_SERVICE_STATE.FILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = PB_GLTFShape.new()
		return _gltf.value
	
	var _obj: PBField
	func has_obj() -> bool:
		return data[55].state == PB_SERVICE_STATE.FILLED
	func get_obj() -> PB_OBJShape:
		return _obj.value
	func clear_obj() -> void:
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_obj() -> PB_OBJShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		data[55].state = PB_SERVICE_STATE.FILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = PB_OBJShape.new()
		return _obj.value
	
	var _avatar: PBField
	func has_avatar() -> bool:
		return data[56].state == PB_SERVICE_STATE.FILLED
	func get_avatar() -> PB_AvatarShape:
		return _avatar.value
	func clear_avatar() -> void:
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_avatar() -> PB_AvatarShape:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		data[56].state = PB_SERVICE_STATE.FILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = PB_AvatarShape.new()
		return _avatar.value
	
	var _basicMaterial: PBField
	func has_basicMaterial() -> bool:
		return data[64].state == PB_SERVICE_STATE.FILLED
	func get_basicMaterial() -> PB_BasicMaterial:
		return _basicMaterial.value
	func clear_basicMaterial() -> void:
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_basicMaterial() -> PB_BasicMaterial:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		data[64].state = PB_SERVICE_STATE.FILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = PB_BasicMaterial.new()
		return _basicMaterial.value
	
	var _texture: PBField
	func has_texture() -> bool:
		return data[68].state == PB_SERVICE_STATE.FILLED
	func get_texture() -> PB_Texture:
		return _texture.value
	func clear_texture() -> void:
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_texture() -> PB_Texture:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		data[68].state = PB_SERVICE_STATE.FILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = PB_Texture.new()
		return _texture.value
	
	var _audioClip: PBField
	func has_audioClip() -> bool:
		return data[200].state == PB_SERVICE_STATE.FILLED
	func get_audioClip() -> PB_AudioClip:
		return _audioClip.value
	func clear_audioClip() -> void:
		data[200].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_audioClip() -> PB_AudioClip:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		data[200].state = PB_SERVICE_STATE.FILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = PB_AudioClip.new()
		return _audioClip.value
	
	var _audioSource: PBField
	func has_audioSource() -> bool:
		return data[201].state == PB_SERVICE_STATE.FILLED
	func get_audioSource() -> PB_AudioSource:
		return _audioSource.value
	func clear_audioSource() -> void:
		data[201].state = PB_SERVICE_STATE.UNFILLED
		_audioSource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_audioSource() -> PB_AudioSource:
		_transform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uuidCallback.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_box.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_sphere.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_plane.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_cone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_cylinder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_nft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_containerRect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_containerStack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_uiTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_uiInputTextShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_uiImageShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_gltf.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[54].state = PB_SERVICE_STATE.UNFILLED
		_obj.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[55].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[56].state = PB_SERVICE_STATE.UNFILLED
		_basicMaterial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[64].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[68].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[200].state = PB_SERVICE_STATE.UNFILLED
		data[201].state = PB_SERVICE_STATE.FILLED
		_audioSource.value = PB_AudioSource.new()
		return _audioSource.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Color4:
	func _init():
		var service
		
		_r = PBField.new("r", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _r
		data[_r.tag] = service
		
		_g = PBField.new("g", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _g
		data[_g.tag] = service
		
		_b = PBField.new("b", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _b
		data[_b.tag] = service
		
		_a = PBField.new("a", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _a
		data[_a.tag] = service
		
	var data = {}
	
	var _r: PBField
	func get_r() -> float:
		return _r.value
	func clear_r() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_r.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_r(value : float) -> void:
		_r.value = value
	
	var _g: PBField
	func get_g() -> float:
		return _g.value
	func clear_g() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_g.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_g(value : float) -> void:
		_g.value = value
	
	var _b: PBField
	func get_b() -> float:
		return _b.value
	func clear_b() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_b.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_b(value : float) -> void:
		_b.value = value
	
	var _a: PBField
	func get_a() -> float:
		return _a.value
	func clear_a() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_a.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_a(value : float) -> void:
		_a.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Color3:
	func _init():
		var service
		
		_r = PBField.new("r", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _r
		data[_r.tag] = service
		
		_g = PBField.new("g", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _g
		data[_g.tag] = service
		
		_b = PBField.new("b", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _b
		data[_b.tag] = service
		
	var data = {}
	
	var _r: PBField
	func get_r() -> float:
		return _r.value
	func clear_r() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_r.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_r(value : float) -> void:
		_r.value = value
	
	var _g: PBField
	func get_g() -> float:
		return _g.value
	func clear_g() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_g.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_g(value : float) -> void:
		_g.value = value
	
	var _b: PBField
	func get_b() -> float:
		return _b.value
	func clear_b() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_b.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_b(value : float) -> void:
		_b.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_TextShapeModel:
	func _init():
		var service
		
		_billboard = PBField.new("billboard", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _billboard
		data[_billboard.tag] = service
		
		_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _value
		data[_value.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_fontSize = PBField.new("fontSize", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _fontSize
		data[_fontSize.tag] = service
		
		_fontAutoSize = PBField.new("fontAutoSize", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _fontAutoSize
		data[_fontAutoSize.tag] = service
		
		_fontWeight = PBField.new("fontWeight", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _fontWeight
		data[_fontWeight.tag] = service
		
		_hTextAlign = PBField.new("hTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hTextAlign
		data[_hTextAlign.tag] = service
		
		_vTextAlign = PBField.new("vTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vTextAlign
		data[_vTextAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_adaptWidth = PBField.new("adaptWidth", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptWidth
		data[_adaptWidth.tag] = service
		
		_adaptHeight = PBField.new("adaptHeight", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptHeight
		data[_adaptHeight.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
		_lineSpacing = PBField.new("lineSpacing", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _lineSpacing
		data[_lineSpacing.tag] = service
		
		_lineCount = PBField.new("lineCount", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _lineCount
		data[_lineCount.tag] = service
		
		_textWrapping = PBField.new("textWrapping", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _textWrapping
		data[_textWrapping.tag] = service
		
		_shadowBlur = PBField.new("shadowBlur", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowBlur
		data[_shadowBlur.tag] = service
		
		_shadowOffsetX = PBField.new("shadowOffsetX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetX
		data[_shadowOffsetX.tag] = service
		
		_shadowOffsetY = PBField.new("shadowOffsetY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetY
		data[_shadowOffsetY.tag] = service
		
		_shadowColor = PBField.new("shadowColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _shadowColor
		service.func_ref = funcref(self, "new_shadowColor")
		data[_shadowColor.tag] = service
		
		_outlineWidth = PBField.new("outlineWidth", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _outlineWidth
		data[_outlineWidth.tag] = service
		
		_outlineColor = PBField.new("outlineColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _outlineColor
		service.func_ref = funcref(self, "new_outlineColor")
		data[_outlineColor.tag] = service
		
	var data = {}
	
	var _billboard: PBField
	func get_billboard() -> bool:
		return _billboard.value
	func clear_billboard() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_billboard(value : bool) -> void:
		_billboard.value = value
	
	var _value: PBField
	func get_value() -> String:
		return _value.value
	func clear_value() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_value(value : String) -> void:
		_value.value = value
	
	var _color: PBField
	func get_color() -> PB_Color3:
		return _color.value
	func clear_color() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color3:
		_color.value = PB_Color3.new()
		return _color.value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _fontSize: PBField
	func get_fontSize() -> float:
		return _fontSize.value
	func clear_fontSize() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_fontSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_fontSize(value : float) -> void:
		_fontSize.value = value
	
	var _fontAutoSize: PBField
	func get_fontAutoSize() -> bool:
		return _fontAutoSize.value
	func clear_fontAutoSize() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_fontAutoSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_fontAutoSize(value : bool) -> void:
		_fontAutoSize.value = value
	
	var _fontWeight: PBField
	func get_fontWeight() -> String:
		return _fontWeight.value
	func clear_fontWeight() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_fontWeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_fontWeight(value : String) -> void:
		_fontWeight.value = value
	
	var _hTextAlign: PBField
	func get_hTextAlign() -> String:
		return _hTextAlign.value
	func clear_hTextAlign() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_hTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hTextAlign(value : String) -> void:
		_hTextAlign.value = value
	
	var _vTextAlign: PBField
	func get_vTextAlign() -> String:
		return _vTextAlign.value
	func clear_vTextAlign() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_vTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vTextAlign(value : String) -> void:
		_vTextAlign.value = value
	
	var _width: PBField
	func get_width() -> float:
		return _width.value
	func clear_width() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_width(value : float) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> float:
		return _height.value
	func clear_height() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_height(value : float) -> void:
		_height.value = value
	
	var _adaptWidth: PBField
	func get_adaptWidth() -> bool:
		return _adaptWidth.value
	func clear_adaptWidth() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_adaptWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptWidth(value : bool) -> void:
		_adaptWidth.value = value
	
	var _adaptHeight: PBField
	func get_adaptHeight() -> bool:
		return _adaptHeight.value
	func clear_adaptHeight() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_adaptHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptHeight(value : bool) -> void:
		_adaptHeight.value = value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	var _lineSpacing: PBField
	func get_lineSpacing() -> float:
		return _lineSpacing.value
	func clear_lineSpacing() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_lineSpacing.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_lineSpacing(value : float) -> void:
		_lineSpacing.value = value
	
	var _lineCount: PBField
	func get_lineCount() -> int:
		return _lineCount.value
	func clear_lineCount() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_lineCount.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_lineCount(value : int) -> void:
		_lineCount.value = value
	
	var _textWrapping: PBField
	func get_textWrapping() -> bool:
		return _textWrapping.value
	func clear_textWrapping() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_textWrapping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_textWrapping(value : bool) -> void:
		_textWrapping.value = value
	
	var _shadowBlur: PBField
	func get_shadowBlur() -> float:
		return _shadowBlur.value
	func clear_shadowBlur() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_shadowBlur.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowBlur(value : float) -> void:
		_shadowBlur.value = value
	
	var _shadowOffsetX: PBField
	func get_shadowOffsetX() -> float:
		return _shadowOffsetX.value
	func clear_shadowOffsetX() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetX(value : float) -> void:
		_shadowOffsetX.value = value
	
	var _shadowOffsetY: PBField
	func get_shadowOffsetY() -> float:
		return _shadowOffsetY.value
	func clear_shadowOffsetY() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetY(value : float) -> void:
		_shadowOffsetY.value = value
	
	var _shadowColor: PBField
	func get_shadowColor() -> PB_Color3:
		return _shadowColor.value
	func clear_shadowColor() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		_shadowColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_shadowColor() -> PB_Color3:
		_shadowColor.value = PB_Color3.new()
		return _shadowColor.value
	
	var _outlineWidth: PBField
	func get_outlineWidth() -> float:
		return _outlineWidth.value
	func clear_outlineWidth() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_outlineWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_outlineWidth(value : float) -> void:
		_outlineWidth.value = value
	
	var _outlineColor: PBField
	func get_outlineColor() -> PB_Color3:
		return _outlineColor.value
	func clear_outlineColor() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_outlineColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_outlineColor() -> PB_Color3:
		_outlineColor.value = PB_Color3.new()
		return _outlineColor.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Vector3:
	func _init():
		var service
		
		_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_z = PBField.new("z", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _z
		data[_z.tag] = service
		
	var data = {}
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		_y.value = value
	
	var _z: PBField
	func get_z() -> float:
		return _z.value
	func clear_z() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_z(value : float) -> void:
		_z.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Quaternion:
	func _init():
		var service
		
		_x = PBField.new("x", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_z = PBField.new("z", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = _z
		data[_z.tag] = service
		
		_w = PBField.new("w", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = _w
		data[_w.tag] = service
		
	var data = {}
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_y(value : float) -> void:
		_y.value = value
	
	var _z: PBField
	func get_z() -> float:
		return _z.value
	func clear_z() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_z(value : float) -> void:
		_z.value = value
	
	var _w: PBField
	func get_w() -> float:
		return _w.value
	func clear_w() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_w.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_w(value : float) -> void:
		_w.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Transform:
	func _init():
		var service
		
		_position = PBField.new("position", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _position
		service.func_ref = funcref(self, "new_position")
		data[_position.tag] = service
		
		_rotation = PBField.new("rotation", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _rotation
		service.func_ref = funcref(self, "new_rotation")
		data[_rotation.tag] = service
		
		_scale = PBField.new("scale", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _scale
		service.func_ref = funcref(self, "new_scale")
		data[_scale.tag] = service
		
	var data = {}
	
	var _position: PBField
	func get_position() -> PB_Vector3:
		return _position.value
	func clear_position() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_position.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_position() -> PB_Vector3:
		_position.value = PB_Vector3.new()
		return _position.value
	
	var _rotation: PBField
	func get_rotation() -> PB_Quaternion:
		return _rotation.value
	func clear_rotation() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_rotation.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_rotation() -> PB_Quaternion:
		_rotation.value = PB_Quaternion.new()
		return _rotation.value
	
	var _scale: PBField
	func get_scale() -> PB_Vector3:
		return _scale.value
	func clear_scale() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_scale() -> PB_Vector3:
		_scale.value = PB_Vector3.new()
		return _scale.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UpdateEntityComponent:
	func _init():
		var service
		
		_entityId = PBField.new("entityId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _entityId
		data[_entityId.tag] = service
		
		_classId = PBField.new("classId", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _classId
		data[_classId.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_data = PBField.new("data", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _data
		data[_data.tag] = service
		
	var data = {}
	
	var _entityId: PBField
	func get_entityId() -> String:
		return _entityId.value
	func clear_entityId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_entityId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_entityId(value : String) -> void:
		_entityId.value = value
	
	var _classId: PBField
	func get_classId() -> int:
		return _classId.value
	func clear_classId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_classId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_classId(value : int) -> void:
		_classId.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _data: PBField
	func get_data() -> String:
		return _data.value
	func clear_data() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_data(value : String) -> void:
		_data.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_ComponentCreated:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_classid = PBField.new("classid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _classid
		data[_classid.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	var _classid: PBField
	func get_classid() -> int:
		return _classid.value
	func clear_classid() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_classid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_classid(value : int) -> void:
		_classid.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_AttachEntityComponent:
	func _init():
		var service
		
		_entityId = PBField.new("entityId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _entityId
		data[_entityId.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
	var data = {}
	
	var _entityId: PBField
	func get_entityId() -> String:
		return _entityId.value
	func clear_entityId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_entityId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_entityId(value : String) -> void:
		_entityId.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_ComponentDisposed:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_ComponentUpdated:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_json = PBField.new("json", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _json
		data[_json.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	var _json: PBField
	func get_json() -> String:
		return _json.value
	func clear_json() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_json.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_json(value : String) -> void:
		_json.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Ray:
	func _init():
		var service
		
		_origin = PBField.new("origin", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _origin
		service.func_ref = funcref(self, "new_origin")
		data[_origin.tag] = service
		
		_direction = PBField.new("direction", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _direction
		service.func_ref = funcref(self, "new_direction")
		data[_direction.tag] = service
		
		_distance = PBField.new("distance", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _distance
		data[_distance.tag] = service
		
	var data = {}
	
	var _origin: PBField
	func get_origin() -> PB_Vector3:
		return _origin.value
	func clear_origin() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_origin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_origin() -> PB_Vector3:
		_origin.value = PB_Vector3.new()
		return _origin.value
	
	var _direction: PBField
	func get_direction() -> PB_Vector3:
		return _direction.value
	func clear_direction() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_direction.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_direction() -> PB_Vector3:
		_direction.value = PB_Vector3.new()
		return _direction.value
	
	var _distance: PBField
	func get_distance() -> float:
		return _distance.value
	func clear_distance() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_distance.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_distance(value : float) -> void:
		_distance.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_RayQuery:
	func _init():
		var service
		
		_queryId = PBField.new("queryId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _queryId
		data[_queryId.tag] = service
		
		_queryType = PBField.new("queryType", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _queryType
		data[_queryType.tag] = service
		
		_ray = PBField.new("ray", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _ray
		service.func_ref = funcref(self, "new_ray")
		data[_ray.tag] = service
		
	var data = {}
	
	var _queryId: PBField
	func get_queryId() -> String:
		return _queryId.value
	func clear_queryId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_queryId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_queryId(value : String) -> void:
		_queryId.value = value
	
	var _queryType: PBField
	func get_queryType() -> String:
		return _queryType.value
	func clear_queryType() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_queryType.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_queryType(value : String) -> void:
		_queryType.value = value
	
	var _ray: PBField
	func get_ray() -> PB_Ray:
		return _ray.value
	func clear_ray() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_ray.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ray() -> PB_Ray:
		_ray.value = PB_Ray.new()
		return _ray.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Query:
	func _init():
		var service
		
		_queryId = PBField.new("queryId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _queryId
		data[_queryId.tag] = service
		
		_payload = PBField.new("payload", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _payload
		data[_payload.tag] = service
		
	var data = {}
	
	var _queryId: PBField
	func get_queryId() -> String:
		return _queryId.value
	func clear_queryId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_queryId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_queryId(value : String) -> void:
		_queryId.value = value
	
	var _payload: PBField
	func get_payload() -> String:
		return _payload.value
	func clear_payload() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_payload.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_payload(value : String) -> void:
		_payload.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_SendSceneMessage:
	func _init():
		var service
		
		_sceneId = PBField.new("sceneId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _sceneId
		data[_sceneId.tag] = service
		
		_tag = PBField.new("tag", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _tag
		data[_tag.tag] = service
		
		_createEntity = PBField.new("createEntity", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _createEntity
		service.func_ref = funcref(self, "new_createEntity")
		data[_createEntity.tag] = service
		
		_removeEntity = PBField.new("removeEntity", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _removeEntity
		service.func_ref = funcref(self, "new_removeEntity")
		data[_removeEntity.tag] = service
		
		_setEntityParent = PBField.new("setEntityParent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _setEntityParent
		service.func_ref = funcref(self, "new_setEntityParent")
		data[_setEntityParent.tag] = service
		
		_updateEntityComponent = PBField.new("updateEntityComponent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _updateEntityComponent
		service.func_ref = funcref(self, "new_updateEntityComponent")
		data[_updateEntityComponent.tag] = service
		
		_attachEntityComponent = PBField.new("attachEntityComponent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _attachEntityComponent
		service.func_ref = funcref(self, "new_attachEntityComponent")
		data[_attachEntityComponent.tag] = service
		
		_componentCreated = PBField.new("componentCreated", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _componentCreated
		service.func_ref = funcref(self, "new_componentCreated")
		data[_componentCreated.tag] = service
		
		_componentDisposed = PBField.new("componentDisposed", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _componentDisposed
		service.func_ref = funcref(self, "new_componentDisposed")
		data[_componentDisposed.tag] = service
		
		_componentRemoved = PBField.new("componentRemoved", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _componentRemoved
		service.func_ref = funcref(self, "new_componentRemoved")
		data[_componentRemoved.tag] = service
		
		_componentUpdated = PBField.new("componentUpdated", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _componentUpdated
		service.func_ref = funcref(self, "new_componentUpdated")
		data[_componentUpdated.tag] = service
		
		_query = PBField.new("query", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _query
		service.func_ref = funcref(self, "new_query")
		data[_query.tag] = service
		
		_sceneStarted = PBField.new("sceneStarted", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _sceneStarted
		service.func_ref = funcref(self, "new_sceneStarted")
		data[_sceneStarted.tag] = service
		
		_openExternalUrl = PBField.new("openExternalUrl", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _openExternalUrl
		service.func_ref = funcref(self, "new_openExternalUrl")
		data[_openExternalUrl.tag] = service
		
		_openNFTDialog = PBField.new("openNFTDialog", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _openNFTDialog
		service.func_ref = funcref(self, "new_openNFTDialog")
		data[_openNFTDialog.tag] = service
		
	var data = {}
	
	var _sceneId: PBField
	func get_sceneId() -> String:
		return _sceneId.value
	func clear_sceneId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_sceneId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sceneId(value : String) -> void:
		_sceneId.value = value
	
	var _tag: PBField
	func get_tag() -> String:
		return _tag.value
	func clear_tag() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_tag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_tag(value : String) -> void:
		_tag.value = value
	
	var _createEntity: PBField
	func has_createEntity() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_createEntity() -> PB_CreateEntity:
		return _createEntity.value
	func clear_createEntity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_createEntity() -> PB_CreateEntity:
		data[3].state = PB_SERVICE_STATE.FILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_createEntity.value = PB_CreateEntity.new()
		return _createEntity.value
	
	var _removeEntity: PBField
	func has_removeEntity() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_removeEntity() -> PB_RemoveEntity:
		return _removeEntity.value
	func clear_removeEntity() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_removeEntity() -> PB_RemoveEntity:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = PB_RemoveEntity.new()
		return _removeEntity.value
	
	var _setEntityParent: PBField
	func has_setEntityParent() -> bool:
		return data[5].state == PB_SERVICE_STATE.FILLED
	func get_setEntityParent() -> PB_SetEntityParent:
		return _setEntityParent.value
	func clear_setEntityParent() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_setEntityParent() -> PB_SetEntityParent:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		data[5].state = PB_SERVICE_STATE.FILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = PB_SetEntityParent.new()
		return _setEntityParent.value
	
	var _updateEntityComponent: PBField
	func has_updateEntityComponent() -> bool:
		return data[6].state == PB_SERVICE_STATE.FILLED
	func get_updateEntityComponent() -> PB_UpdateEntityComponent:
		return _updateEntityComponent.value
	func clear_updateEntityComponent() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_updateEntityComponent() -> PB_UpdateEntityComponent:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		data[6].state = PB_SERVICE_STATE.FILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = PB_UpdateEntityComponent.new()
		return _updateEntityComponent.value
	
	var _attachEntityComponent: PBField
	func has_attachEntityComponent() -> bool:
		return data[7].state == PB_SERVICE_STATE.FILLED
	func get_attachEntityComponent() -> PB_AttachEntityComponent:
		return _attachEntityComponent.value
	func clear_attachEntityComponent() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_attachEntityComponent() -> PB_AttachEntityComponent:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		data[7].state = PB_SERVICE_STATE.FILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = PB_AttachEntityComponent.new()
		return _attachEntityComponent.value
	
	var _componentCreated: PBField
	func has_componentCreated() -> bool:
		return data[8].state == PB_SERVICE_STATE.FILLED
	func get_componentCreated() -> PB_ComponentCreated:
		return _componentCreated.value
	func clear_componentCreated() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_componentCreated() -> PB_ComponentCreated:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		data[8].state = PB_SERVICE_STATE.FILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = PB_ComponentCreated.new()
		return _componentCreated.value
	
	var _componentDisposed: PBField
	func has_componentDisposed() -> bool:
		return data[9].state == PB_SERVICE_STATE.FILLED
	func get_componentDisposed() -> PB_ComponentDisposed:
		return _componentDisposed.value
	func clear_componentDisposed() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_componentDisposed() -> PB_ComponentDisposed:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		data[9].state = PB_SERVICE_STATE.FILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = PB_ComponentDisposed.new()
		return _componentDisposed.value
	
	var _componentRemoved: PBField
	func has_componentRemoved() -> bool:
		return data[10].state == PB_SERVICE_STATE.FILLED
	func get_componentRemoved() -> PB_ComponentRemoved:
		return _componentRemoved.value
	func clear_componentRemoved() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_componentRemoved() -> PB_ComponentRemoved:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		data[10].state = PB_SERVICE_STATE.FILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = PB_ComponentRemoved.new()
		return _componentRemoved.value
	
	var _componentUpdated: PBField
	func has_componentUpdated() -> bool:
		return data[11].state == PB_SERVICE_STATE.FILLED
	func get_componentUpdated() -> PB_ComponentUpdated:
		return _componentUpdated.value
	func clear_componentUpdated() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_componentUpdated() -> PB_ComponentUpdated:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		data[11].state = PB_SERVICE_STATE.FILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = PB_ComponentUpdated.new()
		return _componentUpdated.value
	
	var _query: PBField
	func has_query() -> bool:
		return data[12].state == PB_SERVICE_STATE.FILLED
	func get_query() -> PB_Query:
		return _query.value
	func clear_query() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_query() -> PB_Query:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		data[12].state = PB_SERVICE_STATE.FILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_query.value = PB_Query.new()
		return _query.value
	
	var _sceneStarted: PBField
	func has_sceneStarted() -> bool:
		return data[13].state == PB_SERVICE_STATE.FILLED
	func get_sceneStarted() -> PB_Empty:
		return _sceneStarted.value
	func clear_sceneStarted() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_sceneStarted() -> PB_Empty:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		data[13].state = PB_SERVICE_STATE.FILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = PB_Empty.new()
		return _sceneStarted.value
	
	var _openExternalUrl: PBField
	func has_openExternalUrl() -> bool:
		return data[14].state == PB_SERVICE_STATE.FILLED
	func get_openExternalUrl() -> PB_OpenExternalUrl:
		return _openExternalUrl.value
	func clear_openExternalUrl() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_openExternalUrl() -> PB_OpenExternalUrl:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		data[14].state = PB_SERVICE_STATE.FILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = PB_OpenExternalUrl.new()
		return _openExternalUrl.value
	
	var _openNFTDialog: PBField
	func has_openNFTDialog() -> bool:
		return data[15].state == PB_SERVICE_STATE.FILLED
	func get_openNFTDialog() -> PB_OpenNFTDialog:
		return _openNFTDialog.value
	func clear_openNFTDialog() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_openNFTDialog.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_openNFTDialog() -> PB_OpenNFTDialog:
		_createEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_removeEntity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_setEntityParent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_updateEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_attachEntityComponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_componentCreated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_componentDisposed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_componentRemoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_componentUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_query.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sceneStarted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_openExternalUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		data[15].state = PB_SERVICE_STATE.FILLED
		_openNFTDialog.value = PB_OpenNFTDialog.new()
		return _openNFTDialog.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_SetPosition:
	func _init():
		var service
		
		_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_z = PBField.new("z", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _z
		data[_z.tag] = service
		
	var data = {}
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		_y.value = value
	
	var _z: PBField
	func get_z() -> float:
		return _z.value
	func clear_z() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_z(value : float) -> void:
		_z.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_ContentMapping:
	func _init():
		var service
		
		_file = PBField.new("file", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _file
		data[_file.tag] = service
		
		_hash = PBField.new("hash", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hash
		data[_hash.tag] = service
		
	var data = {}
	
	var _file: PBField
	func get_file() -> String:
		return _file.value
	func clear_file() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_file.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_file(value : String) -> void:
		_file.value = value
	
	var _hash: PBField
	func get_hash() -> String:
		return _hash.value
	func clear_hash() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_hash.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hash(value : String) -> void:
		_hash.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Position:
	func _init():
		var service
		
		_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
	var data = {}
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		_y.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_LoadParcelScenes:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_basePosition = PBField.new("basePosition", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _basePosition
		service.func_ref = funcref(self, "new_basePosition")
		data[_basePosition.tag] = service
		
		_parcels = PBField.new("parcels", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _parcels
		service.func_ref = funcref(self, "add_parcels")
		data[_parcels.tag] = service
		
		_contents = PBField.new("contents", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _contents
		service.func_ref = funcref(self, "add_contents")
		data[_contents.tag] = service
		
		_baseUrl = PBField.new("baseUrl", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _baseUrl
		data[_baseUrl.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	var _basePosition: PBField
	func get_basePosition() -> PB_Position:
		return _basePosition.value
	func clear_basePosition() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_basePosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_basePosition() -> PB_Position:
		_basePosition.value = PB_Position.new()
		return _basePosition.value
	
	var _parcels: PBField
	func get_parcels() -> Array:
		return _parcels.value
	func clear_parcels() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_parcels.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_parcels() -> PB_Position:
		var element = PB_Position.new()
		_parcels.value.append(element)
		return element
	
	var _contents: PBField
	func get_contents() -> Array:
		return _contents.value
	func clear_contents() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_contents.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_contents() -> PB_ContentMapping:
		var element = PB_ContentMapping.new()
		_contents.value.append(element)
		return element
	
	var _baseUrl: PBField
	func get_baseUrl() -> String:
		return _baseUrl.value
	func clear_baseUrl() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_baseUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_baseUrl(value : String) -> void:
		_baseUrl.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_CreateUIScene:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_baseUrl = PBField.new("baseUrl", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _baseUrl
		data[_baseUrl.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	var _baseUrl: PBField
	func get_baseUrl() -> String:
		return _baseUrl.value
	func clear_baseUrl() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_baseUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_baseUrl(value : String) -> void:
		_baseUrl.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UnloadScene:
	func _init():
		var service
		
		_sceneId = PBField.new("sceneId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _sceneId
		data[_sceneId.tag] = service
		
	var data = {}
	
	var _sceneId: PBField
	func get_sceneId() -> String:
		return _sceneId.value
	func clear_sceneId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_sceneId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sceneId(value : String) -> void:
		_sceneId.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_DclMessage:
	func _init():
		var service
		
		_setDebug = PBField.new("setDebug", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _setDebug
		service.func_ref = funcref(self, "new_setDebug")
		data[_setDebug.tag] = service
		
		_setSceneDebugPanel = PBField.new("setSceneDebugPanel", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _setSceneDebugPanel
		service.func_ref = funcref(self, "new_setSceneDebugPanel")
		data[_setSceneDebugPanel.tag] = service
		
		_setEngineDebugPanel = PBField.new("setEngineDebugPanel", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _setEngineDebugPanel
		service.func_ref = funcref(self, "new_setEngineDebugPanel")
		data[_setEngineDebugPanel.tag] = service
		
		_sendSceneMessage = PBField.new("sendSceneMessage", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _sendSceneMessage
		service.func_ref = funcref(self, "new_sendSceneMessage")
		data[_sendSceneMessage.tag] = service
		
		_loadParcelScenes = PBField.new("loadParcelScenes", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _loadParcelScenes
		service.func_ref = funcref(self, "new_loadParcelScenes")
		data[_loadParcelScenes.tag] = service
		
		_unloadScene = PBField.new("unloadScene", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _unloadScene
		service.func_ref = funcref(self, "new_unloadScene")
		data[_unloadScene.tag] = service
		
		_setPosition = PBField.new("setPosition", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _setPosition
		service.func_ref = funcref(self, "new_setPosition")
		data[_setPosition.tag] = service
		
		_reset = PBField.new("reset", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _reset
		service.func_ref = funcref(self, "new_reset")
		data[_reset.tag] = service
		
		_createUIScene = PBField.new("createUIScene", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _createUIScene
		service.func_ref = funcref(self, "new_createUIScene")
		data[_createUIScene.tag] = service
		
	var data = {}
	
	var _setDebug: PBField
	func has_setDebug() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_setDebug() -> PB_Empty:
		return _setDebug.value
	func clear_setDebug() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_setDebug() -> PB_Empty:
		data[1].state = PB_SERVICE_STATE.FILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_setDebug.value = PB_Empty.new()
		return _setDebug.value
	
	var _setSceneDebugPanel: PBField
	func has_setSceneDebugPanel() -> bool:
		return data[2].state == PB_SERVICE_STATE.FILLED
	func get_setSceneDebugPanel() -> PB_Empty:
		return _setSceneDebugPanel.value
	func clear_setSceneDebugPanel() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_setSceneDebugPanel() -> PB_Empty:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		data[2].state = PB_SERVICE_STATE.FILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = PB_Empty.new()
		return _setSceneDebugPanel.value
	
	var _setEngineDebugPanel: PBField
	func has_setEngineDebugPanel() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_setEngineDebugPanel() -> PB_Empty:
		return _setEngineDebugPanel.value
	func clear_setEngineDebugPanel() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_setEngineDebugPanel() -> PB_Empty:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		data[3].state = PB_SERVICE_STATE.FILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = PB_Empty.new()
		return _setEngineDebugPanel.value
	
	var _sendSceneMessage: PBField
	func has_sendSceneMessage() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_sendSceneMessage() -> PB_SendSceneMessage:
		return _sendSceneMessage.value
	func clear_sendSceneMessage() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_sendSceneMessage() -> PB_SendSceneMessage:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = PB_SendSceneMessage.new()
		return _sendSceneMessage.value
	
	var _loadParcelScenes: PBField
	func has_loadParcelScenes() -> bool:
		return data[5].state == PB_SERVICE_STATE.FILLED
	func get_loadParcelScenes() -> PB_LoadParcelScenes:
		return _loadParcelScenes.value
	func clear_loadParcelScenes() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_loadParcelScenes() -> PB_LoadParcelScenes:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		data[5].state = PB_SERVICE_STATE.FILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = PB_LoadParcelScenes.new()
		return _loadParcelScenes.value
	
	var _unloadScene: PBField
	func has_unloadScene() -> bool:
		return data[6].state == PB_SERVICE_STATE.FILLED
	func get_unloadScene() -> PB_UnloadScene:
		return _unloadScene.value
	func clear_unloadScene() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_unloadScene() -> PB_UnloadScene:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		data[6].state = PB_SERVICE_STATE.FILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = PB_UnloadScene.new()
		return _unloadScene.value
	
	var _setPosition: PBField
	func has_setPosition() -> bool:
		return data[7].state == PB_SERVICE_STATE.FILLED
	func get_setPosition() -> PB_SetPosition:
		return _setPosition.value
	func clear_setPosition() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_setPosition() -> PB_SetPosition:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		data[7].state = PB_SERVICE_STATE.FILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = PB_SetPosition.new()
		return _setPosition.value
	
	var _reset: PBField
	func has_reset() -> bool:
		return data[8].state == PB_SERVICE_STATE.FILLED
	func get_reset() -> PB_Empty:
		return _reset.value
	func clear_reset() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_reset() -> PB_Empty:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		data[8].state = PB_SERVICE_STATE.FILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = PB_Empty.new()
		return _reset.value
	
	var _createUIScene: PBField
	func has_createUIScene() -> bool:
		return data[9].state == PB_SERVICE_STATE.FILLED
	func get_createUIScene() -> PB_CreateUIScene:
		return _createUIScene.value
	func clear_createUIScene() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_createUIScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_createUIScene() -> PB_CreateUIScene:
		_setDebug.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_setSceneDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_setEngineDebugPanel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sendSceneMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_loadParcelScenes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_unloadScene.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_setPosition.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		data[9].state = PB_SERVICE_STATE.FILLED
		_createUIScene.value = PB_CreateUIScene.new()
		return _createUIScene.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_AnimationState:
	func _init():
		var service
		
		_clip = PBField.new("clip", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _clip
		data[_clip.tag] = service
		
		_looping = PBField.new("looping", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _looping
		data[_looping.tag] = service
		
		_weight = PBField.new("weight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _weight
		data[_weight.tag] = service
		
		_playing = PBField.new("playing", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _playing
		data[_playing.tag] = service
		
		_shouldReset = PBField.new("shouldReset", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _shouldReset
		data[_shouldReset.tag] = service
		
		_speed = PBField.new("speed", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _speed
		data[_speed.tag] = service
		
	var data = {}
	
	var _clip: PBField
	func get_clip() -> String:
		return _clip.value
	func clear_clip() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_clip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_clip(value : String) -> void:
		_clip.value = value
	
	var _looping: PBField
	func get_looping() -> bool:
		return _looping.value
	func clear_looping() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_looping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_looping(value : bool) -> void:
		_looping.value = value
	
	var _weight: PBField
	func get_weight() -> float:
		return _weight.value
	func clear_weight() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_weight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_weight(value : float) -> void:
		_weight.value = value
	
	var _playing: PBField
	func get_playing() -> bool:
		return _playing.value
	func clear_playing() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_playing.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_playing(value : bool) -> void:
		_playing.value = value
	
	var _shouldReset: PBField
	func get_shouldReset() -> bool:
		return _shouldReset.value
	func clear_shouldReset() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_shouldReset.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_shouldReset(value : bool) -> void:
		_shouldReset.value = value
	
	var _speed: PBField
	func get_speed() -> float:
		return _speed.value
	func clear_speed() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_speed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_speed(value : float) -> void:
		_speed.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Animator:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_AudioClip:
	func _init():
		var service
		
		_url = PBField.new("url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _url
		data[_url.tag] = service
		
		_loop = PBField.new("loop", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _loop
		data[_loop.tag] = service
		
		_volume = PBField.new("volume", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _volume
		data[_volume.tag] = service
		
	var data = {}
	
	var _url: PBField
	func get_url() -> String:
		return _url.value
	func clear_url() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_url(value : String) -> void:
		_url.value = value
	
	var _loop: PBField
	func get_loop() -> bool:
		return _loop.value
	func clear_loop() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_loop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_loop(value : bool) -> void:
		_loop.value = value
	
	var _volume: PBField
	func get_volume() -> float:
		return _volume.value
	func clear_volume() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_volume.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_volume(value : float) -> void:
		_volume.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_AudioSource:
	func _init():
		var service
		
		_audioClip = PBField.new("audioClip", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _audioClip
		service.func_ref = funcref(self, "new_audioClip")
		data[_audioClip.tag] = service
		
		_audioClipId = PBField.new("audioClipId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _audioClipId
		data[_audioClipId.tag] = service
		
		_loop = PBField.new("loop", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _loop
		data[_loop.tag] = service
		
		_volume = PBField.new("volume", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _volume
		data[_volume.tag] = service
		
		_playing = PBField.new("playing", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _playing
		data[_playing.tag] = service
		
		_pitch = PBField.new("pitch", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _pitch
		data[_pitch.tag] = service
		
	var data = {}
	
	var _audioClip: PBField
	func get_audioClip() -> PB_AudioClip:
		return _audioClip.value
	func clear_audioClip() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_audioClip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_audioClip() -> PB_AudioClip:
		_audioClip.value = PB_AudioClip.new()
		return _audioClip.value
	
	var _audioClipId: PBField
	func get_audioClipId() -> String:
		return _audioClipId.value
	func clear_audioClipId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_audioClipId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_audioClipId(value : String) -> void:
		_audioClipId.value = value
	
	var _loop: PBField
	func get_loop() -> bool:
		return _loop.value
	func clear_loop() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_loop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_loop(value : bool) -> void:
		_loop.value = value
	
	var _volume: PBField
	func get_volume() -> float:
		return _volume.value
	func clear_volume() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_volume.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_volume(value : float) -> void:
		_volume.value = value
	
	var _playing: PBField
	func get_playing() -> bool:
		return _playing.value
	func clear_playing() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_playing.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_playing(value : bool) -> void:
		_playing.value = value
	
	var _pitch: PBField
	func get_pitch() -> float:
		return _pitch.value
	func clear_pitch() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_pitch.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_pitch(value : float) -> void:
		_pitch.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_AvatarShape:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_baseUrl = PBField.new("baseUrl", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _baseUrl
		data[_baseUrl.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_bodyShape = PBField.new("bodyShape", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _bodyShape
		service.func_ref = funcref(self, "new_bodyShape")
		data[_bodyShape.tag] = service
		
		_wearables = PBField.new("wearables", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _wearables
		service.func_ref = funcref(self, "add_wearables")
		data[_wearables.tag] = service
		
		_skin = PBField.new("skin", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _skin
		service.func_ref = funcref(self, "new_skin")
		data[_skin.tag] = service
		
		_hair = PBField.new("hair", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _hair
		service.func_ref = funcref(self, "new_hair")
		data[_hair.tag] = service
		
		_eyes = PBField.new("eyes", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _eyes
		service.func_ref = funcref(self, "new_eyes")
		data[_eyes.tag] = service
		
		_eyebrows = PBField.new("eyebrows", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _eyebrows
		service.func_ref = funcref(self, "new_eyebrows")
		data[_eyebrows.tag] = service
		
		_mouth = PBField.new("mouth", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _mouth
		service.func_ref = funcref(self, "new_mouth")
		data[_mouth.tag] = service
		
		_useDummyModel = PBField.new("useDummyModel", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _useDummyModel
		data[_useDummyModel.tag] = service
		
		_expressionTriggerId = PBField.new("expressionTriggerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _expressionTriggerId
		data[_expressionTriggerId.tag] = service
		
		_expressionTriggerTimestamp = PBField.new("expressionTriggerTimestamp", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = _expressionTriggerTimestamp
		data[_expressionTriggerTimestamp.tag] = service
		
	var data = {}
	
	var _id: PBField
	func get_id() -> String:
		return _id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		_id.value = value
	
	var _baseUrl: PBField
	func get_baseUrl() -> String:
		return _baseUrl.value
	func clear_baseUrl() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_baseUrl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_baseUrl(value : String) -> void:
		_baseUrl.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _bodyShape: PBField
	func get_bodyShape() -> PB_Wearable:
		return _bodyShape.value
	func clear_bodyShape() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_bodyShape.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_bodyShape() -> PB_Wearable:
		_bodyShape.value = PB_Wearable.new()
		return _bodyShape.value
	
	var _wearables: PBField
	func get_wearables() -> Array:
		return _wearables.value
	func clear_wearables() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_wearables.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_wearables() -> PB_Wearable:
		var element = PB_Wearable.new()
		_wearables.value.append(element)
		return element
	
	var _skin: PBField
	func get_skin() -> PB_Skin:
		return _skin.value
	func clear_skin() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_skin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_skin() -> PB_Skin:
		_skin.value = PB_Skin.new()
		return _skin.value
	
	var _hair: PBField
	func get_hair() -> PB_Hair:
		return _hair.value
	func clear_hair() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_hair.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_hair() -> PB_Hair:
		_hair.value = PB_Hair.new()
		return _hair.value
	
	var _eyes: PBField
	func get_eyes() -> PB_Eyes:
		return _eyes.value
	func clear_eyes() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_eyes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_eyes() -> PB_Eyes:
		_eyes.value = PB_Eyes.new()
		return _eyes.value
	
	var _eyebrows: PBField
	func get_eyebrows() -> PB_Face:
		return _eyebrows.value
	func clear_eyebrows() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_eyebrows.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_eyebrows() -> PB_Face:
		_eyebrows.value = PB_Face.new()
		return _eyebrows.value
	
	var _mouth: PBField
	func get_mouth() -> PB_Face:
		return _mouth.value
	func clear_mouth() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_mouth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_mouth() -> PB_Face:
		_mouth.value = PB_Face.new()
		return _mouth.value
	
	var _useDummyModel: PBField
	func get_useDummyModel() -> bool:
		return _useDummyModel.value
	func clear_useDummyModel() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_useDummyModel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_useDummyModel(value : bool) -> void:
		_useDummyModel.value = value
	
	var _expressionTriggerId: PBField
	func get_expressionTriggerId() -> String:
		return _expressionTriggerId.value
	func clear_expressionTriggerId() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_expressionTriggerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_expressionTriggerId(value : String) -> void:
		_expressionTriggerId.value = value
	
	var _expressionTriggerTimestamp: PBField
	func get_expressionTriggerTimestamp() -> int:
		return _expressionTriggerTimestamp.value
	func clear_expressionTriggerTimestamp() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_expressionTriggerTimestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_expressionTriggerTimestamp(value : int) -> void:
		_expressionTriggerTimestamp.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Wearable:
	func _init():
		var service
		
		_categody = PBField.new("categody", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _categody
		data[_categody.tag] = service
		
		_contentName = PBField.new("contentName", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _contentName
		data[_contentName.tag] = service
		
		_contents = PBField.new("contents", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _contents
		service.func_ref = funcref(self, "add_contents")
		data[_contents.tag] = service
		
	var data = {}
	
	var _categody: PBField
	func get_categody() -> String:
		return _categody.value
	func clear_categody() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_categody.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_categody(value : String) -> void:
		_categody.value = value
	
	var _contentName: PBField
	func get_contentName() -> String:
		return _contentName.value
	func clear_contentName() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_contentName.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_contentName(value : String) -> void:
		_contentName.value = value
	
	var _contents: PBField
	func get_contents() -> Array:
		return _contents.value
	func clear_contents() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_contents.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_contents() -> PB_ContentMapping:
		var element = PB_ContentMapping.new()
		_contents.value.append(element)
		return element
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Face:
	func _init():
		var service
		
		_texture = PBField.new("texture", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _texture
		data[_texture.tag] = service
		
	var data = {}
	
	var _texture: PBField
	func get_texture() -> String:
		return _texture.value
	func clear_texture() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_texture(value : String) -> void:
		_texture.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Eyes:
	func _init():
		var service
		
		_texture = PBField.new("texture", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _texture
		data[_texture.tag] = service
		
		_mask = PBField.new("mask", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _mask
		data[_mask.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
	var data = {}
	
	var _texture: PBField
	func get_texture() -> String:
		return _texture.value
	func clear_texture() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_texture(value : String) -> void:
		_texture.value = value
	
	var _mask: PBField
	func get_mask() -> String:
		return _mask.value
	func clear_mask() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_mask.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_mask(value : String) -> void:
		_mask.value = value
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Hair:
	func _init():
		var service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
	var data = {}
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Skin:
	func _init():
		var service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
	var data = {}
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_BasicMaterial:
	func _init():
		var service
		
		_texture = PBField.new("texture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _texture
		service.func_ref = funcref(self, "new_texture")
		data[_texture.tag] = service
		
		_alphaTest = PBField.new("alphaTest", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _alphaTest
		data[_alphaTest.tag] = service
		
	var data = {}
	
	var _texture: PBField
	func get_texture() -> PB_Texture:
		return _texture.value
	func clear_texture() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_texture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_texture() -> PB_Texture:
		_texture.value = PB_Texture.new()
		return _texture.value
	
	var _alphaTest: PBField
	func get_alphaTest() -> float:
		return _alphaTest.value
	func clear_alphaTest() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_alphaTest.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_alphaTest(value : float) -> void:
		_alphaTest.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Billboard:
	func _init():
		var service
		
		_x = PBField.new("x", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_z = PBField.new("z", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _z
		data[_z.tag] = service
		
	var data = {}
	
	var _x: PBField
	func get_x() -> bool:
		return _x.value
	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_x(value : bool) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> bool:
		return _y.value
	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_y(value : bool) -> void:
		_y.value = value
	
	var _z: PBField
	func get_z() -> bool:
		return _z.value
	func clear_z() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_z(value : bool) -> void:
		_z.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_BoxShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_uvs = PBField.new("uvs", PB_DATA_TYPE.FLOAT, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _uvs
		data[_uvs.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _uvs: PBField
	func get_uvs() -> Array:
		return _uvs.value
	func clear_uvs() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_uvs.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func add_uvs(value : float) -> void:
		_uvs.value.append(value)
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_CircleShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_segments = PBField.new("segments", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _segments
		data[_segments.tag] = service
		
		_arc = PBField.new("arc", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _arc
		data[_arc.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _segments: PBField
	func get_segments() -> float:
		return _segments.value
	func clear_segments() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_segments.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_segments(value : float) -> void:
		_segments.value = value
	
	var _arc: PBField
	func get_arc() -> float:
		return _arc.value
	func clear_arc() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_arc.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_arc(value : float) -> void:
		_arc.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_ConeShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_radiusTop = PBField.new("radiusTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _radiusTop
		data[_radiusTop.tag] = service
		
		_radiusBottom = PBField.new("radiusBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _radiusBottom
		data[_radiusBottom.tag] = service
		
		_segmentsHeight = PBField.new("segmentsHeight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _segmentsHeight
		data[_segmentsHeight.tag] = service
		
		_segmentsRadial = PBField.new("segmentsRadial", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _segmentsRadial
		data[_segmentsRadial.tag] = service
		
		_openEnded = PBField.new("openEnded", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _openEnded
		data[_openEnded.tag] = service
		
		_radius = PBField.new("radius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _radius
		data[_radius.tag] = service
		
		_arc = PBField.new("arc", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _arc
		data[_arc.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _radiusTop: PBField
	func get_radiusTop() -> float:
		return _radiusTop.value
	func clear_radiusTop() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_radiusTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_radiusTop(value : float) -> void:
		_radiusTop.value = value
	
	var _radiusBottom: PBField
	func get_radiusBottom() -> float:
		return _radiusBottom.value
	func clear_radiusBottom() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_radiusBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_radiusBottom(value : float) -> void:
		_radiusBottom.value = value
	
	var _segmentsHeight: PBField
	func get_segmentsHeight() -> float:
		return _segmentsHeight.value
	func clear_segmentsHeight() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_segmentsHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_segmentsHeight(value : float) -> void:
		_segmentsHeight.value = value
	
	var _segmentsRadial: PBField
	func get_segmentsRadial() -> float:
		return _segmentsRadial.value
	func clear_segmentsRadial() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_segmentsRadial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_segmentsRadial(value : float) -> void:
		_segmentsRadial.value = value
	
	var _openEnded: PBField
	func get_openEnded() -> bool:
		return _openEnded.value
	func clear_openEnded() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_openEnded.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_openEnded(value : bool) -> void:
		_openEnded.value = value
	
	var _radius: PBField
	func get_radius() -> float:
		return _radius.value
	func clear_radius() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_radius.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_radius(value : float) -> void:
		_radius.value = value
	
	var _arc: PBField
	func get_arc() -> float:
		return _arc.value
	func clear_arc() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_arc.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_arc(value : float) -> void:
		_arc.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_CylinderShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_radiusTop = PBField.new("radiusTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _radiusTop
		data[_radiusTop.tag] = service
		
		_radiusBottom = PBField.new("radiusBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _radiusBottom
		data[_radiusBottom.tag] = service
		
		_segmentsHeight = PBField.new("segmentsHeight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _segmentsHeight
		data[_segmentsHeight.tag] = service
		
		_segmentsRadial = PBField.new("segmentsRadial", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _segmentsRadial
		data[_segmentsRadial.tag] = service
		
		_openEnded = PBField.new("openEnded", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _openEnded
		data[_openEnded.tag] = service
		
		_radius = PBField.new("radius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _radius
		data[_radius.tag] = service
		
		_arc = PBField.new("arc", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _arc
		data[_arc.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _radiusTop: PBField
	func get_radiusTop() -> float:
		return _radiusTop.value
	func clear_radiusTop() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_radiusTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_radiusTop(value : float) -> void:
		_radiusTop.value = value
	
	var _radiusBottom: PBField
	func get_radiusBottom() -> float:
		return _radiusBottom.value
	func clear_radiusBottom() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_radiusBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_radiusBottom(value : float) -> void:
		_radiusBottom.value = value
	
	var _segmentsHeight: PBField
	func get_segmentsHeight() -> float:
		return _segmentsHeight.value
	func clear_segmentsHeight() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_segmentsHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_segmentsHeight(value : float) -> void:
		_segmentsHeight.value = value
	
	var _segmentsRadial: PBField
	func get_segmentsRadial() -> float:
		return _segmentsRadial.value
	func clear_segmentsRadial() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_segmentsRadial.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_segmentsRadial(value : float) -> void:
		_segmentsRadial.value = value
	
	var _openEnded: PBField
	func get_openEnded() -> bool:
		return _openEnded.value
	func clear_openEnded() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_openEnded.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_openEnded(value : bool) -> void:
		_openEnded.value = value
	
	var _radius: PBField
	func get_radius() -> float:
		return _radius.value
	func clear_radius() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_radius.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_radius(value : float) -> void:
		_radius.value = value
	
	var _arc: PBField
	func get_arc() -> float:
		return _arc.value
	func clear_arc() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_arc.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_arc(value : float) -> void:
		_arc.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_GlobalPointerDown:
	func _init():
		var service
		
	var data = {}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_GlobalPointerUp:
	func _init():
		var service
		
	var data = {}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_GLTFShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_src = PBField.new("src", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _src
		data[_src.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _src: PBField
	func get_src() -> String:
		return _src.value
	func clear_src() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_src.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_src(value : String) -> void:
		_src.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Material:
	func _init():
		var service
		
		_alpha = PBField.new("alpha", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _alpha
		data[_alpha.tag] = service
		
		_albedoColor = PBField.new("albedoColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _albedoColor
		service.func_ref = funcref(self, "new_albedoColor")
		data[_albedoColor.tag] = service
		
		_emissiveColor = PBField.new("emissiveColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _emissiveColor
		service.func_ref = funcref(self, "new_emissiveColor")
		data[_emissiveColor.tag] = service
		
		_metallic = PBField.new("metallic", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _metallic
		data[_metallic.tag] = service
		
		_roughness = PBField.new("roughness", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _roughness
		data[_roughness.tag] = service
		
		_ambientColor = PBField.new("ambientColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _ambientColor
		service.func_ref = funcref(self, "new_ambientColor")
		data[_ambientColor.tag] = service
		
		_reflectionColor = PBField.new("reflectionColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _reflectionColor
		service.func_ref = funcref(self, "new_reflectionColor")
		data[_reflectionColor.tag] = service
		
		_reflectivityColor = PBField.new("reflectivityColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _reflectivityColor
		service.func_ref = funcref(self, "new_reflectivityColor")
		data[_reflectivityColor.tag] = service
		
		_directIntensity = PBField.new("directIntensity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _directIntensity
		data[_directIntensity.tag] = service
		
		_microSurface = PBField.new("microSurface", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _microSurface
		data[_microSurface.tag] = service
		
		_emissiveIntensity = PBField.new("emissiveIntensity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _emissiveIntensity
		data[_emissiveIntensity.tag] = service
		
		_environmentIntensity = PBField.new("environmentIntensity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _environmentIntensity
		data[_environmentIntensity.tag] = service
		
		_specularIntensity = PBField.new("specularIntensity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _specularIntensity
		data[_specularIntensity.tag] = service
		
		_albedoTexture = PBField.new("albedoTexture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _albedoTexture
		service.func_ref = funcref(self, "new_albedoTexture")
		data[_albedoTexture.tag] = service
		
		_alphaTexture = PBField.new("alphaTexture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _alphaTexture
		service.func_ref = funcref(self, "new_alphaTexture")
		data[_alphaTexture.tag] = service
		
		_emissiveTexture = PBField.new("emissiveTexture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _emissiveTexture
		service.func_ref = funcref(self, "new_emissiveTexture")
		data[_emissiveTexture.tag] = service
		
		_bumpTexture = PBField.new("bumpTexture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _bumpTexture
		service.func_ref = funcref(self, "new_bumpTexture")
		data[_bumpTexture.tag] = service
		
		_refractionTexture = PBField.new("refractionTexture", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _refractionTexture
		service.func_ref = funcref(self, "new_refractionTexture")
		data[_refractionTexture.tag] = service
		
		_disableLighting = PBField.new("disableLighting", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _disableLighting
		data[_disableLighting.tag] = service
		
		_transparencyMode = PBField.new("transparencyMode", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _transparencyMode
		data[_transparencyMode.tag] = service
		
		_hasAlpha = PBField.new("hasAlpha", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _hasAlpha
		data[_hasAlpha.tag] = service
		
	var data = {}
	
	var _alpha: PBField
	func get_alpha() -> float:
		return _alpha.value
	func clear_alpha() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_alpha.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_alpha(value : float) -> void:
		_alpha.value = value
	
	var _albedoColor: PBField
	func get_albedoColor() -> PB_Color3:
		return _albedoColor.value
	func clear_albedoColor() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_albedoColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_albedoColor() -> PB_Color3:
		_albedoColor.value = PB_Color3.new()
		return _albedoColor.value
	
	var _emissiveColor: PBField
	func get_emissiveColor() -> PB_Color3:
		return _emissiveColor.value
	func clear_emissiveColor() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_emissiveColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_emissiveColor() -> PB_Color3:
		_emissiveColor.value = PB_Color3.new()
		return _emissiveColor.value
	
	var _metallic: PBField
	func get_metallic() -> float:
		return _metallic.value
	func clear_metallic() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_metallic.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_metallic(value : float) -> void:
		_metallic.value = value
	
	var _roughness: PBField
	func get_roughness() -> float:
		return _roughness.value
	func clear_roughness() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_roughness.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_roughness(value : float) -> void:
		_roughness.value = value
	
	var _ambientColor: PBField
	func get_ambientColor() -> PB_Color3:
		return _ambientColor.value
	func clear_ambientColor() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_ambientColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ambientColor() -> PB_Color3:
		_ambientColor.value = PB_Color3.new()
		return _ambientColor.value
	
	var _reflectionColor: PBField
	func get_reflectionColor() -> PB_Color3:
		return _reflectionColor.value
	func clear_reflectionColor() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reflectionColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_reflectionColor() -> PB_Color3:
		_reflectionColor.value = PB_Color3.new()
		return _reflectionColor.value
	
	var _reflectivityColor: PBField
	func get_reflectivityColor() -> PB_Color3:
		return _reflectivityColor.value
	func clear_reflectivityColor() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_reflectivityColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_reflectivityColor() -> PB_Color3:
		_reflectivityColor.value = PB_Color3.new()
		return _reflectivityColor.value
	
	var _directIntensity: PBField
	func get_directIntensity() -> float:
		return _directIntensity.value
	func clear_directIntensity() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_directIntensity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_directIntensity(value : float) -> void:
		_directIntensity.value = value
	
	var _microSurface: PBField
	func get_microSurface() -> float:
		return _microSurface.value
	func clear_microSurface() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_microSurface.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_microSurface(value : float) -> void:
		_microSurface.value = value
	
	var _emissiveIntensity: PBField
	func get_emissiveIntensity() -> float:
		return _emissiveIntensity.value
	func clear_emissiveIntensity() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_emissiveIntensity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_emissiveIntensity(value : float) -> void:
		_emissiveIntensity.value = value
	
	var _environmentIntensity: PBField
	func get_environmentIntensity() -> float:
		return _environmentIntensity.value
	func clear_environmentIntensity() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_environmentIntensity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_environmentIntensity(value : float) -> void:
		_environmentIntensity.value = value
	
	var _specularIntensity: PBField
	func get_specularIntensity() -> float:
		return _specularIntensity.value
	func clear_specularIntensity() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_specularIntensity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_specularIntensity(value : float) -> void:
		_specularIntensity.value = value
	
	var _albedoTexture: PBField
	func get_albedoTexture() -> PB_Texture:
		return _albedoTexture.value
	func clear_albedoTexture() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_albedoTexture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_albedoTexture() -> PB_Texture:
		_albedoTexture.value = PB_Texture.new()
		return _albedoTexture.value
	
	var _alphaTexture: PBField
	func get_alphaTexture() -> PB_Texture:
		return _alphaTexture.value
	func clear_alphaTexture() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_alphaTexture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_alphaTexture() -> PB_Texture:
		_alphaTexture.value = PB_Texture.new()
		return _alphaTexture.value
	
	var _emissiveTexture: PBField
	func get_emissiveTexture() -> PB_Texture:
		return _emissiveTexture.value
	func clear_emissiveTexture() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_emissiveTexture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_emissiveTexture() -> PB_Texture:
		_emissiveTexture.value = PB_Texture.new()
		return _emissiveTexture.value
	
	var _bumpTexture: PBField
	func get_bumpTexture() -> PB_Texture:
		return _bumpTexture.value
	func clear_bumpTexture() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_bumpTexture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_bumpTexture() -> PB_Texture:
		_bumpTexture.value = PB_Texture.new()
		return _bumpTexture.value
	
	var _refractionTexture: PBField
	func get_refractionTexture() -> PB_Texture:
		return _refractionTexture.value
	func clear_refractionTexture() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_refractionTexture.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_refractionTexture() -> PB_Texture:
		_refractionTexture.value = PB_Texture.new()
		return _refractionTexture.value
	
	var _disableLighting: PBField
	func get_disableLighting() -> bool:
		return _disableLighting.value
	func clear_disableLighting() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_disableLighting.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_disableLighting(value : bool) -> void:
		_disableLighting.value = value
	
	var _transparencyMode: PBField
	func get_transparencyMode() -> float:
		return _transparencyMode.value
	func clear_transparencyMode() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_transparencyMode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_transparencyMode(value : float) -> void:
		_transparencyMode.value = value
	
	var _hasAlpha: PBField
	func get_hasAlpha() -> bool:
		return _hasAlpha.value
	func clear_hasAlpha() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_hasAlpha.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_hasAlpha(value : bool) -> void:
		_hasAlpha.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_NFTShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_src = PBField.new("src", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _src
		data[_src.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _src: PBField
	func get_src() -> String:
		return _src.value
	func clear_src() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_src.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_src(value : String) -> void:
		_src.value = value
	
	var _color: PBField
	func get_color() -> PB_Color3:
		return _color.value
	func clear_color() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color3:
		_color.value = PB_Color3.new()
		return _color.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_OBJShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_src = PBField.new("src", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _src
		data[_src.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _src: PBField
	func get_src() -> String:
		return _src.value
	func clear_src() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_src.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_src(value : String) -> void:
		_src.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_PlaneShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_uvs = PBField.new("uvs", PB_DATA_TYPE.FLOAT, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _uvs
		data[_uvs.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _width: PBField
	func get_width() -> float:
		return _width.value
	func clear_width() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_width(value : float) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> float:
		return _height.value
	func clear_height() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_height(value : float) -> void:
		_height.value = value
	
	var _uvs: PBField
	func get_uvs() -> Array:
		return _uvs.value
	func clear_uvs() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_uvs.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func add_uvs(value : float) -> void:
		_uvs.value.append(value)
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Shape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_SphereShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_TextShape:
	func _init():
		var service
		
		_withCollisions = PBField.new("withCollisions", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _withCollisions
		data[_withCollisions.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_outlineWidth = PBField.new("outlineWidth", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _outlineWidth
		data[_outlineWidth.tag] = service
		
		_outlineColor = PBField.new("outlineColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _outlineColor
		service.func_ref = funcref(self, "new_outlineColor")
		data[_outlineColor.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_fontSize = PBField.new("fontSize", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _fontSize
		data[_fontSize.tag] = service
		
		_fontWeight = PBField.new("fontWeight", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _fontWeight
		data[_fontWeight.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _value
		data[_value.tag] = service
		
		_lineSpacing = PBField.new("lineSpacing", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _lineSpacing
		data[_lineSpacing.tag] = service
		
		_lineCount = PBField.new("lineCount", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _lineCount
		data[_lineCount.tag] = service
		
		_resizeToFit = PBField.new("resizeToFit", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _resizeToFit
		data[_resizeToFit.tag] = service
		
		_textWrapping = PBField.new("textWrapping", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _textWrapping
		data[_textWrapping.tag] = service
		
		_shadowBlur = PBField.new("shadowBlur", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowBlur
		data[_shadowBlur.tag] = service
		
		_shadowOffsetX = PBField.new("shadowOffsetX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetX
		data[_shadowOffsetX.tag] = service
		
		_shadowOffsetY = PBField.new("shadowOffsetY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetY
		data[_shadowOffsetY.tag] = service
		
		_shadowColor = PBField.new("shadowColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _shadowColor
		service.func_ref = funcref(self, "new_shadowColor")
		data[_shadowColor.tag] = service
		
		_zIndex = PBField.new("zIndex", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _zIndex
		data[_zIndex.tag] = service
		
		_hTextAlign = PBField.new("hTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hTextAlign
		data[_hTextAlign.tag] = service
		
		_vTextAlign = PBField.new("vTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vTextAlign
		data[_vTextAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
		_isPickable = PBField.new("isPickable", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 27, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPickable
		data[_isPickable.tag] = service
		
		_billboard = PBField.new("billboard", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 28, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _billboard
		data[_billboard.tag] = service
		
	var data = {}
	
	var _withCollisions: PBField
	func get_withCollisions() -> bool:
		return _withCollisions.value
	func clear_withCollisions() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_withCollisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_withCollisions(value : bool) -> void:
		_withCollisions.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _outlineWidth: PBField
	func get_outlineWidth() -> float:
		return _outlineWidth.value
	func clear_outlineWidth() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_outlineWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_outlineWidth(value : float) -> void:
		_outlineWidth.value = value
	
	var _outlineColor: PBField
	func get_outlineColor() -> PB_Color3:
		return _outlineColor.value
	func clear_outlineColor() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_outlineColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_outlineColor() -> PB_Color3:
		_outlineColor.value = PB_Color3.new()
		return _outlineColor.value
	
	var _color: PBField
	func get_color() -> PB_Color3:
		return _color.value
	func clear_color() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color3:
		_color.value = PB_Color3.new()
		return _color.value
	
	var _fontSize: PBField
	func get_fontSize() -> float:
		return _fontSize.value
	func clear_fontSize() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_fontSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_fontSize(value : float) -> void:
		_fontSize.value = value
	
	var _fontWeight: PBField
	func get_fontWeight() -> String:
		return _fontWeight.value
	func clear_fontWeight() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_fontWeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_fontWeight(value : String) -> void:
		_fontWeight.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _value: PBField
	func get_value() -> String:
		return _value.value
	func clear_value() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_value(value : String) -> void:
		_value.value = value
	
	var _lineSpacing: PBField
	func get_lineSpacing() -> String:
		return _lineSpacing.value
	func clear_lineSpacing() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_lineSpacing.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_lineSpacing(value : String) -> void:
		_lineSpacing.value = value
	
	var _lineCount: PBField
	func get_lineCount() -> float:
		return _lineCount.value
	func clear_lineCount() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_lineCount.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_lineCount(value : float) -> void:
		_lineCount.value = value
	
	var _resizeToFit: PBField
	func get_resizeToFit() -> bool:
		return _resizeToFit.value
	func clear_resizeToFit() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_resizeToFit.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_resizeToFit(value : bool) -> void:
		_resizeToFit.value = value
	
	var _textWrapping: PBField
	func get_textWrapping() -> bool:
		return _textWrapping.value
	func clear_textWrapping() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_textWrapping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_textWrapping(value : bool) -> void:
		_textWrapping.value = value
	
	var _shadowBlur: PBField
	func get_shadowBlur() -> float:
		return _shadowBlur.value
	func clear_shadowBlur() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_shadowBlur.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowBlur(value : float) -> void:
		_shadowBlur.value = value
	
	var _shadowOffsetX: PBField
	func get_shadowOffsetX() -> float:
		return _shadowOffsetX.value
	func clear_shadowOffsetX() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetX(value : float) -> void:
		_shadowOffsetX.value = value
	
	var _shadowOffsetY: PBField
	func get_shadowOffsetY() -> float:
		return _shadowOffsetY.value
	func clear_shadowOffsetY() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetY(value : float) -> void:
		_shadowOffsetY.value = value
	
	var _shadowColor: PBField
	func get_shadowColor() -> PB_Color3:
		return _shadowColor.value
	func clear_shadowColor() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_shadowColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_shadowColor() -> PB_Color3:
		_shadowColor.value = PB_Color3.new()
		return _shadowColor.value
	
	var _zIndex: PBField
	func get_zIndex() -> float:
		return _zIndex.value
	func clear_zIndex() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_zIndex.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_zIndex(value : float) -> void:
		_zIndex.value = value
	
	var _hTextAlign: PBField
	func get_hTextAlign() -> String:
		return _hTextAlign.value
	func clear_hTextAlign() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_hTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hTextAlign(value : String) -> void:
		_hTextAlign.value = value
	
	var _vTextAlign: PBField
	func get_vTextAlign() -> String:
		return _vTextAlign.value
	func clear_vTextAlign() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_vTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vTextAlign(value : String) -> void:
		_vTextAlign.value = value
	
	var _width: PBField
	func get_width() -> float:
		return _width.value
	func clear_width() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_width(value : float) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> float:
		return _height.value
	func clear_height() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_height(value : float) -> void:
		_height.value = value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	var _isPickable: PBField
	func get_isPickable() -> bool:
		return _isPickable.value
	func clear_isPickable() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_isPickable.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPickable(value : bool) -> void:
		_isPickable.value = value
	
	var _billboard: PBField
	func get_billboard() -> bool:
		return _billboard.value
	func clear_billboard() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_billboard.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_billboard(value : bool) -> void:
		_billboard.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_Texture:
	func _init():
		var service
		
		_src = PBField.new("src", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _src
		data[_src.tag] = service
		
		_samplingMode = PBField.new("samplingMode", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _samplingMode
		data[_samplingMode.tag] = service
		
		_wrap = PBField.new("wrap", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _wrap
		data[_wrap.tag] = service
		
		_hasAlpha = PBField.new("hasAlpha", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _hasAlpha
		data[_hasAlpha.tag] = service
		
	var data = {}
	
	var _src: PBField
	func get_src() -> String:
		return _src.value
	func clear_src() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_src.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_src(value : String) -> void:
		_src.value = value
	
	var _samplingMode: PBField
	func get_samplingMode() -> float:
		return _samplingMode.value
	func clear_samplingMode() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_samplingMode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_samplingMode(value : float) -> void:
		_samplingMode.value = value
	
	var _wrap: PBField
	func get_wrap() -> float:
		return _wrap.value
	func clear_wrap() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_wrap.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_wrap(value : float) -> void:
		_wrap.value = value
	
	var _hasAlpha: PBField
	func get_hasAlpha() -> bool:
		return _hasAlpha.value
	func clear_hasAlpha() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hasAlpha.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_hasAlpha(value : bool) -> void:
		_hasAlpha.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UIButton:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_fontSize = PBField.new("fontSize", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _fontSize
		data[_fontSize.tag] = service
		
		_fontWeight = PBField.new("fontWeight", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _fontWeight
		data[_fontWeight.tag] = service
		
		_thickness = PBField.new("thickness", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _thickness
		data[_thickness.tag] = service
		
		_cornerRadius = PBField.new("cornerRadius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _cornerRadius
		data[_cornerRadius.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_background = PBField.new("background", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _background
		service.func_ref = funcref(self, "new_background")
		data[_background.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
		_shadowBlur = PBField.new("shadowBlur", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowBlur
		data[_shadowBlur.tag] = service
		
		_shadowOffsetX = PBField.new("shadowOffsetX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetX
		data[_shadowOffsetX.tag] = service
		
		_shadowOffsetY = PBField.new("shadowOffsetY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetY
		data[_shadowOffsetY.tag] = service
		
		_shadowColor = PBField.new("shadowColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _shadowColor
		service.func_ref = funcref(self, "new_shadowColor")
		data[_shadowColor.tag] = service
		
		_text = PBField.new("text", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _text
		data[_text.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _fontSize: PBField
	func get_fontSize() -> float:
		return _fontSize.value
	func clear_fontSize() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_fontSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_fontSize(value : float) -> void:
		_fontSize.value = value
	
	var _fontWeight: PBField
	func get_fontWeight() -> String:
		return _fontWeight.value
	func clear_fontWeight() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_fontWeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_fontWeight(value : String) -> void:
		_fontWeight.value = value
	
	var _thickness: PBField
	func get_thickness() -> float:
		return _thickness.value
	func clear_thickness() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_thickness.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_thickness(value : float) -> void:
		_thickness.value = value
	
	var _cornerRadius: PBField
	func get_cornerRadius() -> float:
		return _cornerRadius.value
	func clear_cornerRadius() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_cornerRadius.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_cornerRadius(value : float) -> void:
		_cornerRadius.value = value
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	var _background: PBField
	func get_background() -> PB_Color4:
		return _background.value
	func clear_background() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_background.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_background() -> PB_Color4:
		_background.value = PB_Color4.new()
		return _background.value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	var _shadowBlur: PBField
	func get_shadowBlur() -> float:
		return _shadowBlur.value
	func clear_shadowBlur() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_shadowBlur.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowBlur(value : float) -> void:
		_shadowBlur.value = value
	
	var _shadowOffsetX: PBField
	func get_shadowOffsetX() -> float:
		return _shadowOffsetX.value
	func clear_shadowOffsetX() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetX(value : float) -> void:
		_shadowOffsetX.value = value
	
	var _shadowOffsetY: PBField
	func get_shadowOffsetY() -> float:
		return _shadowOffsetY.value
	func clear_shadowOffsetY() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetY(value : float) -> void:
		_shadowOffsetY.value = value
	
	var _shadowColor: PBField
	func get_shadowColor() -> PB_Color4:
		return _shadowColor.value
	func clear_shadowColor() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_shadowColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_shadowColor() -> PB_Color4:
		_shadowColor.value = PB_Color4.new()
		return _shadowColor.value
	
	var _text: PBField
	func get_text() -> String:
		return _text.value
	func clear_text() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_text(value : String) -> void:
		_text.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UICanvas:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UIContainerRect:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_adaptWidth = PBField.new("adaptWidth", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptWidth
		data[_adaptWidth.tag] = service
		
		_adaptHeight = PBField.new("adaptHeight", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptHeight
		data[_adaptHeight.tag] = service
		
		_thickness = PBField.new("thickness", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _thickness
		data[_thickness.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_alignmentUsesSize = PBField.new("alignmentUsesSize", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _alignmentUsesSize
		data[_alignmentUsesSize.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _adaptWidth: PBField
	func get_adaptWidth() -> bool:
		return _adaptWidth.value
	func clear_adaptWidth() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_adaptWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptWidth(value : bool) -> void:
		_adaptWidth.value = value
	
	var _adaptHeight: PBField
	func get_adaptHeight() -> bool:
		return _adaptHeight.value
	func clear_adaptHeight() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_adaptHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptHeight(value : bool) -> void:
		_adaptHeight.value = value
	
	var _thickness: PBField
	func get_thickness() -> float:
		return _thickness.value
	func clear_thickness() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_thickness.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_thickness(value : float) -> void:
		_thickness.value = value
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	var _alignmentUsesSize: PBField
	func get_alignmentUsesSize() -> bool:
		return _alignmentUsesSize.value
	func clear_alignmentUsesSize() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_alignmentUsesSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_alignmentUsesSize(value : bool) -> void:
		_alignmentUsesSize.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UIContainerStack:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_adaptWidth = PBField.new("adaptWidth", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptWidth
		data[_adaptWidth.tag] = service
		
		_adaptHeight = PBField.new("adaptHeight", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptHeight
		data[_adaptHeight.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_stackOrientation = PBField.new("stackOrientation", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _stackOrientation
		data[_stackOrientation.tag] = service
		
		_spacing = PBField.new("spacing", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _spacing
		data[_spacing.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _adaptWidth: PBField
	func get_adaptWidth() -> bool:
		return _adaptWidth.value
	func clear_adaptWidth() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_adaptWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptWidth(value : bool) -> void:
		_adaptWidth.value = value
	
	var _adaptHeight: PBField
	func get_adaptHeight() -> bool:
		return _adaptHeight.value
	func clear_adaptHeight() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_adaptHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptHeight(value : bool) -> void:
		_adaptHeight.value = value
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	var _stackOrientation: PBField
	func get_stackOrientation():
		return _stackOrientation.value
	func clear_stackOrientation() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_stackOrientation.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_stackOrientation(value) -> void:
		_stackOrientation.value = value
	
	var _spacing: PBField
	func get_spacing() -> float:
		return _spacing.value
	func clear_spacing() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_spacing.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_spacing(value : float) -> void:
		_spacing.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum PB_UIStackOrientation {
	VERTICAL = 0,
	HORIZONTAL = 1
}

class PB_UIImage:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_sourceLeft = PBField.new("sourceLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _sourceLeft
		data[_sourceLeft.tag] = service
		
		_sourceTop = PBField.new("sourceTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _sourceTop
		data[_sourceTop.tag] = service
		
		_sourceWidth = PBField.new("sourceWidth", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _sourceWidth
		data[_sourceWidth.tag] = service
		
		_sourceHeight = PBField.new("sourceHeight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _sourceHeight
		data[_sourceHeight.tag] = service
		
		_source = PBField.new("source", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _source
		service.func_ref = funcref(self, "new_source")
		data[_source.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
		_sizeInPixels = PBField.new("sizeInPixels", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _sizeInPixels
		data[_sizeInPixels.tag] = service
		
		_onClick = PBField.new("onClick", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _onClick
		service.func_ref = funcref(self, "new_onClick")
		data[_onClick.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _sourceLeft: PBField
	func get_sourceLeft() -> float:
		return _sourceLeft.value
	func clear_sourceLeft() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_sourceLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_sourceLeft(value : float) -> void:
		_sourceLeft.value = value
	
	var _sourceTop: PBField
	func get_sourceTop() -> float:
		return _sourceTop.value
	func clear_sourceTop() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_sourceTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_sourceTop(value : float) -> void:
		_sourceTop.value = value
	
	var _sourceWidth: PBField
	func get_sourceWidth() -> float:
		return _sourceWidth.value
	func clear_sourceWidth() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_sourceWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_sourceWidth(value : float) -> void:
		_sourceWidth.value = value
	
	var _sourceHeight: PBField
	func get_sourceHeight() -> float:
		return _sourceHeight.value
	func clear_sourceHeight() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_sourceHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_sourceHeight(value : float) -> void:
		_sourceHeight.value = value
	
	var _source: PBField
	func get_source() -> PB_Texture:
		return _source.value
	func clear_source() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_source.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_source() -> PB_Texture:
		_source.value = PB_Texture.new()
		return _source.value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	var _sizeInPixels: PBField
	func get_sizeInPixels() -> bool:
		return _sizeInPixels.value
	func clear_sizeInPixels() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_sizeInPixels.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_sizeInPixels(value : bool) -> void:
		_sizeInPixels.value = value
	
	var _onClick: PBField
	func get_onClick() -> PB_UUIDCallback:
		return _onClick.value
	func clear_onClick() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_onClick.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_onClick() -> PB_UUIDCallback:
		_onClick.value = PB_UUIDCallback.new()
		return _onClick.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UUIDCallback:
	func _init():
		var service
		
		_type = PBField.new("type", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _type
		data[_type.tag] = service
		
		_uuid = PBField.new("uuid", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _uuid
		data[_uuid.tag] = service
		
	var data = {}
	
	var _type: PBField
	func get_type() -> String:
		return _type.value
	func clear_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_type(value : String) -> void:
		_type.value = value
	
	var _uuid: PBField
	func get_uuid() -> String:
		return _uuid.value
	func clear_uuid() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_uuid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_uuid(value : String) -> void:
		_uuid.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UIInputText:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_outlineWidth = PBField.new("outlineWidth", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _outlineWidth
		data[_outlineWidth.tag] = service
		
		_outlineColor = PBField.new("outlineColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _outlineColor
		service.func_ref = funcref(self, "new_outlineColor")
		data[_outlineColor.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_thickness = PBField.new("thickness", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _thickness
		data[_thickness.tag] = service
		
		_fontSize = PBField.new("fontSize", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _fontSize
		data[_fontSize.tag] = service
		
		_fontWeight = PBField.new("fontWeight", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _fontWeight
		data[_fontWeight.tag] = service
		
		_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _value
		data[_value.tag] = service
		
		_placeholderColor = PBField.new("placeholderColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _placeholderColor
		service.func_ref = funcref(self, "new_placeholderColor")
		data[_placeholderColor.tag] = service
		
		_placeholder = PBField.new("placeholder", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _placeholder
		data[_placeholder.tag] = service
		
		_margin = PBField.new("margin", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _margin
		data[_margin.tag] = service
		
		_maxWidth = PBField.new("maxWidth", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _maxWidth
		data[_maxWidth.tag] = service
		
		_hTextAlign = PBField.new("hTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hTextAlign
		data[_hTextAlign.tag] = service
		
		_vTextAlign = PBField.new("vTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vTextAlign
		data[_vTextAlign.tag] = service
		
		_autoStretchWidth = PBField.new("autoStretchWidth", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _autoStretchWidth
		data[_autoStretchWidth.tag] = service
		
		_background = PBField.new("background", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _background
		service.func_ref = funcref(self, "new_background")
		data[_background.tag] = service
		
		_focusedBackground = PBField.new("focusedBackground", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 27, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _focusedBackground
		service.func_ref = funcref(self, "new_focusedBackground")
		data[_focusedBackground.tag] = service
		
		_textWrapping = PBField.new("textWrapping", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 28, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _textWrapping
		data[_textWrapping.tag] = service
		
		_shadowBlur = PBField.new("shadowBlur", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 29, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowBlur
		data[_shadowBlur.tag] = service
		
		_shadowOffsetX = PBField.new("shadowOffsetX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 30, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetX
		data[_shadowOffsetX.tag] = service
		
		_shadowOffsetY = PBField.new("shadowOffsetY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 31, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetY
		data[_shadowOffsetY.tag] = service
		
		_shadowColor = PBField.new("shadowColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 32, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _shadowColor
		service.func_ref = funcref(self, "new_shadowColor")
		data[_shadowColor.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 33, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 34, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 35, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 36, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
		_onTextSubmit = PBField.new("onTextSubmit", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 37, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _onTextSubmit
		service.func_ref = funcref(self, "new_onTextSubmit")
		data[_onTextSubmit.tag] = service
		
		_onChanged = PBField.new("onChanged", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 38, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _onChanged
		service.func_ref = funcref(self, "new_onChanged")
		data[_onChanged.tag] = service
		
		_onFocus = PBField.new("onFocus", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 39, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _onFocus
		service.func_ref = funcref(self, "new_onFocus")
		data[_onFocus.tag] = service
		
		_onBlur = PBField.new("onBlur", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 40, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _onBlur
		service.func_ref = funcref(self, "new_onBlur")
		data[_onBlur.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _outlineWidth: PBField
	func get_outlineWidth() -> float:
		return _outlineWidth.value
	func clear_outlineWidth() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_outlineWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_outlineWidth(value : float) -> void:
		_outlineWidth.value = value
	
	var _outlineColor: PBField
	func get_outlineColor() -> PB_Color4:
		return _outlineColor.value
	func clear_outlineColor() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_outlineColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_outlineColor() -> PB_Color4:
		_outlineColor.value = PB_Color4.new()
		return _outlineColor.value
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	var _thickness: PBField
	func get_thickness() -> float:
		return _thickness.value
	func clear_thickness() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_thickness.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_thickness(value : float) -> void:
		_thickness.value = value
	
	var _fontSize: PBField
	func get_fontSize() -> float:
		return _fontSize.value
	func clear_fontSize() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_fontSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_fontSize(value : float) -> void:
		_fontSize.value = value
	
	var _fontWeight: PBField
	func get_fontWeight() -> String:
		return _fontWeight.value
	func clear_fontWeight() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_fontWeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_fontWeight(value : String) -> void:
		_fontWeight.value = value
	
	var _value: PBField
	func get_value() -> String:
		return _value.value
	func clear_value() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_value(value : String) -> void:
		_value.value = value
	
	var _placeholderColor: PBField
	func get_placeholderColor() -> PB_Color4:
		return _placeholderColor.value
	func clear_placeholderColor() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_placeholderColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_placeholderColor() -> PB_Color4:
		_placeholderColor.value = PB_Color4.new()
		return _placeholderColor.value
	
	var _placeholder: PBField
	func get_placeholder() -> String:
		return _placeholder.value
	func clear_placeholder() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_placeholder.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_placeholder(value : String) -> void:
		_placeholder.value = value
	
	var _margin: PBField
	func get_margin() -> float:
		return _margin.value
	func clear_margin() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_margin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_margin(value : float) -> void:
		_margin.value = value
	
	var _maxWidth: PBField
	func get_maxWidth() -> float:
		return _maxWidth.value
	func clear_maxWidth() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_maxWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_maxWidth(value : float) -> void:
		_maxWidth.value = value
	
	var _hTextAlign: PBField
	func get_hTextAlign() -> String:
		return _hTextAlign.value
	func clear_hTextAlign() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_hTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hTextAlign(value : String) -> void:
		_hTextAlign.value = value
	
	var _vTextAlign: PBField
	func get_vTextAlign() -> String:
		return _vTextAlign.value
	func clear_vTextAlign() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		_vTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vTextAlign(value : String) -> void:
		_vTextAlign.value = value
	
	var _autoStretchWidth: PBField
	func get_autoStretchWidth() -> bool:
		return _autoStretchWidth.value
	func clear_autoStretchWidth() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_autoStretchWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_autoStretchWidth(value : bool) -> void:
		_autoStretchWidth.value = value
	
	var _background: PBField
	func get_background() -> PB_Color4:
		return _background.value
	func clear_background() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_background.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_background() -> PB_Color4:
		_background.value = PB_Color4.new()
		return _background.value
	
	var _focusedBackground: PBField
	func get_focusedBackground() -> PB_Color4:
		return _focusedBackground.value
	func clear_focusedBackground() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_focusedBackground.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_focusedBackground() -> PB_Color4:
		_focusedBackground.value = PB_Color4.new()
		return _focusedBackground.value
	
	var _textWrapping: PBField
	func get_textWrapping() -> bool:
		return _textWrapping.value
	func clear_textWrapping() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_textWrapping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_textWrapping(value : bool) -> void:
		_textWrapping.value = value
	
	var _shadowBlur: PBField
	func get_shadowBlur() -> float:
		return _shadowBlur.value
	func clear_shadowBlur() -> void:
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_shadowBlur.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowBlur(value : float) -> void:
		_shadowBlur.value = value
	
	var _shadowOffsetX: PBField
	func get_shadowOffsetX() -> float:
		return _shadowOffsetX.value
	func clear_shadowOffsetX() -> void:
		data[30].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetX(value : float) -> void:
		_shadowOffsetX.value = value
	
	var _shadowOffsetY: PBField
	func get_shadowOffsetY() -> float:
		return _shadowOffsetY.value
	func clear_shadowOffsetY() -> void:
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetY(value : float) -> void:
		_shadowOffsetY.value = value
	
	var _shadowColor: PBField
	func get_shadowColor() -> PB_Color4:
		return _shadowColor.value
	func clear_shadowColor() -> void:
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_shadowColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_shadowColor() -> PB_Color4:
		_shadowColor.value = PB_Color4.new()
		return _shadowColor.value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[33].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[34].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[35].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[36].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	var _onTextSubmit: PBField
	func get_onTextSubmit() -> PB_UUIDCallback:
		return _onTextSubmit.value
	func clear_onTextSubmit() -> void:
		data[37].state = PB_SERVICE_STATE.UNFILLED
		_onTextSubmit.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_onTextSubmit() -> PB_UUIDCallback:
		_onTextSubmit.value = PB_UUIDCallback.new()
		return _onTextSubmit.value
	
	var _onChanged: PBField
	func get_onChanged() -> PB_UUIDCallback:
		return _onChanged.value
	func clear_onChanged() -> void:
		data[38].state = PB_SERVICE_STATE.UNFILLED
		_onChanged.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_onChanged() -> PB_UUIDCallback:
		_onChanged.value = PB_UUIDCallback.new()
		return _onChanged.value
	
	var _onFocus: PBField
	func get_onFocus() -> PB_UUIDCallback:
		return _onFocus.value
	func clear_onFocus() -> void:
		data[39].state = PB_SERVICE_STATE.UNFILLED
		_onFocus.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_onFocus() -> PB_UUIDCallback:
		_onFocus.value = PB_UUIDCallback.new()
		return _onFocus.value
	
	var _onBlur: PBField
	func get_onBlur() -> PB_UUIDCallback:
		return _onBlur.value
	func clear_onBlur() -> void:
		data[40].state = PB_SERVICE_STATE.UNFILLED
		_onBlur.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_onBlur() -> PB_UUIDCallback:
		_onBlur.value = PB_UUIDCallback.new()
		return _onBlur.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UIScrollRect:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_valueX = PBField.new("valueX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _valueX
		data[_valueX.tag] = service
		
		_valueY = PBField.new("valueY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _valueY
		data[_valueY.tag] = service
		
		_borderColor = PBField.new("borderColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _borderColor
		service.func_ref = funcref(self, "new_borderColor")
		data[_borderColor.tag] = service
		
		_backgroundColor = PBField.new("backgroundColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _backgroundColor
		service.func_ref = funcref(self, "new_backgroundColor")
		data[_backgroundColor.tag] = service
		
		_isHorizontal = PBField.new("isHorizontal", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isHorizontal
		data[_isHorizontal.tag] = service
		
		_isVertical = PBField.new("isVertical", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isVertical
		data[_isVertical.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
		_onChanged = PBField.new("onChanged", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _onChanged
		service.func_ref = funcref(self, "new_onChanged")
		data[_onChanged.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _valueX: PBField
	func get_valueX() -> float:
		return _valueX.value
	func clear_valueX() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_valueX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_valueX(value : float) -> void:
		_valueX.value = value
	
	var _valueY: PBField
	func get_valueY() -> float:
		return _valueY.value
	func clear_valueY() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_valueY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_valueY(value : float) -> void:
		_valueY.value = value
	
	var _borderColor: PBField
	func get_borderColor() -> PB_Color4:
		return _borderColor.value
	func clear_borderColor() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_borderColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_borderColor() -> PB_Color4:
		_borderColor.value = PB_Color4.new()
		return _borderColor.value
	
	var _backgroundColor: PBField
	func get_backgroundColor() -> PB_Color4:
		return _backgroundColor.value
	func clear_backgroundColor() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_backgroundColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_backgroundColor() -> PB_Color4:
		_backgroundColor.value = PB_Color4.new()
		return _backgroundColor.value
	
	var _isHorizontal: PBField
	func get_isHorizontal() -> bool:
		return _isHorizontal.value
	func clear_isHorizontal() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_isHorizontal.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isHorizontal(value : bool) -> void:
		_isHorizontal.value = value
	
	var _isVertical: PBField
	func get_isVertical() -> bool:
		return _isVertical.value
	func clear_isVertical() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_isVertical.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isVertical(value : bool) -> void:
		_isVertical.value = value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	var _onChanged: PBField
	func get_onChanged() -> PB_UUIDCallback:
		return _onChanged.value
	func clear_onChanged() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_onChanged.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_onChanged() -> PB_UUIDCallback:
		_onChanged.value = PB_UUIDCallback.new()
		return _onChanged.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UIShape:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_UITextShape:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_visible = PBField.new("visible", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _visible
		data[_visible.tag] = service
		
		_opacity = PBField.new("opacity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _opacity
		data[_opacity.tag] = service
		
		_hAlign = PBField.new("hAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hAlign
		data[_hAlign.tag] = service
		
		_vAlign = PBField.new("vAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vAlign
		data[_vAlign.tag] = service
		
		_width = PBField.new("width", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _width
		data[_width.tag] = service
		
		_height = PBField.new("height", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _height
		data[_height.tag] = service
		
		_positionX = PBField.new("positionX", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionX
		data[_positionX.tag] = service
		
		_positionY = PBField.new("positionY", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _positionY
		data[_positionY.tag] = service
		
		_isPointerBlocker = PBField.new("isPointerBlocker", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _isPointerBlocker
		data[_isPointerBlocker.tag] = service
		
		_parent = PBField.new("parent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _parent
		service.func_ref = funcref(self, "new_parent")
		data[_parent.tag] = service
		
		_outlineWidth = PBField.new("outlineWidth", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _outlineWidth
		data[_outlineWidth.tag] = service
		
		_outlineColor = PBField.new("outlineColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _outlineColor
		service.func_ref = funcref(self, "new_outlineColor")
		data[_outlineColor.tag] = service
		
		_color = PBField.new("color", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _color
		service.func_ref = funcref(self, "new_color")
		data[_color.tag] = service
		
		_fontSize = PBField.new("fontSize", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _fontSize
		data[_fontSize.tag] = service
		
		_fontAutoSize = PBField.new("fontAutoSize", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _fontAutoSize
		data[_fontAutoSize.tag] = service
		
		_fontWeight = PBField.new("fontWeight", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _fontWeight
		data[_fontWeight.tag] = service
		
		_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _value
		data[_value.tag] = service
		
		_lineSpacing = PBField.new("lineSpacing", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _lineSpacing
		data[_lineSpacing.tag] = service
		
		_lineCount = PBField.new("lineCount", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _lineCount
		data[_lineCount.tag] = service
		
		_adaptWidth = PBField.new("adaptWidth", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptWidth
		data[_adaptWidth.tag] = service
		
		_adaptHeight = PBField.new("adaptHeight", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _adaptHeight
		data[_adaptHeight.tag] = service
		
		_textWrapping = PBField.new("textWrapping", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _textWrapping
		data[_textWrapping.tag] = service
		
		_shadowBlur = PBField.new("shadowBlur", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowBlur
		data[_shadowBlur.tag] = service
		
		_shadowOffsetX = PBField.new("shadowOffsetX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetX
		data[_shadowOffsetX.tag] = service
		
		_shadowOffsetY = PBField.new("shadowOffsetY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _shadowOffsetY
		data[_shadowOffsetY.tag] = service
		
		_shadowColor = PBField.new("shadowColor", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 27, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _shadowColor
		service.func_ref = funcref(self, "new_shadowColor")
		data[_shadowColor.tag] = service
		
		_hTextAlign = PBField.new("hTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 28, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _hTextAlign
		data[_hTextAlign.tag] = service
		
		_vTextAlign = PBField.new("vTextAlign", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 29, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _vTextAlign
		data[_vTextAlign.tag] = service
		
		_paddingTop = PBField.new("paddingTop", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 30, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingTop
		data[_paddingTop.tag] = service
		
		_paddingRight = PBField.new("paddingRight", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 31, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingRight
		data[_paddingRight.tag] = service
		
		_paddingBottom = PBField.new("paddingBottom", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 32, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingBottom
		data[_paddingBottom.tag] = service
		
		_paddingLeft = PBField.new("paddingLeft", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 33, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _paddingLeft
		data[_paddingLeft.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _visible: PBField
	func get_visible() -> bool:
		return _visible.value
	func clear_visible() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_visible.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_visible(value : bool) -> void:
		_visible.value = value
	
	var _opacity: PBField
	func get_opacity() -> float:
		return _opacity.value
	func clear_opacity() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_opacity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_opacity(value : float) -> void:
		_opacity.value = value
	
	var _hAlign: PBField
	func get_hAlign() -> String:
		return _hAlign.value
	func clear_hAlign() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_hAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hAlign(value : String) -> void:
		_hAlign.value = value
	
	var _vAlign: PBField
	func get_vAlign() -> String:
		return _vAlign.value
	func clear_vAlign() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_vAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vAlign(value : String) -> void:
		_vAlign.value = value
	
	var _width: PBField
	func get_width() -> String:
		return _width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_width(value : String) -> void:
		_width.value = value
	
	var _height: PBField
	func get_height() -> String:
		return _height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_height(value : String) -> void:
		_height.value = value
	
	var _positionX: PBField
	func get_positionX() -> String:
		return _positionX.value
	func clear_positionX() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_positionX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionX(value : String) -> void:
		_positionX.value = value
	
	var _positionY: PBField
	func get_positionY() -> String:
		return _positionY.value
	func clear_positionY() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_positionY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_positionY(value : String) -> void:
		_positionY.value = value
	
	var _isPointerBlocker: PBField
	func get_isPointerBlocker() -> bool:
		return _isPointerBlocker.value
	func clear_isPointerBlocker() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_isPointerBlocker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_isPointerBlocker(value : bool) -> void:
		_isPointerBlocker.value = value
	
	var _parent: PBField
	func get_parent() -> PB_UIShape:
		return _parent.value
	func clear_parent() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_parent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_parent() -> PB_UIShape:
		_parent.value = PB_UIShape.new()
		return _parent.value
	
	var _outlineWidth: PBField
	func get_outlineWidth() -> float:
		return _outlineWidth.value
	func clear_outlineWidth() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_outlineWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_outlineWidth(value : float) -> void:
		_outlineWidth.value = value
	
	var _outlineColor: PBField
	func get_outlineColor() -> PB_Color4:
		return _outlineColor.value
	func clear_outlineColor() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_outlineColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_outlineColor() -> PB_Color4:
		_outlineColor.value = PB_Color4.new()
		return _outlineColor.value
	
	var _color: PBField
	func get_color() -> PB_Color4:
		return _color.value
	func clear_color() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_color.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_color() -> PB_Color4:
		_color.value = PB_Color4.new()
		return _color.value
	
	var _fontSize: PBField
	func get_fontSize() -> float:
		return _fontSize.value
	func clear_fontSize() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_fontSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_fontSize(value : float) -> void:
		_fontSize.value = value
	
	var _fontAutoSize: PBField
	func get_fontAutoSize() -> bool:
		return _fontAutoSize.value
	func clear_fontAutoSize() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_fontAutoSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_fontAutoSize(value : bool) -> void:
		_fontAutoSize.value = value
	
	var _fontWeight: PBField
	func get_fontWeight() -> String:
		return _fontWeight.value
	func clear_fontWeight() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_fontWeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_fontWeight(value : String) -> void:
		_fontWeight.value = value
	
	var _value: PBField
	func get_value() -> String:
		return _value.value
	func clear_value() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_value(value : String) -> void:
		_value.value = value
	
	var _lineSpacing: PBField
	func get_lineSpacing() -> float:
		return _lineSpacing.value
	func clear_lineSpacing() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_lineSpacing.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_lineSpacing(value : float) -> void:
		_lineSpacing.value = value
	
	var _lineCount: PBField
	func get_lineCount() -> float:
		return _lineCount.value
	func clear_lineCount() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_lineCount.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_lineCount(value : float) -> void:
		_lineCount.value = value
	
	var _adaptWidth: PBField
	func get_adaptWidth() -> bool:
		return _adaptWidth.value
	func clear_adaptWidth() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_adaptWidth.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptWidth(value : bool) -> void:
		_adaptWidth.value = value
	
	var _adaptHeight: PBField
	func get_adaptHeight() -> bool:
		return _adaptHeight.value
	func clear_adaptHeight() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_adaptHeight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_adaptHeight(value : bool) -> void:
		_adaptHeight.value = value
	
	var _textWrapping: PBField
	func get_textWrapping() -> bool:
		return _textWrapping.value
	func clear_textWrapping() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_textWrapping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_textWrapping(value : bool) -> void:
		_textWrapping.value = value
	
	var _shadowBlur: PBField
	func get_shadowBlur() -> float:
		return _shadowBlur.value
	func clear_shadowBlur() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		_shadowBlur.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowBlur(value : float) -> void:
		_shadowBlur.value = value
	
	var _shadowOffsetX: PBField
	func get_shadowOffsetX() -> float:
		return _shadowOffsetX.value
	func clear_shadowOffsetX() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetX(value : float) -> void:
		_shadowOffsetX.value = value
	
	var _shadowOffsetY: PBField
	func get_shadowOffsetY() -> float:
		return _shadowOffsetY.value
	func clear_shadowOffsetY() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		_shadowOffsetY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_shadowOffsetY(value : float) -> void:
		_shadowOffsetY.value = value
	
	var _shadowColor: PBField
	func get_shadowColor() -> PB_Color4:
		return _shadowColor.value
	func clear_shadowColor() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		_shadowColor.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_shadowColor() -> PB_Color4:
		_shadowColor.value = PB_Color4.new()
		return _shadowColor.value
	
	var _hTextAlign: PBField
	func get_hTextAlign() -> String:
		return _hTextAlign.value
	func clear_hTextAlign() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		_hTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_hTextAlign(value : String) -> void:
		_hTextAlign.value = value
	
	var _vTextAlign: PBField
	func get_vTextAlign() -> String:
		return _vTextAlign.value
	func clear_vTextAlign() -> void:
		data[29].state = PB_SERVICE_STATE.UNFILLED
		_vTextAlign.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_vTextAlign(value : String) -> void:
		_vTextAlign.value = value
	
	var _paddingTop: PBField
	func get_paddingTop() -> float:
		return _paddingTop.value
	func clear_paddingTop() -> void:
		data[30].state = PB_SERVICE_STATE.UNFILLED
		_paddingTop.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingTop(value : float) -> void:
		_paddingTop.value = value
	
	var _paddingRight: PBField
	func get_paddingRight() -> float:
		return _paddingRight.value
	func clear_paddingRight() -> void:
		data[31].state = PB_SERVICE_STATE.UNFILLED
		_paddingRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingRight(value : float) -> void:
		_paddingRight.value = value
	
	var _paddingBottom: PBField
	func get_paddingBottom() -> float:
		return _paddingBottom.value
	func clear_paddingBottom() -> void:
		data[32].state = PB_SERVICE_STATE.UNFILLED
		_paddingBottom.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingBottom(value : float) -> void:
		_paddingBottom.value = value
	
	var _paddingLeft: PBField
	func get_paddingLeft() -> float:
		return _paddingLeft.value
	func clear_paddingLeft() -> void:
		data[33].state = PB_SERVICE_STATE.UNFILLED
		_paddingLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_paddingLeft(value : float) -> void:
		_paddingLeft.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_OpenExternalUrl:
	func _init():
		var service
		
		_url = PBField.new("url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _url
		data[_url.tag] = service
		
	var data = {}
	
	var _url: PBField
	func get_url() -> String:
		return _url.value
	func clear_url() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_url(value : String) -> void:
		_url.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PB_OpenNFTDialog:
	func _init():
		var service
		
		_assetContractAddress = PBField.new("assetContractAddress", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _assetContractAddress
		data[_assetContractAddress.tag] = service
		
		_tokenId = PBField.new("tokenId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _tokenId
		data[_tokenId.tag] = service
		
		_comment = PBField.new("comment", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _comment
		data[_comment.tag] = service
		
	var data = {}
	
	var _assetContractAddress: PBField
	func get_assetContractAddress() -> String:
		return _assetContractAddress.value
	func clear_assetContractAddress() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_assetContractAddress.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_assetContractAddress(value : String) -> void:
		_assetContractAddress.value = value
	
	var _tokenId: PBField
	func get_tokenId() -> String:
		return _tokenId.value
	func clear_tokenId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_tokenId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_tokenId(value : String) -> void:
		_tokenId.value = value
	
	var _comment: PBField
	func get_comment() -> String:
		return _comment.value
	func clear_comment() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_comment.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_comment(value : String) -> void:
		_comment.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
