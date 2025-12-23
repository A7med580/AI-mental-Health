from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, Dict, Any

@dataclass
class Job:
    job_id: str
    status: str = "queued"   # queued | processing | completed | failed
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    error: Optional[str] = None
    result: Optional[Dict[str, Any]] = None

JOBS: Dict[str, Job] = {}

def touch(job: Job):
    job.updated_at = datetime.utcnow().isoformat()
