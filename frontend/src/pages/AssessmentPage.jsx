import { useState, useEffect, useCallback } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { api } from "../lib/api";
import SEO from "../components/SEO";

// ─── Courses with assessments ──────────────────────────────────────
const AVAILABLE_COURSES = [
  { id: "sap-btp", title: "SAP BTP & CAP Development", icon: "🛠️", available: true },
  { id: "sap-ai", title: "SAP AI Core & Generative AI", icon: "🤖", available: false },
];

const PASS_PERCENTAGE = 70;

// ─── Phase constants ──────────────────────────────────────────────
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

// ─── Progress bar ─────────────────────────────────────────────────
function ProgressBar({ current, total }) {
  const pct = total ? Math.round((current / total) * 100) : 0;
  return (
    <div className="asmt-progress-wrap">
      <div className="asmt-progress-track">
        <div className="asmt-progress-fill" style={{ width: `${pct}%` }} />
      </div>
      <span className="asmt-progress-label">{current} / {total} answered</span>
    </div>
  );
}

// ─── Question card ────────────────────────────────────────────────
function QuestionCard({ question, number, total, answer, onAnswer }) {
  const opts = Array.isArray(question.options)
    ? question.options
    : JSON.parse(question.options);
  return (
    <div className="asmt-question-card">
      <div className="asmt-question-meta">Question {number} of {total}</div>
      <p className="asmt-question-text">{question.question}</p>
      <ul className="asmt-options">
        {opts.map((opt, idx) => (
          <li key={idx}>
            <button
              className={`asmt-option${answer === idx ? " selected" : ""}`}
              onClick={() => onAnswer(question.id, idx)}
            >
              <span className="asmt-option-letter">{String.fromCharCode(65 + idx)}</span>
              <span className="asmt-option-text">{opt}</span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

// ─── Review card ──────────────────────────────────────────────────
function ReviewCard({ result, courseId }) {
  const opts = Array.isArray(result.options)
    ? result.options
    : JSON.parse(result.options);
  return (
    <div className={`asmt-review-card ${result.is_correct ? "correct" : "incorrect"}`}>
      <div className="asmt-review-header">
        <span className="asmt-review-num">Q</span>
        <span className={`asmt-review-badge ${result.is_correct ? "badge-correct" : "badge-wrong"}`}>
          {result.is_correct ? "✓ Correct" : "✗ Incorrect"}
        </span>
      </div>
      <p className="asmt-review-question">{result.question}</p>
      <ul className="asmt-review-options">
        {opts.map((opt, idx) => {
          const isCorrect = idx === result.correct_option;
          const isSelected = idx === result.selected_option;
          let cls = "asmt-review-opt";
          if (isCorrect) cls += " opt-correct";
          else if (isSelected && !isCorrect) cls += " opt-wrong";
          return (
            <li key={idx} className={cls}>
              <span className="asmt-review-opt-letter">{String.fromCharCode(65 + idx)}</span>
              <span>{opt}</span>
              {isCorrect && <span className="opt-tag">✓ Correct answer</span>}
              {isSelected && !isCorrect && <span className="opt-tag opt-tag-wrong">Your answer</span>}
            </li>
          );
        })}
      </ul>
      <div className="asmt-review-explanation">
        <strong>Explanation:</strong> {result.explanation}
      </div>
      <a
        href={topicLink(courseId, result.topic_slug)}
        className="asmt-review-link"
        target="_blank"
        rel="noreferrer"
      >
        📖 Review this topic →
      </a>
    </div>
  );
}

// ─── Main component ───────────────────────────────────────────────
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

  // Load status when courseId is set
  useEffect(() => {
    if (!courseId) return;
    setPhase(PHASE.LOADING);
    // Load saved attempt from localStorage for "review last attempt"
    try {
      const saved = localStorage.getItem(`cgl-last-attempt-${courseId}`);
      if (saved) setSavedAttempt(JSON.parse(saved));
    } catch (_) {}

    api.get(`/api/assessment/status?course_id=${courseId}`)
      .then((data) => { setStatus(data); setPhase(PHASE.INTRO); })
      .catch((err) => { setError(err.message || "Failed to load status"); setPhase(PHASE.ERROR); });
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
      // Persist for "review last attempt" on the intro screen
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

  // ── Course selection ──
  if (phase === PHASE.COURSE_SELECT) {
    return (
      <div className="asmt-page">
        <SEO title="Assessment" robots="noindex" />
        <div className="asmt-intro-card">
          <div className="asmt-intro-icon">📋</div>
          <h1 className="asmt-intro-title">Final Assessment</h1>
          <p className="asmt-intro-sub">Select the course you want to be assessed on:</p>
          <div className="asmt-course-picker">
            {AVAILABLE_COURSES.map((c) => (
              <button
                key={c.id}
                className={`asmt-course-btn${!c.available ? " asmt-course-btn-disabled" : ""}`}
                disabled={!c.available}
                onClick={() => { setCourseId(c.id); }}
              >
                <span className="asmt-course-icon">{c.icon}</span>
                <span className="asmt-course-name">{c.title}</span>
                {!c.available && <span className="asmt-course-soon">Coming soon</span>}
              </button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // ── Loading / Submitting ──
  if (phase === PHASE.LOADING || phase === PHASE.SUBMITTING) {
    return (
      <div className="asmt-page">
        <div className="asmt-loading">
          <div className="asmt-spinner" />
          <p>{phase === PHASE.SUBMITTING ? "Grading your answers…" : "Loading…"}</p>
        </div>
      </div>
    );
  }

  // ── Error ──
  if (phase === PHASE.ERROR) {
    return (
      <div className="asmt-page">
        <div className="asmt-error-box">
          <div className="asmt-error-icon">⚠️</div>
          <p>{error}</p>
          <button className="asmt-btn" onClick={() => setPhase(PHASE.COURSE_SELECT)}>
            Back
          </button>
        </div>
      </div>
    );
  }

  // ── Intro ──
  if (phase === PHASE.INTRO) {
    const course = AVAILABLE_COURSES.find((c) => c.id === courseId);
    return (
      <div className="asmt-page">
        <SEO title="Assessment" robots="noindex" />
        <div className="asmt-intro-card">
          {status?.passed ? (
            <>
              <div className="asmt-intro-icon">🏆</div>
              <h1 className="asmt-intro-title">Assessment Passed!</h1>
              <p className="asmt-intro-sub">
                You've already passed the <strong>{course?.title}</strong> assessment. Your certificate has been issued.
              </p>
              {status?.total_attempts > 0 && (
                <div className="asmt-attempts-info">
                  <span className="asmt-attempts-count">
                    🔄 {status.total_attempts} attempt{status.total_attempts !== 1 ? "s" : ""} total
                  </span>
                  {status.last_attempt && (
                    <span className="asmt-attempts-last">
                      Last score: {status.last_attempt.score}/{status.last_attempt.total} ({Math.round((status.last_attempt.score / status.last_attempt.total) * 100)}%)
                    </span>
                  )}
                </div>
              )}
              <div className="asmt-intro-actions">
                <button className="asmt-btn asmt-btn-primary" onClick={() => navigate("/certificate")}>
                  View My Certificate →
                </button>
                {savedAttempt && (
                  <button
                    className="asmt-btn asmt-btn-secondary"
                    onClick={() => { setSubmitResult(savedAttempt); setPhase(PHASE.REVIEW); }}
                  >
                    📝 Review last attempt ({savedAttempt.correct}/{savedAttempt.total} · {savedAttempt.score_percentage}%)
                  </button>
                )}
                <button className="asmt-btn asmt-btn-ghost" onClick={loadQuestions}>
                  Retake for practice
                </button>
              </div>
            </>
          ) : (
            <>
              <div className="asmt-intro-icon">{course?.icon || "📋"}</div>
              <h1 className="asmt-intro-title">{course?.title}</h1>
              <p className="asmt-intro-sub">
                Pass the <strong>Final Assessment</strong> to earn your CodeGoLive certificate.
              </p>
              <ul className="asmt-intro-rules">
                <li>✦ <strong>30 questions</strong> chosen randomly from 55+ per attempt</li>
                <li>✦ Score <strong>{PASS_PERCENTAGE}% or higher</strong> to pass</li>
                <li>✦ <strong>Unlimited retakes</strong> — new random set each time</li>
                <li>✦ Full review with explanations and topic links after submission</li>
              </ul>
              {status?.total_attempts > 0 && (
                <div className="asmt-attempts-info">
                  <span className="asmt-attempts-count">
                    🔄 {status.total_attempts} attempt{status.total_attempts !== 1 ? "s" : ""} so far
                  </span>
                  {status.last_attempt && (
                    <span className="asmt-attempts-last">
                      Last score: {status.last_attempt.score}/{status.last_attempt.total} ({Math.round((status.last_attempt.score / status.last_attempt.total) * 100)}%)
                    </span>
                  )}
                </div>
              )}
              <div className="asmt-intro-actions">
                <button className="asmt-btn asmt-btn-primary asmt-btn-lg" onClick={loadQuestions}>
                  Start Assessment →
                </button>
                {savedAttempt && (
                  <button
                    className="asmt-btn asmt-btn-secondary"
                    onClick={() => { setSubmitResult(savedAttempt); setPhase(PHASE.REVIEW); }}
                  >
                    📝 Review last attempt ({savedAttempt.correct}/{savedAttempt.total} · {savedAttempt.score_percentage}%)
                  </button>
                )}
                <button className="asmt-btn asmt-btn-ghost" onClick={() => setPhase(PHASE.COURSE_SELECT)}>
                  ← Change course
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  // ── Quiz ──
  if (phase === PHASE.QUIZ) {
    const q = questions[current];
    return (
      <div className="asmt-page">
        <SEO title="Assessment" robots="noindex" />
        <div className="asmt-quiz-wrap">
          <div className="asmt-quiz-header">
            <h2 className="asmt-quiz-title">Final Assessment</h2>
            <ProgressBar current={answeredCount} total={total} />
          </div>

          <QuestionCard
            question={q}
            number={current + 1}
            total={total}
            answer={answers[q.id]}
            onAnswer={handleAnswer}
          />

          <div className="asmt-quiz-nav">
            <button
              className="asmt-btn asmt-btn-secondary"
              disabled={current === 0}
              onClick={() => setCurrent((c) => c - 1)}
            >← Previous</button>

            <span className="asmt-nav-dots">
              {questions.map((_, i) => (
                <span
                  key={i}
                  className={`asmt-dot${i === current ? " dot-active" : ""}${answers[questions[i].id] !== undefined ? " dot-answered" : ""}`}
                  onClick={() => setCurrent(i)}
                />
              ))}
            </span>

            {current < questions.length - 1 ? (
              <button className="asmt-btn asmt-btn-primary" onClick={() => setCurrent((c) => c + 1)}>
                Next →
              </button>
            ) : (
              <button
                className={`asmt-btn asmt-btn-submit${!allAnswered ? " disabled" : ""}`}
                disabled={!allAnswered}
                title={!allAnswered ? `Answer all ${total} questions first (${answeredCount} done)` : ""}
                onClick={handleSubmit}
              >
                Submit ({answeredCount}/{total})
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  // ── Review ──
  if (phase === PHASE.REVIEW && submitResult) {
    const { correct, total: tot, score_percentage, passed, cert_issued, results } = submitResult;
    const wrongResults = results.filter((r) => !r.is_correct);
    const displayResults = showAllReview ? results : wrongResults;

    return (
      <div className="asmt-page">
        <SEO title="Assessment Result" robots="noindex" />
        <div className="asmt-review-wrap">
          <div className={`asmt-score-banner ${passed ? "banner-pass" : "banner-fail"}`}>
            <div className="asmt-score-circle">
              <span className="asmt-score-num">{score_percentage}%</span>
              <span className="asmt-score-sub">{correct}/{tot}</span>
            </div>
            <div className="asmt-score-info">
              <h2 className="asmt-score-title">
                {passed ? "🎉 Passed!" : "📚 Keep studying"}
              </h2>
              <p className="asmt-score-msg">
                {passed
                  ? cert_issued
                    ? "Certificate issued! You can view and download it now."
                    : "Passed! Complete remaining topics to unlock your certificate."
                  : `Need ${PASS_PERCENTAGE}% to pass. Review the topics below and try again.`}
              </p>
              <div className="asmt-score-actions">
                {passed && cert_issued && (
                  <button className="asmt-btn asmt-btn-primary" onClick={() => navigate("/certificate")}>
                    View Certificate →
                  </button>
                )}
                <button className="asmt-btn asmt-btn-secondary" onClick={loadQuestions}>
                  {passed ? "Retake for practice" : "Try Again"}
                </button>
                <button className="asmt-btn asmt-btn-ghost" onClick={() => setPhase(PHASE.INTRO)}>
                  Back to intro
                </button>
              </div>
            </div>
          </div>

          <div className="asmt-review-section">
            <div className="asmt-review-controls">
              <h3 className="asmt-review-heading">
                {showAllReview ? `All ${results.length} Questions` : `Incorrect Answers (${wrongResults.length})`}
              </h3>
              <button className="asmt-btn asmt-btn-ghost asmt-btn-sm" onClick={() => setShowAllReview((v) => !v)}>
                {showAllReview ? "Show incorrect only" : "Show all questions"}
              </button>
            </div>

            {displayResults.length === 0 ? (
              <div className="asmt-review-perfect">🌟 You got every question right!</div>
            ) : (
              displayResults.map((r) => (
                <ReviewCard key={r.question_id} result={r} courseId={courseId} />
              ))
            )}
          </div>
        </div>
      </div>
    );
  }

  return null;
}
