import React from "react";
import { Navigate } from "@tanstack/react-router";
import { useAuth } from "@/lib/auth";

export function Guard({
  stage,
  children,
}: {
  stage: "auth" | "name" | "avatar" | "app";
  children: React.ReactNode;
}) {
  const { user, profile, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-slate-950 text-white">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500" />
      </div>
    );
  }

  if (stage === "auth") {
    if (!user) return <>{children}</>;
    if (!profile?.username) return <Navigate to="/onboarding/name" replace />;
    if (!profile?.onboarded) return <Navigate to="/onboarding/avatar" replace />;
    return <Navigate to="/" replace />;
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  if (stage === "name") {
    if (profile?.username) return <Navigate to="/onboarding/avatar" replace />;
    return <>{children}</>;
  }

  if (stage === "avatar") {
    if (!profile?.username) return <Navigate to="/onboarding/name" replace />;
    if (profile?.onboarded) return <Navigate to="/" replace />;
    return <>{children}</>;
  }

  if (stage === "app") {
    if (!profile?.username) return <Navigate to="/onboarding/name" replace />;
    if (!profile?.onboarded) return <Navigate to="/onboarding/avatar" replace />;
    return <>{children}</>;
  }

  return <>{children}</>;
}
import React, { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import type { User, Session } from "@supabase/supabase-js";

interface Profile {
  id: string;
  username: string | null;
  display_name: string | null;
  avatar_url: string | null;
  onboarded: boolean;
}

interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: Profile | null;
  loading: boolean;
  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  session: null,
  profile: null,
  loading: true,
  refreshProfile: async () => {},
  signOut: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchProfile = async (uid: string) => {
    try {
      const { data } = await supabase
        .from("profiles")
        .select("id, username, display_name, avatar_url, onboarded")
        .eq("id", uid)
        .single();
      if (data) setProfile(data as Profile);
    } catch (err) {
      console.error("Error fetching profile:", err);
    }
  };

  const refreshProfile = async () => {
    if (user?.id) await fetchProfile(user.id);
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user?.id) fetchProfile(session.user.id);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user?.id) {
        await fetchProfile(session.user.id);
      } else {
        setProfile(null);
      }
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signOut = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setSession(null);
    setProfile(null);
  };

  return (
    <AuthContext.Provider value={{ user, session, profile, loading, refreshProfile, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
@import "tailwindcss";

:root {
  --background: #0f172a;
  --foreground: #f8fafc;
  --primary: #10b981;
  --primary-foreground: #022c22;
  --card: #1e293b;
  --card-foreground: #f8fafc;
  --border: #334155;
}

* {
  border-color: var(--border);
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 0;
  background-color: var(--background);
  color: var(--foreground);
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  direction: rtl;
  user-select: none;
  -webkit-user-select: none;
  overflow-x: hidden;
}

button {
  cursor: pointer;
}
{
  "name": "chat-bubble-palace",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@react-three/drei": "^9.121.4",
    "@react-three/fiber": "^8.17.14",
    "@supabase/supabase-js": "^2.49.1",
    "@tanstack/react-router": "^1.114.17",
    "@tanstack/react-start": "^1.114.17",
    "clsx": "^2.1.1",
    "lucide-react": "^0.475.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "sonner": "^2.0.1",
    "tailwind-merge": "^3.0.1",
    "three": "^0.173.0"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.0.6",
    "@types/node": "^22.13.4",
    "@types/react": "^19.0.8",
    "@types/react-dom": "^19.0.3",
    "@types/three": "^0.173.0",
    "@vitejs/plugin-react": "^4.3.4",
    "tailwindcss": "^4.0.6",
    "typescript": "^5.7.3",
    "vite": "^6.1.0"
  }
}
import React, { useState } from "react";
import { useParams, useNavigate } from "@tanstack/react-router";
import { useAuth } from "@/lib/auth";
import { useGame, leaveGame } from "@/lib/game";
import { GlassBridge } from "@/components/game/GlassBridge";
import { showRewardedAd } from "@/lib/ads";
import { Heart, Settings, ShieldAlert, Award, Plane } from "lucide-react";

export function GamePage() {
  const { id } = useParams({ from: "/game/$id" });
  const { user } = useAuth();
  const navigate = useNavigate();
  const { game, players, loading } = useGame(id);

  const [lives, setLives] = useState(4);
  const [adOpen, setAdOpen] = useState(false);
  const [adSeconds, setAdSeconds] = useState(5);
  const [flying, setFlying] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);

  const [moveInput, setMoveInput] = useState({ x: 0, z: 0 });
  const [jumpTick, setJumpTick] = useState(0);

  const isOwner = game?.creator_id === user?.id;

  const handleFall = () => {
    if (lives > 1) {
      setLives((prev) => prev - 1);
    } else {
      setAdOpen(true);
      showRewardedAd((sec) => setAdSeconds(sec)).then(() => {
        setLives(4);
        setAdOpen(false);
      });
    }
  };

  const handleWin = () => {
    alert("🎉 مبروك! نجحت بعبور جسر الزجاج!");
  };

  if (loading || !game) {
    return <div className="text-white p-6 text-center">جاري تحميل اللعبة...</div>;
  }

  return (
    <div className="relative w-screen h-screen overflow-hidden bg-slate-950 select-none">
      {/* مشهد الـ 3D */}
      <GlassBridge
        pattern={game.pattern}
        isOwner={isOwner}
        flying={flying}
        moveInput={moveInput}
        jumpTick={jumpTick}
        flyElevation={flying ? 3.5 : 0}
        onFall={handleFall}
        onWin={handleWin}
        players={players}
        myUserId={user?.id || ""}
      />

      {/* الشريط العلوي: القلوب والإعدادات */}
      <div className="absolute top-4 inset-x-4 flex items-center justify-between pointer-events-none">
        {/* قلوب اللاعب */}
        <div className="flex gap-1 bg-black/60 p-2 rounded-xl backdrop-blur-md pointer-events-auto">
          {Array.from({ length: 4 }).map((_, i) => (
            <Heart
              key={i}
              className={`w-6 h-6 ${i < lives ? "text-red-500 fill-red-500" : "text-gray-600"}`}
            />
          ))}
        </div>

        {/* زر الإعدادات للمالك */}
        {isOwner && (
          <button
            onClick={() => setSettingsOpen(true)}
            className="p-3 bg-slate-800/80 text-white rounded-full backdrop-blur-md pointer-events-auto"
          >
            <Settings className="w-6 h-6" />
          </button>
        )}
      </div>

      {/* أزرار التحكم باللمس (موبايل) */}
      <div className="absolute bottom-6 inset-x-6 flex items-center justify-between pointer-events-none">
        {/* اتجاهات المشي */}
        <div className="grid grid-cols-3 gap-2 pointer-events-auto">
          <div />
          <button
            onPointerDown={() => setMoveInput({ x: 0, z: 1 })}
            onPointerUp={() => setMoveInput({ x: 0, z: 0 })}
            className="w-14 h-14 bg-white/20 rounded-2xl active:bg-white/40 flex items-center justify-center text-white text-xl"
          >
            ⬆️
          </button>
          <div />
          <button
            onPointerDown={() => setMoveInput({ x: -1, z: 0 })}
            onPointerUp={() => setMoveInput({ x: 0, z: 0 })}
            className="w-14 h-14 bg-white/20 rounded-2xl active:bg-white/40 flex items-center justify-center text-white text-xl"
          >
            ⬅️
          </button>
          <div />
          <button
            onPointerDown={() => setMoveInput({ x: 1, z: 0 })}
            onPointerUp={() => setMoveInput({ x: 0, z: 0 })}
            className="w-14 h-14 bg-white/20 rounded-2xl active:bg-white/40 flex items-center justify-center text-white text-xl"
          >
            ➡️
          </button>
        </div>

        {/* أزرار القفز والطيران */}
        <div className="flex flex-col gap-3 pointer-events-auto">
          {isOwner && (
            <button
              onClick={() => setFlying(!flying)}
              className={`p-4 rounded-full ${flying ? "bg-amber-500 text-black" : "bg-white/20 text-white"}`}
            >
              <Plane className="w-7 h-7" />
            </button>
          )}

          <button
            onClick={() => setJumpTick((t) => t + 1)}
            className="w-16 h-16 bg-emerald-500 rounded-full flex items-center justify-center text-white text-lg font-bold shadow-lg active:scale-95"
          >
            قفز
          </button>
        </div>
      </div>

      {/* نافذة الإعلان والمكافأة عند نفاد المحاولات */}
      {adOpen && (
        <div className="absolute inset-0 bg-black/90 flex flex-col items-center justify-center p-6 text-center z-50">
          <ShieldAlert className="w-16 h-16 text-amber-400 mb-4 animate-bounce" />
          <h2 className="text-2xl font-bold text-white mb-2">انتهت كل محاولاتك!</h2>
          <p className="text-slate-300 mb-6">شاهد إعلاناً قصيراً لاستعادة 4 أرواح والعودة فوراً للعب</p>
          <div className="text-emerald-400 font-mono text-xl">
            جاري استعادة الأرواح خلال: {adSeconds} ثانية...
          </div>
        </div>
      )}

      {/* قائمة إعدادات المالك */}
      {settingsOpen && (
        <div className="absolute inset-0 bg-black/80 flex items-center justify-center p-4 z-40">
          <div className="bg-slate-900 border border-slate-700 w-full max-w-sm rounded-2xl p-6">
            <h3 className="text-xl font-bold text-white mb-4">إدارة الجولة</h3>
            <div className="flex flex-col gap-3">
              <button
                onClick={() => {
                  leaveGame(id, user?.id || "");
                  navigate({ to: "/chat" });
                }}
                className="w-full py-3 bg-red-600 rounded-xl text-white font-medium"
              >
                إنهاء ومغادرة اللعبة
              </button>
              <button
                onClick={() => setSettingsOpen(false)}
                className="w-full py-3 bg-slate-800 rounded-xl text-white font-medium"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
import React, { useRef, useState, useEffect } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Text } from "@react-three/drei";
import * as THREE from "three";
import { ROWS } from "@/lib/game";

interface Props {
  pattern: ("L" | "R")[];
  isOwner: boolean;
  flying: boolean;
  moveInput: { x: number; z: number };
  jumpTick: number;
  flyElevation: number;
  onFall: () => void;
  onWin: () => void;
  players: any[];
  myUserId: string;
}

function RobloxCharacter({ position, name, color, isMe }: any) {
  return (
    <group position={position}>
      {/* اسم اللاعب فوق الرأس */}
      <Text
        position={[0, 1.8, 0]}
        fontSize={0.28}
        color={isMe ? "#facc15" : "#ffffff"}
        anchorX="center"
        anchorY="middle"
      >
        {name || "لاعب"}
      </Text>

      {/* الرأس المكعبي */}
      <mesh position={[0, 1.25, 0]}>
        <boxGeometry args={[0.4, 0.4, 0.4]} />
        <meshStandardMaterial color="#fcd34d" />
      </mesh>

      {/* الجسد */}
      <mesh position={[0, 0.7, 0]}>
        <boxGeometry args={[0.5, 0.7, 0.3]} />
        <meshStandardMaterial color={color || "#3b82f6"} />
      </mesh>

      {/* اليدان */}
      <mesh position={[-0.35, 0.7, 0]}>
        <boxGeometry args={[0.18, 0.65, 0.2]} />
        <meshStandardMaterial color={color || "#3b82f6"} />
      </mesh>
      <mesh position={[0.35, 0.7, 0]}>
        <boxGeometry args={[0.18, 0.65, 0.2]} />
        <meshStandardMaterial color={color || "#3b82f6"} />
      </mesh>

      {/* القدمان */}
      <mesh position={[-0.15, 0.15, 0]}>
        <boxGeometry args={[0.2, 0.4, 0.25]} />
        <meshStandardMaterial color="#1e293b" />
      </mesh>
      <mesh position={[0.15, 0.15, 0]}>
        <boxGeometry args={[0.2, 0.4, 0.25]} />
        <meshStandardMaterial color="#1e293b" />
      </mesh>
    </group>
  );
}

function BridgeScene({
  pattern,
  flying,
  moveInput,
  jumpTick,
  flyElevation,
  onFall,
  onWin,
  myUserId,
}: Props) {
  const [pos, setPos] = useState<[number, number, number]>([0, 0, 0]);
  const [brokenTiles, setBrokenTiles] = useState<Record<number, "L" | "R">>({});
  const jumpingRef = useRef(false);
  const vyRef = useRef(0);

  useEffect(() => {
    if (!flying && !jumpingRef.current) {
      jumpingRef.current = true;
      vyRef.current = 0.18;
    }
  }, [jumpTick]);

  useFrame(() => {
    setPos(([px, py, pz]) => {
      let nx = px + moveInput.x * (flying ? 0.25 : 0.12);
      let nz = pz + moveInput.z * (flying ? 0.25 : 0.12);
      let ny = py;

      if (flying) {
        ny = THREE.MathUtils.lerp(ny, flyElevation, 0.1);
      } else {
        if (jumpingRef.current) {
          ny += vyRef.current;
          vyRef.current -= 0.012; // الجاذبية
          if (ny <= 0) {
            ny = 0;
            jumpingRef.current = false;
            vyRef.current = 0;
          }
        }

        // فحص الوقوع على الألواح
        const rowIndex = Math.floor(nz / 2.5);
        if (rowIndex >= 0 && rowIndex < ROWS && ny <= 0.05) {
          const side = nx < 0 ? "L" : "R";
          const safeSide = pattern[rowIndex];
          if (side !== safeSide && !brokenTiles[rowIndex]) {
            setBrokenTiles((b) => ({ ...b, [rowIndex]: side }));
            onFall();
            return [0, 0, 0];
          }
        }

        // الفوز بعد نهاية الجسر
        if (nz > ROWS * 2.5 + 1) {
          onWin();
        }
      }

      return [nx, ny, nz];
    });
  });

  return (
    <>
      <ambientLight intensity={0.7} />
      <directionalLight position={[10, 20, 15]} intensity={1.2} />

      {/* منصة البداية */}
      <mesh position={[0, -0.2, -2]}>
        <boxGeometry args={[4, 0.4, 4]} />
        <meshStandardMaterial color="#334155" />
      </mesh>

      {/* صفوف الزجاج */}
      {Array.from({ length: ROWS }).map((_, i) => {
        const z = i * 2.5 + 1.5;
        const isLeftBroken = brokenTiles[i] === "L";
        const isRightBroken = brokenTiles[i] === "R";

        return (
          <group key={i}>
            {/* اللوح الأيسر */}
            {!isLeftBroken && (
              <mesh position={[-1, -0.05, z]}>
                <boxGeometry args={[1.4, 0.1, 1.8]} />
                <meshPhysicalMaterial
                  color="#93c5fd"
                  transmission={0.8}
                  roughness={0.1}
                  transparent
                  opacity={0.6}
                />
              </mesh>
            )}

            {/* اللوح الأيمن */}
            {!isRightBroken && (
              <mesh position={[1, -0.05, z]}>
                <boxGeometry args={[1.4, 0.1, 1.8]} />
                <meshPhysicalMaterial
                  color="#93c5fd"
                  transmission={0.8}
                  roughness={0.1}
                  transparent
                  opacity={0.6}
                />
              </mesh>
            )}
          </group>
        );
      })}

      {/* منصة الفوز */}
      <mesh position={[0, -0.2, ROWS * 2.5 + 3.5]}>
        <boxGeometry args={[5, 0.4, 4]} />
        <meshStandardMaterial color="#059669" />
      </mesh>

      {/* شخصية اللاعب */}
      <RobloxCharacter position={pos} name="أنت" color="#10b981" isMe={true} />
    </>
  );
}

export function GlassBridge(props: Props) {
  return (
    <Canvas
      camera={{ position: [0, 4, -4], fov: 60 }}
      className="w-full h-full bg-slate-950"
    >
      <BridgeScene {...props} />
    </Canvas>
  );
}
export const ADMOB_APP_ID = "ca-app-pub-3697262724438378~4622934925";
export const REWARDED_AD_UNIT = "ca-app-pub-3697262724438378/4788344043";

export function showRewardedAd(onTick: (secondsLeft: number) => void): Promise<boolean> {
  return new Promise((resolve) => {
    let left = 5;
    onTick(left);

    const timer = setInterval(() => {
      left -= 1;
      onTick(left);
      if (left <= 0) {
        clearInterval(timer);
        resolve(true);
      }
    }, 1000);
  });
}
import { supabase } from "@/integrations/supabase/client";
import { useEffect, useState } from "react";

export const MAX_PLAYERS = 7;
export const ROWS = 12;

export interface GameRow {
  id: string;
  room_id: string;
  creator_id: string;
  status: "lobby" | "in_progress" | "ended";
  pattern: ("L" | "R")[];
  prize_description: string | null;
  winner_id: string | null;
  created_at: string;
}

export interface PlayerRow {
  id: string;
  game_id: string;
  user_id: string;
  joined_at: string;
  profile?: {
    username: string | null;
    display_name: string | null;
    avatar_url: string | null;
  };
}

export function makePattern(rows = ROWS): ("L" | "R")[] {
  const arr: ("L" | "R")[] = [];
  for (let i = 0; i < rows; i++) {
    arr.push(Math.random() < 0.5 ? "L" : "R");
  }
  return arr;
}

export function useGame(gameId: string) {
  const [game, setGame] = useState<GameRow | null>(null);
  const [players, setPlayers] = useState<PlayerRow[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAll = async () => {
    const { data: g } = await supabase.from("games").select("*").eq("id", gameId).single();
    if (g) setGame(g as GameRow);

    const { data: p } = await supabase
      .from("game_players")
      .select("*, profile:profiles(username, display_name, avatar_url)")
      .eq("game_id", gameId);
    if (p) setPlayers(p as any);
    setLoading(false);
  };

  useEffect(() => {
    fetchAll();

    const ch = supabase
      .channel(`game_${gameId}`)
      .on("postgres_changes", { event: "*", schema: "public", table: "games", filter: `id=eq.${gameId}` }, () => {
        fetchAll();
      })
      .on("postgres_changes", { event: "*", schema: "public", table: "game_players", filter: `game_id=eq.${gameId}` }, () => {
        fetchAll();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(ch);
    };
  }, [gameId]);

  return { game, players, loading, refetch: fetchAll };
}

export async function createGame(roomId: string, creatorId: string) {
  const pattern = makePattern();
  const { data, error } = await supabase
    .from("games")
    .insert({
      room_id: roomId,
      creator_id: creatorId,
      pattern,
      status: "lobby",
      prize_description: "وسام الشجاعة 🏆",
    })
    .select()
    .single();

  if (error) throw error;

  await supabase.from("game_players").insert({
    game_id: data.id,
    user_id: creatorId,
  });

  return data as GameRow;
}

export async function joinGame(gameId: string, userId: string) {
  const { error } = await supabase.from("game_players").insert({
    game_id: gameId,
    user_id: userId,
  });
  if (error) throw error;
}

export async function leaveGame(gameId: string, userId: string) {
  await supabase.from("game_players").delete().eq("game_id", gameId).eq("user_id", userId);
}
import React, { useState, useEffect, useRef } from "react";
import { useAuth } from "@/lib/auth";
import { supabase } from "@/integrations/supabase/client";
import { uploadChatFile, getSignedMediaUrl, type MsgKind } from "@/lib/media";
import { createGame } from "@/lib/game";
import { GameCard } from "@/components/GameCard";
import {
  Send,
  Plus,
  Image,
  Video,
  MapPin,
  Gamepad2,
  Trash2,
  X,
} from "lucide-react";

interface Message {
  id: string;
  sender_id: string;
  content: string;
  kind: MsgKind;
  metadata: any;
  created_at: string;
  sender?: {
    username: string | null;
    display_name: string | null;
    avatar_url: string | null;
  };
}

export function ChatPage() {
  const { user, profile } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState("");
  const [plusMenuOpen, setPlusMenuOpen] = useState(false);
  const [signedUrls, setSignedUrls] = useState<Record<string, string>>({});
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [fileTypeToUpload, setFileTypeToUpload] = useState<"image" | "video">("image");

  // التمرير لآخر رسالة
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  // جلب الرسائل
  const fetchMessages = async () => {
    const { data } = await supabase
      .from("public_messages")
      .select("*, sender:profiles(username, display_name, avatar_url)")
      .order("created_at", { ascending: true })
      .limit(100);

    if (data) {
      setMessages(data as any);
      // تحضير الروابط الموقعة للوسائط
      for (const m of data) {
        if ((m.kind === "image" || m.kind === "video") && m.content) {
          getSignedMediaUrl(m.content).then((url) => {
            if (url) {
              setSignedUrls((prev) => ({ ...prev, [m.content]: url }));
            }
          });
        }
      }
    }
  };

  useEffect(() => {
    fetchMessages();

    // الاستماع للرسائل الجديدة فوراً بـ Realtime
    const ch = supabase
      .channel("public_chat")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "public_messages" },
        (payload) => {
          fetchMessages();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(ch);
    };
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // إرسال رسالة نصية
  const handleSendText = async () => {
    if (!inputText.trim() || !user) return;
    const text = inputText;
    setInputText("");

    await supabase.from("public_messages").insert({
      sender_id: user.id,
      content: text,
      kind: "text",
    });
  };

  // إرسال صورة أو فيديو
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    try {
      const path = await uploadChatFile(user.id, file);
      await supabase.from("public_messages").insert({
        sender_id: user.id,
        content: path,
        kind: fileTypeToUpload,
      });
      setPlusMenuOpen(false);
    } catch (err) {
      alert("حدث خطأ أثناء رفع الملف");
    }
  };

  // إرسال الموقع الحالي
  const handleSendLocation = () => {
    if (!navigator.geolocation || !user) {
      alert("خدمة تحديد الموقع غير مدعومة بجهازك");
      return;
    }
    navigator.geolocation.getCurrentPosition(async (pos) => {
      const url = `https://maps.google.com/?q=${pos.coords.latitude},${pos.coords.longitude}`;
      await supabase.from("public_messages").insert({
        sender_id: user.id,
        content: url,
        kind: "location",
      });
      setPlusMenuOpen(false);
    });
  };

  // إنشاء لعبة جسر الزجاج من زر ➕
  const handleCreateGame = async () => {
    if (!user) return;
    try {
      const game = await createGame("general", user.id);
      await supabase.from("public_messages").insert({
        sender_id: user.id,
        content: game.id,
        kind: "game",
        metadata: {
          prize_description: game.prize_description,
        },
      });
      setPlusMenuOpen(false);
    } catch (err) {
      alert("تعذر إنشاء اللعبة حالياً");
    }
  };

  return (
    <div className="flex flex-col h-screen bg-slate-950 text-white">
      {/* الترويسة العلوية */}
      <header className="p-4 border-b border-slate-800 bg-slate-900/90 flex items-center justify-between">
        <div>
          <h1 className="font-bold text-lg text-emerald-400">شات نور المؤمنين</h1>
          <p className="text-xs text-slate-400">الدردشة الجماعية العامة</p>
        </div>
      </header>

      {/* منطقة عرض الرسائل */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg) => {
          const isMe = msg.sender_id === user?.id;
          return (
            <div
              key={msg.id}
              className={`flex gap-2.5 ${isMe ? "flex-row-reverse" : "flex-row"}`}
            >
              {/* صورة المرسل */}
              <div className="w-9 h-9 rounded-full bg-slate-800 overflow-hidden shrink-0 border border-slate-700">
                {msg.sender?.avatar_url ? (
                  <img
                    src={msg.sender.avatar_url}
                    alt=""
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-xs text-slate-400">
                    👤
                  </div>
                )}
              </div>

              {/* فقاعة المحتوى */}
              <div
                className={`max-w-[75%] rounded-2xl p-3 text-sm ${
                  isMe
                    ? "bg-emerald-600 text-white rounded-tr-none"
                    : "bg-slate-800 text-slate-200 rounded-tl-none border border-slate-700"
                }`}
              >
                {!isMe && (
                  <div className="text-xs font-bold text-emerald-400 mb-1">
                    {msg.sender?.display_name || msg.sender?.username || "عضو"}
                  </div>
                )}

                {/* نص عادي */}
                {msg.kind === "text" && <p className="break-words">{msg.content}</p>}

                {/* صورة */}
                {msg.kind === "image" && (
                  <img
                    src={signedUrls[msg.content] || ""}
                    alt="صورة"
                    className="rounded-xl max-h-60 w-full object-cover"
                  />
                )}

                {/* فيديو */}
                {msg.kind === "video" && (
                  <video
                    src={signedUrls[msg.content] || ""}
                    controls
                    className="rounded-xl max-h-60 w-full"
                  />
                )}

                {/* موقع */}
                {msg.kind === "location" && (
                  <a
                    href={msg.content}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center gap-2 text-amber-300 underline"
                  >
                    <MapPin className="w-4 h-4" />
                    <span>عرض الموقع على الخريطة</span>
                  </a>
                )}

                {/* بطاقة اللعبة */}
                {msg.kind === "game" && (
                  <GameCard
                    gameId={msg.content}
                    creatorName={msg.sender?.display_name || "المنشئ"}
                    prizeDescription={msg.metadata?.prize_description}
                    playerCount={1}
                    playerAvatars={[msg.sender?.avatar_url || ""]}
                  />
                )}
              </div>
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* قائمة زر ➕ للوسائط */}
      {plusMenuOpen && (
        <div className="p-3 bg-slate-900 border-t border-slate-800 grid grid-cols-4 gap-2">
          <button
            onClick={() => {
              setFileTypeToUpload("image");
              fileInputRef.current?.click();
            }}
            className="flex flex-col items-center gap-1.5 p-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs"
          >
            <Image className="w-6 h-6 text-emerald-400" />
            <span>صورة</span>
          </button>

          <button
            onClick={() => {
              setFileTypeToUpload("video");
              fileInputRef.current?.click();
            }}
            className="flex flex-col items-center gap-1.5 p-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs"
          >
            <Video className="w-6 h-6 text-blue-400" />
            <span>فيديو</span>
          </button>

          <button
            onClick={handleSendLocation}
            className="flex flex-col items-center gap-1.5 p-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs"
          >
            <MapPin className="w-6 h-6 text-red-400" />
            <span>موقع</span>
          </button>

          <button
            onClick={handleCreateGame}
            className="flex flex-col items-center gap-1.5 p-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs"
          >
            <Gamepad2 className="w-6 h-6 text-amber-400" />
            <span>الألعاب</span>
          </button>
        </div>
      )}

      {/* إدخال الملفات الخفي */}
      <input
        ref={fileInputRef}
        type="file"
        accept={fileTypeToUpload === "image" ? "image/*" : "video/*"}
        onChange={handleFileUpload}
        className="hidden"
      />

      {/* حقل كتابة الرسائل */}
      <div className="p-3 bg-slate-900 border-t border-slate-800 flex items-center gap-2">
        <button
          onClick={() => setPlusMenuOpen(!plusMenuOpen)}
          className="p-2.5 rounded-full bg-slate-800 hover:bg-slate-700 text-slate-300"
        >
          {plusMenuOpen ? <X className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
        </button>

        <input
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSendText()}
          placeholder="اكتب رسالة في نور المؤمنين..."
          className="flex-1 bg-slate-800 border border-slate-700 rounded-full px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500"
        />

        <button
          onClick={handleSendText}
          className="p-2.5 rounded-full bg-emerald-500 hover:bg-emerald-600 text-white"
        >
          <Send className="w-5 h-5 rtl:rotate-180" />
        </button>
      </div>
    </div>
  );
}
import React from "react";
import { useNavigate } from "@tanstack/react-router";
import { Users, Play, Trophy } from "lucide-react";
import { MAX_PLAYERS } from "@/lib/game";

interface Props {
  gameId: string;
  creatorName: string;
  prizeDescription?: string;
  playerCount: number;
  playerAvatars: string[];
}

export function GameCard({
  gameId,
  creatorName,
  prizeDescription,
  playerCount,
  playerAvatars,
}: Props) {
  const navigate = useNavigate();

  return (
    <div className="relative overflow-hidden rounded-2xl border border-amber-500/30 bg-slate-900/80 p-4 backdrop-blur-xl shadow-xl max-w-sm">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="text-2xl">🎲</span>
          <div>
            <h4 className="font-bold text-white text-sm">تحدي جسر الزجاج</h4>
            <p className="text-xs text-slate-400">بواسطة: {creatorName}</p>
          </div>
        </div>
        <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/30">
          {playerCount} / {MAX_PLAYERS} لاعبين
        </span>
      </div>

      {prizeDescription && (
        <div className="flex items-center gap-1.5 text-xs text-amber-400 mb-3 bg-amber-950/30 p-2 rounded-lg border border-amber-800/30">
          <Trophy className="w-4 h-4 shrink-0" />
          <span>الجائزة: {prizeDescription}</span>
        </div>
      )}

      {/* صور اللاعبين المشاركين */}
      <div className="flex items-center gap-1.5 mb-4">
        {Array.from({ length: MAX_PLAYERS }).map((_, i) => (
          <div
            key={i}
            className="w-8 h-8 rounded-full border border-slate-700 bg-slate-800 flex items-center justify-center overflow-hidden text-xs text-slate-500"
          >
            {playerAvatars[i] ? (
              <img
                src={playerAvatars[i]}
                alt="avatar"
                className="w-full h-full object-cover"
              />
            ) : (
              <span>{i + 1}</span>
            )}
          </div>
        ))}
      </div>

      {/* زر دخول اللعبة */}
      <button
        onClick={() => navigate({ to: `/game/${gameId}` })}
        className="w-full py-2.5 px-4 bg-gradient-to-r from-amber-500 to-emerald-600 hover:from-amber-600 hover:to-emerald-700 text-white font-bold rounded-xl flex items-center justify-center gap-2 shadow-lg transition active:scale-95"
      >
        <Play className="w-4 h-4 fill-white" />
        <span>دخول الجولة واللعب</span>
      </button>
    </div>
  );
}
import { supabase } from "@/integrations/supabase/client";

export type MsgKind = "text" | "image" | "video" | "location" | "game";

export interface SendPayload {
  kind: MsgKind;
  content: string;
  metadata?: Record<string, any>;
}

// رفع الصور والمقاطع إلى الباكت المخصص
export async function uploadChatFile(
  userId: string,
  file: File
): Promise<string> {
  const ext = file.name.split(".").pop() || "bin";
  const path = `${userId}/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;

  const { error } = await supabase.storage
    .from("chat-media")
    .upload(path, file, {
      cacheControl: "3600",
      upsert: false,
    });

  if (error) throw error;
  return path;
}

// جلب رابط موقّع لعرض الوسائط الخاصة بأمان
export async function getSignedMediaUrl(path: string): Promise<string | null> {
  if (!path) return null;
  if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("data:")) {
    return path;
  }

  const { data, error } = await supabase.storage
    .from("chat-media")
    .createSignedUrl(path, 60 * 60 * 24); // صالح لمدة 24 ساعة

  if (error || !data) return null;
  return data.signedUrl;
}
-- 1. جدول الحسابات الشخصية
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  onboarded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- تريغر لإنشاء profile تلقائياً عند تسجيل الدخول بجوجل
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'مؤمن'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. جدول الرتب والصلاحيات
CREATE TYPE public.app_role AS ENUM ('owner', 'admin');

CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Roles viewable by everyone" ON public.user_roles FOR SELECT USING (true);

-- 3. جدول رسائل شات نور المؤمنين
CREATE TABLE public.public_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  kind TEXT NOT NULL DEFAULT 'text',
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.public_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Messages viewable by everyone" ON public.public_messages FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert messages" ON public.public_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- 4. جدول ألعاب جسر الزجاج
CREATE TABLE public.games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL DEFAULT 'general',
  creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'lobby',
  pattern TEXT[] NOT NULL,
  prize_description TEXT,
  winner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Games viewable by everyone" ON public.games FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create games" ON public.games FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Creator can update their game" ON public.games FOR UPDATE USING (auth.uid() = creator_id);

-- 5. جدول لاعبي الجولة (بحد أقصى 7 لاعبين)
CREATE TABLE public.game_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(game_id, user_id)
);

ALTER TABLE public.game_players ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Game players viewable by everyone" ON public.game_players FOR SELECT USING (true);
CREATE POLICY "Authenticated users can join games" ON public.game_players FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave or creator can kick" ON public.game_players FOR DELETE USING (
  auth.uid() = user_id OR 
  auth.uid() IN (SELECT creator_id FROM public.games WHERE id = game_id)
);
import React, { useEffect, useRef } from "react";
import { calculatePrayerTimes, type PrayerTimes } from "@/lib/adhan";

interface Props {
  enabled: boolean;
  adhanAudioUrl: string;
  volume?: number;
  latitude?: number;
  longitude?: number;
}

export function AdhanScheduler({
  enabled,
  adhanAudioUrl,
  volume = 0.8,
  latitude = 33.3152, // بغداد كافتراضي
  longitude = 44.3661,
}: Props) {
  const lastPlayedRef = useRef<string>("");
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    if (!audioRef.current) {
      audioRef.current = new Audio(adhanAudioUrl);
    } else {
      audioRef.current.src = adhanAudioUrl;
    }
    audioRef.current.volume = volume;
  }, [adhanAudioUrl, volume]);

  useEffect(() => {
    if (!enabled) return;

    const checkInterval = setInterval(() => {
      const now = new Date();
      const currentHours = String(now.getHours()).padStart(2, "0");
      const currentMinutes = String(now.getMinutes()).padStart(2, "0");
      const currentTimeStr = `${currentHours}:${currentMinutes}`;

      const prayers = calculatePrayerTimes(now, latitude, longitude);
      const prayerList: (keyof PrayerTimes)[] = ["fajr", "dhuhr", "asr", "maghrib", "isha"];

      for (const prayer of prayerList) {
        if (prayers[prayer] === currentTimeStr && lastPlayedRef.current !== `${prayer}_${currentTimeStr}`) {
          lastPlayedRef.current = `${prayer}_${currentTimeStr}`;
          
          // تشغيل صوت الأذان
          audioRef.current?.play().catch(() => {
            console.log("المتصفح يتطلب تفاعل المستخدم أولاً لتشغيل الصوت");
          });

          // إرسال إشعار على الجهاز
          if ("Notification" in window && Notification.permission === "granted") {
            new Notification("حان الآن موعد الصلاة", {
              body: `الله أكبر، حان الآن موعد أذان ${prayer} حسب التوقيت المحلي`,
              icon: "/favicon.ico",
            });
          }
          break;
        }
      }
    }, 10000); // فحص كل 10 ثوانٍ

    return () => clearInterval(checkInterval);
  }, [enabled, latitude, longitude]);

  return null;
}
export type CalculationMethod =
  | "Jafari"
  | "Tehran"
  | "MWL"
  | "ISNA"
  | "Egypt"
  | "Makkah"
  | "Karachi";

export interface PrayerTimes {
  fajr: string;
  sunrise: string;
  dhuhr: string;
  asr: string;
  maghrib: string;
  isha: string;
}

interface MethodParams {
  fajrAngle: number;
  maghribAngle?: number;
  maghribMinutes?: number;
  ishaAngle?: number;
  ishaMinutes?: number;
}

const METHODS: Record<CalculationMethod, MethodParams> = {
  Jafari: { fajrAngle: 16.0, maghribAngle: 4.0, ishaAngle: 14.0 },
  Tehran: { fajrAngle: 17.7, maghribAngle: 4.5, ishaAngle: 14.0 },
  MWL: { fajrAngle: 18.0, ishaAngle: 17.0 },
  ISNA: { fajrAngle: 15.0, ishaAngle: 15.0 },
  Egypt: { fajrAngle: 19.5, ishaAngle: 17.5 },
  Makkah: { fajrAngle: 18.5, ishaMinutes: 90 },
  Karachi: { fajrAngle: 18.0, ishaAngle: 18.0 },
};

function toRad(deg: number) {
  return (deg * Math.PI) / 180;
}

function toDeg(rad: number) {
  return (rad * 180) / Math.PI;
}

export function calculatePrayerTimes(
  date: Date,
  lat: number,
  lng: number,
  method: CalculationMethod = "Jafari",
  manualOffsets: Partial<Record<keyof PrayerTimes, number>> = {}
): PrayerTimes {
  const dayOfYear = Math.floor(
    (date.getTime() - new Date(date.getFullYear(), 0, 0).getTime()) / 86400000
  );

  // معادلة ميل الشمس ومعادلة الوقت
  const b = (2 * Math.PI * (dayOfYear - 81)) / 365;
  const eot = 9.87 * Math.sin(2 * b) - 7.53 * Math.cos(b) - 1.5 * Math.sin(b);
  const declination = 23.45 * Math.sin(toRad((360 / 365) * (dayOfYear - 81)));

  // زوال الشمس (الظهر)
  const timezone = -date.getTimezoneOffset() / 60;
  const noon = 12 + timezone - lng / 15 - eot / 60;

  const sunAngleTime = (angle: number, direction: "am" | "pm") => {
    const cosH =
      (Math.sin(toRad(-angle)) - Math.sin(toRad(lat)) * Math.sin(toRad(declination))) /
      (Math.cos(toRad(lat)) * Math.cos(toRad(declination)));

    if (cosH > 1 || cosH < -1) return noon;
    const hourAngle = toDeg(Math.acos(cosH)) / 15;
    return direction === "am" ? noon - hourAngle : noon + hourAngle;
  };

  const m = METHODS[method];
  const fajrHours = sunAngleTime(m.fajrAngle, "am");
  const sunriseHours = sunAngleTime(0.833, "am");
  const dhuhrHours = noon;

  // العصر
  const asrAlt = toDeg(Math.atan(1 + Math.tan(toRad(Math.abs(lat - declination)))));
  const asrHours = sunAngleTime(90 - asrAlt, "pm");

  // المغرب
  const maghribHours = m.maghribAngle
    ? sunAngleTime(m.maghribAngle, "pm")
    : sunAngleTime(0.833, "pm") + (m.maghribMinutes || 0) / 60;

  // العشاء
  const ishaHours = m.ishaAngle
    ? sunAngleTime(m.ishaAngle, "pm")
    : maghribHours + (m.ishaMinutes || 90) / 60;

  const fmt = (hours: number, offset = 0) => {
    const totalMinutes = Math.round((hours * 60 + offset + 1440) % 1440);
    const h = Math.floor(totalMinutes / 60);
    const min = totalMinutes % 60;
    return `${String(h).padStart(2, "0")}:${String(min).padStart(2, "0")}`;
  };

  return {
    fajr: fmt(fajrHours, manualOffsets.fajr),
    sunrise: fmt(sunriseHours, manualOffsets.sunrise),
    dhuhr: fmt(dhuhrHours, manualOffsets.dhuhr),
    asr: fmt(asrHours, manualOffsets.asr),
    maghrib: fmt(maghribHours, manualOffsets.maghrib),
    isha: fmt(ishaHours, manualOffsets.isha),
  };
}