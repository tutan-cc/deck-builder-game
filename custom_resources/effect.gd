class_name Effect
extends Resource

## 效果的基类。卡牌里存一串 Effect，打出时逐个 execute。
## source 是"谁打出的"（一般是玩家/敌人的 Stats），状态加成要用到它。


func execute(_targets: Array, _source = null) -> void:
	pass
