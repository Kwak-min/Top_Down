export type Verdict = "allow" | "warn" | "block";
export type AnalyzeRequest = { sender: string; message: string; user_profile: string };
export type AnalyzeResponse = {
  verdict: Verdict;
  risk_score: number;
  reasons: string[];
  reported_sender: Record<string, unknown>;
  context_ai: Record<string, unknown>;
  url_checks: Record<string, unknown>[];
  overlay: { touch_block_required: boolean; message: string };
  pipeline_log: { timestamp?: string; ts?: string; step?: string; stage?: string; detail?: unknown; details?: unknown }[];
};
export type SelfTestResponse = { status: string; mode?: string; passed?: number; failed?: number; checks?: unknown[] };
export type NanoclawVerdict = "phishing" | "suspicious" | "legitimate" | "unknown";
export type NanoclawResponse = {
  url: string;
  verdict: NanoclawVerdict;
  is_phishing: boolean;
  confidence: number;
  reasoning: string;
  nanoclaw_response: string;
  evidence_summary: Record<string, unknown>;
};

const API_BASE = import.meta.env.VITE_API_BASE ?? "";

export async function analyzeMessage(payload: AnalyzeRequest): Promise<AnalyzeResponse> {
  const res = await fetch(`${API_BASE}/api/analyze`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
  if (!res.ok) throw new Error(`분석 API 실패: ${res.status}`);
  return await res.json() as AnalyzeResponse;
}

export async function runOfflineSelfTest(): Promise<SelfTestResponse> {
  const res = await fetch(`${API_BASE}/api/offline/self-test`);
  if (!res.ok) throw new Error(`자체검사 API 실패: ${res.status}`);
  return await res.json() as SelfTestResponse;
}

export async function analyzeUrlWithNanoclaw(url: string): Promise<NanoclawResponse> {
  const payload = { url };
  const proxyUrl = `${API_BASE}/api/nanoclaw/analyze`;
  const proxyRes = await fetch(proxyUrl, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
  if (!proxyRes.ok) throw new Error(`NanoClaw 프록시 API 실패: ${proxyRes.status} (${proxyUrl})`);
  return await proxyRes.json() as NanoclawResponse;
}
