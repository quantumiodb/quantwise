const portInput = document.getElementById('port')
const tokenInput = document.getElementById('token')
const saveBtn = document.getElementById('save')

// Load saved config
chrome.storage.local.get(['relayPort', 'relayToken'], (data) => {
  if (data.relayPort) portInput.value = data.relayPort
  if (data.relayToken) tokenInput.value = data.relayToken
})

saveBtn.addEventListener('click', () => {
  chrome.storage.local.set({
    relayPort: parseInt(portInput.value, 10) || 18792,
    relayToken: tokenInput.value.trim(),
  }, () => {
    saveBtn.textContent = 'Saved \u2713'
    saveBtn.classList.add('saved')
    setTimeout(() => {
      saveBtn.textContent = 'Save'
      saveBtn.classList.remove('saved')
    }, 3000)
  })
})
