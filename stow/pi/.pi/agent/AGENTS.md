# Global Agent Rules

## Git restrictions

- `gh` is preferred for PR and repo operations.
- `git` commands are allowed **only with explicit permission in the current chat**.
- Without explicit permission, any operation that would require `git` must be flagged to run manually.

## Persistence

- When I say **`remember`**, persist the note immediately into the appropriate place — `~/.pi/agent/AGENTS.md` for global rules, the relevant skill's `SKILL.md` for domain-specific knowledge, or a project's `AGENTS.md` for project rules.

## Git rebase

- When `git rebase --continue` is needed after resolving conflicts, always run it as `GIT_EDITOR=true git rebase --continue` to suppress the editor prompt.

## Git safety

- **Never** create a git worktree without explicitly asking first.
- **Never** run `git stash` without explicitly asking first.
- **Never** run `npm install`. Always use `yarn install`.
- **Always ask about the base of a new branch** before creating it. Confirm which ref to branch from.

## Code review heuristics

- **Don't trust list ordering.** Indexing an unordered query result with `[0]` is almost always a bug. Prefer storing the exact identifier needed over re-deriving it from a relation list.

## Code style preferences

- **Strict types.** No `any`, no implicit `unknown` leaks. Prefer explicit interfaces, generics, and `as const`.
- **Discriminated unions** over boolean flags or optional-field sprawl. Tag with a `kind` / `status` / `type` literal.
- **Functional patterns.** Pure functions, immutability, composition, `map`/`filter`/`reduce` over imperative loops where it reads cleaner.
- **SOLID**, especially **Open/Closed** — design for extension without modification.
- **TypeScript control flow.** Prefer `if` statements and early returns over ternaries. Reserve `switch` for genuine discriminated-union exhaustiveness checks.
- **Comments: minimal and terse.** Default to no comment. Comment only when the code can't speak for itself — non-obvious *why*, gotchas, edge cases. No narration of *what* the code does.

## Tone

- I'm a senior engineer. Be direct. Skip hedging. State what's true, what's broken, what to do.

## Output formatting

- **No markdown for copy-ready commands.** When emitting a shell command to run/copy, output the bare command — no fences, no backticks, no labels, no prose wrapping.
- **If the response is a command, the response is *just* the command.** No preamble, no trailing explanation. Only add explanation when explicitly asked, there's a genuine safety concern, or multiple alternatives need disambiguating.
