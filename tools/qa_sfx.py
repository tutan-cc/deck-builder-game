#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""用 qwen3.8-omni-flash "听"一遍生成的音效，看它像不像该有的东西。

    $env:DASHSCOPE_API_KEY = "sk-..."
    python tools/qa_sfx.py            # 全部
    python tools/qa_sfx.py slash coin # 指定的

做法：按 gen_sfx.SOUNDS 里的提示词重新生成一次（seed 相同 → 同一段音频），
拿到模型 24 小时有效的签名 URL，直接把这个 URL 丢给 omni 让它描述听到了什么。
这样不需要把成品上传到公网。

用途：我听不到，只能靠它当"第二双耳朵"，专抓"生成的完全不是这个东西"这类硬伤；
它对 8-bit 音效的命名不一定准，别拿它当审美裁判。
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request

import gen_sfx

OMNI = "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
ASK = "这段音频是什么声音？用一句中文回答，尽量具体（比如：金属剑挥砍 / 纸牌摩擦 / 金币叮当 / 低沉的失败音）。"


def post(url: str, body: dict, key: str) -> dict:
    data = json.dumps(body, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json; charset=utf-8"},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.load(resp)


def omni_describe(audio_url: str, key: str) -> str:
    out = post(OMNI, {
        "model": "qwen3.8-omni-flash",
        "input": {"messages": [{"role": "user", "content": [
            {"audio": audio_url},
            {"text": ASK},
        ]}]},
    }, key)
    content = out["output"]["choices"][0]["message"]["content"]
    if isinstance(content, list):
        return " ".join(part.get("text", "") for part in content if isinstance(part, dict)).strip()
    return str(content).strip()


def main() -> int:
    key = os.environ.get("DASHSCOPE_API_KEY", "").strip()
    if not key:
        print("缺少环境变量 DASHSCOPE_API_KEY", file=sys.stderr)
        return 2
    names = sys.argv[1:] or list(gen_sfx.SOUNDS)
    for name in names:
        if name not in gen_sfx.SOUNDS:
            print(f"未知音效: {name}", file=sys.stderr)
            continue
        prompt, seconds = gen_sfx.SOUNDS[name]
        try:
            url = gen_sfx.generate(prompt, key)
            desc = omni_describe(url, key)
            print(f"{name:<14} (想要 {seconds}s) -> {desc}", flush=True)
        except Exception as exc:
            print(f"{name:<14} 失败: {exc}", file=sys.stderr, flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
