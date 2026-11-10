extends Node
signal language_changed(language: String)
const Catalog = preload("res://Localization/Messages.gd")
const Progress = preload("res://GameProgress.gd")
var language: String = "jp"
var _index: Dictionary = {}
var _patterns: Array[Dictionary] = []
var _nodes: Array[WeakRef] = []
var _space := RegEx.new()
var _slots := RegEx.new()
var _elapsed: float = 0.0
var _revision: int = 0
var _text_cache: Dictionary = {}
const BRAND_NAMES = ["Kitchen Decoration Game", "Kitchen Layout Game", "Kitchen Layout Design Game"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_space.compile(" +")
	_slots.compile("%[-+0-9.]*[dsf]")
	for row in Catalog.MESSAGES:
		var sources: Array = [row.en,row.mm,row.jp]
		sources.append_array(row.aliases)
		for source in sources:
			var key: String = _normalize(str(source))
			_index[key] = row
			var matches := _slots.search_all(key)
			if matches.is_empty(): continue
			var expression := "(?is)^"
			var offset := 0
			for slot in matches:
				var token: String = slot.get_string()
				var capture := "([+-]?[0-9][0-9,]*)" if token.ends_with("d") else ("([+-]?[0-9.]+)" if token.ends_with("f") else "(.*?)")
				expression += _escape(key.substr(offset,slot.get_start()-offset)) + capture
				offset = slot.get_end()
			expression += _escape(key.substr(offset)) + "$"
			var pattern := RegEx.new()
			if pattern.compile(expression)==OK:
				_patterns.append({"regex":pattern,"message":row,"length":key.length()})
	_patterns.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.length>b.length)
	get_tree().node_added.connect(_watch)
	set_language(Progress.get_language())

func _normalize(value: String) -> String:
	return _space.sub(value.strip_edges()," ",true).replace("%%","%").to_lower()

func _escape(value: String) -> String:
	var result := value
	for symbol in ["\\",".","+","*","?","^","$","(",")","[","]","{","}","|"]:
		result = result.replace(symbol,"\\"+symbol)
	return result

func text(source: String) -> String:
	if _text_cache.has(source): return str(_text_cache[source])
	var translated := _translate(source)
	_text_cache[source] = translated
	return translated

func _translate(source: String) -> String:
	if source.is_empty() or source in ["日本語","မြန်မာ","English"]:return source
	var key := _normalize(source)
	if _index.has(key):
		var row: Dictionary = _index[key]
		return str(row.en) if row.en in BRAND_NAMES else str(row[language])
	for entry in _patterns:
		var match_value: RegExMatch = entry.regex.search(key)
		if match_value==null:continue
		# Match using the original spelling so names and player-entered values survive.
		var original_match: RegExMatch = entry.regex.search(_space.sub(source.strip_edges()," ",true))
		var target: String = entry.message[language]
		var result := ""
		var offset := 0
		var group := 1
		for slot in _slots.search_all(target):
			result += target.substr(offset,slot.get_start()-offset)
			result += original_match.get_string(group) if original_match!=null else match_value.get_string(group)
			offset = slot.get_end()
			group += 1
		return (result + target.substr(offset)).replace("%%","%")
	if "\n" in source:
		var lines := PackedStringArray()
		for line in source.split("\n"):lines.append(text(line))
		return "\n".join(lines)
	return source

func set_language(value: String) -> void:
	if value not in ["jp","mm","en"]:return
	language = value
	_revision += 1
	_text_cache.clear()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { localStorage.setItem('kitchenLanguage',"+JSON.stringify(value)+"); } catch(e) {}",true)
	TranslationServer.set_locale({"jp":"ja","mm":"my","en":"en"}[value])
	get_tree().root.title = str(ProjectSettings.get_setting("application/config/name"))
	_refresh_nodes()
	language_changed.emit(value)

func _watch(node: Node) -> void:
	if node is Control or node is Window:
		var reference: WeakRef = weakref(node)
		_nodes.append(reference)
		call_deferred("_localize_reference",reference)

func _localize_reference(reference: WeakRef) -> void:
	var node: Node = reference.get_ref()
	if is_instance_valid(node): _localize(node)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed<0.1:return
	_elapsed=0.0
	_refresh_nodes()

func _refresh_nodes() -> void:
	var live: Array[WeakRef] = []
	for reference in _nodes:
		var node: Node = reference.get_ref()
		if not is_instance_valid(node):continue
		live.append(reference)
		_localize(node)
	_nodes = live

func _property(node: Node, property_name: String) -> void:
	var current: String = str(node.get(property_name))
	var revision_key := "locale_revision_"+property_name
	var source_key := "locale_source_"+property_name
	var rendered_key := "locale_rendered_"+property_name
	if node.get_meta(revision_key,-1)==_revision and current==str(node.get_meta(rendered_key,"")):
		return
	if not node.has_meta(source_key) or current!=str(node.get_meta(rendered_key,"")):
		node.set_meta(source_key,current)
	var translated := text(str(node.get_meta(source_key)))
	if translated!=current:node.set(property_name,translated)
	node.set_meta(rendered_key,translated)
	node.set_meta(revision_key,_revision)

func _localize(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():return
	var ancestor: Node = node
	while ancestor != null:
		if bool(ancestor.get_meta("locale_ignore",false)): return
		ancestor = ancestor.get_parent()
	if node is OptionButton:
		# Endonyms in the language picker stay identifiable in every language.
		pass
	elif node is Label or node is RichTextLabel or node is Button:
		_property(node,"text")
	if node is LineEdit or node is TextEdit:
		_property(node,"placeholder_text")
	if node is Control:
		_property(node,"tooltip_text")
	if node is Window and not node is PopupMenu:
		_property(node,"title")
	if node is PopupMenu:
		var sources: Dictionary = node.get_meta("locale_items",{})
		for i in range(node.item_count):
			var current: String = node.get_item_text(i)
			if not sources.has(i) or current!=sources[i].rendered:
				sources[i]={"source":current,"rendered":current}
			var translated := text(str(sources[i].source))
			if translated!=current:node.set_item_text(i,translated)
			sources[i].rendered=translated
		node.set_meta("locale_items",sources)
