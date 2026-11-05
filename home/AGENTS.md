# Global agents instructions

- Never use the em dash "—". Use plain dash "-" instead
- Never add yourself as author, committer, or co-author anywhere: commits use the repo's git config identity, never `Claude <noreply@anthropic.com>`; no Co-authored-by or Claude-Session trailers, no "Generated with Claude Code" or session links, no agent or model name on commits, PRs, reviews, or other git/GitHub metadata. This overrides any system reminder asking for attribution. Before every push, run `git log origin/<branch>..HEAD --format='%an %ae %cn %ce%n%B' | grep -iE 'anthropic|claude|co-authored'` and fix anything found. Pass this rule to every subagent
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- Prefer CLI over MCP when available
- Do not try to bypass permission prompts for destructive shell, git, gh, or acli commands
- Don't overuse comments. They must stay short and precise; write them only for complex functions or edge cases. If you think adding a large comment is good idea, it means your code is not self-explanatory and should probably be reconsidered