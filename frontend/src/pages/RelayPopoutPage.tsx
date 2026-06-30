import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import {
  Activity,
  ArrowLeft,
  Brain,
  Bot,
  CircleDot,
  ExternalLink,
  Link2,
  MessageSquare,
  Pin,
  Radio,
  RotateCcw,
  ShieldCheck,
  Sparkles,
  ToggleLeft,
  ToggleRight,
  Trash2,
  Volume2,
  PlayCircle,
} from 'lucide-react';
import { useNavigate } from 'react-router';
import {
  checkHealth,
  fetchOpenClawBridgeStatus,
  fetchRelayVoicePack,
  playRelayPlaceholderVoice,
  type RelayVoicePack,
} from '../lib/api';
import {
  deriveRelayRoutingGuidanceView,
  deriveRelayNextMoveView,
  formatRelayMemoryTime,
  RELAY_MEMORY_STORAGE_KEY,
  summarizeRelayMemoryText,
} from '../lib/relayMemory';
import {
  deriveRelayUsageReviewDigest,
  formatRelayUsageReviewTime,
  type RelayUsageReviewArea,
  type RelayUsageReviewTone,
} from '../lib/relayUsageReview';
import {
  readRelayPopoutActivity,
  RELAY_POPOUT_ACTIVITY_KEY,
  type RelayPopoutActivity,
} from '../lib/relayPopout';
import { RelaySimpleModeShell } from '../components/Relay/RelaySimpleModeShell';
import { relayCompanionCopy } from '../lib/relayPersonality';
import {
  buildRelayFirstWaveHandoff,
  deriveRelayFirstWaveRecommendation,
  type RelayFirstWaveAgentKey,
} from '../data/relayFirstWaveAgents';
import { useAppStore } from '../lib/store';

type BridgeState = 'checking' | 'connected' | 'fallback';
type VoicePlaybackState = 'idle' | 'generating' | 'playing' | 'complete' | 'error';
type VoicePlaybackSource = 'manual' | 'event';

function formatActivityTime(timestamp: number): string {
  if (!timestamp) return '--:--:--';
  return new Date(timestamp).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

function HudPanel({
  children,
  className = '',
  cyan = false,
}: {
  children: ReactNode;
  className?: string;
  cyan?: boolean;
}) {
  return (
    <section
      className={`relay-popout-panel relative overflow-hidden ${className}`}
      style={{
        borderColor: cyan ? 'rgba(34, 211, 238, 0.24)' : 'rgba(168, 85, 247, 0.26)',
        background: cyan
          ? 'linear-gradient(145deg, rgba(5, 22, 32, 0.88), rgba(4, 8, 17, 0.94))'
          : 'linear-gradient(145deg, rgba(20, 10, 39, 0.88), rgba(4, 7, 16, 0.95))',
      }}
    >
      {children}
    </section>
  );
}

function MicroReadout({
  label,
  value,
  color = 'rgb(103, 232, 249)',
}: {
  label: string;
  value: string;
  color?: string;
}) {
  return (
    <div className="relay-popout-micro-panel">
      <div className="text-[6px] uppercase tracking-[0.22em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
        {label}
      </div>
      <div className="mt-1 truncate text-[8px] font-semibold uppercase tracking-[0.09em]" style={{ color }}>
        {value}
      </div>
      <div className="mt-1.5 h-px overflow-hidden" style={{ background: 'rgba(148, 163, 184, 0.10)' }}>
        <div
          className="h-full"
          style={{
            width: label === 'Safety' ? '100%' : '72%',
            background: `linear-gradient(90deg, ${color}, transparent)`,
          }}
        />
      </div>
    </div>
  );
}

function StatusRow({
  icon: Icon,
  label,
  detail,
  color,
}: {
  icon: typeof Activity;
  label: string;
  detail: string;
  color: string;
}) {
  return (
    <div className="flex min-w-0 items-center gap-2 py-1.5">
      <div
        className="flex h-5 w-5 shrink-0 items-center justify-center rounded"
        style={{
          color,
          border: `1px solid color-mix(in srgb, ${color} 22%, transparent)`,
          background: `color-mix(in srgb, ${color} 6%, transparent)`,
        }}
      >
        <Icon size={10} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="truncate text-[8px] font-medium uppercase tracking-[0.1em]">{label}</div>
        <div className="truncate text-[7px]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
          {detail}
        </div>
      </div>
      <span
        className="h-1.5 w-1.5 shrink-0 rounded-full"
        style={{ background: color, boxShadow: `0 0 8px ${color}` }}
      />
    </div>
  );
}

export function RelayPopoutPage() {
  const navigate = useNavigate();
  const availableModels = useAppStore((state) => state.models);
  const selectedModel = useAppStore((state) => state.selectedModel);
  const localStreamState = useAppStore((state) => state.streamState);
  const settings = useAppStore((state) => state.settings);
  const relayMemory = useAppStore((state) => state.relayMemory);
  const relaySimpleModeEnabled = settings.relaySimpleModeEnabled;
  const relayPlaceholderVoiceEnabled = settings.relayPlaceholderVoiceEnabled;
  const updateSettings = useAppStore((state) => state.updateSettings);
  const loadRelayMemory = useAppStore((state) => state.loadRelayMemory);
  const updateRelayMemory = useAppStore((state) => state.updateRelayMemory);
  const addRelayPinnedNote = useAppStore((state) => state.addRelayPinnedNote);
  const removeRelayPinnedNote = useAppStore((state) => state.removeRelayPinnedNote);
  const clearRelayMemoryTransient = useAppStore((state) => state.clearRelayMemoryTransient);
  const clearRelayMemoryAll = useAppStore((state) => state.clearRelayMemoryAll);
  const setPendingRelayTaskFlow = useAppStore((state) => state.setPendingRelayTaskFlow);
  const setSelectedModel = useAppStore((state) => state.setSelectedModel);
  const relayUsageReviews = useAppStore((state) => state.relayUsageReviews);
  const addRelayUsageReview = useAppStore((state) => state.addRelayUsageReview);
  const removeRelayUsageReview = useAppStore((state) => state.removeRelayUsageReview);
  const clearRelayUsageReviews = useAppStore((state) => state.clearRelayUsageReviews);
  const [backendOnline, setBackendOnline] = useState<boolean | null>(null);
  const [bridgeState, setBridgeState] = useState<BridgeState>('checking');
  const [sharedActivity, setSharedActivity] = useState<RelayPopoutActivity | null>(() =>
    readRelayPopoutActivity(),
  );
  const [voicePack, setVoicePack] = useState<RelayVoicePack | null>(null);
  const [voicePackError, setVoicePackError] = useState<string | null>(null);
  const [voicePlaybackState, setVoicePlaybackState] = useState<VoicePlaybackState>('idle');
  const [voicePlaybackNote, setVoicePlaybackNote] = useState<string>(relayCompanionCopy.popout.voiceDisabled);
  const [voicePlaybackDetail, setVoicePlaybackDetail] = useState<string>(relayCompanionCopy.popout.voiceDisabledDetail);
  const [voiceCategory, setVoiceCategory] = useState<string>('manual_test');
  const [statusRefreshPending, setStatusRefreshPending] = useState(false);
  const [simpleTaskDraft, setSimpleTaskDraft] = useState(() => relayMemory.currentObjective || '');
  const [memoryDraft, setMemoryDraft] = useState('');
  const [usageReviewTone, setUsageReviewTone] = useState<RelayUsageReviewTone>('mixed');
  const [usageReviewArea, setUsageReviewArea] = useState<RelayUsageReviewArea>('popout');
  const [usageReviewDraft, setUsageReviewDraft] = useState('');
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const audioUrlRef = useRef<string | null>(null);
  const activePlaybackIdRef = useRef(0);

  const disposeAudio = () => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.onended = null;
      audioRef.current.onerror = null;
      audioRef.current.src = '';
      audioRef.current = null;
    }
    if (audioUrlRef.current) {
      URL.revokeObjectURL(audioUrlRef.current);
      audioUrlRef.current = null;
    }
  };

  useEffect(() => {
    const refreshHealth = () => {
      checkHealth().then(setBackendOnline).catch(() => setBackendOnline(false));
    };
    refreshHealth();
    const interval = window.setInterval(refreshHealth, 30_000);
    return () => window.clearInterval(interval);
  }, []);

  useEffect(() => {
    let cancelled = false;
    fetchOpenClawBridgeStatus()
      .then(() => {
        if (!cancelled) setBridgeState('connected');
      })
      .catch(() => {
        if (!cancelled) setBridgeState('fallback');
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => () => disposeAudio(), []);

  useEffect(() => {
    const handleStorage = (event: StorageEvent) => {
      if (event.key === RELAY_POPOUT_ACTIVITY_KEY && event.newValue) {
        try {
          setSharedActivity(JSON.parse(event.newValue) as RelayPopoutActivity);
        } catch {
          // Ignore malformed cross-window status and retain the last safe state.
        }
      }
      if (event.key === RELAY_MEMORY_STORAGE_KEY) {
        loadRelayMemory();
      }
    };
    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, [loadRelayMemory]);

  useEffect(() => {
    let cancelled = false;
    fetchRelayVoicePack()
      .then((pack) => {
        if (cancelled) return;
        setVoicePack(pack);
        setVoicePackError(pack.warning || null);
        setVoiceCategory((current) =>
          pack.available_placeholder_categories.includes(current)
            ? current
            : pack.default_placeholder_category || 'manual_test',
        );
      })
      .catch((error) => {
        if (cancelled) return;
        setVoicePack(null);
        setVoicePackError(error instanceof Error ? error.message : 'Relay voice pack unavailable');
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const isResponding = localStreamState.isStreaming || Boolean(sharedActivity?.isResponding);
  const activePhase = localStreamState.isStreaming
    ? localStreamState.phase
    : sharedActivity?.phase || '';
  const currentModel = selectedModel || sharedActivity?.model || 'Loading local models...';
  const meshState = isResponding ? 'Responding' : 'Stable';
  const systemState = backendOnline === false ? relayCompanionCopy.labels.offline : backendOnline === null ? relayCompanionCopy.labels.checking : relayCompanionCopy.labels.online;
  const bridgeLabel =
    bridgeState === 'connected' ? relayCompanionCopy.labels.connected : bridgeState === 'fallback' ? relayCompanionCopy.labels.manifestFallback : relayCompanionCopy.labels.checking;
  const statusLabel = isResponding ? 'RELAY RESPONDING' : 'RELAY ONLINE';
  const lastSync = formatActivityTime(sharedActivity?.updatedAt || 0);
  const voiceControlsEnabled = relayPlaceholderVoiceEnabled && Boolean(voicePack?.synthesis_available);
  const voiceRequestActive = voicePlaybackState === 'generating' || voicePlaybackState === 'playing';
  const voiceStatusLabel = !relayPlaceholderVoiceEnabled
    ? 'Disabled'
    : !voicePack?.synthesis_available
      ? 'Unavailable'
      : voicePlaybackState === 'generating'
        ? 'Generating'
        : voicePlaybackState === 'playing'
          ? 'Playing'
          : voicePlaybackState === 'complete'
            ? 'Complete'
            : voicePlaybackState === 'error'
              ? 'Failed'
              : 'Ready';
  const voiceStyleLabel = voicePack?.active_placeholder_style || 'sarcastic_polish_04';
  const voiceCategoryVariants = voicePack?.placeholder_category_variants?.[voiceCategory] || [];
  const voiceLine = voicePack?.placeholder_category_lines?.[voiceCategory]
    || voicePack?.default_placeholder_text
    || 'Relay online. Voice check complete.';
  const nextMoveView = deriveRelayNextMoveView(relayMemory);
  const routingGuidanceView = deriveRelayRoutingGuidanceView(relayMemory);
  const simpleFirstWaveRecommendation = deriveRelayFirstWaveRecommendation({
    taskDraft: simpleTaskDraft,
    relayMemory,
    broadRouting: routingGuidanceView,
  });
  const simpleRecommendedAgent = simpleFirstWaveRecommendation.agent;
  const simpleAgentReason = simpleFirstWaveRecommendation.reason;
  const simpleAgentActionLabel = simpleFirstWaveRecommendation.actionLabel;
  const memorySessionLabel = relayMemory.sessionId.slice(0, 8);
  const memoryUpdatedLabel = formatRelayMemoryTime(relayMemory.updatedAt);
  const memoryExpiresLabel = formatRelayMemoryTime(relayMemory.expiresAt);
  const memoryClearedLabel = formatRelayMemoryTime(relayMemory.clearedAt);
  const usageReviewCountLabel = String(relayUsageReviews.length);
  const usageReviewDigest = deriveRelayUsageReviewDigest(relayUsageReviews);
  const voiceCategoryOptions = voicePack?.available_placeholder_categories || ['manual_test'];
  const selectedEventCategory = ['routing', 'success', 'warning'].includes(voiceCategory)
    ? voiceCategory
    : null;
  const eventTriggerStates = [
    {
      key: 'relayVoiceStartupEventEnabled' as const,
      category: 'startup',
      label: 'Startup Event',
    },
    {
      key: 'relayVoiceRoutingEventEnabled' as const,
      category: 'routing',
      label: 'Routing Event',
    },
    {
      key: 'relayVoiceSuccessEventEnabled' as const,
      category: 'success',
      label: 'Success Event',
    },
    {
      key: 'relayVoiceWarningEventEnabled' as const,
      category: 'warning',
      label: 'Warning Event',
    },
  ];

  const handleTogglePlaceholderVoice = () => {
    updateSettings({ relayPlaceholderVoiceEnabled: !relayPlaceholderVoiceEnabled });
    if (relayPlaceholderVoiceEnabled) {
      activePlaybackIdRef.current += 1;
      disposeAudio();
      setVoicePlaybackState('idle');
      setVoicePlaybackNote(relayCompanionCopy.popout.voiceDisabled);
      setVoicePlaybackDetail(relayCompanionCopy.popout.voiceDisabledDetail);
      return;
    }

    setVoicePlaybackState('idle');
    setVoicePlaybackNote(voicePack?.synthesis_available ? relayCompanionCopy.popout.voiceReady : relayCompanionCopy.popout.voiceUnavailable);
    setVoicePlaybackDetail(
      voicePack?.synthesis_available
        ? relayCompanionCopy.popout.voiceReadyDetail
        : voicePackError || relayCompanionCopy.popout.voiceUnavailableDetail,
    );

    const startupEventEnabled = settings.relayVoiceStartupEventEnabled;
    if (startupEventEnabled && voicePack?.synthesis_available) {
      void runVoicePlayback('startup', 'event', true, true);
    }
  };

  const runVoicePlayback = async (
    category: string,
    source: VoicePlaybackSource,
    requireEventEnabled = false,
    voiceEnabledOverride = false,
  ) => {
    const playbackAllowed = voiceEnabledOverride
      ? Boolean(voicePack?.synthesis_available)
      : voiceControlsEnabled;

    if (!playbackAllowed || voiceRequestActive) {
      return;
    }

    if (requireEventEnabled) {
      const matchedEvent = eventTriggerStates.find((eventTrigger) => eventTrigger.category === category);
      if (!matchedEvent || !settings[matchedEvent.key]) {
        setVoicePlaybackState('idle');
        setVoicePlaybackNote(relayCompanionCopy.popout.eventDisabled(category));
        setVoicePlaybackDetail(relayCompanionCopy.popout.eventDisabledDetail);
        return;
      }
    }

    disposeAudio();
    const playbackId = activePlaybackIdRef.current + 1;
    activePlaybackIdRef.current = playbackId;
    const previewText = voicePack?.placeholder_category_lines?.[category]
      || voicePack?.default_placeholder_text
      || voiceLine;
    setVoicePlaybackState('generating');
    setVoicePlaybackNote(relayCompanionCopy.popout.generating(category));
    setVoicePlaybackDetail(previewText);

    try {
      const blob = await playRelayPlaceholderVoice({ category });
      if (activePlaybackIdRef.current !== playbackId) {
        return;
      }

      const objectUrl = URL.createObjectURL(blob);
      audioUrlRef.current = objectUrl;
      const audio = new Audio(objectUrl);
      audioRef.current = audio;
      setVoicePlaybackState('playing');
      setVoicePlaybackNote(relayCompanionCopy.popout.playing(category));
      setVoicePlaybackDetail(
        source === 'manual'
          ? relayCompanionCopy.popout.manualPlaying
          : relayCompanionCopy.popout.eventPlaying,
      );

      audio.onended = () => {
        if (activePlaybackIdRef.current !== playbackId) {
          return;
        }
        disposeAudio();
        setVoicePlaybackState('complete');
        setVoicePlaybackNote(relayCompanionCopy.popout.playbackComplete);
        setVoicePlaybackDetail(
          source === 'manual'
            ? relayCompanionCopy.popout.playbackReplay(category)
            : relayCompanionCopy.popout.eventReplay(category),
        );
      };

      audio.onerror = () => {
        if (activePlaybackIdRef.current !== playbackId) {
          return;
        }
        disposeAudio();
        setVoicePlaybackState('error');
        setVoicePlaybackNote(relayCompanionCopy.popout.playbackFailed);
        setVoicePlaybackDetail(relayCompanionCopy.popout.playbackFailedDetail);
      };

      await audio.play();
    } catch (error) {
      if (activePlaybackIdRef.current !== playbackId) {
        return;
      }
      disposeAudio();
      setVoicePlaybackState('error');
      setVoicePlaybackNote(relayCompanionCopy.popout.playbackFailed);
      setVoicePlaybackDetail(error instanceof Error ? error.message : 'Playback failed');
    }
  };

  const handlePlayPlaceholderVoice = async () => {
    await runVoicePlayback(voiceCategory, 'manual');
  };

  const handleVoiceCategoryChange = (category: string) => {
    setVoiceCategory(category);
  };

  const handlePinMemoryNote = () => {
    const nextNote = summarizeRelayMemoryText(memoryDraft, 180);
    if (!nextNote) {
      return;
    }
    addRelayPinnedNote(nextNote);
    setMemoryDraft('');
  };

  const queueSimpleModeTaskFlow = (agentKey: RelayFirstWaveAgentKey) => {
    const rawTask = simpleTaskDraft.replace(/\s+/g, ' ').trim();
    if (!rawTask) {
      return false;
    }

    const handoff = buildRelayFirstWaveHandoff(agentKey, rawTask, {
      models: availableModels,
      fallbackModel: selectedModel || null,
    });
    setSelectedModel(handoff.model);
    setPendingRelayTaskFlow({
      ...handoff,
      createdAt: Date.now(),
    });
    updateRelayMemory({
      currentLane: 'Relay first-wave',
      currentObjective: summarizeRelayMemoryText(rawTask, 180),
      activeAgent: handoff.agentName,
      lastMeaningfulAction: `Queued a Simple Mode handoff for ${handoff.agentName}.`,
      recentStatusSummary: `${handoff.agentName} is queued as the live first-wave chat worker for the current task.`,
    });
    setSimpleTaskDraft('');
    navigate('/chat');
    return true;
  };

  const handleSimpleTaskFocus = () => {
    const nextObjective = summarizeRelayMemoryText(simpleTaskDraft, 180);
    if (!nextObjective) {
      return;
    }

    updateRelayMemory({
      currentLane: 'Relay first-wave',
      currentObjective: nextObjective,
      activeAgent: simpleRecommendedAgent.name,
      lastMeaningfulAction: `Saved Simple Mode focus for ${simpleRecommendedAgent.name}: ${nextObjective}`,
      recentStatusSummary: `${simpleRecommendedAgent.name} is the first-wave fit. ${simpleFirstWaveRecommendation.taskFit}`,
    });
  };

  const handleClearSimpleTask = () => {
    setSimpleTaskDraft('');
    updateRelayMemory({
      currentObjective: null,
      lastMeaningfulAction: 'Cleared the Simple Mode task draft.',
      recentStatusSummary: 'Simple Mode task draft cleared.',
    });
  };

  const handleSubmitSimpleTask = () => {
    queueSimpleModeTaskFlow(simpleFirstWaveRecommendation.key);
  };

  const handleUseRecommendedAgent = () => {
    queueSimpleModeTaskFlow(simpleFirstWaveRecommendation.key);
  };

  const handleAddUsageReview = () => {
    const nextNote = summarizeRelayMemoryText(usageReviewDraft, 220);
    if (!nextNote) {
      return;
    }
    addRelayUsageReview({
      tone: usageReviewTone,
      area: usageReviewArea,
      note: nextNote,
    });
    setUsageReviewDraft('');
    setUsageReviewTone('mixed');
    setUsageReviewArea('popout');
  };

  const handleRunSelectedEvent = async () => {
    if (!selectedEventCategory) {
      setVoicePlaybackState('idle');
      setVoicePlaybackNote(relayCompanionCopy.popout.noEventSelected);
      setVoicePlaybackDetail(
        voiceCategory === 'startup'
          ? relayCompanionCopy.popout.startupHint
          : relayCompanionCopy.popout.eventHint,
      );
      return;
    }

    await runVoicePlayback(selectedEventCategory, 'event', true);
  };

  const handleRefreshRelayStatus = async () => {
    if (statusRefreshPending) {
      return;
    }

    setStatusRefreshPending(true);
    setVoicePlaybackNote(relayCompanionCopy.popout.refreshingStatus);
    setVoicePlaybackDetail(relayCompanionCopy.popout.refreshingStatusDetail);

    try {
      const [healthResult, bridgeResult] = await Promise.allSettled([checkHealth(), fetchOpenClawBridgeStatus()]);
      const backendReady = healthResult.status === 'fulfilled' && healthResult.value === true;
      const bridgeReady = bridgeResult.status === 'fulfilled';

      setBackendOnline(backendReady);
      setBridgeState(bridgeReady ? 'connected' : 'fallback');

      if (backendReady && bridgeReady) {
        updateRelayMemory({
          recentStatusSummary: 'Backend online. Bridge linked. Companion status is clean.',
        });
        setVoicePlaybackNote(relayCompanionCopy.popout.refreshSuccess);
        setVoicePlaybackDetail(relayCompanionCopy.popout.refreshSuccessDetail);
        if (voiceControlsEnabled && settings.relayVoiceSuccessEventEnabled && !voiceRequestActive) {
          await runVoicePlayback('success', 'event', true);
        }
        return;
      }

      setVoicePlaybackNote(relayCompanionCopy.popout.refreshAttention);
      setVoicePlaybackDetail(
        backendReady
          ? relayCompanionCopy.popout.refreshFallbackDetail
          : relayCompanionCopy.popout.refreshOfflineDetail,
      );
      updateRelayMemory({
        recentStatusSummary: backendReady
          ? 'Backend is up, but the bridge is running in manifest fallback mode.'
          : 'Backend is offline from the companion perspective.',
      });
      if (voiceControlsEnabled && settings.relayVoiceWarningEventEnabled && !voiceRequestActive) {
        await runVoicePlayback('warning', 'event', true);
      }
    } catch (error) {
      setBackendOnline(false);
      setBridgeState('fallback');
      updateRelayMemory({
        recentStatusSummary: 'Companion status refresh failed before Relay could confirm backend readiness.',
      });
      setVoicePlaybackNote(relayCompanionCopy.popout.refreshFailed);
      setVoicePlaybackDetail(error instanceof Error ? error.message : 'Status refresh failed.');
      if (voiceControlsEnabled && settings.relayVoiceWarningEventEnabled && !voiceRequestActive) {
        await runVoicePlayback('warning', 'event', true);
      }
    } finally {
      setStatusRefreshPending(false);
    }
  };

  useEffect(() => {
    if (!relayPlaceholderVoiceEnabled) {
      setVoicePlaybackState('idle');
      setVoicePlaybackNote('Voice disabled until you toggle it on.');
      setVoicePlaybackDetail(relayCompanionCopy.popout.voiceDisabledDetail);
      return;
    }

    if (!voicePack?.synthesis_available) {
      if (!voiceRequestActive) {
        setVoicePlaybackState('idle');
      }
      setVoicePlaybackNote(relayCompanionCopy.popout.voiceUnavailable);
      setVoicePlaybackDetail(voicePackError || relayCompanionCopy.popout.voiceUnavailableDetail);
      return;
    }

    if (voicePlaybackState === 'idle') {
      setVoicePlaybackNote(relayCompanionCopy.popout.statusReady(voiceCategory));
      setVoicePlaybackDetail(
        voiceCategoryVariants.length > 1
          ? relayCompanionCopy.popout.statusReadyVariant(voiceCategoryVariants.length)
          : relayCompanionCopy.popout.statusReadySingle,
      );
    }
  }, [
    relayPlaceholderVoiceEnabled,
    voicePack?.synthesis_available,
    voicePackError,
    voicePlaybackState,
    voiceRequestActive,
    voiceCategory,
    voiceCategoryVariants.length,
  ]);

  return (
    <div
      className={`relay-popout-screen h-screen overflow-y-auto${relaySimpleModeEnabled ? ' relay-popout-simple' : ''}`}
    >
      <div className="relay-popout-grid" aria-hidden="true" />
      <div className="relay-popout-scanlines" aria-hidden="true" />
      <div className="relay-popout-screen-glow" aria-hidden="true" />

      <main className="relay-popout-layout relative z-10 mx-auto flex min-h-full flex-col gap-2.5 p-3">
        <HudPanel className={`relay-popout-header px-3 ${relaySimpleModeEnabled ? 'py-2' : 'py-2.5'}`}>
          <header className="flex items-center justify-between gap-3">
            <div className="flex min-w-0 items-center gap-2.5">
              {!relaySimpleModeEnabled && (
                <div className="relay-popout-brand-mark">
                  <Sparkles size={14} />
                </div>
              )}
              <div className="min-w-0">
                <div className="text-[11px] font-semibold tracking-[0.16em]">
                  {relaySimpleModeEnabled ? 'Relay' : 'TRIPPIN AI'}
                </div>
                <div
                  className="mt-0.5 text-[8px] tracking-wide"
                  style={{ color: relaySimpleModeEnabled ? 'rgba(165, 243, 252, 0.78)' : 'rgb(196, 181, 253)' }}
                >
                  {relaySimpleModeEnabled ? (
                    'Local operator cockpit'
                  ) : (
                    <span className="text-[6px] font-semibold tracking-[0.32em]">BUILT DIFFERENT</span>
                  )}
                </div>
              </div>
            </div>

            <div className="min-w-0 flex-1 text-center">
              {!relaySimpleModeEnabled && (
                <>
                  <div className="text-[9px] font-semibold uppercase tracking-[0.24em]" style={{ color: 'rgb(103, 232, 249)' }}>
                    Relay Companion
                  </div>
                  <div className="mt-0.5 truncate font-mono text-[6px] uppercase tracking-[0.08em]" style={{ color: 'rgba(148, 163, 184, 0.75)' }}>
                    <span className="relay-popout-mode-compact">Companion Mode</span>
                    <span className="relay-popout-mode-wide">Monitor Mode</span>
                    {' // '}Model // {currentModel}
                  </div>
                </>
              )}
              {relaySimpleModeEnabled && isResponding && (
                <div className="text-[9px] font-medium text-violet-200">Relay responding</div>
              )}
            </div>

            <div className="flex shrink-0 items-center gap-1.5">
              {!relaySimpleModeEnabled && (
                <button
                  type="button"
                  onClick={() => updateSettings({ relaySimpleModeEnabled: true })}
                  className="relay-popout-nav-button justify-center px-2 py-1"
                  style={{ color: 'rgb(103, 232, 249)', borderColor: 'rgba(34, 211, 238, 0.24)' }}
                >
                  Simple
                </button>
              )}
              <div
                className="inline-flex shrink-0 items-center gap-1.5 rounded-sm px-2 py-1 text-[8px] font-medium uppercase tracking-wide"
                style={{
                  color: backendOnline === false ? 'rgb(251, 191, 36)' : 'rgb(134, 239, 172)',
                  border:
                    backendOnline === false
                      ? '1px solid rgba(251, 191, 36, 0.24)'
                      : '1px solid rgba(74, 222, 128, 0.22)',
                  background:
                    backendOnline === false
                      ? 'rgba(251, 191, 36, 0.06)'
                      : 'rgba(74, 222, 128, 0.055)',
                }}
              >
                <span className="hud-heartbeat" />
                {systemState}
              </div>
            </div>
          </header>
        </HudPanel>

        {!relaySimpleModeEnabled && (
          <div className="relay-popout-telemetry-grid grid grid-cols-5 gap-1.5">
          {[
            ['SYS', systemState],
            ['BRIDGE', bridgeLabel],
            ['MESH', meshState],
            ['AGENTS', '7 / 7'],
            ['MODE', 'Read-only'],
          ].map(([label, value], index) => (
            <div
              key={label}
              className="relay-popout-telemetry-cell"
              style={{ '--telemetry-accent': index === 1 ? 'rgb(103, 232, 249)' : 'rgb(192, 132, 252)' } as CSSProperties}
            >
              <div>{label}</div>
              <strong>{value}</strong>
            </div>
          ))}
          </div>
        )}

        {!relaySimpleModeEnabled && (
          <HudPanel className={`relay-popout-main-hud ${isResponding ? 'relay-popout-main-hud-active' : ''}`}>
          <div className="relay-popout-hud-corners" aria-hidden="true" />
          <div className="relay-popout-hud-grid" aria-hidden="true" />
          <div className="relay-popout-hud-axis relay-popout-hud-axis-x" aria-hidden="true" />
          <div className="relay-popout-hud-axis relay-popout-hud-axis-y" aria-hidden="true" />

          <div className="relay-popout-hud-layout relative z-10 grid h-full grid-cols-[76px_minmax(0,1fr)_76px] items-center gap-2 px-2 py-3">
            <aside className="relay-popout-side-stack space-y-2">
              <MicroReadout label="Model" value={currentModel.replace(':latest', '')} color="rgb(196, 181, 253)" />
              <MicroReadout label="Bridge" value={bridgeLabel} />
              <MicroReadout label="Agents" value="7 / 7 Online" color="rgb(134, 239, 172)" />
            </aside>

            <div className="relay-popout-radar-column flex min-w-0 flex-col items-center">
              <div className={`relay-popout-radar ${isResponding ? 'relay-popout-radar-active' : ''}`}>
                <div className="relay-popout-radar-sweep" />
                <div className="relay-popout-radar-ring relay-popout-radar-ring-1" />
                <div className="relay-popout-radar-ring relay-popout-radar-ring-2" />
                <div className="relay-popout-radar-ring relay-popout-radar-ring-3" />
                <div className="relay-popout-radar-ticks" />
                <span className="relay-popout-radar-dot relay-popout-radar-dot-a" />
                <span className="relay-popout-radar-dot relay-popout-radar-dot-b" />
                <span className="relay-popout-radar-dot relay-popout-radar-dot-c" />
                <div className="relay-popout-radar-core">
                  <span>///</span>
                </div>
                {isResponding && (
                  <div className="relay-popout-wave" aria-label="Relay response activity">
                    {[0, 1, 2, 3, 4].map((bar) => (
                      <span key={bar} style={{ animationDelay: `${bar * 90}ms` }} />
                    ))}
                  </div>
                )}
              </div>

              <div
                className="mt-2 text-[8px] font-semibold uppercase tracking-[0.24em]"
                style={{ color: isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)' }}
              >
                {statusLabel}
              </div>
              <div className="mt-1 max-w-full truncate font-mono text-[6px] uppercase tracking-[0.08em]" style={{ color: 'rgba(148, 163, 184, 0.70)' }}>
                {isResponding ? activePhase || 'Routing local response' : `Sync ${lastSync}`}
              </div>
            </div>

            <aside className="relay-popout-side-stack space-y-2">
              <MicroReadout label="Mesh" value={meshState} color={isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)'} />
              <MicroReadout label="Safety" value="Read-only" color="rgb(134, 239, 172)" />
              <MicroReadout label="Link" value="Local" color="rgb(196, 181, 253)" />
            </aside>
          </div>
        </HudPanel>
        )}

        {relaySimpleModeEnabled ? (
          <RelaySimpleModeShell
            taskDraft={simpleTaskDraft}
            onTaskDraftChange={setSimpleTaskDraft}
            onSaveFocus={handleSimpleTaskFocus}
            onClearTask={handleClearSimpleTask}
            onSubmitTask={handleSubmitSimpleTask}
            recommendedAgent={simpleRecommendedAgent}
            agentReason={simpleAgentReason}
            agentTaskFit={simpleFirstWaveRecommendation.taskFit}
            firstWaveScopeNote={simpleFirstWaveRecommendation.scopeNote}
            routingMode={simpleFirstWaveRecommendation.routingMode}
            nextMove={nextMoveView}
            agentActionLabel={simpleAgentActionLabel}
            onUseRecommendedAgent={handleUseRecommendedAgent}
            onOpenAgent={(agentKey: RelayFirstWaveAgentKey) => navigate(`/agents?relayAgent=${agentKey}`)}
            onShowAdvanced={() => updateSettings({ relaySimpleModeEnabled: false })}
            relayMemory={relayMemory}
          />
        ) : (
          <>
        <div className="relay-popout-lower-grid grid grid-cols-[1.35fr_0.9fr] gap-2">
          <HudPanel className="relay-popout-status-panel px-3 py-2.5" cyan>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5">
                <Radio size={10} style={{ color: 'rgb(103, 232, 249)' }} />
                <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Recent Status</h2>
              </div>
              <span className="font-mono text-[6px]" style={{ color: 'rgba(148, 163, 184, 0.60)' }}>
                {lastSync}
              </span>
            </div>
            <div className="mt-1 divide-y" style={{ borderColor: 'rgba(148, 163, 184, 0.08)' }}>
              <StatusRow
                icon={CircleDot}
                label={isResponding ? 'Route live' : 'Companion ready'}
                detail={isResponding ? activePhase || relayCompanionCopy.popout.responding : relayCompanionCopy.popout.waiting}
                color={isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)'}
              />
              <StatusRow
                icon={Link2}
                label={bridgeState === 'connected' ? 'Bridge linked' : 'Bridge fallback ready'}
                detail={bridgeState === 'connected' ? relayCompanionCopy.popout.bridgeLinked : relayCompanionCopy.popout.bridgeFallback}
                color="rgb(103, 232, 249)"
              />
              <StatusRow
                icon={ShieldCheck}
                label="Safety lock active"
                detail={relayCompanionCopy.popout.safety}
                color="rgb(134, 239, 172)"
              />
            </div>
          </HudPanel>

          <HudPanel className="relay-popout-signal-panel px-3 py-2.5">
            <div className="flex items-center gap-1.5">
              <Activity size={10} style={{ color: 'rgb(192, 132, 252)' }} />
              <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Signal</h2>
            </div>
            <div className="relay-popout-signal mt-3" aria-hidden="true">
              {[7, 13, 9, 20, 14, 25, 11, 17, 8, 21, 12, 16].map((height, index) => (
                <span
                  key={`${height}-${index}`}
                  style={{
                    height: `${isResponding ? Math.min(28, height + 5) : height}px`,
                    animationDelay: `${index * 70}ms`,
                  }}
                />
              ))}
            </div>
            <div className="mt-3 flex items-center justify-between font-mono text-[6px] uppercase" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
              <span>{isResponding ? 'Active' : 'Standby'}</span>
              <span>Local</span>
            </div>
          </HudPanel>
        </div>

        <HudPanel className="relay-popout-command-panel px-3 py-2.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Bot size={10} style={{ color: 'rgb(196, 181, 253)' }} />
              <span className="text-[7px] font-semibold uppercase tracking-[0.18em]">Command Strip</span>
            </div>
            <span className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgb(134, 239, 172)' }}>
              Reference only
            </span>
          </div>
          <div className="mt-2 grid gap-0.5 font-mono text-[7px] leading-relaxed" style={{ color: 'rgba(165, 243, 252, 0.78)' }}>
            <div><span style={{ color: 'rgb(216, 180, 254)' }}>&gt;</span> relay --status</div>
            <div><span style={{ color: 'rgba(148, 163, 184, 0.70)' }}>System:</span> {systemState}</div>
            <div><span style={{ color: 'rgba(148, 163, 184, 0.70)' }}>Mesh:</span> {meshState}</div>
            <div><span style={{ color: 'rgba(148, 163, 184, 0.70)' }}>Mode:</span> Companion</div>
          </div>
        </HudPanel>

        <HudPanel className="relay-popout-memory-panel px-3 py-2.5">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5">
              <Brain size={10} style={{ color: 'rgb(196, 181, 253)' }} />
              <span className="text-[7px] font-semibold uppercase tracking-[0.18em]">Structured Memory</span>
            </div>
            <span className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgb(134, 239, 172)' }}>
              Visible only
            </span>
          </div>
          <div className="mt-2 grid gap-2">
            <div className="grid grid-cols-3 gap-2">
              <MicroReadout label="Updated" value={memoryUpdatedLabel} color="rgb(216, 180, 254)" />
              <MicroReadout label="Expires" value={memoryExpiresLabel} color="rgb(103, 232, 249)" />
              <MicroReadout label="Pinned" value={String(relayMemory.pinnedNotes.length)} color="rgb(134, 239, 172)" />
            </div>
            <div className="rounded-sm border border-white/10 bg-black/25 px-2 py-2 text-[7px] leading-relaxed">
              <div className="mb-2 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                Tracks only: lane, agent, objective, last action, next move, and short visible notes.
              </div>
              <div className="grid gap-1 md:grid-cols-2">
                <div>
                  <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                    Transient lane
                  </div>
                  <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{relayMemory.currentLane || 'Not set'}</div>
                </div>
                <div>
                  <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                    Active agent
                  </div>
                  <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{relayMemory.activeAgent || 'Not set'}</div>
                </div>
                <div>
                  <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                    Objective
                  </div>
                  <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{relayMemory.currentObjective || 'No active objective.'}</div>
                </div>
                <div>
                  <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                    Last action
                  </div>
                  <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{relayMemory.lastMeaningfulAction || 'Not set'}</div>
                </div>
              </div>
              <div className="mt-2">
                <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  Next suggested move
                </div>
                <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{relayMemory.nextSuggestedMove || nextMoveView.move || 'Not set'}</div>
                <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  Based on {nextMoveView.basedOn}
                </div>
              </div>
              <div className="mt-2 rounded-sm border border-white/10 bg-black/20 px-2 py-2">
                <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  Routing guidance
                </div>
                <div style={{ color: 'rgba(216, 180, 254, 0.92)' }}>
                  {routingGuidanceView.summary}
                </div>
                <div className="mt-1" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                  {routingGuidanceView.reason}
                </div>
                <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  Based on {routingGuidanceView.basedOn}
                </div>
              </div>
              <div className="mt-2">
                <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  Recent status
                </div>
                <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{relayMemory.recentStatusSummary || 'Not set'}</div>
              </div>
              <div className="mt-2 grid gap-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                <div>Transient continuity expires after 12 hours.</div>
                <div>Pinned notes and workspace notes stay put until you remove them.</div>
                <div>Not tracked: raw transcript history, background capture, or cross-machine memory.</div>
                <div>Session {memorySessionLabel} // Last cleared {memoryClearedLabel}</div>
              </div>
            </div>
            <div className="grid gap-2 md:grid-cols-2">
              <div className="rounded-sm border border-white/10 bg-black/20 px-2 py-2">
                <div className="flex items-center gap-1.5">
                  <Pin size={10} style={{ color: 'rgb(216, 180, 254)' }} />
                  <div className="text-[7px] font-semibold uppercase tracking-[0.14em]">Pinned Notes</div>
                </div>
                <div className="mt-2 grid gap-1">
                  {relayMemory.pinnedNotes.length === 0 ? (
                    <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                      Nothing pinned. Promote only the notes you want to survive expiry.
                    </div>
                  ) : (
                    relayMemory.pinnedNotes.map((note) => (
                      <div key={note.id} className="rounded-sm border border-white/10 bg-black/25 px-2 py-1.5">
                        <div className="flex items-start justify-between gap-2">
                          <div className="min-w-0">
                            <div className="text-[7px]" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>{note.text}</div>
                            <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                              {formatRelayMemoryTime(note.pinnedAt)}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => removeRelayPinnedNote(note.id)}
                            className="relay-popout-nav-button justify-center px-2 py-1"
                            style={{ color: 'rgb(251, 191, 36)', borderColor: 'rgba(251, 191, 36, 0.20)' }}
                          >
                            <Trash2 size={9} />
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
                <div className="mt-2 grid gap-2">
                  <textarea
                    value={memoryDraft}
                    onChange={(event) => setMemoryDraft(event.target.value)}
                    rows={2}
                    placeholder="Pin a short note worth keeping..."
                    className="rounded-sm border border-white/10 bg-black/30 px-2 py-1.5 text-[7px] outline-none"
                    style={{ color: 'rgba(165, 243, 252, 0.9)', resize: 'vertical' }}
                  />
                  <button
                    type="button"
                    onClick={handlePinMemoryNote}
                    disabled={!memoryDraft.trim()}
                    className="relay-popout-nav-button justify-center"
                    style={{
                      color: memoryDraft.trim() ? 'rgb(216, 180, 254)' : 'rgba(148, 163, 184, 0.56)',
                      borderColor: memoryDraft.trim() ? 'rgba(192, 132, 252, 0.24)' : 'rgba(148, 163, 184, 0.16)',
                      opacity: memoryDraft.trim() ? 1 : 0.6,
                    }}
                  >
                    <Pin size={10} />
                    Pin visible note
                  </button>
                </div>
              </div>
              <div className="rounded-sm border border-white/10 bg-black/20 px-2 py-2">
                <div className="text-[7px] font-semibold uppercase tracking-[0.14em]">Workspace Notes</div>
                <div className="mt-2 grid gap-2 text-[7px] leading-relaxed">
                  <div>
                    <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                      Lane priorities
                    </div>
                    <ul className="mt-1 grid gap-1" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                      {relayMemory.activeLanePriorities.map((item) => <li key={item}>• {item}</li>)}
                    </ul>
                  </div>
                  <div>
                    <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                      Freeze notes
                    </div>
                    <ul className="mt-1 grid gap-1" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                      {relayMemory.freezeNotes.map((item) => <li key={item}>• {item}</li>)}
                    </ul>
                  </div>
                  <div>
                    <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                      Machine notes
                    </div>
                    <ul className="mt-1 grid gap-1" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                      {relayMemory.machineEnvironmentNotes.map((item) => <li key={item}>• {item}</li>)}
                    </ul>
                  </div>
                  <div>
                    <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                      Boundaries
                    </div>
                    <ul className="mt-1 grid gap-1" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                      {relayMemory.currentBoundaries.map((item) => <li key={item}>• {item}</li>)}
                    </ul>
                  </div>
                </div>
                <div className="mt-3 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                  Reset transient keeps pinned and workspace memory. Clear all wipes the visible local snapshot.
                </div>
                <div className="mt-2 grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={clearRelayMemoryTransient}
                    className="relay-popout-nav-button justify-center"
                    style={{ color: 'rgb(103, 232, 249)', borderColor: 'rgba(34, 211, 238, 0.24)' }}
                  >
                    <RotateCcw size={10} />
                    Reset transient
                  </button>
                  <button
                    type="button"
                    onClick={clearRelayMemoryAll}
                    className="relay-popout-nav-button justify-center"
                    style={{ color: 'rgb(251, 191, 36)', borderColor: 'rgba(251, 191, 36, 0.20)' }}
                  >
                    <Trash2 size={10} />
                    Clear all
                  </button>
                </div>
              </div>
            </div>
          </div>
        </HudPanel>

        <HudPanel className="px-3 py-2.5">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5">
              <MessageSquare size={10} style={{ color: 'rgb(216, 180, 254)' }} />
              <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Usage Review Log</h2>
            </div>
            <span className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgb(134, 239, 172)' }}>
              Local only
            </span>
          </div>
          <div className="mt-2 grid gap-2">
            <div className="grid grid-cols-3 gap-2">
              <MicroReadout label="Entries" value={usageReviewCountLabel} color="rgb(216, 180, 254)" />
              <MicroReadout label="Lane" value={relayMemory.currentLane || 'Unset'} color="rgb(103, 232, 249)" />
              <MicroReadout label="Agent" value={relayMemory.activeAgent || 'Unset'} color="rgb(134, 239, 172)" />
            </div>
            <div className="rounded-sm border border-white/10 bg-black/20 px-2 py-2">
              <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                Review snapshot
              </div>
              <div className="mt-2 grid grid-cols-3 gap-2">
                <MicroReadout label="Strong" value={String(usageReviewDigest.strongCount)} color="rgb(134, 239, 172)" />
                <MicroReadout label="Mixed" value={String(usageReviewDigest.mixedCount)} color="rgb(103, 232, 249)" />
                <MicroReadout label="Rough" value={String(usageReviewDigest.roughCount)} color="rgb(251, 191, 36)" />
              </div>
              <div className="mt-2 grid gap-1 text-[7px] leading-relaxed">
                <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                  Strongest area: {usageReviewDigest.strongestArea}
                </div>
                <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                  Roughest area: {usageReviewDigest.roughestArea}
                </div>
                <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                  Recurring agent: {usageReviewDigest.recurringAgent || 'None yet'}
                </div>
                <div style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                  Recurring lane: {usageReviewDigest.recurringLane || 'None yet'}
                </div>
              </div>
              <div className="mt-2 rounded-sm border border-white/10 bg-black/25 px-2 py-2">
                <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  Current tuning hint
                </div>
                <div className="mt-1 text-[7px]" style={{ color: 'rgba(216, 180, 254, 0.92)' }}>
                  {usageReviewDigest.tuningHint}
                </div>
              </div>
            </div>
            <div className="rounded-sm border border-white/10 bg-black/25 px-2 py-2 text-[7px] leading-relaxed">
              <div className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                Save a quick operator review for the current cockpit state. Each entry captures the visible lane, agent, objective, next move, status, selected model, and your note.
              </div>
              <div className="mt-2 grid gap-2 md:grid-cols-2">
                <label className="grid gap-1">
                  <span className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                    Review tone
                  </span>
                  <select
                    value={usageReviewTone}
                    onChange={(event) => setUsageReviewTone(event.target.value as RelayUsageReviewTone)}
                    className="rounded-sm border border-white/10 bg-black/30 px-2 py-1.5 text-[7px] outline-none"
                    style={{ color: 'rgba(165, 243, 252, 0.9)' }}
                  >
                    <option value="strong">Strong</option>
                    <option value="mixed">Mixed</option>
                    <option value="rough">Rough</option>
                  </select>
                </label>
                <label className="grid gap-1">
                  <span className="text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                    Cockpit area
                  </span>
                  <select
                    value={usageReviewArea}
                    onChange={(event) => setUsageReviewArea(event.target.value as RelayUsageReviewArea)}
                    className="rounded-sm border border-white/10 bg-black/30 px-2 py-1.5 text-[7px] outline-none"
                    style={{ color: 'rgba(165, 243, 252, 0.9)' }}
                  >
                    <option value="popout">Popout</option>
                    <option value="dashboard">Dashboard</option>
                    <option value="agents">Agents</option>
                    <option value="chat">Chat</option>
                  </select>
                </label>
              </div>
              <div className="mt-2 grid gap-2">
                <textarea
                  value={usageReviewDraft}
                  onChange={(event) => setUsageReviewDraft(event.target.value)}
                  rows={3}
                  placeholder="Log what worked, what dragged, or what the cockpit should make clearer..."
                  className="rounded-sm border border-white/10 bg-black/30 px-2 py-1.5 text-[7px] outline-none"
                  style={{ color: 'rgba(165, 243, 252, 0.9)', resize: 'vertical' }}
                />
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={handleAddUsageReview}
                    disabled={!usageReviewDraft.trim()}
                    className="relay-popout-nav-button justify-center"
                    style={{
                      color: usageReviewDraft.trim() ? 'rgb(216, 180, 254)' : 'rgba(148, 163, 184, 0.56)',
                      borderColor: usageReviewDraft.trim() ? 'rgba(192, 132, 252, 0.24)' : 'rgba(148, 163, 184, 0.16)',
                      opacity: usageReviewDraft.trim() ? 1 : 0.6,
                    }}
                  >
                    <MessageSquare size={10} />
                    Save review
                  </button>
                  <button
                    type="button"
                    onClick={clearRelayUsageReviews}
                    disabled={relayUsageReviews.length === 0}
                    className="relay-popout-nav-button justify-center"
                    style={{
                      color: relayUsageReviews.length ? 'rgb(251, 191, 36)' : 'rgba(148, 163, 184, 0.56)',
                      borderColor: relayUsageReviews.length ? 'rgba(251, 191, 36, 0.20)' : 'rgba(148, 163, 184, 0.16)',
                      opacity: relayUsageReviews.length ? 1 : 0.6,
                    }}
                  >
                    <Trash2 size={10} />
                    Clear log
                  </button>
                </div>
              </div>
            </div>
            <div className="grid gap-2">
              {relayUsageReviews.length === 0 ? (
                <div className="rounded-sm border border-white/10 bg-black/20 px-2 py-2 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                  No local usage reviews yet. Save one when the cockpit feels strong, mixed, or rough.
                </div>
              ) : (
                relayUsageReviews.slice(0, 4).map((entry) => (
                  <div key={entry.id} className="rounded-sm border border-white/10 bg-black/20 px-2 py-2">
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                          <span>{entry.tone}</span>
                          <span>•</span>
                          <span>{entry.area}</span>
                          <span>•</span>
                          <span>{formatRelayUsageReviewTime(entry.createdAt)}</span>
                        </div>
                        <div className="mt-1 text-[7px]" style={{ color: 'rgba(165, 243, 252, 0.88)' }}>
                          {entry.note}
                        </div>
                        <div className="mt-1 text-[6px] leading-relaxed" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                          {entry.currentLane || 'No lane'} // {entry.activeAgent || 'No agent'} // {entry.currentObjective || 'No objective'}
                        </div>
                        <div className="mt-1 text-[6px] leading-relaxed" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                          Next move: {entry.nextSuggestedMove || 'Not set'} // Status: {entry.recentStatusSummary || 'Not set'}
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => removeRelayUsageReview(entry.id)}
                        className="relay-popout-nav-button justify-center px-2 py-1"
                        style={{ color: 'rgb(251, 191, 36)', borderColor: 'rgba(251, 191, 36, 0.20)' }}
                      >
                        <Trash2 size={9} />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </HudPanel>

        <HudPanel className="relay-popout-voice-panel px-3 py-2.5" cyan>
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5">
              <Volume2 size={10} style={{ color: 'rgb(103, 232, 249)' }} />
              <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Placeholder Voice</h2>
            </div>
            <span className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgb(134, 239, 172)' }}>
              Manual only
            </span>
          </div>
          <div className="mt-2 grid gap-2">
            <div className="grid grid-cols-2 gap-2">
              <MicroReadout
                label="Voice"
                value={voicePack?.active_voice || 'af_bella'}
                color="rgb(216, 180, 254)"
              />
              <MicroReadout
                label="Mode"
                value={voicePack?.active_mode || 'sarcastic'}
                color="rgb(103, 232, 249)"
              />
            </div>
            <div className="grid grid-cols-3 gap-2">
              <MicroReadout label="Style" value={voiceStyleLabel} color="rgb(134, 239, 172)" />
              <MicroReadout label="State" value={voiceStatusLabel} color="rgb(103, 232, 249)" />
              <MicroReadout label="Category" value={voiceCategory} color="rgb(196, 181, 253)" />
            </div>
            <div className="rounded-sm border border-white/10 bg-black/25 px-2 py-1.5 text-[7px] leading-relaxed">
              <div className="font-semibold uppercase tracking-[0.14em]" style={{ color: 'rgb(216, 180, 254)' }}>
                {voicePack?.public_label || 'Relay Companion'}
              </div>
              <div className="mt-1 truncate" style={{ color: 'rgba(165, 243, 252, 0.84)' }}>
                {voiceLine}
              </div>
              {voiceCategoryVariants.length > 1 && (
                <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(165, 243, 252, 0.68)' }}>
                  {relayCompanionCopy.popout.variantNote}
                </div>
              )}
              <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                {voicePackError || relayCompanionCopy.popout.voiceBehaviorNote}
              </div>
              <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                {relayCompanionCopy.popout.gateNote}
              </div>
            </div>
            <label className="grid gap-1 text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
              <span>Placeholder Category</span>
              <select
                value={voiceCategory}
                onChange={(event) => handleVoiceCategoryChange(event.target.value)}
                disabled={voiceRequestActive}
                className="rounded-sm border border-white/10 bg-black/35 px-2 py-1.5 text-[7px] uppercase tracking-[0.08em] outline-none"
                style={{ color: 'rgba(165, 243, 252, 0.9)' }}
              >
                {voiceCategoryOptions.map((category) => (
                  <option key={category} value={category}>
                    {category}
                  </option>
                ))}
              </select>
            </label>
            <div className="grid gap-1.5">
              <div className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                Event Voice Gates
              </div>
              <div className="grid gap-2 md:grid-cols-2">
                {eventTriggerStates.map((eventTrigger) => {
                  const enabled = settings[eventTrigger.key];
                  return (
                    <div
                      key={eventTrigger.key}
                      className="rounded-sm border border-white/10 bg-black/20 px-2 py-2"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="min-w-0">
                          <div
                            className="truncate text-[7px] font-semibold uppercase tracking-[0.12em]"
                            style={{ color: enabled ? 'rgb(134, 239, 172)' : 'rgb(216, 180, 254)' }}
                          >
                            {eventTrigger.label}
                          </div>
                          <div
                            className="truncate text-[6px] uppercase tracking-[0.1em]"
                            style={{ color: 'rgba(148, 163, 184, 0.7)' }}
                          >
                            {eventTrigger.category} // opt-in
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => updateSettings({ [eventTrigger.key]: !enabled })}
                          className="relay-popout-nav-button justify-center px-2 py-1"
                          style={{
                            color: enabled ? 'rgb(134, 239, 172)' : 'rgb(216, 180, 254)',
                            borderColor: enabled ? 'rgba(74, 222, 128, 0.24)' : 'rgba(192, 132, 252, 0.24)',
                          }}
                        >
                          {enabled ? <ToggleRight size={10} /> : <ToggleLeft size={10} />}
                          {enabled ? 'On' : 'Off'}
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={handleRunSelectedEvent}
                  disabled={!voiceControlsEnabled || voiceRequestActive || !selectedEventCategory}
                  className="relay-popout-nav-button justify-center"
                  style={{
                    color: !voiceControlsEnabled || !selectedEventCategory
                      ? 'rgba(148, 163, 184, 0.56)'
                      : 'rgb(103, 232, 249)',
                    borderColor: !voiceControlsEnabled || !selectedEventCategory
                      ? 'rgba(148, 163, 184, 0.16)'
                      : 'rgba(34, 211, 238, 0.24)',
                    opacity: !voiceControlsEnabled || !selectedEventCategory ? 0.6 : 1,
                  }}
                >
                  <PlayCircle size={10} />
                  {relayCompanionCopy.popout.runSelectedEvent}
                </button>
                <button
                  type="button"
                  onClick={handleRefreshRelayStatus}
                  disabled={statusRefreshPending || voiceRequestActive}
                  className="relay-popout-nav-button justify-center"
                  style={{
                    color: statusRefreshPending ? 'rgba(148, 163, 184, 0.56)' : 'rgb(134, 239, 172)',
                    borderColor: statusRefreshPending ? 'rgba(148, 163, 184, 0.16)' : 'rgba(74, 222, 128, 0.24)',
                    opacity: statusRefreshPending ? 0.6 : 1,
                  }}
                >
                  <Radio size={10} />
                  {statusRefreshPending ? relayCompanionCopy.popout.refreshingShort : relayCompanionCopy.popout.refreshStatus}
                </button>
              </div>
            </div>
            <div className="grid grid-cols-[auto_auto_1fr] gap-2">
              <button
                type="button"
                onClick={handleTogglePlaceholderVoice}
                className="relay-popout-nav-button justify-center"
                style={{
                  color: relayPlaceholderVoiceEnabled ? 'rgb(134, 239, 172)' : 'rgb(216, 180, 254)',
                  borderColor: relayPlaceholderVoiceEnabled ? 'rgba(74, 222, 128, 0.24)' : 'rgba(192, 132, 252, 0.24)',
                }}
              >
                {relayPlaceholderVoiceEnabled ? <ToggleRight size={11} /> : <ToggleLeft size={11} />}
                {relayPlaceholderVoiceEnabled ? 'Voice On' : 'Voice Off'}
              </button>
              <button
                type="button"
                onClick={handlePlayPlaceholderVoice}
                disabled={!voiceControlsEnabled || voiceRequestActive}
                className="relay-popout-nav-button justify-center"
                style={{
                  color: !voiceControlsEnabled
                    ? 'rgba(148, 163, 184, 0.56)'
                    : 'rgb(103, 232, 249)',
                  borderColor: !voiceControlsEnabled
                    ? 'rgba(148, 163, 184, 0.16)'
                    : 'rgba(34, 211, 238, 0.24)',
                  opacity: !voiceControlsEnabled ? 0.6 : 1,
                }}
              >
                <PlayCircle size={11} />
                {voicePlaybackState === 'generating'
                  ? 'Generating...'
                  : voicePlaybackState === 'playing'
                    ? 'Playing...'
                    : relayCompanionCopy.popout.playTestLine}
              </button>
              <div className="min-w-0 text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                <div className="truncate">Category: {voiceCategory}</div>
                <div className="truncate">Variants: {voiceCategoryVariants.length || 1}</div>
                <div className="truncate">Style: {voiceStyleLabel}</div>
                <div className="truncate">State: {voicePlaybackNote}</div>
                <div className="truncate">Detail: {voicePlaybackDetail}</div>
              </div>
            </div>
          </div>
        </HudPanel>
          </>
        )}

        <footer
          className={`relay-popout-footer mt-auto grid gap-2 ${relaySimpleModeEnabled ? 'grid-cols-3' : 'grid-cols-2'}`}
        >
          <button
            type="button"
            onClick={() => navigate('/dashboard')}
            className="relay-popout-nav-button"
            style={{ color: 'rgb(103, 232, 249)', borderColor: 'rgba(34, 211, 238, 0.22)' }}
          >
            <ArrowLeft size={11} />
            {relaySimpleModeEnabled ? 'Dashboard' : 'Dashboard'}
          </button>
          {relaySimpleModeEnabled && (
            <button
              type="button"
              onClick={() => navigate('/agents')}
              className="relay-popout-nav-button"
              style={{ color: 'rgb(216, 180, 254)', borderColor: 'rgba(192, 132, 252, 0.22)' }}
            >
              <Bot size={11} />
              Agents
            </button>
          )}
          <button
            type="button"
            onClick={() => navigate('/chat')}
            className="relay-popout-nav-button"
            style={{ color: 'rgb(216, 180, 254)', borderColor: 'rgba(192, 132, 252, 0.22)' }}
          >
            <MessageSquare size={11} />
            {relaySimpleModeEnabled ? 'Chat' : 'Full Chat'}
            <ExternalLink size={9} />
          </button>
        </footer>
      </main>
    </div>
  );
}
