import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import SEO from "../components/SEO";
import QuoteBanner from "../components/QuoteBanner";
import { QUOTES } from "../constants/quotes";

export default function ProfilePage() {
  const { session, profile, updateProfile } = useAuth();
  const navigate = useNavigate();

  const [displayName, setDisplayName] = useState(profile?.display_name || "");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState("");

  if (!session) {
    navigate("/login", { replace: true });
    return null;
  }

  const email = session.user.email || "";
  const initials = displayName.trim()
    ? displayName.trim().split(/\s+/).map(w => w[0]).join("").slice(0, 2).toUpperCase()
    : "?";

  const handleSave = async (e) => {
    e.preventDefault();
    const name = displayName.trim();
    if (!name) { setError("Name cannot be empty."); return; }
    setSaving(true);
    setError("");
    setSaved(false);
    const { error: err } = await updateProfile({ display_name: name });
    setSaving(false);
    if (err) {
      setError("Failed to save. Please try again.");
    } else {
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    }
  };

  return (
    <>
      <SEO title="Edit Profile" robots="noindex, nofollow" />
      <div className="prof-page">
        <QuoteBanner quote={QUOTES.PROFILE} emoji="👤" variant="default" style={{marginBottom:"1.25rem"}} />
        <div className="prof-card">
          {/* Avatar */}
          <div className="prof-avatar-wrap">
            <div className="prof-avatar">{initials}</div>
          </div>

          <h1 className="prof-title">Edit Profile</h1>
          <p className="prof-subtitle">{email}</p>

          <form className="prof-form" onSubmit={handleSave}>
            <div className="prof-field">
              <label className="prof-label" htmlFor="display-name">
                Display name
              </label>
              <input
                id="display-name"
                className="prof-input"
                type="text"
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                placeholder="Your full name"
                maxLength={80}
                autoFocus
              />
              <p className="prof-hint">
                This name appears on your certificate and community posts.
              </p>
            </div>

            {error && <p className="prof-error">{error}</p>}

            <div className="prof-actions">
              <button
                type="submit"
                className="btn btn-primary"
                disabled={saving}
              >
                {saving ? "Saving…" : saved ? "✓ Saved!" : "Save changes"}
              </button>
              <button
                type="button"
                className="btn btn-outline"
                onClick={() => navigate(-1)}
              >
                Cancel
              </button>
            </div>
          </form>

          {profile?.role && profile.role !== "learner" && (
            <div className="prof-role-info">
              <span className="prof-role-badge">{profile.role}</span>
              <span className="prof-role-note">Role is managed by admins</span>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
