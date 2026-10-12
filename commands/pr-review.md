---
description: Thorough local review of a BitBucket PR, no posting
argument-hint: <pr-number> [repo]
allowed-tools: Read, Grep, Glob, Task, Bash(git:*), mcp__bitbucket
disable-model-invocation: true
---

Review BitBucket pull request #$1.

## Repository

Resolve in this order:
1. Repository argument, if non-empty: $2
2. `git remote get-url origin` in the working directory, then repo slug.
3. Fallback: `platform-sw`.

If the resolved repo has no PR #$1, stop and tell me rather than guessing.

## Before reviewing

- Read the PR description, the diff, and all existing comments and review
  threads, resolved ones and inline comments included.
- Apply every check in the local review skills. Delegate to the local
  review agents where they fit; require each to report what it examined,
  not only what it found.

## 1. Is this the right change?

Judge the change before judging any line. Correct code can still be the
wrong change.
- Needed at all? Does an existing mechanism already do this?
- Right layer, or a workaround for something that should be fixed
  elsewhere?
- New or modified public API: too intimate? Does it expose internal
  structure, lifetime, ownership, or sequencing that callers shouldn't
  need to know? Could a narrower surface meet the need?
- Hard to misuse? What's the most likely wrong call, and does the design
  prevent it or merely document against it?
- Holds up as the codebase grows: naming, symmetry with existing APIs,
  what it commits us to. API and ABI are effectively permanent, so flag
  anything expensive to walk back.
- Right size? Should it be split; is anything unrelated riding along?

## 2. Line-level

- File by file through the diff. Don't conclude until every changed file
  is done.
- For each changed function, trace callers and callees even in untouched
  files. Most real bugs live at the boundary between changed and unchanged
  code.
- Diff against stated intent: flag anything it does that the description
  doesn't mention.
- What's missing, not just what's wrong: error handling, tests, cleanup on
  failure paths.

## 3. Reconcile with existing comments

- Don't repeat a point already made; if you agree, mark it +1.
- Addressed by a later commit, say so.
- Not addressed but the thread was resolved or went quiet, flag it. Those
  are the ones that slip through.
- Disagree with an existing comment, say so and why.

## Severity

- `blocker`: correctness, safety, resource or lifetime bug, or a permanent
  API/ABI commitment. Must not merge.
- `major`: real bug or design problem off the critical path. Fix first.
- `minor`: should fix, breaks nothing.
- `nit`: preference. Author may ignore.

Don't inflate. If everything is major, nothing is.

## Voice

I paste these comments into BitBucket, so write each finding as a message
to the author, in the voice of an experienced colleague who reviewed the
code and is telling them what he found.

- Plain words. Not "utilize", "leverage", "robust", "comprehensive",
  "ensure", "facilitate", "delve", "crucial", "seamless".
- No em dashes. Commas, colons, or two sentences instead.
- No "it's worth noting", "it's important to", "this raises the question
  of", "not only X but also Y", "at the end of the day".
- No bolded lead-in labels inside a comment.
- Say the thing. "This leaks if the second alloc throws", not "there
  appears to be a potential resource management concern here".
- A real question is fine when you're actually unsure: "is the caller
  guaranteed to hold the lock here?" Don't fake-question something you
  know is wrong.
- Hedge once at most. Not "you might possibly want to perhaps consider".
- No praise padding. If something is genuinely good and worth saying, say
  it in five words.
- Short sentences are fine. Fragments are fine. Vary the length.
- Match the language the PR's existing comments are written in.

Every finding must stand alone. When I paste one into BitBucket the author
sees only that sentence, with no summary above it, so don't write comments
that depend on "as mentioned above" or on the severity tag to make sense.
The N-number is for my reference only, never part of the posted text.

## Output

Be terse. Thoroughness applies to the reviewing, not the writing. Depth of
analysis must not show up as length of output.
- One line per finding, two only if the fix isn't obvious from the first.
- Conclusions, not reasoning. I'll ask for reasoning.
- Number every new comment N1, N2, N3, in severity order, highest first.
  Numbering is stable for the rest of the session: if I ask you to revise
  or drop one, keep the original numbers on everything else and don't
  renumber.
- Empty section, one word: nothing.
- No preamble, no closing paragraph, no restating the diff outside the
  summary.
- Drop anything flagged only because a review is expected to find
  something.

Format:

`<repo>`, resolved from <arg | git remote | fallback>

**Summary** (2 to 3 lines, the only place description is allowed)
What the PR actually does, read from the code. Note it if that differs
from the description. Then a bottom line I can act on: "good, two nits" /
"sound approach, error paths incomplete" / "don't merge, the new API leaks
allocator internals". Confidence: high/med/low. A fundamental design
objection goes here, not buried below.

**New comments**
- `N1` `[blocker] file.cpp:42` then the comment text, postable as written.
- `N2` `[minor] other.cpp:88` then the comment text.

**Existing threads**
- `#3 addressed` / `#5 unaddressed`, one clause each. These are BitBucket
  thread IDs, not my numbering.

**Coverage**
- Files and call paths examined. Skill categories skipped, if any.
- Bare list, no prose.

Do NOT post anything to BitBucket. Present the review and wait for my
explicit approval before publishing.
