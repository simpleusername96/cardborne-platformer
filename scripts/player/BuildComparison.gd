class_name BuildComparison
extends RefCounted


static func stat_deltas(current: Dictionary, projected: Dictionary) -> Array[Dictionary]:
	var stat_ids: Array = current.keys()
	for stat_id in projected:
		if not stat_ids.has(stat_id):
			stat_ids.append(stat_id)
	stat_ids.sort()
	var deltas: Array[Dictionary] = []
	for raw_stat_id in stat_ids:
		var stat_id := String(raw_stat_id)
		var before := float(current.get(stat_id, 0.0))
		var after := float(projected.get(stat_id, 0.0))
		if is_equal_approx(before, after):
			continue
		deltas.append({
			"stat_id": stat_id,
			"before": before,
			"after": after,
			"delta": after - before,
		})
	return deltas
