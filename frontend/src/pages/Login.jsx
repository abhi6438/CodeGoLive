import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Link } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import SEO from "../components/SEO";
import Logo from "../components/Logo";

export default function Login() {
  const { session, signInWithGoogle, signInWithPassword, signUpWithPassword, signInWithEmail, resendConfirmation, resetPassword } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (session) navigate("/", { replace: true });
  }, [session, navigate]);

  const [tab, setTab] = useState("signin"); // "signin" | "signup" | "magic"
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
  const [error, setError] = useState("");
  const [signedUp, setSignedUp] = useState(false);
  const [magicSent, setMagicSent] = useState(false);
  const [resendSent, setResendSent] = useState(false);
  const [showResend, setShowResend] = useState(false);
  const [resetSent, setResetSent] = useState(false);

  const switchTab = (t) => { setTab(t); setError(""); setSignedUp(false); setMagicSent(false); setShowResend(false); setResendSent(false); setResetSent(false); };

  const handleGoogle = async () => {
    setGoogleLoading(true);
    setError("");
    const { error: err } = await signInWithGoogle();
    if (err) { setError(err.message); setGoogleLoading(false); }
  };

  const handleMagicLink = async (e) => {
    e.preventDefault();
    if (!email.trim()) return;
    setLoading(true);
    setError("");
    try {
      const { error: err } = await signInWithEmail(email.trim());
      if (err) {
        if (err.message?.toLowerCase().includes("rate limit") || err.status === 429) {
          setError("Too many email requests — please wait a few minutes and try again, or use Google sign-in.");
        } else {
          setError(err.message || "Could not send magic link.");
        }
      } else {
        setMagicSent(true);
      }
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      if (tab === "signin") {
        const { error: err } = await signInWithPassword(email, password);
        if (err) {
          const msg = err.message || "";
          if (msg.includes("Invalid login") || msg.includes("invalid_credentials")) setError("Wrong email or password.");
          else if (msg.includes("Email not confirmed") || err.code === "email_not_confirmed") {
            setError("Please confirm your email first — check your inbox (and spam folder) for a verification link.");
            setShowResend(true);
          }
          else setError(msg || "Something went wrong.");
        }
      } else {
        if (password.length < 6) { setError("Password must be at least 6 characters."); setLoading(false); return; }
        const { error: err } = await signUpWithPassword(email, password);
        if (err) {
          if (err.message?.toLowerCase().includes("rate limit") || err.status === 429) {
            setError("Email rate limit reached — please wait a few minutes, or use Google sign-in instead.");
          } else {
            setError(err.message || "Something went wrong.");
          }
        } else {
          setSignedUp(true);
        }
      }
    } catch { setError("Something went wrong. Please try again."); }
    finally { setLoading(false); }
  };

  const handleReset = async (e) => {
    e.preventDefault();
    if (!email.trim()) return;
    setLoading(true);
    setError("");
    try {
      const { error: err } = await resetPassword(email.trim());
      if (err) {
        if (err.message?.toLowerCase().includes("rate limit") || err.status === 429) {
          setError("Too many requests — please wait a few minutes and try again.");
        } else {
          setError(err.message || "Could not send reset email.");
        }
      } else {
        setResetSent(true);
      }
    } catch { setError("Something went wrong. Please try again."); }
    finally { setLoading(false); }
  };

  const handleResend = async () => {
    if (!email.trim()) return;
    setLoading(true);
    try {
      const { error: err } = await resendConfirmation(email.trim());
      if (err) setError(err.message || "Could not resend. Please try again.");
      else { setResendSent(true); setShowResend(false); setError(""); }
    } catch { setError("Something went wrong."); }
    finally { setLoading(false); }
  };

  return (
    <div className="lp-shell">
      <SEO title="Sign In" robots="noindex, nofollow" />
      {/* ── Left panel ── */}
      <div className="lp-left">
        <div className="lp-left-inner">
          <Link to="/" className="lp-brand">
            <Logo size={34} showText textClass="lp-brand-text" />
          </Link>

          <div className="lp-left-body">
            <h2 className="lp-tagline">
              Learn SAP.<br />
              <span className="lp-tagline-accent">Ship real things.</span>
            </h2>
            <p className="lp-tagline-sub">
              Hands-on courses by practitioners — free forever.
            </p>

            <div className="lp-courses">
              <p className="lp-courses-label">Available courses</p>
              <div className="lp-course-item">
                <span className="lp-course-dot" />
                <div>
                  <strong>SAP BTP &amp; CAP Development</strong>
                  <span>SAPUI5 · CAP · BTP deploy · CI/CD</span>
                </div>
              </div>
              <div className="lp-course-item">
                <span className="lp-course-dot" />
                <div>
                  <strong>SAP AI Core &amp; Generative AI</strong>
                  <span>Prompt engineering · RAG · Gen AI Hub</span>
                </div>
              </div>
              <div className="lp-course-item">
                <span className="lp-course-dot" />
                <div>
                  <strong>SAP Integration Suite</strong>
                  <span>iFlows · Adapters · Mappings · BTP</span>
                </div>
              </div>
              <div className="lp-course-item lp-course-more">
                <span className="lp-course-dot lp-course-dot--dim" />
                <div>
                  <strong>More courses coming soon</strong>
                  <span>New topics added regularly</span>
                </div>
              </div>
            </div>
            <p className="lp-free-badge">✦ Free forever — no credit card needed</p>
          </div>

          <p className="lp-left-footer">Trusted by SAP developers worldwide 🌍</p>
        </div>
      </div>

      {/* ── Right panel ── */}
      <div className="lp-right">
        <div className="lp-form-wrap">

          {/* ── Account created success ── */}
          {signedUp ? (
            <div className="lp-sent">
              <div className="lp-sent-icon">📬</div>
              <h1 className="lp-welcome">Check your inbox!</h1>
              <p className="lp-welcome-sub">
                We sent a confirmation link to <strong>{email}</strong>.<br />
                Click it to activate your account, then sign in.
              </p>
              <p className="lp-sent-hint">Don&apos;t see it? Check your spam / junk folder.</p>
              <button className="btn btn-primary lp-submit" style={{ marginTop: "1.5rem" }} onClick={() => switchTab("signin")}>
                Back to sign in
              </button>
            </div>

          /* ── Magic link sent ── */
          ) : magicSent ? (
            <div className="lp-sent">
              <div className="lp-sent-icon">✨</div>
              <h1 className="lp-welcome">Magic link sent!</h1>
              <p className="lp-welcome-sub">
                We emailed a sign-in link to <strong>{email}</strong>.<br />
                Click it to sign in instantly — no password needed.
              </p>
              <p className="lp-sent-hint">Don&apos;t see it? Check your spam / junk folder.</p>
              <button className="lp-switch-btn" style={{ marginTop: "1.25rem", fontSize: "0.875rem" }}
                onClick={() => { setMagicSent(false); setEmail(""); }}>
                Try a different email
              </button>
            </div>

          ) : (
            <>
              <h1 className="lp-welcome">
                {tab === "signin" ? <>Welcome back 👋</> : tab === "signup" ? <>Create account 🚀</> : <>Magic link ✨</>}
              </h1>
              <p className="lp-welcome-sub">
                {tab === "signin" ? "Sign in to your account to continue."
                  : tab === "signup" ? "Join free — no credit card needed."
                  : tab === "reset" ? "Enter your email and we'll send a password reset link."
                  : "Get a one-click sign-in link sent to your email."}
              </p>

              {/* Google button */}
              <button className="lp-google-btn" onClick={handleGoogle} disabled={googleLoading}>
                <svg width="20" height="20" viewBox="0 0 48 48" fill="none">
                  <path d="M44.5 20H24v8.5h11.7C34.2 33.6 29.6 37 24 37c-7.2 0-13-5.8-13-13s5.8-13 13-13c3.1 0 5.9 1.1 8.1 2.9l6-6C34.5 5.1 29.5 3 24 3 12.4 3 3 12.4 3 24s9.4 21 21 21c10.5 0 20-7.6 20-21 0-1.3-.1-2.7-.5-4z" fill="#FFC107"/>
                  <path d="M6.3 14.7l7 5.1C15.1 16.1 19.2 13 24 13c3.1 0 5.9 1.1 8.1 2.9l6-6C34.5 5.1 29.5 3 24 3 16.3 3 9.7 7.9 6.3 14.7z" fill="#FF3D00"/>
                  <path d="M24 45c5.4 0 10.3-1.9 14.1-5.1l-6.5-5.3C29.6 36.3 26.9 37 24 37c-5.6 0-10.2-3.4-11.7-8.3l-7 5.4C8.8 41.3 15.9 45 24 45z" fill="#4CAF50"/>
                  <path d="M44.5 20H24v8.5h11.7c-.8 2.2-2.2 4-4 5.4l6.5 5.3c3.8-3.5 6.3-8.8 6.3-15.2 0-1.3-.1-2.7-.5-4z" fill="#1976D2"/>
                </svg>
                {googleLoading ? "Redirecting…" : "Continue with Google"}
              </button>

              <div className="lp-divider"><span>or</span></div>

              {/* Tabs */}
              <div className="lp-tabs">
                <button className={`lp-tab${tab === "signin" ? " active" : ""}`} onClick={() => switchTab("signin")}>Sign in</button>
                <button className={`lp-tab${tab === "signup" ? " active" : ""}`} onClick={() => switchTab("signup")}>Sign up</button>
                <button className={`lp-tab${tab === "magic" ? " active" : ""}`} onClick={() => switchTab("magic")}>
                  ✨ Magic link
                </button>
              </div>

              {/* Magic link form */}
              {tab === "magic" ? (
                <form onSubmit={handleMagicLink} className="lp-form">
                  <div className="lp-field">
                    <label className="lp-label" htmlFor="lp-magic-email">EMAIL</label>
                    <input id="lp-magic-email" type="email" className="lp-input"
                      placeholder="you@example.com"
                      value={email} onChange={(e) => setEmail(e.target.value)}
                      required autoFocus />
                  </div>
                  {error && <div className="lp-error">{error}</div>}
                  <button type="submit" className="lp-submit" disabled={loading || !email}>
                    {loading ? "Sending…" : "Send magic link →"}
                  </button>
                  <p className="lp-magic-note">
                    No password required — we&apos;ll email you a secure one-click sign-in link.
                  </p>
                </form>

              ) : tab === "reset" ? (
                resetSent ? (
                  <div className="lp-sent-box">
                    <div className="lp-sent-icon">✉️</div>
                    <p className="lp-sent-title">Check your inbox</p>
                    <p className="lp-sent-sub">We sent a password reset link to <strong>{email}</strong>. Click the link in the email to set a new password.</p>
                    <button type="button" className="lp-switch-btn" onClick={() => switchTab("signin")}>Back to sign in</button>
                  </div>
                ) : (
                  <form onSubmit={handleReset} className="lp-form">
                    <div className="lp-field">
                      <label className="lp-label" htmlFor="lp-reset-email">EMAIL</label>
                      <input id="lp-reset-email" type="email" className="lp-input"
                        placeholder="you@example.com"
                        value={email} onChange={(e) => setEmail(e.target.value)}
                        required autoFocus />
                    </div>
                    {error && <div className="lp-error">{error}</div>}
                    <button type="submit" className="lp-submit" disabled={loading || !email}>
                      {loading ? "Sending…" : "Send reset link →"}
                    </button>
                    <p className="lp-magic-note">
                      You&apos;ll receive an email with a link to set a new password.
                    </p>
                  </form>
                )

              ) : (
                /* Password form */
                <form onSubmit={handleSubmit} className="lp-form">
                  <div className="lp-field">
                    <label className="lp-label" htmlFor="lp-email">EMAIL</label>
                    <input id="lp-email" type="email" className="lp-input" placeholder="you@example.com"
                      value={email} onChange={(e) => setEmail(e.target.value)} required autoFocus />
                  </div>

                  <div className="lp-field">
                    <div className="lp-label-row">
                      <label className="lp-label" htmlFor="lp-pass">PASSWORD</label>
                      {tab === "signin" && (
                        <button type="button" className="lp-forgot" onClick={() => switchTab("reset")}>
                          Forgot password?
                        </button>
                      )}
                    </div>
                    <input id="lp-pass" type="password" className="lp-input" placeholder="••••••••"
                      value={password} onChange={(e) => setPassword(e.target.value)} required />
                  </div>

                  {error && <div className="lp-error">{error}</div>}
                  {showResend && !resendSent && (
                    <button type="button" className="lp-resend-btn" onClick={handleResend} disabled={loading}>
                      Resend confirmation email
                    </button>
                  )}
                  {resendSent && (
                    <p className="lp-success">Confirmation email resent — check your inbox.</p>
                  )}

                  <button type="submit" className="lp-submit" disabled={loading || !email || !password}>
                    {loading ? "Please wait…" : tab === "signin" ? "Sign in →" : "Create account →"}
                  </button>
                </form>
              )}

              <p className="lp-switch">
                {tab === "signin"
                  ? <>Don&apos;t have an account? <button className="lp-switch-btn" onClick={() => switchTab("signup")}>Sign up free</button></>
                  : tab === "signup"
                  ? <>Already have an account? <button className="lp-switch-btn" onClick={() => switchTab("signin")}>Sign in</button></>
                  : tab === "reset"
                  ? <>Remember your password? <button className="lp-switch-btn" onClick={() => switchTab("signin")}>Sign in</button></>
                  : <>Prefer a password? <button className="lp-switch-btn" onClick={() => switchTab("signin")}>Sign in with password</button></>}
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
