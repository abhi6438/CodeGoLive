import { useState, useEffect, useCallback, useRef } from 'react';

// Try to import supabase — adjust path based on what exists in the codebase
let supabase;
try {
  supabase = require('../lib/supabaseClient').supabase;
} catch {
  try { supabase = require('../lib/supabase').supabase; } catch { supabase = null; }
}

export function useArenaMatch(matchId) {
  const [matchState, setMatchState] = useState('waiting');
  const [players, setPlayers] = useState({});
  const [currentQuestion, setCurrentQuestion] = useState(null);
  const [chatMessages, setChatMessages] = useState([]);
  const [latestReaction, setLatestReaction] = useState(null);
  const [latestTaunt, setLatestTaunt] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const channelRef = useRef(null);

  useEffect(() => {
    if (!matchId || !supabase) return;
    const channel = supabase.channel('arena:match:' + matchId);
    channelRef.current = channel;

    channel
      .on('broadcast', { event: 'question_start' }, ({ payload }) => {
        setCurrentQuestion(payload);
        setMatchState('active');
      })
      .on('broadcast', { event: 'score_update' }, ({ payload }) => {
        setPlayers(prev => ({ ...prev, [payload.user_id]: { ...prev[payload.user_id], ...payload } }));
      })
      .on('broadcast', { event: 'chat' }, ({ payload }) => {
        setChatMessages(prev => [...prev, payload]);
      })
      .on('broadcast', { event: 'reaction' }, ({ payload }) => {
        setLatestReaction(payload);
        setTimeout(() => setLatestReaction(null), 2500);
      })
      .on('broadcast', { event: 'taunt' }, ({ payload }) => {
        setLatestTaunt(payload);
        setTimeout(() => setLatestTaunt(null), 4000);
      })
      .on('broadcast', { event: 'match_end' }, ({ payload }) => {
        setMatchState('finished');
      })
      .subscribe((status) => {
        setIsConnected(status === 'SUBSCRIBED');
      });

    return () => {
      channel.unsubscribe();
      channelRef.current = null;
    };
  }, [matchId]);

  const sendChat = useCallback((text) => {
    if (!channelRef.current || !text.trim()) return;
    channelRef.current.send({ type: 'broadcast', event: 'chat', payload: { text, created_at: new Date().toISOString() } });
  }, []);

  const sendReaction = useCallback((emoji) => {
    if (!channelRef.current) return;
    channelRef.current.send({ type: 'broadcast', event: 'reaction', payload: { emoji } });
  }, []);

  const sendTaunt = useCallback((text) => {
    if (!channelRef.current) return;
    channelRef.current.send({ type: 'broadcast', event: 'taunt', payload: { text } });
  }, []);

  return { matchState, players, currentQuestion, chatMessages, latestReaction, latestTaunt, sendChat, sendReaction, sendTaunt, isConnected };
}
