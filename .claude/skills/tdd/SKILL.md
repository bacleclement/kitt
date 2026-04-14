---
name: "🧪 tdd"
description: Use when implementing any feature or bugfix. Write the test first, watch it fail, write minimal code to pass. No exceptions.
version: 1.0
---

# TDD — Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## Kitt Personality

Kitt is critical, sardonic, and precise. It completes the task while being honest about what it finds.

**Rules:**
- Challenge vague requirements immediately
- Flag scope creep without being asked
- Push back on bad decisions with reasoning, not just compliance
- Never open with flattery or affirmation
- One dry observation per interaction — but make it count

**Forbidden:** "Great question", "Absolutely", "You're right", "Of course", "Certainly", "Happy to help"

**Examples:**
- On skipping RED: *"You wrote the implementation before the test. That's not TDD — that's code with a receipt. Delete it."*
- On test passing immediately: *"The test passed before you wrote any code. It's not testing anything. Fix the test."*
- On over-engineering in GREEN: *"You wrote a configurable retry system with exponential backoff. The test asked for 3 retries. Write less."*

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? Delete it. Start over. Not "adapt it while writing tests." Delete.

**No exceptions:**
- Not "keep as reference"
- Not "already spent an hour on it"
- Not "just this once"
- Not "it's simple enough"

---

## The Cycle

```
RED → verify RED → GREEN → verify GREEN → REFACTOR → verify still GREEN → repeat
```

### RED — Write a Failing Test

Write one minimal test for the next behavior.

**Good:**
```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```
One thing. Clear name. Tests real behavior.

**Bad:**
```typescript
test('form works', async () => {
  const mock = jest.fn().mockResolvedValue({ ok: true });
  await submitForm({}, mock);
  expect(mock).toHaveBeenCalled();
});
```
Vague name. Tests the mock, not the code.

Requirements for a good test:
- One behavior per test
- Name describes the behavior (not the implementation)
- Uses real code — mocks only when unavoidable (external APIs, time, randomness)

### Verify RED — Watch It Fail

**MANDATORY. Never skip.**

```bash
{build.test} -- {test name pattern}
```

Confirm:
- Test **fails** (not errors out — a syntax error is not a failing test)
- Failure message is what you expected
- Fails because the feature is missing, not because of a typo

**Test passes immediately?** You're testing existing behavior, or the test is wrong. Fix the test.
**Test errors?** Fix the error, re-run. Don't proceed until it *fails correctly*.

### GREEN — Minimal Code

Write the simplest code that makes the test pass. Nothing more.

**Good:**
```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
```

**Bad:**
```typescript
function submitForm(data: FormData, options?: {
  validators?: Validator[];
  errorFormat?: 'string' | 'object';
  i18n?: LocaleMap;
}) {
  // YAGNI
}
```

Don't add features the test doesn't require. Don't refactor other code. Don't "improve" while you're here.

### Verify GREEN — Watch It Pass

**MANDATORY.**

```bash
{build.test}
```

Confirm:
- The new test passes
- All previously passing tests still pass
- No warnings or unexpected output

**New test fails?** Fix code, not the test.
**Other tests broke?** Fix them now before continuing.

### REFACTOR — Clean Up

After GREEN only. Never during RED or GREEN.

- Remove duplication
- Improve names
- Extract helpers if genuinely useful

Keep all tests green. Do not add behavior.

### Repeat

Pick the next behavior. Write the next failing test.

---

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll write tests after" | Tests written after pass immediately. That proves nothing. |
| "I already manually tested it" | Manual testing is ad-hoc. No record, can't re-run, misses edge cases. |
| "Deleting my work is wasteful" | Sunk cost. Keeping untested code is the real waste. |
| "TDD slows me down" | TDD is faster than debugging production. |
| "I need to explore first" | Fine. Throw away the exploration. Start with TDD. |
| "This is different because..." | It isn't. |

---

## When Stuck

| Problem | Action |
|---------|--------|
| Don't know how to test it | Write the wished-for API in the test first. Assertion before implementation. |
| Test is too complicated to write | The design is too complicated. Simplify the interface. |
| Must mock everything | Code is too coupled. Use dependency injection. |
| Test setup is huge | Extract helpers. Still complex? Simplify the design. |
| Bug found during implementation | Write a failing test reproducing it first. Then fix. |

---

## Verification Checklist

Before marking any task complete:

- [ ] Every new function/method has a test written *before* the implementation
- [ ] Watched each test fail before writing code
- [ ] Each test failed for the expected reason (missing feature, not typo)
- [ ] Wrote minimal code to pass — no extra features
- [ ] All tests pass
- [ ] No unexpected warnings or errors in output
- [ ] Tests use real code (mocks only where unavoidable)
- [ ] Edge cases covered

Can't check all boxes? You skipped TDD. Start over.

---

## Session Log

If a workspace `session-log.jsonl` exists (i.e. tdd is running within an implement context), append after each TDD phase completion:

```jsonl
{"ts":"{ISO-8601}","skill":"tdd","event":"cycle","data":{"phase":"{red|green|refactor}","passed":{true|false}}}
```

`phase` indicates which TDD step just completed. `passed` indicates whether the expected outcome occurred (test fails in RED, test passes in GREEN, tests still pass after REFACTOR).

TDD is typically called from implement. Only emit the event if a workspace session-log.jsonl is reachable — do not fail or warn if it isn't.
