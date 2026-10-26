import React, { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { motion } from 'motion/react'
import { Activity, BrainCircuit, Check, Code2, ExternalLink, Layers3, LoaderCircle, Plus, Settings2, X } from 'lucide-react'
import './styles.css'
import './dialog.css'

function App() {
  const [status, setStatus] = useState({ free: false, lite: false })
  const [busy, setBusy] = useState('')
  const [notice, setNotice] = useState('Preparando sistema...')
  const [showSettings, setShowSettings] = useState(false)
  const [providers, setProviders] = useState([])
  const refresh = () => window.xhumanx?.status?.().then(setStatus).catch(() => {})
  const refreshProviders = () => window.xhumanx?.providers?.().then(setProviders).catch(() => {})
  useEffect(() => { const boot = async () => { const result = await window.xhumanx?.prepare?.(); setNotice(result?.ok ? 'Sistema listo' : (result?.message || 'No se pudo preparar el sistema')); refresh(); refreshProviders() }; boot(); const timer = setInterval(refresh, 2500); return () => clearInterval(timer) }, [])
  const launch = async (target) => { setBusy(target); setNotice(`Iniciando ${target === 'codex' ? 'Codex' : 'Claude Code'}...`); const result = await window.xhumanx?.launch?.(target); setBusy(''); setNotice(result?.ok ? result.message : (result?.message || 'No se pudo iniciar')); refresh() }
  return <main className="app">
    <header><div className="logo"><BrainCircuit size={25} /><span>XHUMANX <b>&amp; IA</b></span></div><div className="header-tools"><span className="local"><i /> LOCAL</span><button className="settings" onClick={() => setShowSettings(true)} title="Configuración de APIs"><Settings2 size={17} /></button></div></header>
    <section className="welcome"><p>CODE CONTROL</p><h1>¿Qué quieres abrir?</h1></section>
    <section className="buttons"><AgentButton name="Claude Code" icon={<Code2 />} accent="violet" busy={busy === 'claude'} onClick={() => launch('claude')} /><AgentButton name="Codex CLI" icon={<Layers3 />} accent="cyan" busy={busy === 'codex'} onClick={() => launch('codex')} /></section>
    <section className="monitor"><div className="monitor-title"><span><Activity size={15} /> MONITOR</span><b>auto:smart</b></div><div className="services"><Service name="FreeLLMAPI" port="31415" ok={status.free} /><Service name="LiteLLM" port="4000" ok={status.lite} /></div><p className="notice">{notice}</p></section>
    <footer>Hecho por <b>XHumanX &amp; IA</b></footer>
    {showSettings && <ProviderDialog providers={providers} onClose={() => setShowSettings(false)} refresh={refreshProviders} />}
  </main>
}

function AgentButton({ name, icon, accent, busy, onClick }) { return <motion.button className={`agent ${accent}`} whileHover={{ scale: 1.025 }} whileTap={{ scale: .98 }} onClick={onClick} disabled={busy}><span className="agent-icon">{busy ? <LoaderCircle className="spin" /> : icon}</span><span>{name}</span><small>{busy ? 'INICIANDO...' : 'ABRIR'}</small></motion.button> }
function Service({ name, port, ok }) { return <div className="service"><i className={ok ? 'ok' : ''} /><span>{name}</span><small>:{port}</small>{ok && <Check size={14} />}</div> }

function ProviderDialog({ providers, onClose, refresh }) {
  const links = [['LLM7', 'https://dash.llm7.io/'], ['Groq', 'https://console.groq.com/keys'], ['Google AI', 'https://aistudio.google.com/app/apikey'], ['Mistral', 'https://console.mistral.ai/api-keys'], ['OpenRouter', 'https://openrouter.ai/keys'], ['Hugging Face', 'https://huggingface.co/settings/tokens'], ['Cerebras', 'https://cloud.cerebras.ai/'], ['NVIDIA NIM', 'https://build.nvidia.com/']]
  const choices = [['groq', 'Groq'], ['google', 'Google AI'], ['gemini', 'Gemini'], ['cerebras', 'Cerebras'], ['mistral', 'Mistral'], ['openrouter', 'OpenRouter'], ['huggingface', 'Hugging Face'], ['cohere', 'Cohere'], ['cloudflare', 'Cloudflare'], ['zhipu', 'Zhipu'], ['pollinations', 'Pollinations'], ['llm7', 'LLM7'], ['nvidia', 'NVIDIA NIM'], ['longcat', 'LongCat'], ['volcengine', 'Volcengine'], ['routeway', 'Routeway']]
  const [platform, setPlatform] = useState('groq')
  const [key, setKey] = useState('')
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const open = (url) => window.xhumanx?.openExternal?.(url) || window.open(url, '_blank')
  const list = providers.length ? providers : [{ name: 'Kilo', status: 'healthy', keyless: true }, { name: 'OVH', status: 'healthy', keyless: true }, { name: 'AI Horde', status: 'healthy', keyless: true }]
  const add = async (event) => { event.preventDefault(); setSaving(true); setMessage('Conectando...'); const result = await window.xhumanx?.addProvider?.({ platform, key }); setSaving(false); setMessage(result?.message || 'No se pudo conectar.'); if (result?.ok) { setKey(''); refresh() } }
  return <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}><div className="dialog"><div className="dialog-head"><div><p className="eyebrow"><Settings2 size={14} /> API CONFIG</p><h2>Proveedores</h2></div><button className="close" onClick={onClose}><X size={18} /></button></div><form className="api-form" onSubmit={add}><div className="form-row"><select value={platform} onChange={(event) => setPlatform(event.target.value)}>{choices.map(([value, label]) => <option value={value} key={value}>{label}</option>)}</select><input type="password" value={key} onChange={(event) => setKey(event.target.value)} placeholder="Pega tu API key" autoComplete="off" /><button className="add-key" disabled={saving || !key.trim()}>{saving ? <LoaderCircle className="spin" size={15} /> : <Plus size={15} />} Añadir</button></div>{message && <p className="form-message">{message}</p>}</form><div className="provider-list">{list.map((provider) => <div className="provider" key={provider.platform || provider.name}><span className="provider-dot" /><span>{provider.name}</span><small>{provider.keyless ? 'SIN CLAVE' : 'CLAVE'}</small><b>{provider.status}</b></div>)}</div><button className="dashboard" onClick={() => open('http://127.0.0.1:31415/')}><Settings2 size={15} /> Configuración avanzada <ExternalLink size={14} /></button><p className="dialog-label">Obtener una clave</p><div className="link-grid">{links.map(([name, url]) => <button key={name} type="button" onClick={() => open(url)}><Plus size={13} /> {name}</button>)}</div><p className="hint">La clave se envía al CLI oficial de FreeLLMAPI y no se escribe en el registro de XHumanX. Para endpoints personalizados usa Configuración avanzada.</p></div></div>
}

createRoot(document.getElementById('root')).render(<App />)
