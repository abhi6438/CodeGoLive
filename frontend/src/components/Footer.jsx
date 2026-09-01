import { Link } from "react-router-dom";

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="site-footer">
      <nav className="site-footer-links">
        <Link to="/about">About</Link>
        <Link to="/contact">Contact</Link>
        <Link to="/privacy">Privacy Policy</Link>
        <Link to="/terms">Terms &amp; Conditions</Link>
        <Link to="/cookies">Cookie Policy</Link>
        <Link to="/disclaimer">Disclaimer</Link> · <Link to="/verify">Verify Certificate</Link>
      </nav>
      <p className="site-footer-copy">
        &copy; {year} CodeGoLive. All rights reserved. Educational content provided for learning purposes.
      </p>
    </footer>
  );
}
