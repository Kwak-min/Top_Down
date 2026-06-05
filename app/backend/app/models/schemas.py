# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from pydantic import BaseModel, Field
from typing import Any, Literal
Verdict = Literal["allow", "warn", "block"]
class AnalyzeRequest(BaseModel):
    sender: str = Field(..., examples=["01000000000"])
    message: str
    user_profile: str = "senior"
class UrlCheckRequest(BaseModel):
    url: str
    offline: bool = True
class NanoclawAnalyzeRequest(BaseModel):
    url: str
class OverlayPolicy(BaseModel):
    touch_block_required: bool
    message: str
class AnalyzeResponse(BaseModel):
    verdict: Verdict
    risk_score: float
    reasons: list[str]
    reported_sender: dict[str, Any]
    context_ai: dict[str, Any]
    url_checks: list[dict[str, Any]]
    overlay: OverlayPolicy
    pipeline_log: list[dict[str, Any]]
