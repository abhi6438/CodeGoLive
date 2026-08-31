import SEO from "../components/SEO";

// CONFIGURE: fill in before publishing
const EFFECTIVE_DATE = "[CONFIGURE: e.g. 1 January 2025]";
const LEGAL_EMAIL = "legal@codegoLive.com"; // CONFIGURE
const LEGAL_ENTITY = "[CONFIGURE: legal entity name, e.g. CodeGoLive Ltd]";
const JURISDICTION = "[CONFIGURE: e.g. England and Wales / India / Delaware, USA]";

function H2({ children }) {
  return <h2 style={{ fontSize: "1.1rem", fontWeight: 700, color: "var(--text)", margin: "2rem 0 0.6rem" }}>{children}</h2>;
}
function P({ children }) {
  return <p style={{ color: "var(--text-2)", lineHeight: 1.8, marginBottom: "0.75rem" }}>{children}</p>;
}

export default function TermsPage() {
  return (
    <div style={{ maxWidth: 760, margin: "0 auto", padding: "2.5rem 1.25rem 4rem" }}>
      <SEO title="Terms & Conditions" description="CodeGoLive Terms and Conditions — rules governing use of our learning platform." robots="noindex" />
      <h1 style={{ fontSize: "1.75rem", fontWeight: 800, color: "var(--text)", marginBottom: "0.4rem" }}>Terms &amp; Conditions</h1>
      <p style={{ color: "var(--text-3)", fontSize: "0.82rem", marginBottom: "2rem" }}>Effective date: {EFFECTIVE_DATE}</p>

      <P>Please read these Terms and Conditions ("Terms") carefully before using CodeGoLive (the "Platform"). By accessing or using the Platform, you agree to be bound by these Terms.</P>

      <H2>1. Acceptance of Terms</H2>
      <P>By creating an account or using the Platform, you confirm that you are at least 13 years old and accept these Terms. If you do not agree, you must not use the Platform.</P>

      <H2>2. Account Registration</H2>
      <P>You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorised use of your account. We are not liable for any loss resulting from unauthorised use of your account.</P>

      <H2>3. Course Content and Licence</H2>
      <P>All course content, lessons, and materials on CodeGoLive are provided for personal educational use only. You may not copy, redistribute, sell, or reproduce any course content without our prior written consent. Content is provided "as is" and is subject to change.</P>

      <H2>4. User-Generated Content</H2>
      <P>If you post questions, answers, or replies in the Community section, you retain ownership of that content. By posting, you grant CodeGoLive a non-exclusive, royalty-free licence to display and moderate that content on the Platform. You agree not to post:</P>
      <ul style={{ color: "var(--text-2)", lineHeight: 1.9, paddingLeft: "1.5rem" }}>
        <li>Spam, advertising, or off-topic commercial content</li>
        <li>Abusive, harassing, or defamatory material</li>
        <li>Content that infringes third-party intellectual property rights</li>
        <li>Personally identifiable information of others without consent</li>
      </ul>

      <H2>5. Intellectual Property</H2>
      <P>All course content, branding, and platform code is the intellectual property of {LEGAL_ENTITY}. The CodeGoLive name and logo are protected. SAP, BTP, SAPUI5, and CAP are trademarks of SAP SE. CodeGoLive is not affiliated with or endorsed by SAP SE.</P>

      <H2>6. Disclaimer of Warranties</H2>
      <P>The Platform is provided on an "as is" and "as available" basis. We make no warranties, express or implied, regarding the accuracy, completeness, or fitness for a particular purpose of any content. Technical information is provided for educational purposes and should be independently verified before use in production systems.</P>

      <H2>7. Limitation of Liability</H2>
      <P>To the fullest extent permitted by law in {JURISDICTION}, CodeGoLive shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the Platform, including but not limited to loss of data, loss of profits, or business interruption.</P>

      <H2>8. Account Termination</H2>
      <P>We reserve the right to suspend or terminate your account at our sole discretion if you violate these Terms, abuse the Platform, or engage in conduct harmful to other users or the Platform.</P>

      <H2>9. Changes to These Terms</H2>
      <P>We may update these Terms from time to time. We will update the effective date above. Continued use of the Platform after changes are posted constitutes your acceptance of the revised Terms.</P>

      <H2>10. Governing Law</H2>
      <P>These Terms shall be governed by and construed in accordance with the laws of {JURISDICTION}. Any disputes shall be subject to the exclusive jurisdiction of the courts of {JURISDICTION}.</P>

      <H2>11. Contact</H2>
      <P>Questions about these Terms: <a href={`mailto:${LEGAL_EMAIL}`} style={{ color: "var(--accent)" }}>{LEGAL_EMAIL}</a></P>
    </div>
  );
}
