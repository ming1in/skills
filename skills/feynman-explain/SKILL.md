---
name: feynman-explain
description: Break down any concept, system, code, or decision using the Feynman-technical hybrid formula — plain-language mechanism → evidence/numbers → actionable implication. Use whenever the user asks to explain, break down, simplify, or understand something. Trigger on "feynman this", "ELI5", "break this down", "help me understand", "explain like I'm five", "walk me through", "what does X actually mean", "why does X work", or any request to make something clearer. Also use proactively when explaining architecture decisions, engineering trade-offs, research findings, or anything where both accessibility and rigor matter. When in doubt, use this skill — clarity is never wrong.
---

# Feynman Explain

Use the three-step Feynman-technical hybrid formula. Every explanation follows this structure, adapted to the subject's complexity:

## Step 1 — Explain the Mechanism (Feynman)

Start with what physically or logically happens and *why it matters*. Write as if the reader has never encountered this topic before. Use an analogy when it helps — a good analogy collapses the learning curve. Strip the jargon: if a technical term is unavoidable, define it in the same sentence.

The test: could someone outside the domain read this step and explain it back to you? If not, simplify.

## Step 2 — Prove It (Technical)

Back the mechanism with specific evidence: numbers, metrics, benchmarks, timelines, error rates, latency figures, costs, citations. No hand-waving ("it's fast") — show the number that proves it ("P99 latency is 12ms under 10k rps"). If real numbers aren't available, be explicit about that rather than inventing precision.

When there's nothing to quantify (a pure design principle, a philosophical concept), skip this step and say so — don't manufacture false precision.

## Step 3 — Conclude with the Implication

End with what to do about it. The explanation is only complete when it connects to a decision, action, or next step. "Here's what's happening" without "here's what that means for you" is analysis without value.

---

## Format

Structure the output with clear section headers matching these three steps. Keep each step as tight as the subject allows — a single sentence is enough if the point is simple. Resist the urge to pad.

If the subject has multiple components (e.g., a system with three layers, a decision with three trade-offs), run the three-step formula per component rather than mixing them together.

## Anti-patterns to avoid

- **Jargon without definition** — "CoWoS interposer yield degradation" needs to say what an interposer is before the sentence ends
- **Hand-waving without proof** — "the market is growing fast" needs a number and a source
- **Analysis without action** — "here's what's happening" needs "here's what to do about it"
- **Over-explaining the obvious** — if a concept is simple, a sentence is fine; don't inflate it to look thorough
