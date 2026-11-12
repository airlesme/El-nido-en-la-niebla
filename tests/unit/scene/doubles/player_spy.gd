## Test double of the player: records `colocar` calls (GDD 2 `colocar(position, yaw, pitch)`).
class_name PlayerSpy extends Node

var events: Array[String] = []
var placed: Array[Dictionary] = []


func colocar(position: Vector3, yaw: float, pitch: float) -> void:
	events.append("colocar")
	placed.append({&"position": position, &"yaw": yaw, &"pitch": pitch})
