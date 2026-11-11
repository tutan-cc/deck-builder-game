#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""用阿里云 qwen-audio-3.1-tts-next 生成游戏音效，裁成短音效并导出 ogg。

用法（key 只走环境变量，不要写进仓库）：
    $env:DASHSCOPE_API_KEY = "sk-..."
    python tools/gen_sfx.py slash block

为什么不直接用生成结果：
    这个模型是"统一音频生成"，一次固定吐 ~30 秒的完整声景（即使提示词写了 0.3 秒）。
    所以每段都要自己找第一个起音点、截到目标长度、加淡出、归一化，再转 ogg。
"""
from __future__ import annotations

import json
import os
import struct
import subprocess
import sys
import tempfile
import urllib.request
import wave

import numpy as np

API = "https://dashscope.aliyuncs.com/api/v1/services/audio/tts/SpeechSynthesizer"
MODEL = "qwen-audio-3.1-tts-next"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art", "audio")
WORK_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sfx_work")
FFMPEG = os.environ.get("FFMPEG", "ffmpeg")

# name -> (提示词, 目标秒数)
SOUNDS: dict[str, tuple[str, float]] = {
    "slash": ("8-bit 像素游戏音效：一次快速凌厉的金属剑挥砍，短促尖锐，只有一下，不要音乐、不要人声", 0.38),
    "block": ("8-bit 像素游戏音效：盾牌挡住攻击的金属撞击，短促厚重，只有一下，不要音乐", 0.34),
    "enemy_attack": ("8-bit 像素游戏音效：怪物挥爪扑击的破风声，短促凶狠，只有一下，不要音乐", 0.42),
    "enemy_block": ("8-bit 像素游戏音效：敌人举盾格挡的钝器碰撞声，短促发闷，只有一下", 0.34),
    "axe": ("8-bit 像素游戏音效：斧头劈进木头的闷响，短促有劈裂感，只有一下，不要音乐", 0.36),
    "card_play": ("8-bit 像素游戏音效：一张纸牌被甩出去的轻快摩擦声，非常短，只有一下", 0.22),
    "damage": ("8-bit 像素游戏音效：角色被击中时的闷响，短促有力，只有一下，不要人声", 0.3),
    "enemy_die": ("8-bit 像素游戏音效：怪物被打碎消散，短促下行的破碎感，只有一下", 0.55),
    "victory": ("8-bit 像素游戏音效：战斗胜利的短促上行小号角，怪物猎人风格，两秒内结束", 1.6),
    "defeat": ("8-bit 像素游戏音效：失败的短促低沉下行，压抑，两秒内结束", 1.6),
    "coin": ("8-bit 像素游戏音效：金币拾取的清脆叮当，短促明亮，只有一下", 0.3),
}


def post_json(url: str, body: dict, key: str) -> dict:
    data = json.dumps(body, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json; charset=utf-8"},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.load(resp)


def generate(prompt: str, key: str, seed: int = 42) -> str:
    out = post_json(API, {
        "model": MODEL,
        "input": {
            "text_prompt": prompt,
            "format": "wav",
            "sample_rate": 44100,
            "channels": 1,
            "seed": seed,
            "rate": 1.0,
        },
    }, key)
    return out["output"]["audio"]["url"]


def download(url: str, path: str) -> None:
    with urllib.request.urlopen(url, timeout=300) as resp, open(path, "wb") as f:
        f.write(resp.read())


def read_wav(path: str) -> tuple[np.ndarray, int]:
    with wave.open(path, "rb") as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        raw = w.readframes(w.getnframes())
    data = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    if ch > 1:
        data = data.reshape(-1, ch).mean(axis=1)
    return data, sr


def first_onset(x: np.ndarray, sr: int, hop_ms: float = 4.0) -> float:
    """找第一个明显的起音点（相对全段峰值 -30dB 以上的第一处）。"""
    hop = max(1, int(sr * hop_ms / 1000))
    n = len(x) // hop
    if n == 0:
        return 0.0
    env = np.sqrt(np.mean(x[: n * hop].reshape(n, hop) ** 2, axis=1) + 1e-12)
    peak = env.max()
    if peak <= 0:
        return 0.0
    thresh = peak * (10 ** (-30 / 20))
    idx = int(np.argmax(env > thresh))
    return max(0.0, idx * hop / sr - 0.015)  # 起音前留一点


def shape(x: np.ndarray, sr: int, seconds: float) -> np.ndarray:
    """截到目标长度，尾部淡出，峰值归一到 -1 dBFS。"""
    n = min(len(x), int(sr * seconds))
    out = x[:n].copy()
    fade = min(len(out), int(sr * min(0.08, seconds * 0.35)))
    if fade > 0:
        out[-fade:] *= np.linspace(1.0, 0.0, fade) ** 1.5
    peak = float(np.max(np.abs(out))) if len(out) else 0.0
    if peak > 0:
        out *= (10 ** (-1 / 20)) / peak
    return out


def write_wav(path: str, x: np.ndarray, sr: int) -> None:
    pcm = np.clip(x * 32767.0, -32768, 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def to_ogg(src: str, dst: str) -> None:
    subprocess.run(
        [FFMPEG, "-y", "-v", "error", "-i", src, "-c:a", "libvorbis", "-q:a", "5", dst],
        check=True,
    )


def one(name: str, key: str) -> None:
    prompt, seconds = SOUNDS[name]
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(WORK_DIR, exist_ok=True)
    print(f"[{name}] 生成中…", flush=True)
    url = generate(prompt, key)
    raw = os.path.join(WORK_DIR, f"{name}_raw.wav")
    download(url, raw)
    x, sr = read_wav(raw)
    start = first_onset(x, sr)
    trimmed = shape(x[int(start * sr):], sr, seconds)
    tmp = os.path.join(WORK_DIR, f"{name}_trim.wav")
    write_wav(tmp, trimmed, sr)
    dst = os.path.join(OUT_DIR, f"{name}.ogg")
    to_ogg(tmp, dst)
    print(f"[{name}] {len(x)/sr:.1f}s -> {len(trimmed)/sr:.2f}s  onset={start:.2f}s  {os.path.getsize(dst)} bytes",
          flush=True)


def main() -> int:
    key = os.environ.get("DASHSCOPE_API_KEY", "").strip()
    if not key:
        print("缺少环境变量 DASHSCOPE_API_KEY", file=sys.stderr)
        return 2
    names = sys.argv[1:] or list(SOUNDS)
    bad = [n for n in names if n not in SOUNDS]
    if bad:
        print(f"未知音效: {bad}；可选: {', '.join(SOUNDS)}", file=sys.stderr)
        return 2
    for name in names:
        try:
            one(name, key)
        except Exception as exc:  # 单个失败不影响其它
            print(f"[{name}] 失败: {exc}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
