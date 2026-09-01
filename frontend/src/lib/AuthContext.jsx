import { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "./supabaseClient";
import { api } from "./api";

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
      .maybeSingle()
      .then(({ data, error }) => {
        console.log("[Auth] profile result:", data, "error:", error);
        if (data) {
          setProfile(data);
        } else {
          // Profile row missing — auto-create it
          console.log("[Auth] no profile found, creating one...");
          supabase
            .from("profiles")
            .insert({
              id: session.user.id,
              role: "learner",
              display_name:
                session.user.user_metadata?.full_name ||
                session.user.user_metadata?.name ||
                session.user.email?.split("@")[0] ||
                "Learner",
            })
            .select()
            .maybeSingle()
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

  const resetPassword = (email) =>
    supabase.auth.resetPasswordForEmail(email, {
      redirectTo: window.location.origin + "/reset-password",
    });

  const updatePassword = (newPassword) =>
    supabase.auth.updateUser({ password: newPassword });

  const resendConfirmation = (email) =>
    supabase.auth.resend({ type: "signup", email, options: { emailRedirectTo: window.location.origin } });

  const updateProfile = async (fields) => {
    try {
      const data = await api.patch("/api/profile", fields);
      if (data) setProfile(prev => ({ ...prev, ...data }));
      return { data, error: null };
    } catch (err) {
      return { data: null, error: err };
    }
  };

  const signOut = () => supabase.auth.signOut();

  return (
    <AuthContext.Provider value={{ session, profile, loading, signInWithGoogle, signInWithEmail, signInWithPassword, signUpWithPassword, resendConfirmation, resetPassword, updatePassword, updateProfile, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
