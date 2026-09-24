# Ada-SPARK-Ravenscar-Job-Pool

Educational Ada 2022 / SPARK sheet: a **fixed carrier worker pool** plus a
**protected job queue**. `Spawn` is goroutine-*shaped* enqueue — it does **not**
dynamically create Ada tasks.

Inspired by the Ada forum thread
[Would it be possible to make a multithreaded runtime like Go goroutines or Rust’s Tokio with Ravenscar?](https://forum.ada-lang.io/t/would-it-be-possible-to-make-a-multithreaded-runtime-like-go-goroutines-or-rust-s-tokio-with-ravenscar/4604)
(ValorZard and replies): under Ravenscar/Jorvik you cannot spawn tasks at
run time, so the practical pattern is a **fixed task set** of carrier workers
that pull jobs from a protected queue.

## Fixed pool vs dynamic spawn

| Model | What happens on `Spawn` |
|-------|-------------------------|
| Go goroutine / many async runtimes | New lightweight thread of control (dynamic) |
| **This sheet** | Job record enqueued; one of `Worker_Count` library-level tasks runs it |

Ravenscar-compatible *pattern* used here:

- Fixed worker tasks created at library elaboration (`Worker_Count` = 4)
- Protected objects for the ready queue, job table / futures, and channel
- No `select`, no dynamic task allocation

**Host GNAT (desktop full RTS) is fine** for building and testing. The sheet
documents the Ravenscar-shaped design; it does not require a bare-metal
Ravenscar runtime to run the tests.

## Layout

| Unit | Role | SPARK |
|------|------|-------|
| `Bounded_Buffer` | Sequential circular buffer | **On**, proved |
| `Channel` | Bounded channel Put/Get with Pre/Post | **On**, proved |
| `Channel.Sync` | Protected `PO` Enqueue/Dequeue | **Off** (host PO/tasking) |
| `Job_Table` | Sequential free-stack job table model | **On**, proved |
| `Job_Pool` | `Spawn` / `Await` / `Sync` / `Shutdown` + workers | Spec On, **body Off** |
| `Demo_Jobs` | `Increment_Counter`, `Ping_Channel` | Spec On, **body Off** |

## API sketch

- `Max_Jobs`, `Job_Id` / `Valid_Job_Id`
- `Job_Kind` enum + `Job_Request` data slots (no access-to-subprogram)
- `Spawn` — enqueue work; returns id for `Await`
- `Await` / `Sync` — protected future / idle barrier
- `Channel` — capacity `N` Put/Get with Pre/Post; `Channel.Sync.PO` for concurrent use
- `Shutdown` — drain work, then wake carriers with a sentinel so they exit cleanly

## Build & test

Requires host GNAT (Ada 2022). **No Alire.** SPARK Community / FSF gnatprove for `make prove`.

```bash
make test    # gprbuild -gnatwa -gnat2022 -gnata && ./bin/tests
make prove   # Level 2, cvc5; warnings and checks as errors
make clean
```

## License

MIT — see [LICENSE](LICENSE).

## LLM usage disclosure

AI assistance was used for this project.
