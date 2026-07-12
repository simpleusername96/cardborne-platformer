class_name StageGenerationResult
extends RefCounted

var success: bool
var plan: StagePlan
var report: GenerationReport


func _init(
	was_successful: bool = false,
	accepted_plan: StagePlan = null,
	generation_report: GenerationReport = null
) -> void:
	success = was_successful
	plan = accepted_plan
	report = generation_report
