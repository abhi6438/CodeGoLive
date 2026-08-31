import { Link } from "react-router-dom";
import SEO from "../components/SEO";

function H2({ children }) {
  return <h2 style={{ fontSize: "1.1rem", fontWeight: 700, color: "var(--text)", margin: "2rem 0 0.6rem" }}>{children}</h2>;
}
function P({ children }) {
  return <p style={{ color: "var(--text-2)", lineHeight: 1.8, marginBottom: "0.75rem" }}>{children}</p>;
}

function CookieTable({ rows }) {
  return (
    <div style={{ overflowX: "auto", marginBottom: "0.75rem" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.85rem" }}>
        <thead>
          <tr style={{ borderBottom: "2px solid var(--border)" }}>
            {["Name / Key", "Type", "Purpose", "Duration"].map(h => (
              <th key={h} style={{ textAlign: "left", padding: "0.5rem 0.75rem", color: "var(--text-3)", fontWeight: 600, whiteSpace: "nowrap" }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i} style={{ borderBottom: "1px solid var(--border)" }}>
              {r.map((cell, j) => (
                <td key={j} style={{ padding: "0.55rem 0.75rem", color: "var(--text-2)", verticalAlign: "top" }}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function CookiePage() {
  return (
    <div style={{ maxWidth: 760, margin: "0 auto", padding: "2.5rem 1.25rem 4rem" }}>
      <SEO title="Cookie Policy" description="CodeGoLive Cookie Policy — how we use cookies and local storage on our learning platform." robots="noindex" />
      <h1 style={{ fontSize: "1.75rem", fontWeight: 800, color: "var(--text)", marginBottom: "0.4rem" }}>Cookie Policy</h1>
      <p style={{ color: "var(--text-2)", lineHeight: 1.8, marginBottom: "2rem" }}>
        This Cookie Policy explains how CodeGoLive uses cookies and similar browser storage technologies when you visit codegoLive.com.
      </p>

      <H2>1. What Are Cookies?</H2>
      <P>Cookies are small text files stored in your browser. They help websites remember information about your visit. We also use browser localStorage to store preferences on your device.</P>

      <H2>2. Essential Cookies</H2>
      <P>These cookies are strictly necessary to provide you with the core functions of the Platform, including staying signed in. They cannot be disabled without breaking login functionality.</P>
      <CookieTable rows={[
        ["sb-*-auth-token", "Cookie", "Supabase authentication session — keeps you signed in", "Session / up to 1 year"],
        ["sb-*-auth-token-code-verifier", "Cookie", "PKCE code verifier for OAuth flows", "Session"],
      ]} />

      <H2>3. Preference Storage (localStorage)</H2>
      <P>We use your browser's localStorage (not a cookie) to remember your preferences. This data stays on your device and is never sent to our servers.</P>
      <CookieTable rows={[
        ["cgl-theme", "localStorage", "Remembers your chosen theme: light, dark, or system", "Persistent (cleared on browser data clear)"],
        ["cgl-cookie-consent", "localStorage", "Records that you have seen and accepted this cookie notice", "Persistent"],
      ]} />

      <H2>4. Analytics</H2>
      <P>We use Vercel Analytics for anonymous, aggregate page-view statistics. Vercel Analytics does not use cookies and does not collect personally identifiable information.</P>

      <H2>5. Advertising Cookies</H2>
      <P>CodeGoLive does not currently serve advertising. We are not yet integrated with any advertising network. If advertising (such as Google AdSense) is added in the future:</P>
      <ul style={{ color: "var(--text-2)", lineHeight: 1.9, paddingLeft: "1.5rem", marginBottom: "0.75rem" }}>
        <li>This Cookie Policy will be updated before advertising is activated</li>
        <li>A consent mechanism will be presented to you before any advertising cookies are set</li>
        <li>You will be able to opt out of personalised advertising</li>
      </ul>

      <H2>6. Third-Party Cookies</H2>
      <P>When you use Google Sign-In, Google may set its own cookies governed by Google's privacy policy. We do not control those cookies. See <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" style={{ color: "var(--accent)" }}>Google's Privacy Policy</a>.</P>

      <H2>7. Managing Cookies</H2>
      <P>You can control cookies through your browser settings. Be aware that disabling all cookies will prevent you from signing in to CodeGoLive. Instructions for common browsers:</P>
      <ul style={{ color: "var(--text-2)", lineHeight: 1.9, paddingLeft: "1.5rem", marginBottom: "0.75rem" }}>
        <li><a href="https://support.google.com/chrome/answer/95647" target="_blank" rel="noopener noreferrer" style={{ color: "var(--accent)" }}>Google Chrome</a></li>
        <li><a href="https://support.mozilla.org/en-US/kb/cookies-information-websites-store-on-your-computer" target="_blank" rel="noopener noreferrer" style={{ color: "var(--accent)" }}>Mozilla Firefox</a></li>
        <li><a href="https://support.apple.com/en-gb/guide/safari/sfri11471/mac" target="_blank" rel="noopener noreferrer" style={{ color: "var(--accent)" }}>Safari</a></li>
      </ul>

      <H2>8. Changes to This Policy</H2>
      <P>We may update this Cookie Policy, especially before adding advertising. Check back here for updates. Significant changes will be noted in the notice banner.</P>

      <H2>9. More Information</H2>
      <P>
        See our full <Link to="/privacy" style={{ color: "var(--accent)" }}>Privacy Policy</Link> for details on how we handle your personal data.
        Questions? <Link to="/contact" style={{ color: "var(--accent)" }}>Contact us</Link>.
      </P>
    </div>
  );
}
