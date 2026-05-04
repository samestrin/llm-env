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

The installer falls back to `~/.local/bin` if `/usr/local/bin` isn't writable. If `~/.local/bin` isn't on your `PATH` yet, the installer's next-steps output prints the exact `export PATH=...` line to add. (Use `sudo bash` instead if you want a system-wide install.)

Verify:

```bash
llm-env --version
# llm-env - LLM Environment Manager v1.5.2
```

## Step 2 — Run quickstart (interactive)

```bash
llm-env quickstart
```

You'll see a menu like this:

```
Which catalogs would you like to add?
  1) Synthetic — Kimi, GLM, MiniMax, Qwen, DeepSeek, Llama, GPT-OSS, Nemotron
  2) Alibaba Cloud Coding Plan — Qwen, Kimi, GLM, MiniMax
  a) all
  q) quit
Choose [1/2/a/q]:
```

Pick **1**, **2**, or **a**. For each catalog you choose, the command:

1. Adds the provider definitions to `~/.config/llm-env/config.conf` (~28 entries for Synthetic, ~12 for Alibaba, in both `openai_*` and `anth_*` forms with group bindings).
2. Prints the signup URL with our referral code embedded.
3. Pauses while you sign up and copy your API key.
4. Prompts for the key (input is hidden, like a password).
5. Appends `export LLM_<vendor>_API_KEY='<your-key>'` to your shell rc file (`~/.bashrc` or `~/.zshrc`) so it persists.
6. Verifies the key with a tiny test call to the provider's API.

Just press Enter (or type `s`) at the key prompt if you'd rather sign up later — your config is still populated, you just won't have a working key yet.

If a key for that provider is already configured (set in your environment or already exported in your shell rc), the prompt is skipped automatically and the existing key is preserved.

### Skipping the menu

If you'd rather not see the menu (say you're scripting an install or already know which one you want):

```bash
llm-env quickstart synthetic            # only Synthetic
llm-env quickstart alibaba              # only Alibaba
llm-env quickstart synthetic,alibaba    # both
llm-env quickstart all                  # both (alias for synthetic,alibaba)
```

When stdin isn't a TTY (CI, piped install scripts), `quickstart` skips the menu *and* the key prompts and just provisions every available catalog — same behavior as `llm-env quickstart all`.

### About the referral links

The signup URLs printed by quickstart embed referral codes that support this project:

- Synthetic: <https://synthetic.new/?referral=ugceNlJ08A3Eeww>
- Alibaba Cloud Coding Plan: <https://www.alibabacloud.com/campaign/benefits?referral_code=A92LUX>

Using them is the easiest way to support `llm-env` development.

## Step 3 — Reload your shell

`quickstart` writes your API key to your shell rc file but the export takes effect on next shell load:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

(Or just open a new terminal.)

## Step 4 — Point Claude Code at your model of choice

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

## Step 5 — Run Claude Code

```bash
claude
```

Claude Code now talks to Kimi K2.5 via Synthetic. Use it exactly like you would against real Claude — the protocol is identical.

## Step 6 — Switch models any time

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
