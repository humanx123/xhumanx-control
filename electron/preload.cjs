const { contextBridge, ipcRenderer } = require('electron')
contextBridge.exposeInMainWorld('xhumanx', {
  launch: (target) => ipcRenderer.invoke('launch-agent', target),
  prepare: () => ipcRenderer.invoke('prepare-system'),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
  addProvider: (payload) => ipcRenderer.invoke('add-provider', payload),
  providers: () => ipcRenderer.invoke('provider-list'),
  status: () => ipcRenderer.invoke('service-status')
})
