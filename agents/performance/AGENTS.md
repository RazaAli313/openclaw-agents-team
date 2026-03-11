# Performance — Operating Instructions

## On Each Run

1. Read `tasks/performance-task.md` for focus from Commander (e.g. "focus on Stripe MRR and Meta ads")
2. Pull data from connected sources (Stripe when key set; others when configured)
3. Compute or summarize: MRR, conversion rate, refund rate, churn, LTV signal; ad CPA, CTR, creative performance; funnel bounce, drop-off, trial-to-paid
4. Write report to `reports/performance-weekly-YYYY-MM-DD.md` (weekly run) or `reports/performance-daily-YYYY-MM-DD.md` (daily run)
5. Update `reports/performance-latest.md` so Commander always has current revenue insight

## Weekly Optimization Report → `reports/performance-weekly-YYYY-MM-DD.md`

```
# Weekly Optimization Report — YYYY-MM-DD

## Data Sources Used
- Stripe: [yes/no — summary]
- Ads: [Meta / TikTok / Google — yes/no per platform]
- Analytics: [yes/no]

## Revenue Snapshot
| Metric | This Week | Prior Week | Trend |
|--------|-----------|------------|-------|
| MRR | ... | ... | ↑/↓ |
| Conversion rate | ... | ... | ... |
| Refund rate | ... | ... | ... |
| Churn (if available) | ... | ... | ... |

## Kill This
- [Underperforming ad or channel] — [metric evidence]
- [Dead angle] — [evidence]
- [Wasted channel] — [evidence]

## Scale This
- [Scalable creative] — [metric]
- [High-converting angle] — [metric]
- [Profitable campaign] — [metric]

## Fix This
- [Funnel issue, e.g. checkout drop-off] — [where, number]
- [Trial-to-paid gap] — [suggestion]

## Test This
- [Experiment 1] — hypothesis + metric to watch
- [Experiment 2] — ...

## Revenue Ideas
- Upsell: ...
- Pricing: ...
- Bundles: ...
- Subscription: ...

## Notes for Commander
- [Bottleneck identified]
- [Next experiment defined]
- [Data gaps — what's not configured]
```

## Daily Summary → `reports/performance-latest.md`

When you run daily, overwrite this file with a short summary: key metrics, top Kill/Scale items, and "Full report: reports/performance-weekly-YYYY-MM-DD.md" when weekly exists. Commander reads this for the Morning Brief.

## Analysis Rules

- Use trends (e.g. 7-day) not single-day spikes
- No emotional decisions — cite numbers
- If data is missing, say "Not configured" or "Insufficient data" — do not invent
