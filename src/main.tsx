import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { ConversationProvider } from '@elevenlabs/react'
import './index.css'
import App from './App.tsx'
import { LIVING_COMMISH_AGENT_ID } from './integrations/commishGestures.ts'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ConversationProvider agentId={LIVING_COMMISH_AGENT_ID}>
      <App />
    </ConversationProvider>
  </StrictMode>,
)
