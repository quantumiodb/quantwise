#!/usr/bin/env node
/**
 * vote_sim.mjs — 正态分布温度控制的 LLM 投票模拟器（通用版）
 *
 * Usage: node vote_sim.mjs [options] "<question>" <option1> <option2> [option3...]
 *
 * Options:
 *   --n=<count>       Number of agents (default: 100)
 *   --mean=<float>    Temperature mean (default: 0.6)
 *   --std=<float>     Temperature std dev (default: 0.20)
 *   --concurrency=<n> Parallel calls (default: 20)
 *   --model=<id>      Model to use (default: from env)
 *   --context=<text>  Background context injected into each persona's prompt
 */

import Anthropic from '@anthropic-ai/sdk'
import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

// ── Load .env ─────────────────────────────────────────────────────────────────

function loadDotEnv() {
  const candidates = [
    resolve(process.cwd(), '.env'),
    resolve(dirname(fileURLToPath(import.meta.url)), '../../../../.env'),
  ]
  for (const p of candidates) {
    try {
      const lines = readFileSync(p, 'utf8').split('\n')
      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed || trimmed.startsWith('#')) continue
        const eq = trimmed.indexOf('=')
        if (eq < 0) continue
        const key = trimmed.slice(0, eq).trim()
        const val = trimmed.slice(eq + 1).trim().replace(/^["']|["']$/g, '')
        if (!(key in process.env)) process.env[key] = val
      }
      break
    } catch { /* try next */ }
  }
}

loadDotEnv()

// ── Chalk ─────────────────────────────────────────────────────────────────────

const { default: chalk } = await import('chalk')

const C = {
  title:    (s) => chalk.bold.white(s),
  border:   (s) => chalk.dim(s),
  label:    (s) => chalk.dim.white(s),
  value:    (s) => chalk.white(s),
  winner:   (s) => chalk.bold.green(s),
  second:   (s) => chalk.yellow(s),
  other:    (s) => chalk.cyan(s),
  cold:     (s) => chalk.blue(s),
  warm:     (s) => chalk.yellow(s),
  hot:      (s) => chalk.red(s),
  dim:      (s) => chalk.dim(s),
  stat:     (s) => chalk.dim(s),
  pct:      (s) => chalk.bold(s),
  bar_win:  (s) => chalk.bgGreen.black(s),
  bar_2nd:  (s) => chalk.bgYellow.black(s),
  bar_rest: (s) => chalk.bgCyan.black(s),
  bar_empty:(s) => chalk.dim(s),
  err:      (s) => chalk.red(s),
}

// ── Argument Parsing ──────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2)

let N = 100
let MEAN_TEMP = 0.6
let STD_TEMP = 0.20
let CONCURRENCY = 5
let MODEL = process.env.ANTHROPIC_DEFAULT_HAIKU_MODEL || 'claude-haiku-4-5-20251001'
let CONTEXT = ''

const positional = []
for (const arg of rawArgs) {
  if      (arg.startsWith('--n='))            N = parseInt(arg.slice(4))
  else if (arg.startsWith('--mean='))         MEAN_TEMP = parseFloat(arg.slice(7))
  else if (arg.startsWith('--std='))          STD_TEMP = parseFloat(arg.slice(6))
  else if (arg.startsWith('--concurrency='))  CONCURRENCY = parseInt(arg.slice(14))
  else if (arg.startsWith('--model='))        MODEL = arg.slice(8)
  else if (arg.startsWith('--context='))      CONTEXT = arg.slice(10)
  else if (arg.startsWith('--context-file=')) CONTEXT = readFileSync(arg.slice(15), 'utf8').trim()
  else positional.push(arg)
}

if (positional.length < 3) {
  console.error('Usage: vote_sim.mjs "<question>" <option1> <option2> [option3...]')
  process.exit(1)
}

const [question, ...options] = positional

// ── Normal Distribution (Box-Muller) ─────────────────────────────────────────

function sampleNormal(mean, std) {
  const u1 = Math.random(), u2 = Math.random()
  const z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2)
  return Math.max(0.01, Math.min(1.0, mean + z * std))
}

// ── Client ────────────────────────────────────────────────────────────────────

const IS_OLLAMA = process.env.ANTHROPIC_AUTH_TOKEN === 'ollama'
const OLLAMA_BASE = (process.env.ANTHROPIC_BASE_URL || '').replace(/\/$/, '')

function createClient() {
  if (IS_OLLAMA) return null
  const opts = {}
  if (process.env.ANTHROPIC_AUTH_TOKEN) {
    opts.authToken = process.env.ANTHROPIC_AUTH_TOKEN
  } else {
    opts.apiKey = process.env.ANTHROPIC_API_KEY_OVERRIDE || process.env.ANTHROPIC_API_KEY
  }
  if (process.env.ANTHROPIC_BASE_URL) opts.baseURL = process.env.ANTHROPIC_BASE_URL
  return new Anthropic(opts)
}

const client = createClient()

async function ollamaChat(systemPrompt, userMsg, temperature) {
  const url = `${OLLAMA_BASE}/api/chat`
  const body = {
    model: MODEL,
    think: false,
    stream: false,
    options: { temperature },
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user',   content: userMsg },
    ],
  }
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error(`Ollama ${res.status}: ${await res.text()}`)
  const json = await res.json()
  return json.message?.content?.trim() ?? ''
}

// ── Persona System（通用版）────────────────────────────────────────────────────
//
// 设计原则：
//   1. 每个 persona 被随机分配一个"倾向选项"（均匀分布到所有选项）
//   2. Temperature 控制执行力/坚定程度，而非领域立场
//   3. 背景是通用的人口统计，不预设任何领域
//
// 这样对任何问题（技术选型、生活决策、政策讨论等）都适用。

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)]
}

const BACKGROUNDS = {
  age:   ['19岁', '25岁', '31岁', '38岁', '46岁', '54岁', '63岁'],
  style: ['分析思考型', '直觉行动型', '保守稳健型', '开放创新型', '务实平衡型', '数据驱动型', '经验导向型'],
  job:   ['学生', '工程师', '教师', '医生', '企业主', '自由职业者', '公务员', '研究员', '设计师', '退休人员'],
}

// 每个选项对应多条通用倾向描述模板
const STANCE_TEMPLATES = [
  (opt) => `你经过深思熟虑后认为"${opt}"是当前最合适的选择，立场坚定。`,
  (opt) => `你的经验和判断告诉你"${opt}"在关键维度上表现更优，你倾向于支持它。`,
  (opt) => `你认为"${opt}"是最实际的方案，它的潜在效果最为可观。`,
  (opt) => `你支持"${opt}"，认为它在各方面的权衡中是最佳选项。`,
  (opt) => `你倾向于"${opt}"，基于你对相关信息的分析，这是最理性的选择。`,
  (opt) => `你觉得"${opt}"更符合当前的需求，支持度更高。`,
]

function temperatureToConviction(temp) {
  if (temp < 0.25) return '你今天状态极佳，思维清晰，判断极为坚定，不会受到任何外部干扰的影响。'
  if (temp < 0.45) return '你思路清晰，有原则，基本会按照自己的分析行事。'
  if (temp < 0.65) return '你稍微有些犹豫，大体上按自己想法行事，但偶尔会受到外部信息的影响。'
  if (temp < 0.80) return '你今天有些情绪化，容易被周围的意见带偏，判断可能偏离平时的立场。'
  return '你今天状态不稳定，极易受外部影响，可能会做出与自己平时立场不一致的冲动选择。'
}

function generatePersona(temperature) {
  // 均匀随机选一个倾向选项
  const leanIndex = Math.floor(Math.random() * options.length)
  const leanOption = options[leanIndex]
  const stanceTemplate = STANCE_TEMPLATES[Math.floor(Math.random() * STANCE_TEMPLATES.length)]

  return {
    age:        pick(BACKGROUNDS.age),
    style:      pick(BACKGROUNDS.style),
    job:        pick(BACKGROUNDS.job),
    leanOption,
    leanIndex,
    stance:     stanceTemplate(leanOption),
    temperature,
  }
}

const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']

function personaToPrompt(p, question, opts, context) {
  const optLines = opts.map((o, i) => `${LETTERS[i]}. ${o}`).join('\n')
  const lines = [
    `你是一位${p.age}的${p.job}（${p.style}）。`,
    `你的观点倾向：${p.stance}`,
    `你当前的决策状态：${temperatureToConviction(p.temperature)}`,
  ]
  if (context) {
    lines.push(``, `【背景参考信息】`, context, `【以上为参考信息】`)
  }
  lines.push(
    ``,
    `投票题目：${question}`,
    `选项：`,
    optLines,
    ``,
    `根据你的倾向和当前决策状态选一个字母，直接输出字母，不要解释。`,
  )
  return lines.join('\n')
}

function buildUserMessage() {
  return '你的答案（字母）：'
}

function letterToOption(raw, opts) {
  for (let i = 0; i < opts.length; i++) {
    if (raw.toUpperCase().includes(LETTERS[i])) return opts[i]
  }
  return null
}

async function castVote(agentId, temperature) {
  const persona = generatePersona(temperature)
  const sysprompt = personaToPrompt(persona, question, options, CONTEXT)
  const usermsg = buildUserMessage()
  try {
    let raw
    if (IS_OLLAMA) {
      raw = await ollamaChat(sysprompt, usermsg, temperature)
    } else {
      const response = await client.messages.create({
        model: MODEL,
        max_tokens: 2000,
        temperature,
        system: sysprompt,
        messages: [{ role: 'user', content: usermsg }],
      })
      const textBlock = response.content?.find?.((b) => b.type === 'text')
      raw = textBlock?.text?.trim() ?? ''
    }
    const matched = raw
      ? letterToOption(raw, options) ??
        options.find((o) => raw.toLowerCase().includes(o.toLowerCase())) ??
        options.find((o) => o.toLowerCase().includes(raw.toLowerCase())) ??
        'other'
      : 'other'
    return { agentId, temperature, vote: matched, raw, persona }
  } catch (e) {
    return { agentId, temperature, vote: 'error', raw: String(e.message), persona }
  }
}

// ── TUI Helpers ───────────────────────────────────────────────────────────────

const WIDTH = 64

function box(lines, { title = '' } = {}) {
  const top    = title
    ? C.border('╔══') + C.title(` ${title} `) + C.border('═'.repeat(WIDTH - title.length - 4) + '╗')
    : C.border('╔' + '═'.repeat(WIDTH) + '╗')
  const bottom = C.border('╚' + '═'.repeat(WIDTH) + '╝')
  const rows   = lines.map((l) => C.border('║ ') + l.padEnd(WIDTH - 2) + C.border(' ║'))
  return [top, ...rows, bottom].join('\n')
}

function barRow(label, count, total, rank, barWidth = 38) {
  const pct = total > 0 ? count / total : 0
  const filled = Math.round(pct * barWidth)
  const empty  = barWidth - filled
  const filledChar = '█'
  const emptyChar  = '░'

  const colorBar   = rank === 0 ? C.bar_win : rank === 1 ? C.bar_2nd : C.bar_rest
  const colorLabel = rank === 0 ? C.winner  : rank === 1 ? C.second  : C.other

  const bar    = (filled > 0 ? colorBar(filledChar.repeat(filled)) : '') +
                 (empty  > 0 ? C.bar_empty(emptyChar.repeat(empty)) : '')
  const votes  = String(count).padStart(4)
  const pctStr = (pct * 100).toFixed(1).padStart(5) + '%'
  const isPlurality = rank === 0
  const isMajority = isPlurality && pct > 0.5
  const tag = isPlurality
    ? ' ' + (isMajority ? C.winner('▶ 过半胜出') : C.winner('▶ 相对多数'))
    : ''

  return `${colorLabel(label.padEnd(8))} ${bar} ${C.value(votes)} ${C.pct(pctStr)}${tag}`
}

const SPARKS = ' ▁▂▃▄▅▆▇█'
function sparkline(counts) {
  const mx = Math.max(...counts)
  return counts.map(c => {
    if (mx === 0) return ' '
    const idx = Math.round((c / mx) * (SPARKS.length - 1))
    return SPARKS[idx]
  }).join('')
}

function histBars(counts) {
  const mx = Math.max(...counts, 1)
  const H = 6
  const BLOCK = ['░', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']
  return counts.map((c, i) => {
    const ratio = c / mx
    const full = Math.floor(ratio * H)
    const frac = Math.round((ratio * H - full) * 8)
    const bar = '█'.repeat(full) + (frac > 0 && full < H ? BLOCK[frac] : '')
    const t = (i + 0.5) / counts.length
    const colorize = t < 0.4 ? C.cold : t < 0.7 ? C.warm : C.hot
    return { bar: colorize(bar || '▁'), count: c }
  })
}

// ── Run Simulation ────────────────────────────────────────────────────────────

const temperatures = Array.from({ length: N }, () => sampleNormal(MEAN_TEMP, STD_TEMP))
const results = []

process.stderr.write('\n')
process.stderr.write(box([
  C.title('🗳  投票模拟器  Vote Simulator'),
  '',
  C.label('  问题  ') + C.value(question),
  C.label('  选项  ') + options.map((o, i) => i === 0 ? C.winner(o) : C.other(o)).join(C.dim('  ·  ')),
  C.label('  规模  ') + C.value(`${N} agents`) + C.stat(`   温度 μ=${MEAN_TEMP.toFixed(2)} σ=${STD_TEMP.toFixed(2)}`),
]) + '\n')

const progressBar = (done) => {
  const W = 32
  const filled = Math.round((done / N) * W)
  const bar = chalk.green('█'.repeat(filled)) + chalk.dim('░'.repeat(W - filled))
  const pct = ((done / N) * 100).toFixed(0).padStart(3)
  return `  ${C.label('投票中')}  [${bar}]  ${C.value(pct + '%')}  ${C.stat(done + '/' + N)}`
}

for (let i = 0; i < N; i += CONCURRENCY) {
  const batch = temperatures.slice(i, i + CONCURRENCY)
  const done = Math.min(i + CONCURRENCY, N)
  process.stderr.write('\r' + progressBar(done) + '  ')
  const batchResults = await Promise.all(batch.map((temp, j) => castVote(i + j, temp)))
  results.push(...batchResults)
}
process.stderr.write('\r' + progressBar(N) + '  \n\n')

// ── Aggregate ─────────────────────────────────────────────────────────────────

const tally = {}
options.forEach((o) => (tally[o] = 0))
tally['other'] = 0
results.forEach((r) => {
  if (r.vote in tally) tally[r.vote]++
  else tally['other']++
})

const sortedOptions = [...options].sort((a, b) => (tally[b] ?? 0) - (tally[a] ?? 0))
if (tally['other'] > 0) sortedOptions.push('other')

const total = results.length

const buckets = [
  { label: '❄  冷静', range: '0.01–0.40', colorFn: C.cold, votes: results.filter((r) => r.temperature < 0.4) },
  { label: '🌤 温和', range: '0.40–0.70', colorFn: C.warm, votes: results.filter((r) => r.temperature >= 0.4 && r.temperature < 0.7) },
  { label: '🔥 随机', range: '0.70–1.00', colorFn: C.hot,  votes: results.filter((r) => r.temperature >= 0.7) },
]

const HIST_BINS = 10
const histCounts = Array(HIST_BINS).fill(0)
temperatures.forEach((t) => {
  histCounts[Math.min(Math.floor(t * HIST_BINS), HIST_BINS - 1)]++
})
const histLabels = Array.from({ length: HIST_BINS }, (_, i) => `${(i * 0.1).toFixed(1)}`)

const actualMean = (temperatures.reduce((s, t) => s + t, 0) / N).toFixed(3)
const actualStd  = Math.sqrt(temperatures.reduce((s, t) => s + (t - parseFloat(actualMean)) ** 2, 0) / N).toFixed(3)
const sortedTemps = [...temperatures].sort((a, b) => a - b)
const median = sortedTemps[Math.floor(N / 2)].toFixed(3)

// ── Render ────────────────────────────────────────────────────────────────────

// ① 投票结果
const lines1 = [
  C.title('  📊 投票结果'),
  '',
  ...sortedOptions.map((opt, rank) => {
    if (opt === 'other' && tally['other'] === 0) return null
    return '  ' + barRow(opt, tally[opt] ?? 0, total, rank)
  }).filter(Boolean),
]
console.log(box(lines1))
console.log()

// ② 温度区间分析
const zoneParts = []
for (const { label, range, colorFn, votes } of buckets) {
  if (votes.length === 0) continue
  const avgTemp = (votes.reduce((s, r) => s + r.temperature, 0) / votes.length).toFixed(3)
  const subTally = {}
  votes.forEach((r) => { subTally[r.vote] = (subTally[r.vote] || 0) + 1 })
  zoneParts.push(
    `  ${colorFn(label)}  ${C.stat(range)}  ${C.label('n=')}${C.value(String(votes.length))}  ${C.stat('avg_temp=')}${colorFn(avgTemp)}`
  )
  const subSorted = Object.entries(subTally).sort((a, b) => b[1] - a[1])
  for (const [opt, cnt] of subSorted) {
    const pct = (cnt / votes.length * 100).toFixed(0)
    const barLen = Math.round(cnt / votes.length * 24)
    const optRank = sortedOptions.indexOf(opt)
    const colorOpt = optRank === 0 ? C.winner : optRank === 1 ? C.second : C.other
    const colorBar = optRank === 0 ? C.bar_win : optRank === 1 ? C.bar_2nd : C.bar_rest
    zoneParts.push(
      `    ${colorOpt(opt.padEnd(8))} ${colorBar('█'.repeat(barLen) || '')}${C.bar_empty('░'.repeat(24 - barLen))} ${C.stat(String(cnt).padStart(3) + ' (' + pct + '%)')}`
    )
  }
  zoneParts.push('')
}
console.log(box([C.title('  🌡  温度区间分析'), '', ...zoneParts]))
console.log()

// ③ 倾向 × 实际投票 一致性分析
// 按 leanOption 分组，分析各倾向群体的实际投票分布
const leanGroups = {}
options.forEach((o) => (leanGroups[o] = []))
results.forEach((r) => {
  const lo = r.persona?.leanOption
  if (lo && leanGroups[lo]) leanGroups[lo].push(r)
})

const conformLines = [C.title('  👤 倾向 × 实际投票 一致性分析'), '']
const optColors = [C.winner, C.second, C.other, C.warm, C.cold]
for (let i = 0; i < options.length; i++) {
  const opt = options[i]
  const group = leanGroups[opt] || []
  if (group.length === 0) continue
  const colorFn = optColors[i] || C.other
  const conform = group.filter((r) => r.vote === opt).length
  const conformPct = group.length > 0 ? (conform / group.length * 100).toFixed(0) : 0
  const tally_ = {}
  group.forEach((r) => { tally_[r.vote] = (tally_[r.vote] || 0) + 1 })
  const breakdown = Object.entries(tally_)
    .sort((a, b) => b[1] - a[1])
    .map(([o, cnt]) => {
      const rank = sortedOptions.indexOf(o)
      const c = rank === 0 ? C.winner : rank === 1 ? C.second : C.other
      return c(`${o}:${cnt}`)
    }).join(C.stat('  '))
  conformLines.push(
    `  ${colorFn(('→ ' + opt).padEnd(12))}  ` +
    `n=${C.value(String(group.length).padStart(3))}  ` +
    `一致率 ${colorFn(String(conformPct).padStart(3) + '%')}  ` +
    breakdown
  )
}

// 风格 × 投票
conformLines.push('')
conformLines.push(C.stat('  决策风格 × 投票:'))
const styleMap = {}
results.forEach((r) => {
  if (!r.persona) return
  const s = r.persona.style
  if (!styleMap[s]) styleMap[s] = {}
  styleMap[s][r.vote] = (styleMap[s][r.vote] || 0) + 1
})
const topStyles = Object.entries(styleMap)
  .sort((a, b) => Object.values(b[1]).reduce((s, v) => s + v, 0) - Object.values(a[1]).reduce((s, v) => s + v, 0))
  .slice(0, 6)
for (const [style, votes] of topStyles) {
  const total_ = Object.values(votes).reduce((s, v) => s + v, 0)
  const breakdown = Object.entries(votes).sort((a, b) => b[1] - a[1]).map(([opt, cnt]) => {
    const rank = sortedOptions.indexOf(opt)
    const c = rank === 0 ? C.winner : rank === 1 ? C.second : C.other
    return c(`${opt}:${cnt}`)
  }).join(C.stat(' · '))
  conformLines.push(`  ${C.label(style.padEnd(10))}  ${C.stat('n=' + total_)}  ${breakdown}`)
}

console.log(box(conformLines))
console.log()

// ④ 温度分布直方图
const BAR_H = 8
const histMax = Math.max(...histCounts, 1)
const histRows = []
for (let row = BAR_H; row >= 1; row--) {
  const threshold = (row / BAR_H) * histMax
  const cells = histCounts.map((c, i) => {
    const t = (i + 0.5) / HIST_BINS
    const colorize = t < 0.4 ? C.cold : t < 0.7 ? C.warm : C.hot
    if (c >= threshold) return colorize('█')
    else if (c >= threshold - histMax / BAR_H * 0.5) return colorize('▄')
    else return C.stat(' ')
  })
  const rowLabel = row === BAR_H ? C.stat(String(histMax).padStart(3)) : row === Math.ceil(BAR_H / 2) ? C.stat(String(Math.round(histMax / 2)).padStart(3)) : '   '
  histRows.push(`  ${rowLabel} ${C.stat('│')} ${cells.join('   ')}`)
}
histRows.push(`       ${C.stat('└' + '─'.repeat(HIST_BINS * 4 - 3))}`)
histRows.push(`       ${histLabels.map((l) => C.stat(l)).join(' ')}`)

const spark = sparkline(histCounts)
const lines3 = [
  C.title('  📈 温度分布  ') + C.stat(`μ=${actualMean}  σ=${actualStd}  median=${median}`),
  '',
  ...histRows,
  '',
  `   ${C.stat('分布')}  ${C.cold('■ 冷静 <0.4')}  ${C.warm('■ 温和 0.4–0.7')}  ${C.hot('■ 随机 >0.7')}`,
  `   ${C.stat('曲线')}  ${spark}`,
]
console.log(box(lines3))
console.log()
