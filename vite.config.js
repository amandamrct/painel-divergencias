import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// base './' para a página funcionar em qualquer pasta do servidor.
export default defineConfig({
  plugins: [react()],
  base: './',
})
