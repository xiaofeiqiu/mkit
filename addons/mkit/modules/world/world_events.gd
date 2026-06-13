class_name WorldEvents
extends RefCounted
## 世界领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 稳定标识 `ROOM_CLEARED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ROOM_CLEARED := "room_cleared"
## 稳定标识 `ZONE_CHANGED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ZONE_CHANGED := "zone_changed"
## 稳定标识 `RUN_STARTED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const RUN_STARTED := "run_started"
## 稳定标识 `RUN_FINISHED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const RUN_FINISHED := "run_finished"


## 执行 `room_cleared` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func room_cleared(room_id: String) -> DomainEvent:
	return DomainEvent.create(ROOM_CLEARED, room_id, "", {})


## 执行 `zone_changed` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func zone_changed(from_zone_id: String, to_zone_id: String) -> DomainEvent:
	return DomainEvent.create(
		ZONE_CHANGED,
		from_zone_id,
		to_zone_id,
		{"from_zone_id": from_zone_id, "to_zone_id": to_zone_id}
	)


## 执行 `run_started` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func run_started(run_id: String, seed: int) -> DomainEvent:
	return DomainEvent.create(RUN_STARTED, run_id, "", {"seed": seed})


## 执行 `run_finished` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func run_finished(run_id: String, result: String) -> DomainEvent:
	return DomainEvent.create(RUN_FINISHED, run_id, "", {"result": result})
