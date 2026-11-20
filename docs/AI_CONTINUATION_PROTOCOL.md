# BiddWorld AI Continuation & Recovery Protocol

## Purpose
This protocol makes AI-assisted development restartable if Bolt.new reaches a usage limit, a browser/chat crashes, or work moves to another AI tool.

## Source of truth
- Repository: https://github.com/kkjan2006-self/biddworld
- Development branch: `completion-work`
- Protected baseline: `main`
- Supabase project: BiddWorld-Production (`hbqatszyzqobgtauyuzy`, ap-south-1)
- Never create a replacement repository or silently switch branches.
- GitHub is the durable source of truth. An AI builder's private workspace is only a working copy.

## Safe handoff rules
1. Work only on `completion-work`. Do not edit `main` directly.
2. Before starting a session, connect/import this exact repository and select `completion-work`.
3. At the beginning, pull/sync the latest GitHub commit. Confirm the branch name and latest commit SHA.
4. Do not have Bolt and another AI tool edit the same branch simultaneously.
5. Before switching tools, stop edits in the first tool, wait for GitHub status to say Synced, verify the latest commit is visible on GitHub, and download a ZIP backup if the tool offers it.
6. In the replacement tool, import the same repository and branch. Pull/sync before editing.
7. After each coherent module, run tests, TypeScript check and production build; fix failures before checkpointing.
8. Commit/push each verified module with a descriptive message. Never leave the only copy of work in an AI workspace.
9. Keep `docs/PRODUCTION_CHECKLIST.md` and this handover file updated with completed work, pending work, test results, current branch and last verified commit SHA.
10. If sync fails, stop editing. Export/download a ZIP backup first. Do not disconnect the repository or overwrite GitHub until differences have been compared.

## AI tool fallback
- Primary: Bolt.new — import the existing GitHub repository and work on `completion-work`.
- Fallback: Google AI Studio Build mode — use **Add files (+) → Import from GitHub** to import the same repository; link/sync the same branch using its GitHub settings.
- Other GitHub-capable coding agents may be used only if they can pull and push the existing repository/branch without replacing its history.
- Do not use a tool that can only generate a new standalone app or export into a new repository as the sole development workspace.

## Production data protection
- Do not reset, seed, truncate, overwrite or delete Production data.
- Do not run all migrations blindly. The Production database migration history and repository migration set require reconciliation; use forward-only, reviewed migrations after comparing live schema, functions, grants, policies and migration history.
- Never expose Supabase service-role/secret keys in frontend code, prompts, GitHub, or Vite environment variables.
- Use Preview mode or an isolated disposable TEST Supabase project for tests. Never create test users or test transactions in Production.
- Do not enable unfinished bidding, commissions, withdrawals, Fixed Bid, winner selection, winning payments, duplicate IDs or notifications as a side effect of UI work.
- Do not claim a feature is complete based only on UI presence. Verify server-side authorization, RLS, RPC behavior, idempotency, tests and Android browser behavior.

## Required verification commands
Run the repository's configured scripts:
- `npm test`
- `npm run typecheck`
- `npm run build`

Also run relevant SQL/static checks and isolated integration/E2E tests when applicable. Record actual command output and do not report unrun tests as passing.

## Required session handover format
At the end of every AI work session, update the project status with:
- Repository and branch
- Last GitHub commit SHA and link
- Files/modules changed
- Tests actually run and their results
- Work not completed
- Exact next task
- Any uncommitted or unsynced changes (must be disclosed)

## Reusable master instruction for any AI developer

You are continuing the existing BiddWorld project, not creating a new project.

First inspect this repository: https://github.com/kkjan2006-self/biddworld
Use only the existing `completion-work` branch. Preserve `main`. Pull the latest GitHub state before editing and report the current commit SHA.

Read `README.md`, `docs/PRODUCTION_CHECKLIST.md`, all relevant source files, SQL migrations, tests and existing project documentation before making changes. Treat `docs/PRODUCTION_CHECKLIST.md` as the detailed project-state record, but verify it against the current code and database before relying on it.

Continue in bulk by coherent modules, not by repeatedly asking the owner for small approvals. Do not ask the owner to repeat requirements already documented in the repository. Do not create a new repository, replace the existing application, discard working modules, or rewrite unrelated code.

Before each module: inspect dependencies and existing implementation. After each module: run tests, typecheck and build; fix failures; commit and push to `completion-work`; update the handover/status record. If the session or tool stops, the next AI must resume from the latest GitHub commit and this handover record.

Protect BiddWorld-Production. Never reset or overwrite its data, blindly replay migrations, expose secret keys, or use Production for test records. Reconcile migration history and live schema before proposing any database deployment. Keep unfinished financial and auction workflows disabled unless the owner has explicitly enabled the relevant work and all required backend checks pass.

The owner uses an Android phone and needs browser-based, mobile-friendly steps. Keep website UI in English and explain setup steps in Telugu. Prefer free-tier tools and services. Do not purchase hosting or a domain or introduce paid dependencies.

The goal is to complete and verify the existing BiddWorld application while preserving all existing work. Never say 100% complete unless every required module and its backend, security, tests, and Android checks are actually verified.
