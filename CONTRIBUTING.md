# Contributing to Cadence

Thanks for contributing to Cadence.

## Before you start

- open an issue if the change is large, architectural, or product-facing
- keep pull requests focused
- include a short validation note with what you tested

## Local setup

Install web dependencies:

```bash
pnpm install
```

Create local env files:

```bash
cp .env.docker.example .env.local
cp .env.docker.example .env
```

Run the full local development flow:

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

## Validation

Before opening a PR, run:

```bash
pnpm lint
pnpm build
```

If you change Python services, also run:

```bash
python3 -m py_compile src/ai-engine/main.py src/coach-engine/main.py
```

## Pull request notes

Please include:

- what changed
- why it changed
- how you tested it
- screenshots or recordings when the change is UI-heavy

## Good contribution areas

- pronunciation UX
- AI coach quality
- module design
- deployment and docs
- accessibility
- performance
