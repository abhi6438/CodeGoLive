import { useState, useEffect, useCallback } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const AVAILABLE_COURSES = [
  { id: "sap-btp", title: "SAP BTP & CAP Development", subtitle: "55+ questions · 30 per attempt", available: true },
  { id: "sap-ai", title: "SAP AI Core & Generative AI", subtitle: "Coming soon", available: false },
];

const PASS_PERCENTAGE = 70;

const PHASE = {
  LOADING: "loading",
  COURSE_SELECT: "course_select",
  INTRO: "intro",
  QUIZ: "quiz",
  SUBMITTING: "submitting",
  REVIEW: "review",
  ERROR: "error",
};

function topicLink(courseId, topicSlug) {
  return `/course/${courseId}/${topicSlug}`;
}

// ── Loading skeleton ─────────────────────────────────────────────
function Skeleton({ w = "100%", h, r = 6 }) {
  return <div className="asmt-skel" style={{ width: w, height: h, borderRadius: r }} />;
}

function LoadingSkeleton() {
  return (
    <div className="asmt-shell">
      <div className="asmt-skel-header">
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <Skeleton w="140px" h="13px" />
          <Skeleton w="80px" h="13px" />
        </div>
        <Skeleton w="100%" h="5px" r={99} />
      </div>
      <div className="asmt-skel-card">
        <Skeleton w="100px" h="11px" />
        <div style={{ marginTop: 12 }}>
          <Skeleton w="100%" h="20px" />
          <div style={{ marginTop: 6 }}><Skeleton w="68%" h="20px" /></div>
        </div>
        <div style={{ marginTop: 24, display: "flex", flexDirection: "column", gap: 10 }}>
          {[0, 1, 2, 3].map((i) => <Skeleton key={i} w="100%" h="52px" r={10} />)}
        </div>
      </div>
    </div>
  );
}

// ── Score ring ───────────────────────────────────────────────────
function ScoreRing({ pct, passed }) {
  const r = 52;
  const circ = 2 * Math.PI * r;
  const fill = (pct / 100) * circ;
  const stroke = pct === 100 ? "#7c3aed" : passed ? "var(--success)" : "var(--danger)";
  return (
    <div className="asmt-score-ring-wrap">
      <svg width="136" height="136" viewBox="0 0 136 136" aria-hidden="true">
        <circle cx="68" cy="68" r={r} fill="none" stroke="var(--border)" strokeWidth="10"
          style={{ transform: "rotate(-90deg)", transformOrigin: "68px 68px" }} />
        <circle cx="68" cy="68" r={r} fill="none" stroke={stroke} strokeWidth="10"
          strokeDasharray={`${fill} ${circ}`} strokeLinecap="round"
          style={{ transform: "rotate(-90deg)", transformOrigin: "68px 68px", transition: "stroke-dasharray 0.9s ease" }} />
      </svg>
      <div className="asmt-score-ring-inner">
        <span className="asmt-score-ring-pct">{pct}%</span>
        <span className="asmt-score-ring-lbl">Score</span>
      </div>
    </div>
  );
}

// ── Question navigator ───────────────────────────────────────────
function QuestionNavigator({ questions, answers, current, onJump }) {
  return (
    <div className="asmt-nav-grid" role="navigation" aria-label="Question navigator">
      {questions.map((q, i) => {
        const answered = answers[q.id] !== undefined;
        const active = i === current;
        return (
          <button
            key={i}
            className={`asmt-nav-cell${active ? " nav-active" : answered ? " nav-answered" : ""}`}
            onClick={() => onJump(i)}
            aria-label={`Question ${i + 1}${answered ? ", answered" : ""}${active ? ", current" : ""}`}
            aria-current={active ? "step" : undefined}
          >
            {i + 1}
          </button>
        );
      })}
    </div>
  );
}

// ── Answer option ────────────────────────────────────────────────
function AnswerOption({ letter, text, selected, onClick }) {
  return (
    <button
      role="radio"
      aria-checked={selected}
      className={`asmt-answer-opt${selected ? " opt-selected" : ""}`}
      onClick={onClick}
    >
      <span className={`asmt-answer-letter${selected ? " letter-sel" : ""}`}>{letter}</span>
      <span className="asmt-answer-text">{text}</span>
      {selected && <span className="asmt-answer-check" aria-hidden="true">✓</span>}
    </button>
  );
}

// ── Review card ──────────────────────────────────────────────────
function ReviewCard({ result, courseId, index }) {
  const opts = Array.isArray(result.options) ? result.options : JSON.parse(result.options);
  const [expanded, setExpanded] = useState(!result.is_correct);

  return (
    <div className={`asmt-rc ${result.is_correct ? "rc-ok" : "rc-bad"}`}>
      <div className="asmt-rc-head">
        <div className="asmt-rc-meta">
          <span className="asmt-rc-qnum">Q{index + 1}</span>
          <span className={`asmt-rc-badge ${result.is_correct ? "rcb-ok" : "rcb-bad"}`}>
            {result.is_correct ? "Correct" : "Incorrect"}
          </span>
        </div>
        <button
          className="asmt-rc-toggle"
          onClick={() => setExpanded((v) => !v)}
          aria-expanded={expanded}
          aria-label={expanded ? "Collapse" : "Expand"}
        >
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2">
            {expanded
              ? <polyline points="2,9 7,4 12,9" />
              : <polyline points="2,5 7,10 12,5" />}
          </svg>
        </button>
      </div>

      <p className="asmt-rc-question">{result.question}</p>

      {expanded && (
        <div className="asmt-rc-body">
          <div className="asmt-rc-opts">
            {opts.map((opt, idx) => {
              const isCorrect = idx === result.correct_option;
              const isSelected = idx === result.selected_option;
              if (!isCorrect && !isSelected) return null;
              return (
                <div key={idx} className={`asmt-rc-opt ${isCorrect ? "rco-ok" : "rco-bad"}`}>
                  <span className="asmt-rc-letter">{String.fromCharCode(65 + idx)}</span>
                  <span className="asmt-rc-opt-text">{opt}</span>
                  <span className="asmt-rc-opt-tag">
                    {isCorrect ? "✓ Correct" : "✗ Your answer"}
                  </span>
                </div>
              );
            })}
          </div>

          <div className="asmt-rc-expl">
            <span className="asmt-rc-expl-label">Explanation</span>
            <span className="asmt-rc-expl-text">{result.explanation}</span>
          </div>

          <a href={topicLink(courseId, result.topic_slug)} className="asmt-rc-link"
            target="_blank" rel="noreferrer">
            Review topic →
          </a>
        </div>
      )}
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────
export default function AssessmentPage() {
  const navigate = useNavigate();
  const { courseId: paramCourseId } = useParams();

  const [courseId, setCourseId] = useState(paramCourseId || null);
  const [phase, setPhase] = useState(paramCourseId ? PHASE.LOADING : PHASE.COURSE_SELECT);
  const [status, setStatus] = useState(null);
  const [questions, setQuestions] = useState([]);
  const [total, setTotal] = useState(0);
  const [answers, setAnswers] = useState({});
  const [current, setCurrent] = useState(0);
  const [submitResult, setSubmitResult] = useState(null);
  const [error, setError] = useState(null);
  const [showAllReview, setShowAllReview] = useState(false);
  const [savedAttempt, setSavedAttempt] = useState(null);

  useEffect(() => {
    if (!courseId) return;
    setPhase(PHASE.LOADING);
    Promise.all([
      api.get(`/api/assessment/status?course_id=${courseId}`),
      api.get(`/api/assessment/last-attempt?course_id=${courseId}`).catch(() => {
        try {
          const saved = localStorage.getItem(`cgl-last-attempt-${courseId}`);
          return saved ? JSON.parse(saved) : null;
        } catch (_) { return null; }
      }),
    ])
      .then(([statusData, attemptData]) => {
        setStatus(statusData);
        if (attemptData) setSavedAttempt(attemptData);
        setPhase(PHASE.INTRO);
      })
      .catch((err) => { setError(err.message || "Failed to load"); setPhase(PHASE.ERROR); });
  }, [courseId]);

  const loadQuestions = useCallback(() => {
    setPhase(PHASE.LOADING);
    setAnswers({});
    setCurrent(0);
    setSubmitResult(null);
    api.get(`/api/assessment/questions?course_id=${courseId}`)
      .then((data) => { setQuestions(data.questions); setTotal(data.total); setPhase(PHASE.QUIZ); })
      .catch((err) => { setError(err.message || "Failed to load questions"); setPhase(PHASE.ERROR); });
  }, [courseId]);

  const handleAnswer = (questionId, idx) => {
    setAnswers((prev) => ({ ...prev, [questionId]: idx }));
  };

  const handleSubmit = async () => {
    setPhase(PHASE.SUBMITTING);
    try {
      const result = await api.post("/api/assessment/submit", {
        course_id: courseId,
        answers: Object.entries(answers).map(([question_id, selected_option]) => ({
          question_id, selected_option,
        })),
      });
      setSubmitResult(result);
      setStatus({ passed: result.passed });
      try {
        localStorage.setItem(
          `cgl-last-attempt-${courseId}`,
          JSON.stringify({ ...result, saved_at: new Date().toISOString() })
        );
      } catch (_) {}
      setPhase(PHASE.REVIEW);
    } catch (err) {
      setError(err.message || "Submission failed");
      setPhase(PHASE.ERROR);
    }
  };

  const answeredCount = Object.keys(answers).length;
  const allAnswered = questions.length > 0 && answeredCount === questions.length;

  // ── COURSE SELECT ──────────────────────────────────────────────
  if (phase === PHASE.COURSE_SELECT) {
    return (
      <div className="asmt-page">
        <SEO title="Assessment" robots="noindex" />
        <div className="asmt-center-card">
          <div className="asmt-cc-head">
            <h1 className="asmt-cc-title">Final Assessment</h1>
            <p className="asmt-cc-sub">Choose the course you want to be assessed on</p>
          </div>
          <div className="asmt-course-list">
            {AVAILABLE_COURSES.map((c) => (
              <button
                key={c.id}
                className={`asmt-course-card${!c.available ? " asmt-course-disabled" : ""}`}
                disabled={!c.available}
                onClick={() => setCourseId(c.id)}
              >
                <div className="asmt-cc-info">
                  <span className="asmt-cc-name">{c.title}</span>
                  <span className="asmt-cc-detail">{c.subtitle}</span>
                </div>
                {c.available
                  ? <span className="asmt-cc-arrow" aria-hidden="true">→</span>
                  : <span className="asmt-cc-soon">Soon</span>}
              </button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // ── LOADING ────────────────────────────────────────────────────
  if (phase === PHASE.LOADING) {
    return (
      <div className="asmt-page">
        <LoadingSkeleton />
      </div>
    );
  }

  // ── SUBMITTING ─────────────────────────────────────────────────
  if (phase === PHASE.SUBMITTING) {
    return (
      <div className="asmt-page">
        <div className="asmt-submitting">
          <div className="asmt-spin-ring" />
          <p className="asmt-submitting-msg">Grading your answers…</p>
          <p className="asmt-submitting-sub">This only takes a moment</p>
        </div>
      </div>
    );
  }

  // ── ERROR ──────────────────────────────────────────────────────
  if (phase === PHASE.ERROR) {
    return (
      <div className="asmt-page">
        <div className="asmt-error-state">
          <div className="asmt-error-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <circle cx="12" cy="16" r="0.6" fill="currentColor" />
            </svg>
          </div>
          <h2 className="asmt-error-title">Something went wrong</h2>
          <p className="asmt-error-msg">{error}</p>
          <button className="asmt-primary-btn" onClick={() => setPhase(PHASE.COURSE_SELECT)}>
            Try again
          </button>
        </div>
      </div>
    );
  }

  // ── INTRO ──────────────────────────────────────────────────────
  if (phase === PHASE.INTRO) {
    const course = AVAILABLE_COURSES.find((c) => c.id === courseId);
    const lastScore = status?.last_attempt;
    const lastPct = lastScore ? Math.round((lastScore.score / lastScore.total) * 100) : null;

    return (
      <div className="asmt-page">
        <SEO title="Assessment" robots="noindex" />
        <div className="asmt-center-card">
          {status?.passed ? (
            <>
              <span className="asmt-passed-badge">Passed ✓</span>
              <div className="asmt-cc-head">
                <h1 className="asmt-cc-title">{course?.title}</h1>
                <p className="asmt-cc-sub">You've already passed and earned your certificate.</p>
              </div>
              {status?.total_attempts > 0 && (
                <div className="asmt-stat-row">
                  <div className="asmt-stat-pill">
                    <span className="asmt-stat-val">{status.total_attempts}</span>
                    <span className="asmt-stat-lbl">Attempt{status.total_attempts !== 1 ? "s" : ""}</span>
                  </div>
                  {lastPct !== null && (
                    <div className="asmt-stat-pill">
                      <span className="asmt-stat-val">{lastPct}%</span>
                      <span className="asmt-stat-lbl">Last score</span>
                    </div>
                  )}
                </div>
              )}
              <div className="asmt-intro-actions">
                <button className="asmt-primary-btn" onClick={() => navigate("/certificate")}>
                  View Certificate
                </button>
                {savedAttempt && (
                  <button className="asmt-secondary-btn" onClick={() => { setSubmitResult(savedAttempt); setPhase(PHASE.REVIEW); }}>
                    Review last attempt · {savedAttempt.correct}/{savedAttempt.total}
                  </button>
                )}
                <button className="asmt-ghost-btn" onClick={loadQuestions}>Retake for practice</button>
              </div>
            </>
          ) : (
            <>
              <div className="asmt-cc-head">
                <h1 className="asmt-cc-title">{course?.title}</h1>
                <p className="asmt-cc-sub">Pass the final assessment to earn your CodeGoLive certificate.</p>
              </div>
              <div className="asmt-rules-grid">
                <div className="asmt-rule-item">
                  <span className="asmt-rule-val">30</span>
                  <span className="asmt-rule-lbl">Questions</span>
                </div>
                <div className="asmt-rule-item">
                  <span className="asmt-rule-val">{PASS_PERCENTAGE}%</span>
                  <span className="asmt-rule-lbl">To pass</span>
                </div>
                <div className="asmt-rule-item">
                  <span className="asmt-rule-val">∞</span>
                  <span className="asmt-rule-lbl">Retakes</span>
                </div>
              </div>

              {status?.total_attempts > 0 && (
                <div className="asmt-stat-row">
                  <div className="asmt-stat-pill">
                    <span className="asmt-stat-val">{status.total_attempts}</span>
                    <span className="asmt-stat-lbl">Attempt{status.total_attempts !== 1 ? "s" : ""} so far</span>
                  </div>
                  {lastPct !== null && (
                    <div className={`asmt-stat-pill${lastPct >= PASS_PERCENTAGE ? " pill-pass" : " pill-fail"}`}>
                      <span className="asmt-stat-val">{lastPct}%</span>
                      <span className="asmt-stat-lbl">Last score</span>
                    </div>
                  )}
                </div>
              )}

              <div className="asmt-intro-actions">
                <button className="asmt-primary-btn asmt-primary-lg" onClick={loadQuestions}>
                  Start Assessment
                </button>
                {savedAttempt && (
                  <button className="asmt-secondary-btn" onClick={() => { setSubmitResult(savedAttempt); setPhase(PHASE.REVIEW); }}>
                    Review last attempt · {savedAttempt.correct}/{savedAttempt.total}
                  </button>
                )}
                <button className="asmt-ghost-btn" onClick={() => setPhase(PHASE.COURSE_SELECT)}>
                  ← Change course
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  // ── QUIZ ───────────────────────────────────────────────────────
  if (phase === PHASE.QUIZ) {
    const q = questions[current];
    const opts = Array.isArray(q.options) ? q.options : JSON.parse(q.options);
    const pct = total ? Math.round((answeredCount / total) * 100) : 0;

    return (
      <div className="asmt-page">
        <SEO title="Assessment" robots="noindex" />
        <div className="asmt-shell">
          {/* Compact quiz header */}
          <div className="asmt-qheader">
            <div className="asmt-qheader-row">
              <span className="asmt-qheader-label">Final Assessment</span>
              <span className="asmt-qheader-count">
                {answeredCount} / {total} answered
              </span>
            </div>
            <div
              className="asmt-qprog-track"
              role="progressbar"
              aria-valuenow={pct}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label={`${pct}% complete`}
            >
              <div className="asmt-qprog-fill" style={{ width: `${pct}%` }} />
            </div>
          </div>

          {/* Question card */}
          <div className="asmt-qcard" role="group" aria-label={`Question ${current + 1} of ${total}`}>
            <div className="asmt-qcard-eyebrow">Question {current + 1} of {total}</div>
            <p className="asmt-qcard-text">{q.question}</p>
            <div className="asmt-answers" role="radiogroup" aria-label="Answer options">
              {opts.map((opt, idx) => (
                <AnswerOption
                  key={idx}
                  letter={String.fromCharCode(65 + idx)}
                  text={opt}
                  selected={answers[q.id] === idx}
                  onClick={() => handleAnswer(q.id, idx)}
                />
              ))}
            </div>
          </div>

          {/* Navigator */}
          <QuestionNavigator questions={questions} answers={answers} current={current} onJump={setCurrent} />

          {/* Footer nav */}
          <div className="asmt-qfooter">
            <button
              className="asmt-secondary-btn"
              disabled={current === 0}
              onClick={() => setCurrent((c) => c - 1)}
            >
              ← Previous
            </button>

            <div className="asmt-qfooter-mid">
              {!allAnswered && (
                <span className="asmt-unanswered-hint">
                  {total - answeredCount} left
                </span>
              )}
            </div>

            {current < questions.length - 1 ? (
              <button className="asmt-primary-btn" onClick={() => setCurrent((c) => c + 1)}>
                Next →
              </button>
            ) : (
              <button
                className={`asmt-submit-btn${!allAnswered ? " submit-disabled" : ""}`}
                disabled={!allAnswered}
                title={!allAnswered ? `Answer all ${total} questions first (${answeredCount} of ${total} done)` : ""}
                onClick={handleSubmit}
              >
                Submit
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  // ── REVIEW ─────────────────────────────────────────────────────
  if (phase === PHASE.REVIEW && submitResult) {
    const { correct, total: tot, score_percentage, passed, cert_issued, results } = submitResult;
    const wrongResults = results ? results.filter((r) => !r.is_correct) : [];
    const displayResults = showAllReview ? (results || []) : wrongResults;
    const perfect = passed && wrongResults.length === 0;

    return (
      <div className="asmt-page">
        <SEO title="Assessment Result" robots="noindex" />
        <div className="asmt-shell">
          {/* Result card */}
          <div className={`asmt-result-card ${passed ? "result-pass" : "result-fail"}${perfect ? " result-perfect" : ""}`}>
            <ScoreRing pct={score_percentage} passed={passed} />
            <div className="asmt-result-info">
              <h2 className="asmt-result-title">
                {perfect ? "Perfect score!" : passed ? "Passed!" : "Not quite yet"}
              </h2>
              <p className="asmt-result-msg">
                {passed
                  ? cert_issued
                    ? "Your certificate has been issued. View and download it now."
                    : "Passed! Complete all course topics to unlock your certificate."
                  : `You need ${PASS_PERCENTAGE}% to pass. Review the topics below and try again.`}
              </p>
              <div className="asmt-result-stats">
                <div className="asmt-rs-item">
                  <span className="asmt-rs-val rs-green">{correct}</span>
                  <span className="asmt-rs-lbl">Correct</span>
                </div>
                <div className="asmt-rs-item">
                  <span className="asmt-rs-val rs-red">{tot - correct}</span>
                  <span className="asmt-rs-lbl">Incorrect</span>
                </div>
                <div className="asmt-rs-item">
                  <span className="asmt-rs-val">{tot}</span>
                  <span className="asmt-rs-lbl">Total</span>
                </div>
              </div>
              <div className="asmt-result-actions">
                {passed && cert_issued && (
                  <button className="asmt-primary-btn" onClick={() => navigate("/certificate")}>
                    View Certificate
                  </button>
                )}
                <button className="asmt-secondary-btn" onClick={loadQuestions}>
                  {passed ? "Retake for practice" : "Try Again"}
                </button>
                <button className="asmt-ghost-btn" onClick={() => setPhase(PHASE.INTRO)}>Back</button>
              </div>
            </div>
          </div>

          {/* Review section */}
          {results && results.length > 0 && (
            <div className="asmt-review-section">
              <div className="asmt-review-bar">
                <h3 className="asmt-review-bar-title">
                  {showAllReview ? `All ${results.length} Questions` : `Incorrect Answers (${wrongResults.length})`}
                </h3>
                <button className="asmt-ghost-btn asmt-ghost-sm" onClick={() => setShowAllReview((v) => !v)}>
                  {showAllReview ? "Incorrect only" : "Show all"}
                </button>
              </div>

              {displayResults.length === 0 ? (
                <div className="asmt-perfect-msg">
                  You answered every question correctly. Outstanding work!
                </div>
              ) : (
                <div className="asmt-rc-list">
                  {displayResults.map((r) => (
                    <ReviewCard
                      key={r.question_id}
                      result={r}
                      courseId={courseId}
                      index={(results || []).indexOf(r)}
                    />
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    );
  }

  return null;
}
