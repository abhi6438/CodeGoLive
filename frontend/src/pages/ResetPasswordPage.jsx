import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { supabase } from "../lib/supabaseClient";
import SEO from "../components/SEO";
import Logo from "../components/Logo";

export default function ResetPasswordPage() {
  const { updatePassword } = useAuth();
  const navigate = useNavigate();

  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === "PASSWORD_RECOVERY") setReady(true);
    });
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) setReady(true);
    });
    return () => subscription.unsubscribe();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (password.length < 6) { setError("Password must be at least 6 characters."); return; }
    if (password !== confirm) { setError("Passwords don't match."); return; }
    setLoading(true);
    setError("");
    try {
      const { error: err } = await updatePassword(password);
      if (err) setError(err.message || "Could not update password.");
      else setDone(true);
    } catch { setError("Something went wrong. Please try again."); }
    finally { setLoading(false); }
  };

  return (
    <div className="lp-shell">
      <SEO title="Set New Password" robots="noindex" />
      <div className="lp-left">
        <div className="lp-left-inner">
          <Link to="/" className="lp-brand">
            <Logo size={34} showText textClass="lp-brand-text" />
          </Link>
          <div className="lp-left-body">
            <h2 className="lp-tagline">Learn SAP.<br /><span className="lp-tagline-accent">Ship real things.</span></h2>
            <p className="lp-tagline-sub">Hands-on courses by practitioners — free forever.</p>
          </div>
        </div>
      </div>

      <div className="lp-right">
        <div className="lp-form-box">
          {done ? (
            <div className="lp-sent-box">
              <div className="lp-sent-icon">✅</div>
              <p className="lp-sent-title">Password updated!</p>
              <p className="lp-sent-sub">Your new password has been saved. You can now sign in.</p>
              <button className="lp-submit" style={{marginTop:"1rem"}} onClick={() => navigate("/", { replace: true })}>
                Go to sign in
              </button>
            </div>
          ) : !ready ? (
            <div className="lp-sent-box">
              <div className="lp-sent-icon">⏳</div>
              <p className="lp-sent-title">Verifying link…</p>
              <p className="lp-sent-sub">Please wait while we verify your reset link. If nothing happens, try clicking the link in your email again.</p>
            </div>
          ) : (
            <>
              <h1 className="lp-welcome">Set new password</h1>
              <p className="lp-welcome-sub">Choose a strong password for your CodeGoLive account.</p>
              <form onSubmit={handleSubmit} className="lp-form">
                <div className="lp-field">
                  <label className="lp-label" htmlFor="rp-pass">NEW PASSWORD</label>
                  <input id="rp-pass" type="password" className="lp-input" placeholder="At least 6 characters"
                    value={password} onChange={(e) => setPassword(e.target.value)} required autoFocus />
                </div>
                <div className="lp-field">
                  <label className="lp-label" htmlFor="rp-confirm">CONFIRM PASSWORD</label>
                  <input id="rp-confirm" type="password" className="lp-input" placeholder="Repeat password"
                    value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
                </div>
                {error && <div className="lp-error">{error}</div>}
                <button type="submit" className="lp-submit" disabled={loading || !password || !confirm}>
                  {loading ? "Saving…" : "Set new password →"}
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
