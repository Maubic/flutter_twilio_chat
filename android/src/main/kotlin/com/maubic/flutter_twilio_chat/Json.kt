package com.maubic.flutter_twilio_chat

import org.json.JSONObject
import org.json.JSONArray

fun fromJson(obj: Any?): Any? {
  if (obj == null || obj == JSONObject.NULL) {
    return null
  } else if (obj is JSONObject) {
    return obj.toMap()
  } else if (obj is JSONArray) {
    return obj.toList()
  } else {
    return obj
  }
}

fun JSONObject.toMap(): Map<String, Any?> {
  val map: MutableMap<String, Any?> = mutableMapOf()
  val keys: Iterator<String> = this.keys()
  while (keys.hasNext()) {
    val key: String = keys.next()
    map.put(key, fromJson(this.get(key)))
  }
  return map
}

fun JSONArray.toList(): List<Any?> {
  val list: MutableList<Any?> = mutableListOf()
  val length = this.length()
  for (i in 0 until length) {
    list.add(fromJson(this.get(i)))
  }
  return list
}
