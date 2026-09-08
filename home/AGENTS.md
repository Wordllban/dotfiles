# Global agents instructions

- Never use the em dash "—". Use plain dash "-" instead
- Never add yourself as a co-author anywhere: no Co-authored-by trailers, no agent or model name on commits, PRs, reviews, or other git/GitHub metadata
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- Prefer CLI over MCP when available
- Do not try to bypass permission prompts for destructive shell, git, gh, or acli commands
- Don't overuse comments. They must stay short and precise; write them only for complex functions or edge cases. If you think adding a large comment is good idea, it means your code is not self-explanatory and should probably be reconsidered