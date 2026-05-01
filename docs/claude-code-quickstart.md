# Claude Code Quickstart with llm-env

This walkthrough gets you running [Claude Code](https://docs.claude.com/en/docs/claude-code) against models hosted on **[Synthetic](https://synthetic.new)** or **[Alibaba Cloud's Coding Plan](https://www.alibabacloud.com/help/en/model-studio/coding-plan)** — Kimi, GLM, MiniMax, Qwen, DeepSeek, Llama, and more. No Anthropic API key required.

The whole flow takes about five minutes if you don't already have an account.

## Why use this?

Claude Code is a great CLI; it's not married to Claude. Both Synthetic and Alibaba's Coding Plan expose **Anthropic-compatible endpoints**, which means anything that speaks Anthropic's protocol — including Claude Code — can talk to their models with no code changes. `llm-env` handles the env-var plumbing.

Real-world reasons to do this:
- **Pricing.** Synthetic's flat subscription and Alibaba's Coding Plan tiers are both cheaper than direct Anthropic API access at moderate volume.
- **Model variety.** Kimi-K2.5 for long context, Qwen3-Coder-480B for code-specific work, GLM-5.1 for fast general-purpose, DeepSeek-R1 for reasoning. All addressable from the same `claude` invocation.
- **Quota separation.** Your Synthetic/Alibaba subscription doesn't burn against your Anthropic API limits or vice versa.

## Step 1 — Install llm-env

```bash
curl -fsSL https://raw.githubusercontent.com/samestrin/llm-env/main/install.sh | bash
```

When prompted, accept the offer to add synthetic providers. (Or skip and run `llm-env quickstart` manually later.)

Verify:

```bash
llm-env --version
# llm-env - LLM Environment Manager v1.5.2
```

## Step 2 — Run quickstart

If you didn't accept during install:

```bash
llm-env quickstart
```

This adds ~36 provider entries plus group bindings to `~/.config/llm-env/config.conf`, covering every model Synthetic and Alibaba currently expose on both their OpenAI- and Anthropic-compatible endpoints. The command prints sign-up links for both providers when it finishes.

## Step 3 — Sign up for Synthetic, Alibaba, or both

You only need one. Pick based on what models you want:

**Synthetic** — broad catalog (Kimi, GLM family, MiniMax, DeepSeek V/R, Qwen base/Coder/Thinking, GPT-OSS, Llama, Nemotron). Flat-rate subscription.

→ <https://synthetic.new/?referral=ugceNlJ08A3Eeww>

**Alibaba Cloud Coding Plan** — curated coding-focused list (today: qwen3.6-plus, kimi-k2.5, glm-5, MiniMax-M2.5). Subscription tiers (Lite, Pro).

→ <https://www.alibabacloud.com/campaign/benefits?referral_code=A92LUX>

Both signup links above include referral codes that benefit this project — using them is the easiest way to support `llm-env` development.

## Step 4 — Add your API key to your shell profile

After signing up, copy your API key from the provider's dashboard. Then add the matching environment variable to `~/.bashrc` or `~/.zshrc`:

```bash
# For Synthetic:
export LLM_SYNTHETIC_API_KEY="your-synthetic-key-here"

# For Alibaba (if you signed up there):
export LLM_ALIBABA_API_KEY="your-alibaba-key-here"
```

Reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

## Step 5 — Test the connection

```bash
llm-env test anth_synth_kimi-k2.5
# 🧪 Testing provider: anth_synth_kimi-k2.5 (protocol: anthropic)
# ✅ API key found: ••••••••••••8d62
# 🔗 Base URL: https://api.synthetic.new/anthropic/v1
# ✅ anth_synth_kimi-k2.5: Connected successfully
```

(If you signed up for Alibaba, swap in `anth_alibaba_kimi-k2.5` or `anth_alibaba_qwen3.6-plus`.)

## Step 6 — Point Claude Code at your model of choice

```bash
llm-env set anth_synth_kimi-k2.5
```

You should see:

```
✅ Set: provider=openai_synth_kimi-k2.5 protocol=openai host=api.synthetic.new model=hf:moonshotai/Kimi-K2.5
✅ Set: provider=anth_synth_kimi-k2.5 protocol=anthropic host=api.synthetic.new model=hf:moonshotai/Kimi-K2.5
🔧 Additional Claude Code variables set: ANTHROPIC_DEFAULT_OPUS_MODEL=hf:moonshotai/Kimi-K2.5, ...
```

This is using the per-model **group** — it activates both the OpenAI-compatible and Anthropic-compatible variants of the same model in one shot, so any tool you run in this shell (Claude Code, aichat, your own scripts) all use the same backend.

## Step 7 — Run Claude Code

```bash
claude
```

Claude Code now talks to Kimi K2.5 via Synthetic. Use it exactly like you would against real Claude — the protocol is identical.

## Step 8 — Switch models any time

```bash
llm-env set anth_synth_glm-5.1            # GLM 5.1
llm-env set anth_synth_qwen3-coder-480b   # Qwen3 Coder 480B
llm-env set synth_kimi                    # whatever's currently latest in the Kimi family
llm-env set alibaba_qwen                  # latest Qwen on Alibaba's Coding Plan

llm-env unset                             # clear everything; back to Claude Code's native login
```

The "family-latest" aliases (`synth_kimi`, `synth_glm`, `synth_qwen-coder`, `alibaba_qwen`, etc.) automatically resolve to whichever version is currently latest in that effective family — convenient when you don't want to track specific version numbers.

`llm-env list` shows everything currently available.

## Cheat sheet

| What you want | Command |
|---|---|
| Latest Kimi on Synthetic | `llm-env set synth_kimi` |
| Latest Qwen Coder on Synthetic | `llm-env set synth_qwen-coder` |
| Latest GLM Flash on Synthetic | `llm-env set synth_glm-flash` |
| Latest Qwen on Alibaba | `llm-env set alibaba_qwen` |
| Specific version, both protocols | `llm-env set synth_kimi-k2.5` |
| Specific version, Anthropic protocol only (Claude Code) | `llm-env set anth_synth_kimi-k2.5` |
| Specific version, OpenAI protocol only (aichat, Cursor, etc.) | `llm-env set openai_synth_kimi-k2.5` |
| Show what's currently set | `llm-env show` |
| Test connectivity | `llm-env test <provider>` |
| Clear everything | `llm-env unset` |

## Troubleshooting

**Claude Code reports auth errors.** Run `llm-env show` — it should display the current `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` (masked). If those are empty, the `set` command didn't run in your current shell — make sure `llm-env` is on your `PATH` (the installer adds a wrapper function so you don't need `source`).

**Provider name not recognized.** Run `llm-env list` to see exactly what's in your config. Names follow the scheme `<protocol>_<vendor-short>_<model>` (e.g., `anth_synth_kimi-k2.5`). If your config still has v1-style names, run `llm-env quickstart` to add the v2 entries (existing entries are skipped).

**The model list is out of date.** Pull the latest repo and re-run `quickstart`:

```bash
cd /path/to/llm-env-checkout && git pull
llm-env quickstart
```

The parser skips providers that already exist, so re-running only adds new models.
