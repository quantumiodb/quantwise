/**
 * QuantWise Browser Relay — Chrome Extension Background Service Worker (MV3)
 *
 * Lifecycle:
 *   1. User clicks extension icon → attach debugger to active tab
 *   2. Connect WebSocket to local relay server (ws://127.0.0.1:<port>)
 *   3. Authenticate with token
 *   4. Forward CDP commands from relay → chrome.debugger
 *   5. Forward CDP events from chrome.debugger → relay
 *
 * MV3 considerations:
 *   - Service worker can be killed at any time
 *   - State persisted in chrome.storage.session
 *   - Keepalive alarm every 25 seconds
 *   - Rehydrate state on service worker restart
 */

// ── Configuration defaults ──
const DEFAULT_PORT = 18792
const DEFAULT_TOKEN = ''
const CDP_VERSION = '1.3'
const MAX_RECONNECT_ATTEMPTS = 5
const BASE_RECONNECT_DELAY_MS = 200

// ── State ──
let ws = null
let attachedTab = null // { tabId, url, title }
let authenticated = false
let reconnectAttempts = 0
let config = { port: DEFAULT_PORT, token: DEFAULT_TOKEN }

// ── Persistence (MV3 service worker survives via chrome.storage.session) ──

async function saveState() {
  try {
    await chrome.storage.session.set({
      relayState: {
        attachedTab,
        authenticated,
        config,
      },
    })
  } catch {
    // storage.session may not be available in all contexts
  }
}

async function rehydrateState() {
  try {
    const data = await chrome.storage.session.get('relayState')
    if (data.relayState) {
      const s = data.relayState
      config = s.config || config
      if (s.attachedTab) {
        // Verify tab still exists
        try {
          const tab = await chrome.tabs.get(s.attachedTab.tabId)
          if (tab) {
            attachedTab = s.attachedTab
            // Re-attach debugger if we were attached
            await attachDebugger(attachedTab.tabId)
            connectWebSocket()
          }
        } catch {
          attachedTab = null
        }
      }
    }
  } catch {
    // Fresh start
  }
}

// ── Load user config from chrome.storage.local ──

async function loadConfig() {
  try {
    const data = await chrome.storage.local.get(['relayPort', 'relayToken'])
    config.port = parseInt(data.relayPort, 10) || DEFAULT_PORT
    config.token = data.relayToken || DEFAULT_TOKEN
  } catch {
    // Use defaults
  }
}

// ── Extension icon click handler ──

chrome.action.onClicked.addListener(async (tab) => {
  if (!tab.id) return

  // Toggle: if already attached to this tab, detach
  if (attachedTab && attachedTab.tabId === tab.id) {
    await detachDebugger(tab.id)
    disconnectWebSocket()
    attachedTab = null
    await saveState()
    updateBadge('OFF')
    return
  }

  // Detach from previous tab if any
  if (attachedTab) {
    await detachDebugger(attachedTab.tabId)
  }

  await loadConfig()

  if (!config.token) {
    console.warn('[QuantWise Relay] No token configured. Open extension options to set token.')
    updateBadge('ERR')
    return
  }

  const success = await attachDebugger(tab.id)
  if (success) {
    attachedTab = { tabId: tab.id, url: tab.url || '', title: tab.title || '' }
    await saveState()
    connectWebSocket()
    updateBadge('ON')
  } else {
    updateBadge('ERR')
  }
})

// ── Debugger management ──

async function attachDebugger(tabId) {
  try {
    await chrome.debugger.attach({ tabId }, CDP_VERSION)
    return true
  } catch (err) {
    // Already attached is OK
    if (err.message?.includes('Already attached')) return true
    console.error('[QuantWise Relay] Failed to attach debugger:', err.message)
    return false
  }
}

async function detachDebugger(tabId) {
  try {
    await chrome.debugger.detach({ tabId })
  } catch {
    // Ignore — may already be detached
  }
}

// Handle debugger detach (user closed DevTools, navigated away, etc.)
chrome.debugger.onDetach.addListener((source, reason) => {
  if (!attachedTab || source.tabId !== attachedTab.tabId) return

  console.log('[QuantWise Relay] Debugger detached:', reason)

  // Try to reattach with exponential backoff
  reattachWithBackoff(source.tabId)
})

async function reattachWithBackoff(tabId) {
  for (let i = 0; i < MAX_RECONNECT_ATTEMPTS; i++) {
    const delay = BASE_RECONNECT_DELAY_MS * Math.pow(2, i) // 200, 400, 800, 1600, 3200
    await sleep(delay)

    try {
      // Verify tab still exists
      await chrome.tabs.get(tabId)
    } catch {
      // Tab closed — give up
      attachedTab = null
      disconnectWebSocket()
      updateBadge('OFF')
      await saveState()
      return
    }

    const success = await attachDebugger(tabId)
    if (success) {
      console.log(`[QuantWise Relay] Reattached debugger after attempt ${i + 1}`)
      updateBadge('ON')
      return
    }
  }

  // All attempts failed
  console.error('[QuantWise Relay] Failed to reattach debugger after max attempts')
  attachedTab = null
  disconnectWebSocket()
  updateBadge('ERR')
  await saveState()
}

// ── CDP event forwarding ──

chrome.debugger.onEvent.addListener((source, method, params) => {
  if (!attachedTab || source.tabId !== attachedTab.tabId) return
  if (!ws || ws.readyState !== WebSocket.OPEN || !authenticated) return

  ws.send(
    JSON.stringify({
      method: 'forwardCDPEvent',
      params: {
        sessionId: `tab-${attachedTab.tabId}`,
        method,
        params: params || {},
      },
    })
  )
})

// ── WebSocket connection to relay server ──

function connectWebSocket() {
  if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
    return
  }

  const url = `ws://127.0.0.1:${config.port}`
  console.log(`[QuantWise Relay] Connecting to ${url}`)

  try {
    ws = new WebSocket(url)
  } catch (err) {
    console.error('[QuantWise Relay] WebSocket creation failed:', err)
    scheduleReconnect()
    return
  }

  ws.onopen = () => {
    console.log('[QuantWise Relay] WebSocket connected, authenticating...')
    reconnectAttempts = 0
    ws.send(
      JSON.stringify({
        type: 'req',
        method: 'connect',
        params: { auth: { token: config.token } },
      })
    )
  }

  ws.onmessage = (event) => {
    let msg
    try {
      msg = JSON.parse(event.data)
    } catch {
      return
    }
    handleRelayMessage(msg)
  }

  ws.onclose = () => {
    console.log('[QuantWise Relay] WebSocket closed')
    authenticated = false
    ws = null
    if (attachedTab) {
      scheduleReconnect()
    }
  }

  ws.onerror = (err) => {
    console.error('[QuantWise Relay] WebSocket error')
    // onclose will fire after this
  }
}

function disconnectWebSocket() {
  authenticated = false
  if (ws) {
    ws.close()
    ws = null
  }
}

function scheduleReconnect() {
  reconnectAttempts++
  if (reconnectAttempts > MAX_RECONNECT_ATTEMPTS) {
    console.error('[QuantWise Relay] Max reconnect attempts reached')
    updateBadge('ERR')
    return
  }
  const delay = BASE_RECONNECT_DELAY_MS * Math.pow(2, reconnectAttempts)
  console.log(`[QuantWise Relay] Reconnecting in ${delay}ms (attempt ${reconnectAttempts})`)
  setTimeout(connectWebSocket, delay)
}

// ── Handle messages from relay server ──

async function handleRelayMessage(msg) {
  // Auth response
  if (msg.type === 'res' && msg.method === 'connect') {
    if (msg.result?.ok) {
      authenticated = true
      console.log('[QuantWise Relay] Authenticated')
      updateBadge('ON')
      // Send current tab info
      sendTabsUpdate()
    } else {
      console.error('[QuantWise Relay] Auth failed:', msg.error)
      updateBadge('ERR')
      disconnectWebSocket()
    }
    return
  }

  // Heartbeat
  if (msg.method === 'ping') {
    ws?.send(JSON.stringify({ method: 'pong' }))
    return
  }
  if (msg.method === 'pong') {
    return
  }

  // CDP command from relay
  if (msg.method === 'forwardCDPCommand' && typeof msg.id === 'number') {
    if (!attachedTab) {
      ws?.send(JSON.stringify({ id: msg.id, error: 'No tab attached' }))
      return
    }

    const { method, params } = msg.params || {}
    try {
      const result = await chrome.debugger.sendCommand(
        { tabId: attachedTab.tabId },
        method,
        params || {}
      )
      ws?.send(JSON.stringify({ id: msg.id, result }))
    } catch (err) {
      ws?.send(JSON.stringify({ id: msg.id, error: err.message || String(err) }))
    }
    return
  }
}

function sendTabsUpdate() {
  if (!ws || ws.readyState !== WebSocket.OPEN || !authenticated) return
  const tabs = attachedTab
    ? [
        {
          sessionId: `tab-${attachedTab.tabId}`,
          tabId: attachedTab.tabId,
          url: attachedTab.url,
          title: attachedTab.title,
        },
      ]
    : []
  ws.send(JSON.stringify({ method: 'tabsUpdate', params: { tabs } }))
}

// ── Track tab URL/title changes ──

chrome.webNavigation.onCompleted.addListener((details) => {
  if (!attachedTab || details.tabId !== attachedTab.tabId || details.frameId !== 0) return
  chrome.tabs.get(details.tabId).then((tab) => {
    if (tab) {
      attachedTab.url = tab.url || ''
      attachedTab.title = tab.title || ''
      saveState()
      sendTabsUpdate()
    }
  })
})

// Clean up if tab is closed
chrome.tabs.onRemoved.addListener((tabId) => {
  if (!attachedTab || attachedTab.tabId !== tabId) return
  attachedTab = null
  disconnectWebSocket()
  updateBadge('OFF')
  saveState()
})

// ── Keepalive alarm (MV3 service workers get killed after ~30s idle) ──

chrome.alarms.create('relay-keepalive', { periodInMinutes: 25 / 60 }) // ~25 seconds

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name !== 'relay-keepalive') return

  // Keep WebSocket alive
  if (ws && ws.readyState === WebSocket.OPEN && authenticated) {
    ws.send(JSON.stringify({ method: 'ping' }))
  }

  // Reconnect if we should be connected but aren't
  if (attachedTab && (!ws || ws.readyState !== WebSocket.OPEN)) {
    connectWebSocket()
  }
})

// ── Badge helper ──

function updateBadge(status) {
  const colors = { ON: '#4CAF50', OFF: '#9E9E9E', ERR: '#F44336' }
  const text = status === 'ON' ? 'ON' : status === 'ERR' ? '!' : ''
  chrome.action.setBadgeText({ text })
  chrome.action.setBadgeBackgroundColor({ color: colors[status] || '#9E9E9E' })
}

// ── Utility ──

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

// ── Startup ──

rehydrateState()
updateBadge('OFF')
