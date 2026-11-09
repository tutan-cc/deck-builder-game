extends HBoxContainer

## 手牌区：只负责排队摆牌。发牌是 battle 的事（它管牌堆）。

func clear_hand() -> void:
	for child in get_children():
		child.queue_free()
