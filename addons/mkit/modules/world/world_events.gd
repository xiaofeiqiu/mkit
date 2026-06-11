class_name WorldEvents
extends RefCounted
## 世界领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 公开常量 `ROOM_CLEARED`，作为 `WorldEvents` 对外暴露的类型、事件或命令标识。
const ROOM_CLEARED := "room_cleared"
## 公开常量 `ZONE_CHANGED`，作为 `WorldEvents` 对外暴露的类型、事件或命令标识。
const ZONE_CHANGED := "zone_changed"
## 公开常量 `RUN_STARTED`，作为 `WorldEvents` 对外暴露的类型、事件或命令标识。
const RUN_STARTED := "run_started"
## 公开常量 `RUN_FINISHED`，作为 `WorldEvents` 对外暴露的类型、事件或命令标识。
const RUN_FINISHED := "run_finished"


## 执行 `room_cleared` 对应的公开操作，并保持 `WorldEvents` 的领域契约一致。
static func room_cleared(room_id: String) -> DomainEvent:
	return DomainEvent.create(ROOM_CLEARED, room_id, "", {})


## 执行 `zone_changed` 对应的公开操作，并保持 `WorldEvents` 的领域契约一致。
static func zone_changed(from_zone_id: String, to_zone_id: String) -> DomainEvent:
	return DomainEvent.create(
		ZONE_CHANGED,
		from_zone_id,
		to_zone_id,
		{"from_zone_id": from_zone_id, "to_zone_id": to_zone_id}
	)


## 执行 `run_started` 对应的公开操作，并保持 `WorldEvents` 的领域契约一致。
static func run_started(run_id: String, seed: int) -> DomainEvent:
	return DomainEvent.create(RUN_STARTED, run_id, "", {"seed": seed})


## 执行 `run_finished` 对应的公开操作，并保持 `WorldEvents` 的领域契约一致。
static func run_finished(run_id: String, result: String) -> DomainEvent:
	return DomainEvent.create(RUN_FINISHED, run_id, "", {"result": result})
