extends RefCounted
# Presentation spans ten planned stages; unavailable games stay locked.
const TOTAL_STAGES: int=10
const Progress=preload("res://GameProgress.gd")
static func completed_count() -> int:
 var count:=0
 for stage in range(1,TOTAL_STAGES+1):
  if Progress.is_completed(stage):count+=1
 return count
static func current_stage() -> int:
 if Progress.has_session() and not Progress.is_completed(Progress.resume_stage()):return Progress.resume_stage()
 for stage in range(1,TOTAL_STAGES+1):
  if not Progress.is_completed(stage):return stage
 return TOTAL_STAGES
static func available_count() -> int:
 var count:=0
 for stage in range(1,TOTAL_STAGES+1):
  if Progress.is_level_unlocked(stage):count+=1
 return count
