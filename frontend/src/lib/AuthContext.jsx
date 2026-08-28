import { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "./supabaseClient";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });
    const { data: sub } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
    });
    return () => sub.subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (!session?.user) { setProfile(null); return; }
    console.log("[Auth] fetching profile for", session.user.id);
    supabase
      .from("profiles")
      .select("*")
      .eq("id", session.user.id)
      .single()
      .then(({ data, error }) => {
        console.log("[Auth] profile result:", data, "error:", error);
        if (data) {
          setProfile(data);
        } else {
          // Profile row missing — auto-create it
          console.log("[Auth] no profile found, creating one...");
          supabase
            .from("profiles")
            .insert({ id: session.user.id, role: "learner" })
            .select()
            .single()
            .then(({ data: created, error: createErr }) => {
              console.log("[Auth] created profile:", created, "error:", createErr);
              setProfile(created);
            });
        }
      });
  }, [session]);

  const signInWithGoogle = () =>
    supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: window.location.origin } });

  const signInWithEmail = (email) =>
    supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: window.location.origin } });

  const signInWithPassword = (email, password) =>
    supabase.auth.signInWithPassword({ email, password });

  const signUpWithPassword = (email, password) =>
    supabase.auth.signUp({ email, password, options: { emailRedirectTo: window.location.origin } });

  const signOut = () => supabase.auth.signOut();

  return (
    <AuthContext.Provider value={{ session, profile, loading, signInWithGoogle, signInWithEmail, signInWithPassword, signUpWithPassword, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
