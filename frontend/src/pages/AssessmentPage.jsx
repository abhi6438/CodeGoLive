import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const COURSE_ID = "sap-btp";

// ─── Phase constants ──────────────────────────────────────────────
const PHASE = {
  LOADING: "loading",
  INTRO: "intro",
  QUIZ: "quiz",
  SUBMITTING: "submitting",
  REVIEW: "review",
  ERROR: "error",
};

// ─── Helpers ──────────────────────────────────────────────────────
function topicLink(topicSlug) {
  return `/course/${COURSE_ID}/${topicSlug}`;
}

// ─── Sub-components ───────────────────────────────────────────────

function ProgressBar({ current, total }) {
  const pct = total ? Math.round((current / total) * 100) : 0;
  return (
    <div className="asmt-progress-wrap">
      <div className="asmt-progress-track">
        <div className="asmt-progress-fill" style={{ width: `${pct}%` }} />
      </div>
      <span className="asmt-progress-label">
        {current} / {total}
      </span>
    </div>
  );
}

function QuestionCard({ question, number, total, answer, onAnswer }) {
  const opts = Array.isArray(question.options)
    ? question.options
    : JSON.parse(question.options);

  return (
    <div className="asmt-question-card">
      <div className="asmt-question-meta">Question {number} of {total}</div>
      <p className="asmt-question-text">{question.question}</p>
      <ul className="asmt-options">
        {opts.map((opt, idx) => {
          const selected = answer === idx;
          return (
            <li key={idx}>
              <button
                className={`asmt-option${selected ? " selected" : ""}`}
                onClick={() => onAnswer(question.id, idx)}
              >
                <span className="asmt-option-letter">
                  {String.fromCharCode(65 + idx)}
                </span>
                <span className="asmt-option-text">{opt}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function ReviewCard({ result, index }) {
  const opts = Array.isArray(result.options)
    ? result.options
    : JSON.parse(result.options);

  return (
    <div className={`asmt-review-card ${result.is_correct ? "correct" : "incorrect"}`}>
      <div className="asmt-review-header">
        <span className="asmt-review-num">Q{index + 1}</span>
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
              <span className="asmt-review-opt-letter">
                {String.fromCharCode(65 + idx)}
              </span>
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
        href={topicLink(result.topic_slug)}
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

  const [phase, setPhase] = useState(PHASE.LOADING);
  const [status, setStatus] = useState(null);       // {passed, last_attempt}
  const [questions, setQuestions] = useState([]);
  const [total, setTotal] = useState(0);
  const [passPercent, setPassPercent] = useState(70);
  const [answers, setAnswers] = useState({});       // {questionId: selectedIdx}
  const [current, setCurrent] = useState(0);        // current question index
  const [submitResult, setSubmitResult] = useState(null);
  const [error, setError] = useState(null);
  const [showAllReview, setShowAllReview] = useState(false);

  // Load status on mount
  useEffect(() => {
    api.get("/api/assessment/status")
      .then((data) => {
        setStatus(data);
        setPhase(PHASE.INTRO);
      })
      .catch((err) => {
        setError(err.message || "Failed to load assessment status");
        setPhase(PHASE.ERROR);
      });
  }, []);

  const loadQuestions = useCallback(() => {
    setPhase(PHASE.LOADING);
    setAnswers({});
    setCurrent(0);
    setSubmitResult(null);
    api.get("/api/assessment/questions")
      .then((data) => {
        setQuestions(data.questions);
        setTotal(data.total);
        setPassPercent(data.pass_percentage);
        setPhase(PHASE.QUIZ);
      })
      .catch((err) => {
        setError(err.message || "Failed to load questions");
        setPhase(PHASE.ERROR);
      });
  }, []);

  const handleAnswer = (questionId, idx) => {
    setAnswers((prev) => ({ ...prev, [questionId]: idx }));
  };

  const handleSubmit = async () => {
    const payload = {
      answers: Object.entries(answers).map(([question_id, selected_option]) => ({
        question_id,
        selected_option,
      })),
    };
    setPhase(PHASE.SUBMITTING);
    try {
      const result = await api.post("/api/assessment/submit", payload);
      setSubmitResult(result);
      setStatus({ passed: result.passed, last_attempt: { score: result.correct, total: result.total, passed: result.passed } });
      setPhase(PHASE.REVIEW);
    } catch (err) {
      setError(err.message || "Submission failed");
      setPhase(PHASE.ERROR);
    }
  };

  const answeredCount = Object.keys(answers).length;
  const allAnswered = questions.length > 0 && answeredCount === questions.length;

  // ── Render helpers ──
  if (phase === PHASE.LOADING || phase === PHASE.SUBMITTING) {
    return (
      <div className="asmt-page">
        <div className="asmt-loading">
          <div className="asmt-spinner" />
          <p>{phase === PHASE.SUBMITTING ? "Grading your answers…" : "Loading assessment…"}</p>
        </div>
      </div>
    );
  }

  if (phase === PHASE.ERROR) {
    return (
      <div className="asmt-page">
        <div className="asmt-error-box">
          <div className="asmt-error-icon">⚠️</div>
          <p>{error}</p>
          <button className="asmt-btn" onClick={() => navigate("/certificate")}>
            Back to Certificate
          </button>
        </div>
      </div>
    );
  }

  if (phase === PHASE.INTRO) {
    return (
      <div className="asmt-page">
        <SEO title="Final Assessment" robots="noindex" />
        <div className="asmt-intro-card">
          {status?.passed ? (
            <>
              <div className="asmt-intro-icon">🏆</div>
              <h1 className="asmt-intro-title">Assessment Passed!</h1>
              <p className="asmt-intro-sub">
                You've already passed the final assessment. Your certificate has been issued.
              </p>
              {status.last_attempt && (
                <p className="asmt-intro-score">
                  Best score: {status.last_attempt.score}/{status.last_attempt.total}
                </p>
              )}
              <div className="asmt-intro-actions">
                <button className="asmt-btn asmt-btn-primary" onClick={() => navigate("/certificate")}>
                  View My Certificate →
                </button>
                <button className="asmt-btn asmt-btn-secondary" onClick={loadQuestions}>
                  Retake for practice
                </button>
              </div>
            </>
          ) : (
            <>
              <div className="asmt-intro-icon">📋</div>
              <h1 className="asmt-intro-title">Final Assessment</h1>
              <p className="asmt-intro-sub">
                Complete this assessment to earn your <strong>CodeGoLive SAP BTP Certificate</strong>.
              </p>
              <ul className="asmt-intro-rules">
                <li>✦ <strong>30 questions</strong> chosen randomly from a pool of 55+</li>
                <li>✦ Score <strong>{passPercent}% or higher</strong> to pass</li>
                <li>✦ <strong>Unlimited retakes</strong> — each attempt uses a new random set</li>
                <li>✦ After submission you'll see a <strong>full review</strong> with explanations and topic links</li>
              </ul>
              {status?.last_attempt && (
                <p className="asmt-intro-prev">
                  Last attempt: {status.last_attempt.score}/{status.last_attempt.total} (
                  {Math.round((status.last_attempt.score / status.last_attempt.total) * 100)}%)
                </p>
              )}
              <button className="asmt-btn asmt-btn-primary asmt-btn-lg" onClick={loadQuestions}>
                Start Assessment →
              </button>
            </>
          )}
        </div>
      </div>
    );
  }

  if (phase === PHASE.QUIZ) {
    const q = questions[current];
    return (
      <div className="asmt-page">
        <SEO title="Final Assessment" robots="noindex" />
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
            >
              ← Previous
            </button>

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
              <button
                className="asmt-btn asmt-btn-primary"
                onClick={() => setCurrent((c) => c + 1)}
              >
                Next →
              </button>
            ) : (
              <button
                className={`asmt-btn asmt-btn-submit${allAnswered ? "" : " disabled"}`}
                disabled={!allAnswered}
                title={!allAnswered ? `Answer all questions first (${answeredCount}/${total} answered)` : ""}
                onClick={handleSubmit}
              >
                Submit ({answeredCount}/{total} answered)
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  if (phase === PHASE.REVIEW && submitResult) {
    const { correct, total: tot, score_percentage, passed, cert_issued, results } = submitResult;
    const wrongResults = results.filter((r) => !r.is_correct);
    const displayResults = showAllReview ? results : wrongResults;

    return (
      <div className="asmt-page">
        <SEO title="Assessment Result" robots="noindex" />
        <div className="asmt-review-wrap">
          {/* Score banner */}
          <div className={`asmt-score-banner ${passed ? "banner-pass" : "banner-fail"}`}>
            <div className="asmt-score-circle">
              <span className="asmt-score-num">{score_percentage}%</span>
              <span className="asmt-score-sub">{correct}/{tot} correct</span>
            </div>
            <div className="asmt-score-info">
              <h2 className="asmt-score-title">
                {passed ? "🎉 Assessment Passed!" : "📚 Keep Studying"}
              </h2>
              <p className="asmt-score-msg">
                {passed
                  ? cert_issued
                    ? "Your certificate has been issued! You can view and download it now."
                    : "You passed! Complete any remaining topics to unlock your certificate."
                  : `You need ${passPercent}% to pass. Review the topics below and try again.`}
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
                <button className="asmt-btn asmt-btn-ghost" onClick={() => navigate("/")}>
                  Back to Courses
                </button>
              </div>
            </div>
          </div>

          {/* Review section */}
          <div className="asmt-review-section">
            <div className="asmt-review-controls">
              <h3 className="asmt-review-heading">
                {showAllReview ? "All Questions" : `Incorrect Answers (${wrongResults.length})`}
              </h3>
              <button
                className="asmt-btn asmt-btn-ghost asmt-btn-sm"
                onClick={() => setShowAllReview((v) => !v)}
              >
                {showAllReview ? "Show incorrect only" : "Show all questions"}
              </button>
            </div>

            {displayResults.length === 0 ? (
              <div className="asmt-review-perfect">
                🌟 Perfect score on all questions shown!
              </div>
            ) : (
              displayResults.map((r, i) => (
                <ReviewCard key={r.question_id} result={r} index={results.indexOf(r)} />
              ))
            )}
          </div>
        </div>
      </div>
    );
  }

  return null;
}
