# AI Todo App (Jac)

Luke Whelton
68071155

## Feature Added: Snooze Todo

I added a snooze feature so each todo can be hidden temporarily and then reappear automatically.

Supported snooze options:
- 30 seconds
- 1 minute
- 30 minutes
- 1 hour
- Tomorrow

When a todo is snoozed, it is removed from the visible list until its wake time. The app refreshes periodically and shows it again when the snooze expires.

main.jac contains this feature

Key additions:

Todo node includes snoozed_until
snooze_todo(id, mode) backend function
get_todos filters out currently snoozed items
UI snooze buttons in cl def:pub app -> any
periodic refresh (setInterval) to make expired snoozes reappear

## How to Run

1. Go to project folder:
   ```bash
   cd /home/lwhelton/eecs449/my-todo


2. export GOOGLE_API_KEY="your_key_here"


3. rm -rf .jac/data  (just a check to clear old data)

4. jac start main.jac
