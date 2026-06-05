import React from "react";
import { createRoot } from "react-dom/client";
import {
  AlertTriangle,
  ArrowRight,
  CheckCircle2,
  ClipboardCheck,
  Clock3,
  ExternalLink,
  FileSearch,
  Globe2,
  Link2,
  Loader2,
  MessageSquareWarning,
  Phone,
  Shield,
  ShieldAlert,
  Siren,
  Sparkles,
  UserRoundCheck,
} from "lucide-react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { analyzeMessage, analyzeUrlWithNanoclaw, runOfflineSelfTest, type AnalyzeResponse, type NanoclawResponse, type SelfTestResponse } from "./services/api";
import "./styles/app.css";

const defaultMessage = "엄마 나 폰 고장났어. 지금 상품권 30만원 보내줘. 통화는 안돼. http://phish.test";
const defaultUrl = "https://example.com";

const scenarioSamples = [
  {
    title: "가족 사칭",
    caption: "가장 흔한 긴급 송금 유도",
    sender: "01000000000",
    message: defaultMessage,
  },
  {
    title: "지원금 안내",
    caption: "정부/기관 사칭 링크",
    sender: "0215660000",
    message: "정부 지원금 오늘까지 신청하세요. 본인 확인 후 계좌 인증이 필요합니다. http://support-money-login-auth.test",
  },
  {
    title: "은행 보안",
    caption: "계좌 동결·인증 협박",
    sender: "01099998888",
    message: "고객님의 계좌가 위험합니다. 즉시 본인 인증을 진행하세요. http://bank-login.test",
  },
  {
    title: "정상 문자",
    caption: "일상 대화 예시",
    sender: "01022223333",
    message: "오늘 저녁 7시에 가족 식사합니다. 늦지 않게 오세요.",
  },
];

const pipelineLabels: Record<string, string> = {
  request_received: "요청 접수",
  url_extraction: "URL 추출",
  reported_sender_lookup: "신고번호 조회",
  context_ai_analysis: "문맥 분석",
  risk_score_merge: "위험도 병합",
  overlay_touch_block_policy: "차단 정책 결정",
  response_ready: "결과 준비",
  offline_url_sandbox: "URL 샌드박스",
  url_sandbox: "URL 샌드박스",
};

function verdictLabel(verdict?: string) {
  if (verdict === "block") return "즉시 차단";
  if (verdict === "warn") return "주의 필요";
  return "안전 범위";
}

function verdictTone(verdict?: string) {
  if (verdict === "block") return "danger";
  if (verdict === "warn") return "caution";
  return "safe";
}

function actionText(result: AnalyzeResponse | null) {
  if (!result) return "문자를 붙여넣고 검사하면 바로 행동 안내를 보여드립니다.";
  if (result.verdict === "block") return "링크를 누르지 말고 송금·인증을 중단한 뒤 가족 또는 보호자에게 전화로 확인하세요.";
  if (result.verdict === "warn") return "내용이 의심스럽습니다. 개인정보 입력 전 공식 번호로 다시 확인하세요.";
  return "현재 검사에서는 큰 위험 신호가 낮지만, 링크와 계좌 정보 입력은 계속 조심하세요.";
}

function getBoolean(record: Record<string, unknown>, key: string) {
  return typeof record[key] === "boolean" ? record[key] : undefined;
}

function getString(record: Record<string, unknown>, key: string) {
  return typeof record[key] === "string" ? record[key] : undefined;
}

function getNumber(record: Record<string, unknown>, key: string) {
  return typeof record[key] === "number" ? record[key] : undefined;
}

function getRecord(record: Record<string, unknown>, key: string) {
  const value = record[key];
  return value && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : {};
}

function normalizeUrl(value: string) {
  const trimmed = value.trim();
  if (!trimmed) return "";
  return /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`;
}

function nanoclawTone(result: NanoclawResponse | null) {
  if (!result) return "neutral";
  if (result.verdict === "phishing") return "danger";
  if (result.verdict === "suspicious" || result.verdict === "unknown") return "caution";
  return "safe";
}

function nanoclawLabel(result: NanoclawResponse | null) {
  if (!result) return "대기 중";
  if (result.verdict === "phishing") return "피싱 위험";
  if (result.verdict === "suspicious") return "의심 필요";
  if (result.verdict === "legitimate") return "정상 가능성";
  return "판단 불가";
}

function formatPercent(value: number) {
  return `${Math.round(value * 100)}%`;
}

function pipelineStage(log: AnalyzeResponse["pipeline_log"][number]) {
  return log.stage ?? log.step ?? "unknown_step";
}

function FeatureCard({ icon, title, value, detail, tone = "neutral" }: { icon: React.ReactNode; title: string; value: string; detail: string; tone?: "safe" | "caution" | "danger" | "neutral" }) {
  return (
    <article className={`feature-card ${tone}`}>
      <div className="feature-icon">{icon}</div>
      <div>
        <span>{title}</span>
        <strong>{value}</strong>
        <p>{detail}</p>
      </div>
    </article>
  );
}

function App() {
  const [sender, setSender] = React.useState("01000000000");
  const [message, setMessage] = React.useState(defaultMessage);
  const [result, setResult] = React.useState<AnalyzeResponse | null>(null);
  const [selfTest, setSelfTest] = React.useState<SelfTestResponse | null>(null);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");
  const [browserUrl, setBrowserUrl] = React.useState(defaultUrl);
  const [activeBrowserUrl, setActiveBrowserUrl] = React.useState(defaultUrl);
  const [nanoclawResult, setNanoclawResult] = React.useState<NanoclawResponse | null>(null);
  const [nanoclawLoading, setNanoclawLoading] = React.useState(false);
  const [nanoclawError, setNanoclawError] = React.useState("");

  const tone = verdictTone(result?.verdict);
  const risk = Math.round((result?.risk_score ?? 0) * 100);
  const reportedSender = result?.reported_sender ?? {};
  const contextAi = result?.context_ai ?? {};
  const urlChecks = result?.url_checks ?? [];
  const overlay = result?.overlay;
  const pipelineLog = result?.pipeline_log ?? [];
  const reported = getBoolean(reportedSender, "reported") === true;
  const urlRisk = Math.max(...(urlChecks.map((check) => getNumber(check, "risk_score") ?? 0) ?? [0]));
  const riskRingStyle: React.CSSProperties = {
    background: `conic-gradient(#203b2e ${risk}%, rgba(255,255,255,.68) 0)`,
  };
  const chartData = [
    { name: "문맥", value: Math.round((getNumber(contextAi, "risk_score") ?? 0) * 100), color: "#f97316" },
    { name: "URL", value: Math.round(urlRisk * 100), color: "#dc2626" },
    { name: "종합", value: risk, color: tone === "danger" ? "#b91c1c" : tone === "caution" ? "#d97706" : "#15803d" },
  ];
  const nanoclawResultTone = nanoclawTone(nanoclawResult);
  const evidence = nanoclawResult?.evidence_summary ?? {};
  const screenshotEvidence = getRecord(evidence, "screenshot");

  async function submit() {
    setLoading(true);
    setError("");
    try {
      setResult(await analyzeMessage({ sender, message, user_profile: "senior" }));
    } catch (e) {
      setError(e instanceof Error ? e.message : "분석 중 오류가 발생했습니다.");
    } finally {
      setLoading(false);
    }
  }

  async function selfCheck() {
    setLoading(true);
    setError("");
    try {
      setSelfTest(await runOfflineSelfTest());
    } catch (e) {
      setError(e instanceof Error ? e.message : "자체검사 중 오류가 발생했습니다.");
    } finally {
      setLoading(false);
    }
  }

  function openBrowserPage() {
    const nextUrl = normalizeUrl(browserUrl);
    if (!nextUrl) {
      setNanoclawError("열 URL을 입력하세요.");
      return;
    }
    setBrowserUrl(nextUrl);
    setActiveBrowserUrl(nextUrl);
    setNanoclawError("");
  }

  async function analyzeBrowserUrl() {
    const nextUrl = normalizeUrl(browserUrl);
    if (!nextUrl) {
      setNanoclawError("검사할 URL을 입력하세요.");
      return;
    }
    setBrowserUrl(nextUrl);
    setActiveBrowserUrl(nextUrl);
    setNanoclawLoading(true);
    setNanoclawError("");
    try {
      setNanoclawResult(await analyzeUrlWithNanoclaw(nextUrl));
    } catch (e) {
      setNanoclawError(e instanceof Error ? e.message : "NanoClaw 분석 중 오류가 발생했습니다.");
    } finally {
      setNanoclawLoading(false);
    }
  }

  return (
    <main className="app-shell">
      <section className="hero-card">
        <div className="hero-copy">
          <p className="eyebrow"><Sparkles size={18} /> Topdown Guard</p>
          <h1>NanoClaw로 웹페이지 피싱 여부를 바로 확인합니다.</h1>
          <p>
            URL을 입력하면 실제 페이지를 브라우저처럼 열어 보고, Jetson NanoClaw 분석 API로
            피싱 여부와 판단 근거를 받아 표시합니다.
          </p>
          <div className="hero-actions">
            <button className="primary" onClick={analyzeBrowserUrl} disabled={nanoclawLoading}>
              {nanoclawLoading ? <Loader2 className="spin" size={22} /> : <ShieldAlert size={22} />}
              NanoClaw 검사하기
            </button>
            <a className="hero-link" href={activeBrowserUrl} target="_blank" rel="noreferrer"><ExternalLink size={20} /> 새 탭에서 열기</a>
          </div>
        </div>
        <aside className={`verdict-board ${nanoclawResultTone}`} aria-live="polite">
          <span className="verdict-kicker">NanoClaw 판단</span>
          <strong>{nanoclawLabel(nanoclawResult)}</strong>
          <div className="risk-ring" style={{ background: `conic-gradient(#203b2e ${Math.round((nanoclawResult?.confidence ?? 0) * 100)}%, rgba(255,255,255,.68) 0)` }}><span>{Math.round((nanoclawResult?.confidence ?? 0) * 100)}</span><small>%</small></div>
          <p>{nanoclawResult?.reasoning ?? "URL을 입력하고 NanoClaw 검사를 실행하세요."}</p>
        </aside>
      </section>

      <section className="panel browser-panel">
        <div className="section-title">
          <Globe2 />
          <div>
            <p>NanoClaw 웹 분석</p>
            <h2>브라우저처럼 URL을 열고 API로 피싱 여부를 확인합니다</h2>
          </div>
        </div>
        <form
          className="browser-toolbar"
          onSubmit={(event) => {
            event.preventDefault();
            void analyzeBrowserUrl();
          }}
        >
          <input value={browserUrl} onChange={(event) => setBrowserUrl(event.target.value)} placeholder="https://example.com" aria-label="검사할 URL" />
          <button className="ghost browser-open" type="button" onClick={openBrowserPage}>
            <Globe2 size={20} /> 페이지 열기
          </button>
          <button className="primary" type="submit" disabled={nanoclawLoading}>
            {nanoclawLoading ? <Loader2 className="spin" size={20} /> : <ShieldAlert size={20} />}
            NanoClaw 검사
          </button>
          <a className="external-link" href={activeBrowserUrl} target="_blank" rel="noreferrer">
            <ExternalLink size={18} /> 새 탭
          </a>
        </form>
        {nanoclawError && <p className="error"><AlertTriangle size={18} /> {nanoclawError}</p>}
        <div className="browser-grid">
          <div className="browser-frame-wrap">
            <div className="browser-chrome"><span /><span /><span /><strong>{activeBrowserUrl}</strong></div>
            <iframe className="browser-frame" src={activeBrowserUrl} title="인터넷 페이지 미리보기" sandbox="allow-forms allow-same-origin allow-scripts allow-popups" />
            <p className="muted">일부 사이트는 보안 정책 때문에 화면 안에서 열리지 않을 수 있습니다. 그 경우 새 탭 버튼을 사용하세요.</p>
          </div>
          <aside className={`nanoclaw-card ${nanoclawResultTone}`} aria-live="polite">
            <span className="verdict-kicker">NanoClaw 판단</span>
            <strong>{nanoclawLabel(nanoclawResult)}</strong>
            <div className="confidence-row">
              <span>신뢰도</span>
              <b>{formatPercent(nanoclawResult?.confidence ?? 0)}</b>
            </div>
            <p>{nanoclawResult?.reasoning ?? "URL을 입력한 뒤 NanoClaw 검사 버튼을 누르면 Jetson 분석 API 결과가 표시됩니다."}</p>
            <dl className="evidence-list">
              <div><dt>HTTP 상태</dt><dd>{getString(evidence, "fetch_status") ?? "-"}</dd></div>
              <div><dt>최종 URL</dt><dd>{getString(evidence, "final_url") ?? nanoclawResult?.url ?? "-"}</dd></div>
              <div><dt>페이지 제목</dt><dd>{getString(evidence, "title") ?? getString(screenshotEvidence, "page_title") ?? "-"}</dd></div>
              <div><dt>스크린샷</dt><dd>{getString(screenshotEvidence, "status") ?? "-"}</dd></div>
            </dl>
          </aside>
        </div>
      </section>

    </main>
  );
}

createRoot(document.getElementById("root")!).render(<App />);
