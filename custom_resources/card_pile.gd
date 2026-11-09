class_name CardPile
extends Resource

## 一个牌堆：抽牌堆 / 弃牌堆都用它。
## 只做"从前面拿、往后面放"，洗牌交给 shuffle()。

signal pile_changed(size: int)

@export var cards: Array[Card] = []


func is_empty() -> bool:
	return cards.is_empty()


func size() -> int:
	return cards.size()


func draw_card() -> Card:
	if cards.is_empty():
		return null
	var card: Card = cards.pop_front()
	pile_changed.emit(cards.size())
	return card


func add_card(card: Card) -> void:
	cards.append(card)
	pile_changed.emit(cards.size())


func shuffle() -> void:
	cards.shuffle()


func clear() -> void:
	cards.clear()
	pile_changed.emit(0)
