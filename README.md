# Cadence

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Next.js](https://img.shields.io/badge/Next.js-16-black)](https://nextjs.org/)
[![React](https://img.shields.io/badge/React-19-149eca)](https://react.dev/)
[![Open Source](https://img.shields.io/badge/open%20source-yes-1f8f5f)](https://github.com/pstepanovum/Cadence)

Cadence is an open-source AI pronunciation coach built with Next.js, Supabase, and Python model services. It combines phoneme-level pronunciation feedback, guided speaking modules, structured conversation practice, and an open-topic AI coach so learners can improve spoken English in one product.

Cadence is designed for people who want more than flashcards: it gives live speech feedback, targeted repetition, theory modules, conversation drills, and a flexible AI coach that keeps the practice loop moving.

## Why Cadence

- phoneme-aware pronunciation feedback instead of vague speaking scores
- guided learning modules and open conversation in the same app
- transcript-based and target-based speaking flows
- modern product UI, not a research demo
- fully open source and free to run with your own infrastructure

## Core Features

- quick pronunciation drills for single words and short replies
- guided sound modules with theory, practice, and assessment
- conversation modules with turn-by-turn coach-led speaking
- open-topic AI Coach for freer spoken practice
- transcript-based and target-based response modes
- authentication, onboarding, checkout, and profile flows

## Product Structure

Cadence currently has three main speaking experiences:

1. `Learn`
   Structured pronunciation modules with theory, practice, and assessment.

2. `Conversation`
   Guided back-and-forth speaking modules where the coach leads the topic and the learner replies turn by turn.

3. `AI Coach`
   Open-topic practice where the user can start on any situation, respond in targeted or freedom mode, and keep the thread going naturally.

## Tech Stack

- `Next.js 16` with the App Router
- `React 19`
- `Tailwind CSS 4`
- `Supabase` for auth and user data
- `Stripe` for billing flows
- `Python` model services for scoring, transcription, TTS, and coach generation

## Who This Is For

- English learners who want sharper pronunciation feedback
- developers building speech-learning products
- researchers or hackers who want a real full-stack pronunciation app to extend
- founders exploring AI-native language-learning UX

## Architecture

Cadence is split into three services:

- `web`
  The Next.js application and user-facing API routes

- `src/ai-engine`
  Pronunciation scoring, reference audio generation, and transcription

- `src/coach-engine`
  Open-topic AI Coach turn generation

The browser only talks to the Next.js app. The Next.js API routes proxy requests to the Python services.

### Local service routing

- `web` -> `http://127.0.0.1:8000`
- `web` -> `http://127.0.0.1:8001`

### Docker service routing

- `web` -> `http://ai-engine:8000`
- `web` -> `http://coach-engine:8001`

## Repository Layout

```text
.
├── src/app                 # Next.js routes
├── src/components          # UI and product components
├── src/lib                 # shared web-side utilities and types
├── src/ai-engine           # pronunciation / TTS / transcription service
├── src/coach-engine        # AI Coach service
├── public                  # static assets
├── supabase                # Supabase project files
├── Dockerfile              # web image
└── docker-compose.yml      # full local stack
```

## Quick Start

### 1. Clone and install web dependencies

```bash
pnpm install
```

### 2. Create local environment files

Start from the included template:

```bash
cp .env.docker.example .env.local
cp .env.docker.example .env
```

Fill in the values you actually use.

If you want the shortest possible first run, use Docker. If you want the fastest product iteration loop, run the web app and both Python services locally.

## Running Cadence

### Recommended local development flow

This is the best day-to-day loop on macOS:

Terminal 1:

```bash
cd src/ai-engine
python main.py
```

Terminal 2:

```bash
cd src/coach-engine
python main.py
```

Terminal 3:

```bash
pnpm dev
```

Then open:

```text
http://localhost:3000
```

### Full stack with Docker

From the repo root:

```bash
docker compose --env-file .env.local up --build
```

Detached mode:

```bash
docker compose --env-file .env.local up --build -d
```

Open:

```text
http://localhost:3000
```

## Stopping the App Cleanly

Normal stop:

```bash
docker compose --env-file .env.local down
```

Recommended day-to-day stop:

```bash
docker compose --env-file .env.local down --remove-orphans
```

Full reset, including cached model downloads:

```bash
docker compose --env-file .env.local down --volumes --remove-orphans
```

## Environment Variables

Cadence does not commit runtime secrets. Use `.env.local` for local development and configure hosted secrets through your deployment platform.

Common web-side variables:

- `NEXT_PUBLIC_APP_URL`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_BRANDFETCH_CLIENT_ID`
- `AI_ENGINE_URL`
- `AI_COACH_ENGINE_URL`

Optional billing variables:

- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRICE_ID`

Optional email variables:

- `BREVO_SMTP_HOST`
- `BREVO_SMTP_PORT`
- `BREVO_SMTP_USER`
- `BREVO_SMTP_PASSWORD`
- `BREVO_API_KEY`

Model-service variables:

- `COACH_LLM_MODEL_ID`
- `COACH_LLM_DEVICE`
- `HF_TOKEN`
- `CADENCE_LOG_LEVEL`

## Deployment

### Recommended production split

Deploy the Next.js app to Vercel and run the Python services on separate infrastructure.

- Vercel:
  hosts the web app
- AI host or VPS:
  hosts `src/ai-engine` and `src/coach-engine`

Then point the web app to those services with:

- `AI_ENGINE_URL=https://ai.your-domain.com`
- `AI_COACH_ENGINE_URL=https://coach.your-domain.com`

### Why the AI services are separate

The pronunciation engine and the coach engine use different Python dependency stacks and model-serving needs. Keeping them separate makes deployment, warmup, and dependency management much more stable.

## GitHub-Friendly Setup

Cadence is organized to be easy to explore:

- `src/app` for routes
- `src/components` for interface and product flows
- `src/lib` for shared product logic
- `src/ai-engine` for pronunciation and audio intelligence
- `src/coach-engine` for AI coach generation

If you are opening the repo for the first time, start with:

1. [README.md](./README.md)
2. [CONTRIBUTING.md](./CONTRIBUTING.md)
3. [src/app/page.tsx](./src/app/page.tsx)
4. [src/components/coach/AiCoachPlayground.tsx](./src/components/coach/AiCoachPlayground.tsx)
5. [src/ai-engine/main.py](./src/ai-engine/main.py)

## Open Source Notes

- Cadence is free to use and open source under the MIT license.
- The repository is meant to be a real product codebase, not a minimal starter.
- If you fork it, make sure you configure your own Supabase, Stripe, email, and model-service credentials.

## Contributing

Issues and pull requests are welcome. Start with [CONTRIBUTING.md](./CONTRIBUTING.md).

## Security

Please do not commit secrets, API keys, `.env` files, or provider tokens. For security issues, see [SECURITY.md](./SECURITY.md).

## Status

Cadence is actively evolving. The UI, learning flows, and model stack are moving quickly, so expect ongoing changes as the product matures.
