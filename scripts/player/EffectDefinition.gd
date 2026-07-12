class_name EffectDefinition
extends Resource

const OPERATION_ADD := "add"
const OPERATION_MULTIPLY := "multiply"
const OPERATION_OVERRIDE := "override"

const SOURCE_SCOPE_MASTERY := "mastery"
const SOURCE_SCOPE_EQUIPMENT := "equipment"
const SOURCE_SCOPE_RUN_LEVEL := "run_level"
const SOURCE_SCOPE_CARD := "card"
const SOURCE_SCOPE_TEMPORARY := "temporary"

const STACKING_STACK := "stack"
const STACKING_UNIQUE := "unique"
const STACKING_REPLACE := "replace"
const STACKING_HIGHEST := "highest"

@export var stat_id: StringName = &""
@export_enum("add", "multiply", "override") var operation: String = OPERATION_ADD
@export var value: float = 0.0
@export_enum("stack", "unique", "replace", "highest") var stacking: String = STACKING_STACK
@export var stack_key: StringName = &""
@export var source_id: StringName = &""
@export_enum("mastery", "equipment", "run_level", "card", "temporary") var source_scope: String = SOURCE_SCOPE_CARD

# Higher priority applies later within one source scope and wins local ties.
@export var priority: int = 0
