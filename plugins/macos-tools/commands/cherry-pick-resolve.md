Resolve cherry-pick conflicts interactively. Arguments: $ARGUMENTS

Follow these steps:

1. Run `git status` to identify files with conflicts
2. For each conflicted file:
   - Read the file to understand the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Analyze both versions and determine the correct resolution
   - Use the Edit tool to resolve the conflict, keeping the appropriate changes
3. After resolving all conflicts:
   - Stage the resolved files with `git add`
   - Continue the cherry-pick with `git cherry-pick --continue`
4. If the conflicts are too complex, explain the situation and ask the user for guidance

Always show a summary of what was resolved and how.
