#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""程序化合成 8-bit 音效（不用 AI，纯方波/噪声 + 包络）。

    $env:FFMPEG = "…\\ffmpeg.exe"      # 没在 PATH 时
    python tools/gen_chip.py           # 全部
    python tools/gen_chip.py coin      # 单个

为什么不用 qwen-audio-3.1-tts-next 了：
    那个模型是"统一音频生成"（旁白/播客/声景），给 8-bit 音效它会自己往里塞人声——
    实测 11 个里有 5 个混进了男声（"print"、"Hey"、裁判的 "Fight"、西语、痛呼），
    把提示词改成"纯音效、无人声"也没用（变成唱片刮擦声/撕胶带声）。
    对像素游戏来说，方波合成比它的输出更像这个年代的东西，而且确定性、零成本、不会有人声。
    证据见 docs/音效-2026-11-11.md。
"""
from __future__ import annotations

import os
import subprocess
import sys
import wave

import numpy as np

SR = 22050
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art", "audio")
WORK_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sfx_work")
FFMPEG = os.environ.get("FFMPEG", "ffmpeg")

rng = np.random.default_rng(7)


# ---------- 基础波形 ----------

def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(SR * seconds), dtype=np.float32) / SR


def square(freq, seconds: float, duty: float = 0.5) -> np.ndarray:
    """freq 可以是常数，也可以是和 t 等长的数组（做扫频）。"""
    t = t_axis(seconds)
    f = np.full_like(t, freq, dtype=np.float32) if np.isscalar(freq) else np.asarray(freq, dtype=np.float32)[: len(t)]
    phase = np.cumsum(f) / SR
    return np.where((phase % 1.0) < duty, 1.0, -1.0).astype(np.float32)


def triangle(freq, seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    f = np.full_like(t, freq, dtype=np.float32) if np.isscalar(freq) else np.asarray(freq, dtype=np.float32)[: len(t)]
    phase = np.cumsum(f) / SR
    return (2.0 * np.abs(2.0 * (phase % 1.0) - 1.0) - 1.0).astype(np.float32)


def noise(seconds: float) -> np.ndarray:
    return rng.uniform(-1.0, 1.0, int(SR * seconds)).astype(np.float32)


def brighten(x: np.ndarray) -> np.ndarray:
    """一阶差分 = 简陋高通，噪声会变"嘶"，符合 8-bit 的廉价感。"""
    y = np.diff(x, prepend=0.0)
    return (y * 0.5).astype(np.float32)


def env(seconds: float, attack: float = 0.002, curve: float = 5.0) -> np.ndarray:
    """短促起音 + 指数衰减。"""
    n = int(SR * seconds)
    a = max(1, int(SR * attack))
    e = np.ones(n, dtype=np.float32)
    e[:a] = np.linspace(0.0, 1.0, a, dtype=np.float32)
    rest = np.linspace(0.0, 1.0, max(1, n - a), dtype=np.float32)
    e[a:] = np.exp(-curve * rest).astype(np.float32)
    return e


def sweep(f0: float, f1: float, seconds: float, power: float = 1.0) -> np.ndarray:
    n = int(SR * seconds)
    u = np.linspace(0.0, 1.0, n, dtype=np.float32) ** power
    return (f0 + (f1 - f0) * u).astype(np.float32)


def pad(x: np.ndarray, seconds: float) -> np.ndarray:
    n = int(SR * seconds)
    out = np.zeros(n, dtype=np.float32)
    m = min(n, len(x))
    out[:m] = x[:m]
    return out


def mix(*parts) -> np.ndarray:
    n = max(len(p) for p in parts)
    out = np.zeros(n, dtype=np.float32)
    for p in parts:
        out[: len(p)] += p
    return out


# ---------- 每个音效 ----------

def s_slash() -> np.ndarray:
    d = 0.34
    whoosh = brighten(noise(d)) * env(d, 0.004, 6.0)
    shing = square(sweep(1800.0, 260.0, d, 0.6), d, 0.25) * env(d, 0.001, 7.0)
    return mix(whoosh * 0.9, shing * 0.45)


def s_block() -> np.ndarray:
    d = 0.3
    thud = square(140.0, d) * env(d, 0.001, 9.0)
    ring = mix(
        square(760.0, d, 0.25) * env(d, 0.001, 11.0),
        square(1140.0, d, 0.25) * env(d, 0.001, 13.0),
        square(1520.0, d, 0.5) * env(d, 0.001, 15.0),
    )
    click = brighten(noise(0.05)) * env(0.05, 0.001, 12.0)
    return mix(thud * 0.9, ring * 0.35, pad(click, d) * 0.5)


def s_enemy_block() -> np.ndarray:
    d = 0.3
    thud = square(110.0, d) * env(d, 0.001, 8.0)
    ring = mix(
        square(520.0, d, 0.5) * env(d, 0.001, 12.0),
        square(690.0, d, 0.25) * env(d, 0.001, 14.0),
    )
    return mix(thud * 1.0, ring * 0.28)


def s_damage() -> np.ndarray:
    d = 0.26
    thump = square(sweep(190.0, 70.0, d, 0.8), d) * env(d, 0.001, 8.0)
    grit = brighten(noise(0.08)) * env(0.08, 0.001, 14.0)
    return mix(thump, pad(grit, d) * 0.6)


def s_enemy_attack() -> np.ndarray:
    d = 0.3
    growl = square(sweep(90.0, 220.0, d, 2.0), d, 0.35) * env(d, 0.02, 4.0)
    whoosh = brighten(noise(d)) * env(d, 0.05, 3.0)
    return mix(growl * 0.7, whoosh * 0.8)


def s_enemy_die() -> np.ndarray:
    d = 0.5
    fall = square(sweep(520.0, 70.0, d, 0.7), d, 0.35) * env(d, 0.002, 5.0)
    fizz = brighten(noise(d)) * env(d, 0.02, 6.0)
    return mix(fall * 0.9, fizz * 0.45)


def s_card_play() -> np.ndarray:
    d = 0.16
    flick = brighten(noise(d)) * env(d, 0.002, 16.0)
    zip_ = square(sweep(400.0, 1400.0, d, 1.5), d, 0.25) * env(d, 0.004, 12.0)
    return mix(flick * 1.0, zip_ * 0.3)


def s_coin() -> np.ndarray:
    a, b = 0.07, 0.16
    p1 = square(1568.0, a, 0.25) * env(a, 0.001, 10.0)
    p2 = mix(square(2093.0, b, 0.25), triangle(2093.0, b) * 0.4) * env(b, 0.001, 8.0)
    return mix(pad(p1, a + b), np.concatenate([np.zeros(int(SR * a), dtype=np.float32), p2]))


def s_axe() -> np.ndarray:
    d = 0.32
    chop = brighten(noise(0.07)) * env(0.07, 0.001, 15.0)
    wood = square(sweep(160.0, 85.0, d, 0.9), d) * env(d, 0.001, 9.0)
    return mix(pad(chop, d) * 0.8, wood)


def _seq(notes, note_len: float, duty: float = 0.5, tail: float = 0.0) -> np.ndarray:
    parts = []
    for f in notes:
        parts.append(square(f, note_len, duty) * env(note_len, 0.002, 3.2))
    out = np.concatenate(parts) if parts else np.zeros(1, dtype=np.float32)
    if tail > 0:
        out = np.concatenate([out, square(notes[-1], tail, duty) * env(tail, 0.002, 2.2)])
    return out


def s_victory() -> np.ndarray:
    d = 1.5
    lead = _seq([523.25, 659.25, 783.99, 1046.5], 0.14, 0.5, tail=0.5)
    harm = _seq([392.0, 523.25, 659.25, 783.99], 0.14, 0.25, tail=0.5) * 0.4
    return mix(pad(lead, d), pad(harm, d))


def s_defeat() -> np.ndarray:
    d = 1.5
    lead = _seq([329.63, 261.63, 220.0, 164.81], 0.22, 0.5, tail=0.45)
    low = _seq([164.81, 130.81, 110.0, 82.41], 0.22, 0.25, tail=0.45) * 0.5
    return mix(pad(lead, d), pad(low, d))


BUILDERS = {
    "slash": s_slash, "block": s_block, "enemy_block": s_enemy_block, "damage": s_damage,
    "enemy_attack": s_enemy_attack, "enemy_die": s_enemy_die, "card_play": s_card_play,
    "coin": s_coin, "axe": s_axe, "victory": s_victory, "defeat": s_defeat,
}


# ---------- 输出 ----------

def finish(x: np.ndarray, seconds: float) -> np.ndarray:
    out = pad(x, seconds)[: int(SR * seconds)].copy()
    fade = min(len(out), int(SR * min(0.03, seconds * 0.2)))
    if fade:
        out[-fade:] *= np.linspace(1.0, 0.0, fade) ** 1.5
    peak = float(np.max(np.abs(out)))
    if peak > 0:
        out *= (10 ** (-1.5 / 20)) / peak
    return out


def write_wav(path: str, x: np.ndarray) -> None:
    pcm = np.clip(x * 32767.0, -32768, 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(WORK_DIR, exist_ok=True)
    names = sys.argv[1:] or list(BUILDERS)
    bad = [n for n in names if n not in BUILDERS]
    if bad:
        print(f"未知音效 {bad}；可选: {', '.join(BUILDERS)}", file=sys.stderr)
        return 2
    for name in names:
        raw = BUILDERS[name]()
        out = finish(raw, len(raw) / SR)
        wav = os.path.join(WORK_DIR, f"{name}_chip.wav")
        write_wav(wav, out)
        dst = os.path.join(OUT_DIR, f"{name}.ogg")
        subprocess.run([FFMPEG, "-y", "-v", "error", "-i", wav,
                        "-c:a", "libvorbis", "-q:a", "5", dst], check=True)
        print(f"{name:<14} {len(out)/SR:5.2f}s  {os.path.getsize(dst):>6} bytes", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
