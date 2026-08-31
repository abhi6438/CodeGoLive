import SEO from "../components/SEO";
import { Link } from "react-router-dom";

// CONFIGURE: update these before publishing
const EFFECTIVE_DATE = "[CONFIGURE: e.g. 1 January 2025]";
const PRIVACY_EMAIL = "privacy@codegoLive.com"; // CONFIGURE: replace with real email

function H2({ children }) {
  return (
    <h2 style={{ fontSize: "1.1rem", fontWeight: 700, color: "var(--text)", margin: "2rem 0 0.6rem" }}>
      {children}
    </h2>
  );
}
function P({ children }) {
  return <p style={{ color: "var(--text-2)", lineHeight: 1.8, marginBottom: "0.75rem" }}>{children}</p>;
}

export default function PrivacyPage() {
  return (
    <div style={{ maxWidth: 760, margin: "0 auto", padding: "2.5rem 1.25rem 4rem" }}>
      <SEO title="Privacy Policy" description="CodeGoLive Privacy Policy — how we collect, use, and protect your information." robots="noindex" />

      <h1 style={{ fontSize: "1.75rem", fontWeight: 800, color: "var(--text)", marginBottom: "0.4rem" }}>Privacy Policy</h1>
      <p style={{ color: "var(--text-3)", fontSize: "0.82rem", marginBottom: "2rem" }}>Effective date: {EFFECTIVE_DATE}</p>

      <P>
        This Privacy Policy explains how CodeGoLive ("we", "us", "our") collects, uses, and protects
        information about you when you use our learning platform at codegoLive.com
        (the "Platform"). Please read it carefully.
      </P>

      <H2>1. Information We Collect</H2>
      <P><strong style={{color:"var(--text)"}}>Account information:</strong> When you register or sign in, we collect your email address and display name via Supabase Auth. If you use Google Sign-In, we receive your Google account email and display name.</P>
      <P><strong style={{color:"var(--text)"}}>Learning progress:</strong> We store which topics you have completed and the timestamps of completion, so we can track your progress and issue certificates.</P>
      <P><strong style={{color:"var(--text)"}}>Community content:</strong> If you post questions, answers, or replies in the Community section, that content is stored and visible to other users.</P>
      <P><strong style={{color:"var(--text)"}}>Technical data:</strong> Standard web server logs (IP address, browser type, pages visited) may be collected automatically by our hosting provider (Vercel).</P>

      <H2>2. How We Use Your Information</H2>
      <P>We use the information we collect to:</P>
      <ul style={{ color: "var(--text-2)", lineHeight: 1.9, paddingLeft: "1.5rem" }}>
        <li>Provide and maintain your account</li>
        <li>Track and display your learning progress</li>
        <li>Issue certificates of completion</li>
        <li>Enable community Q&amp;A features</li>
        <li>Send notifications about answers to your questions (when enabled)</li>
        <li>Improve the Platform and its content</li>
      </ul>
      <P>We do not sell your personal data to third parties.</P>

      <H2>3. Cookies and Local Storage</H2>
      <P><strong style={{color:"var(--text)"}}>Essential cookies:</strong> Supabase Auth sets session cookies (prefixed <code>sb-</code>) that are required for you to stay signed in. These are essential and cannot be disabled without losing login functionality.</P>
      <P><strong style={{color:"var(--text)"}}>Local storage:</strong> We store your theme preference (light/dark/system) in your browser's localStorage under the key <code>cgl-theme</code>. This data never leaves your device.</P>
      <P><strong style={{color:"var(--text)"}}>Analytics:</strong> We use Vercel Analytics for anonymous page view statistics. This does not track personal data or set advertising cookies.</P>
      <P><strong style={{color:"var(--text)"}}>Advertising cookies:</strong> We do not currently serve advertising. If Google AdSense or similar advertising is added in the future, this policy will be updated and a cookie consent mechanism will be provided before advertising cookies are set.</P>
      <P>See our <Link to="/cookies" style={{color:"var(--accent)"}}>Cookie Policy</Link> for full details.</P>

      <H2>4. Third-Party Services</H2>
      <P><strong style={{color:"var(--text)"}}>Supabase:</strong> We use Supabase for authentication and database storage. Supabase may host data in the EU or US. See <a href="https://supabase.com/privacy" target="_blank" rel="noopener noreferrer" style={{color:"var(--accent)"}}>Supabase's Privacy Policy</a>.</P>
      <P><strong style={{color:"var(--text)"}}>Vercel:</strong> Our Platform is hosted on Vercel, which processes web traffic logs. See <a href="https://vercel.com/legal/privacy-policy" target="_blank" rel="noopener noreferrer" style={{color:"var(--accent)"}}>Vercel's Privacy Policy</a>.</P>
      <P><strong style={{color:"var(--text)"}}>Google OAuth:</strong> If you sign in with Google, your sign-in is handled by Google's authentication service. We only receive your email and display name.</P>

      <H2>5. Data Retention</H2>
      <P>We retain your account information and learning progress for as long as your account remains active. If you wish to delete your account and all associated data, please contact us using the details below.</P>
      <P style={{fontStyle:"italic", color:"var(--text-3)"}}>
        {/* CONFIGURE: add specific retention periods if applicable */}
        [CONFIGURE: add specific data retention periods here if applicable]
      </P>

      <H2>6. Your Rights</H2>
      <P>Depending on your location, you may have the right to access, correct, or delete your personal data. To exercise these rights, please contact us at <a href={`mailto:${PRIVACY_EMAIL}`} style={{color:"var(--accent)"}}>{PRIVACY_EMAIL}</a>.</P>
      <P style={{fontStyle:"italic", color:"var(--text-3)"}}>
        {/* CONFIGURE: add GDPR/CCPA specific rights if applicable to your jurisdiction */}
        [CONFIGURE: add jurisdiction-specific rights if applicable]
      </P>

      <H2>7. Security</H2>
      <P>We implement reasonable technical and organisational measures to protect your data. Authentication is handled by Supabase with industry-standard JWT tokens. However, no system is completely secure and we cannot guarantee absolute security.</P>

      <H2>8. Children's Privacy</H2>
      <P>CodeGoLive is not directed at children under 13 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.</P>

      <H2>9. Changes to This Policy</H2>
      <P>We may update this Privacy Policy from time to time. When we do, we will update the effective date above. Continued use of the Platform after changes constitutes your acceptance of the updated policy.</P>

      <H2>10. Contact</H2>
      <P>If you have any questions about this Privacy Policy, please contact us at:</P>
      <P>
        <strong style={{color:"var(--text)"}}>Email:</strong>{" "}
        <a href={`mailto:${PRIVACY_EMAIL}`} style={{color:"var(--accent)"}}>{PRIVACY_EMAIL}</a>
        {/* CONFIGURE: add postal address if required by your jurisdiction */}
      </P>
    </div>
  );
}
