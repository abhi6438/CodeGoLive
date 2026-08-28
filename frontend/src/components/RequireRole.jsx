import { useAuth } from "../lib/AuthContext";

export default function RequireRole({ roles, children }) {
  const { session, profile, loading } = useAuth();

  if (loading) return <div className="container" style={{ padding: "2rem" }}>Loading...</div>;

  if (!session) {
    return <div className="container" style={{ padding: "2rem" }}>Please sign in to view this page.</div>;
  }

  if (!profile || !roles.includes(profile.role)) {
    return <div className="container" style={{ padding: "2rem" }}>You don't have access to this page.</div>;
  }

  return children;
}
