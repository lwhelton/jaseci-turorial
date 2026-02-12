import from uuid { uuid4 }
import from byllm.lib { Model }
import from time { time }

cl import "./styles.css";

glob llm = Model(model_name="gemini/gemini-2.5-flash");

enum Category { WORK, PERSONAL, SHOPPING, HEALTH, OTHER }

node Todo {
    has id: str,
        title: str,
        done: bool = False,
        category: str = "other",
        snoozed_until: float = 0.0;  # unix timestamp; 0 = not snoozed
}

def now_ts -> float {
    return time();
}



"""Categorize a todo based on its title."""
def categorize(title: str) -> Category by llm();

"""Add a todo with AI categorization."""
def:pub add_todo(title: str) -> dict {
    category = str(categorize(title)).split(".")[-1].lower();
    todo = root ++> Todo(id=str(uuid4()), title=title, category=category);
    return {
        "id": todo[0].id, "title": todo[0].title,
        "done": todo[0].done, "category": todo[0].category,
        "snoozed_until": todo[0].snoozed_until
    };
}

"""Get all todos."""
def:pub get_todos -> list {
    now = now_ts();
    return [
        {
            "id": t.id, "title": t.title, "done": t.done,
            "category": t.category, "snoozed_until": t.snoozed_until
        }
        for t in [root-->](?:Todo)
        if t.snoozed_until <= now
    ];
}

"""Snooze a todo: 30s | 1m | 30m | 1h | tomorrow."""
def:pub snooze_todo(id: str, mode: str) -> dict {
    wake = now_ts();
    if mode == "30s" {
        wake = wake + 30.0;
    } elif mode == "1m" {
        wake = wake + 60.0;
    } elif mode == "30m" {
        wake = wake + 1800.0;
    } elif mode == "1h" {
        wake = wake + 3600.0;
    } elif mode == "tomorrow" {
        wake = wake + 86400.0;
    } else {
        return {};
    }

    for todo in [root-->](?:Todo) {
        if todo.id == id {
            todo.snoozed_until = wake;
            return {"id": todo.id, "snoozed_until": todo.snoozed_until};
        }
    }
    return {};
}


"""Toggle a todo's done status."""
def:pub toggle_todo(id: str) -> dict {
    for todo in [root-->](?:Todo) {
        if todo.id == id {
            todo.done = not todo.done;
            return {
                "id": todo.id, "title": todo.title,
                "done": todo.done, "category": todo.category
            };
        }
    }
    return {};
}

"""Delete a todo."""
def:pub delete_todo(id: str) -> dict {
    for todo in [root-->](?:Todo) {
        if todo.id == id {
            del todo;
            return {"deleted": id};
        }
    }
    return {};
}

cl def:pub app -> any {
    has items: list = [],
        text: str = "";

    async def refresh -> None {
        items = await get_todos();
    }

    async can with entry {
        await refresh();
        setInterval(lambda -> None { refresh(); }, 30000);
    }

    async def add -> None {
        if text.trim() {
            todo = await add_todo(text.trim());
            items = items.concat([todo]);
            text = "";
        }
    }

    async def toggle(id: str) -> None {
        await toggle_todo(id);
        items = items.map(
            lambda t: any -> any {
                return {
                    "id": t.id, "title": t.title,
                    "done": not t.done, "category": t.category,
                    "snoozed_until": t.snoozed_until
                }
                if t.id == id else t;
            }
        );
    }

    async def remove(id: str) -> None {
        await delete_todo(id);
        items = items.filter(lambda t: any -> bool { return t.id != id; });
    }

    async def snooze(id: str, mode: str) -> None {
        await snooze_todo(id, mode);
        items = items.filter(lambda t: any -> bool { return t.id != id; });
    }

    remaining = items.filter(lambda t: any -> bool { return not t.done; }).length;

    return
        <div class="container">
            <h1>AI Todo App</h1>
            <div class="input-row">
                <input
                    class="input"
                    value={text}
                    onChange={lambda e: any -> None { text = e.target.value; }}
                    onKeyPress={lambda e: any -> None {
                        if e.key == "Enter" { add(); }
                    }}
                    placeholder="What needs to be done?"
                />
                <button class="btn-add" onClick={add}>Add</button>
            </div>
            {[
                <div key={t.id} class="todo-item">
                    <input
                        type="checkbox"
                        checked={t.done}
                        onChange={lambda -> None { toggle(t.id); }}
                    />
                    <span class={"todo-title " + ("todo-done" if t.done else "")}>
                        {t.title}
                    </span>
                    <span class="category">{t.category}</span>
                    <button onClick={lambda -> None { snooze(t.id, "30s"); }}>30s</button>
                    <button onClick={lambda -> None { snooze(t.id, "1m"); }}>1m</button>
                    <button onClick={lambda -> None { snooze(t.id, "30m"); }}>30m</button>
                    <button onClick={lambda -> None { snooze(t.id, "1h"); }}>1h</button>
                    <button onClick={lambda -> None { snooze(t.id, "tomorrow"); }}>Tomorrow</button>
                    <button
                        class="btn-delete"
                        onClick={lambda -> None { remove(t.id); }}
                    >
                        X
                    </button>
                </div> for t in items
            ]}
            <div class="count">{remaining} items remaining</div>
        </div>;
}
