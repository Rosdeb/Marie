# IPro mobile app — Practice section integration brief

You are building the Practice section of **IPro**, a Flutter app that helps
intellectual-property attorneys and paralegals prepare for professional exams.
The backend is finished and running. Your job is the app side only: do not ask
for backend changes, and do not invent endpoints — every endpoint you need is
listed below.

Read this whole document before writing code. Section 9 is a checklist you must
be able to tick off when you are done.

---

## 1. The one idea that makes the rest make sense

A practice session is always "draw some questions, answer them, see the result".
What differs between the seven **modes** is only **which questions get drawn**.

So:

* There is **one** start endpoint: `POST /practice/session`.
* All seven modes call it. Only the JSON body differs.
* The response is the **same shape** for all seven.
* Therefore the quiz screen, the result screen and the review screen are
  **built once** and reused by all seven modes.

If your Postman collection shows six or seven separate "Start — ..." requests,
those are seven saved example bodies for one endpoint, not seven endpoints.

The seven modes:

| mode | what it draws |
|---|---|
| `by_level` | one office + one discipline + one difficulty level |
| `by_theme` | one office + one discipline + one theme, across all levels |
| `random` | everything in one office (optionally narrowed to a discipline) |
| `theme_across_offices` | the same theme in two or more offices, to compare |
| `review_mistakes` | only questions this user got wrong and has not since fixed |
| `learning_path` | the next questions in curriculum order, resuming where they stopped |
| `demo` | the free sample questions of an office; works with no account |

---

## 2. Vocabulary

Every question in the bank carries these labels. The menu endpoints and the
start body are nothing but filters over them.

| label | meaning | example |
|---|---|---|
| **office** | the patent/trademark office whose law the question tests | `USPTO`, `EPO`, `IPI` |
| **discipline** (`subject`) | branch of IP law | `Patents`, `Trademarks`, `Designs` |
| **level** (`difficulty`) | how hard | `Beginner`, `Intermediate`, `Advanced`, `Expert` |
| **theme** | topic inside a discipline | `Priority`, `Patentability`, `Time limits & remedies` |
| **step** | position in the curriculum, used only by `learning_path` | `2` |

Two things people get wrong:

1. **theme and level are independent axes.** A theme spans all four levels. A
   theme quiz is never restricted to one level — the API rejects it.
2. **the paywall is the office, never the level or the theme.** Every level and
   every theme is included with an office the user has bought.

---

## 3. API basics

**Base URL** — read from config, never hardcode in widgets:

```
https://sabbir2004.ssh.bd/api/v1
```

**Auth** — a JSON Web Token in the standard header:

```
Authorization: Bearer <accessToken>
```

Endpoints are marked below as:

* **public** — works with no token
* **optional token** — works without a token, but send it when the user is
  signed in, because the response is then personalised (access flags, progress)
* **token required** — 401 without one

Send the token whenever you have one, even on `optional token` endpoints.

**Response envelope** — every endpoint wraps its payload:

```json
{ "success": true, "message": "...", "data": {} }
```

List endpoints add `meta`:

```json
{ "success": true, "message": "...", "meta": {}, "data": [] }
```

Unwrap `data` once in your HTTP layer. Everything below describes the contents
of `data`.

**Errors** — non-2xx responses use the same envelope with `success: false` and
a human-readable `message`. **Show `message` to the user as-is.** It is written
for the end user, not for developers. Examples you will actually hit:

| status | message | why |
|---|---|---|
| 400 | `A theme quiz runs across all four levels; it cannot be combined with a single level.` | you sent `level` with `by_theme` |
| 400 | `theme_across_offices needs subject, theme and at least two offices.` | fewer than two offices ticked |
| 401 | `This mode needs an account.` | any mode except `demo` with no token |
| 403 | `Your subscription does not include EPO. The paywall in IPro is the office.` | office not bought |
| 404 | `There are no questions for that choice yet.` | empty pool |
| 404 | `You have no outstanding mistakes. Everything you got wrong you have since answered correctly.` | `review_mistakes` with nothing to review |

---

## 4. Screens

### Already designed (do not redesign)

| # | screen | status |
|---|---|---|
| S1 | **Practice — selected office**: office card, discipline cards, "Available content" | needs a new section, see below |
| S2 | **Practice office catalogue**: all offices grouped International / Regional / National | keep as is |
| S3 | **Choose your level**: four level cards with question count and minutes | keep as is |
| S4 | **Ready to begin?**: confirmation, then Start | must be made generic, see below |
| S5 | **Quiz**: question, four options, timer, Previous / Next, "Report a problem" | keep as is |

### Build these three

| # | screen | for |
|---|---|---|
| **N1** | **How do you want to practise?** — four options | choosing between `by_level`, `by_theme`, `random`, `learning_path` |
| **N2** | **Choose a theme** — list of themes with question counts | `by_theme` |
| **N3** | **Across offices** — discipline, theme, then a multi-select of offices | `theme_across_offices` |

N2 is visually the same component as S3 (a list of tappable cards with a count
and a subtitle). Reuse it.

### Change these two

**S1** — add a section under the discipline cards:

```
Other ways to practise
  ↻  Review my mistakes          47  →      → straight to S4
  ⇄  Compare across offices          →      → N3
```

These two live here, not behind a discipline, because neither is scoped to a
single office + discipline: `review_mistakes` spans everything the user has
answered, and `theme_across_offices` needs several offices at once.

**S4** — today it is hardcoded to `Patents · Beginner`. Seven different paths
now arrive at it, so the subtitle must be built from whatever was chosen:

| arrived from | subtitle |
|---|---|
| `by_level` | `Patents · Beginner` |
| `by_theme` | `Patents · Priority` |
| `random` | `Patents · All levels` |
| `learning_path` | `Patents · Learning path` |
| `review_mistakes` | `Your mistakes · 47 questions` |
| `theme_across_offices` | `Patents · Priority · 3 offices` |
| `demo` | `USPTO · Demo` |

The `Questions` and `Time limit` rows carry over the numbers from the previous
screen. They are a preview — see rule R6 in section 8.

### Navigation map

```
S2 catalogue ──tap office──► S1 practice home
                                │
            ┌───────────────────┼─────────────────────┐
            │                   │                     │
     tap a discipline    "Review my mistakes"   "Compare across offices"
            │                   │                     │
            ▼                   ▼                     ▼
     N1 how to practise        S4                    N3
       │    │    │   │                                │
 by_level│  │    │   │ learning_path                  │
       ▼    │    │   └──────────┐                     │
      S3    │    │ random       │                     │
     level  │    └───────┐      │                     │
            │ by_theme   │      │                     │
            ▼            │      │                     │
           N2 theme      │      │                     │
            │            │      │                     │
            └────────────┴──────┴─────────────────────┘
                              ▼
                    S4 Ready to begin?
                              │
                   POST /practice/session
                              ▼
                        S5 Quiz screen
                              │
                  POST .../submit  ──►  result + review
```

---

## 5. Menu endpoints — what each screen calls

### S2 — office catalogue

```http
GET /practice/offices
GET /practice/offices?subscriptionId=<id>
```

**optional token**

Without `subscriptionId`: all 15 offices, including ones the user has not
bought, each flagged with `hasAccess`. This is the browse/upsell view.

With `subscriptionId`: **only the offices included in that one plan**. Use this
when the user has more than one subscription and has picked which one to look
at. Get the ids from `GET /subscription/my-access` (token required), which
returns the user's subscriptions each with an `id`.

`data` is an array of:

```json
{
  "code": "USPTO",
  "name": "USPTO",
  "territory": "United States",
  "type": "national",
  "disciplines": [{ "name": "Patents", "questions": 1040 }],
  "sheets": 12,
  "questions": 2820,
  "levels": ["Beginner", "Intermediate", "Advanced", "Expert"],
  "hasAccess": true,
  "isAvailable": true
}
```

Field use:

| screen element | field |
|---|---|
| section headers International / Regional / National | `type` = `international` \| `regional` \| `national` |
| office title and subtitle | `name`, `territory` |
| "Included" badge | `hasAccess === true` |
| "Not included with your current plan" | `hasAccess === false` |
| expandable discipline rows | `disciplines[]` |
| "4 levels" badge | `levels.length` |
| "Total sheets" / "Total questions" | `sheets`, `questions` |

`isAvailable: false` means no questions have been imported for that office yet.
Show it greyed out and non-tappable, whatever `hasAccess` says.

### S1 — disciplines of the selected office

```http
GET /practice/offices/{office}/disciplines
```

**optional token** — e.g. `/practice/offices/USPTO/disciplines`

```json
{
  "office": "USPTO",
  "officeName": "USPTO",
  "profileType": "Attorney",
  "disciplines": [
    {
      "name": "Patents",
      "questions": 1040,
      "levels": [
        {
          "level": "Beginner",
          "questions": 260,
          "minutes": 20,
          "questionsPerSession": 20,
          "isAvailable": true
        }
      ]
    }
  ]
}
```

This single response fills **both S1 and S3**. Do not call anything again when
moving from S1 to S3 — keep the chosen discipline object in state.

| screen element | field |
|---|---|
| S1 discipline card title | `name` |
| S1 "4 levels" badge | **count of `levels` where `isAvailable === true`** — never the literal 4 |
| S1 "Beginner to Expert" | first and last available level |
| S3 level card title | `level` |
| S3 "20 questions" badge | `questionsPerSession` |
| S3 "20 mins" | `minutes` |
| S3 button enabled | `isAvailable` |

`minutes` and `questionsPerSession` are configured by the administrator and can
change at any time. **Never hardcode 20 / 20-30-40-50.** Render what arrives.

`profileType` is `Paralegal` or `Attorney` and decides which questions the user
is allowed to see. A paralegal sees only paralegal questions, so their counts
are smaller. You do not filter on it — the server already has.

### N2 — themes of a discipline

```http
GET /practice/offices/{office}/disciplines/{subject}/themes
```

**optional token** — e.g. `/practice/offices/USPTO/disciplines/Patents/themes`

```json
{
  "office": "USPTO",
  "discipline": "Patents",
  "profileType": "Attorney",
  "themes": [
    {
      "theme": "Priority",
      "questions": 60,
      "sessionLength": 20,
      "isShortSession": false
    },
    {
      "theme": "Infringement & remedies",
      "questions": 16,
      "sessionLength": 16,
      "isShortSession": true,
      "note": "This theme has 16 questions: this session has 16."
    }
  ]
}
```

Card title is `theme`; subtitle is `questions`. When `isShortSession` is true
you **must** display `note` on the card, before the user starts. A user who
expects 20 questions and gets 16 without warning will report it as a bug.

There is no level picker on this screen and there must not be one.

### N3 — themes across offices

```http
GET /practice/themes/cross-office?subject=Patents
```

**optional token**

```json
{
  "discipline": "Patents",
  "profileType": "Attorney",
  "excludedOffices": ["WIPO", "UPC"],
  "themes": [
    {
      "theme": "Priority",
      "offices": ["USPTO", "EPO", "IPI"],
      "questions": 180
    }
  ]
}
```

Flow on this screen, in order:

1. Pick a discipline → call the endpoint above with that `subject`.
2. Pick a theme from `themes`.
3. That theme's own `offices` array is the checkbox list. Show only those.
4. Require **at least two** ticked before enabling Start.

`excludedOffices` are never offered here: their theme vocabularies are their
own and cannot be compared. Do not add them back.

### Progress endpoints (optional but recommended)

```http
GET /practice/mistakes
```

**token required**

```json
{ "total": 47, "byOffice": [{ "office": "USPTO", "mistakes": 31 }] }
```

Use `total` for the badge on the "Review my mistakes" row of S1. When `total`
is 0, disable the row — starting the mode would return 404.

```http
GET /practice/learning-path
GET /practice/learning-path?office=USPTO
```

**token required**

```json
[
  {
    "office": "USPTO",
    "discipline": "Patents",
    "lastStepCompleted": 140,
    "totalQuestions": 260,
    "percentage": 54,
    "updatedAt": "..."
  }
]
```

Use it for a progress bar on the `learning_path` option in N1.

### Profile type

```http
PATCH /practice/profile-type
```

**token required**

```json
{ "profileType": "Paralegal" }
```

Ask this once, after sign-up, and expose it in Account settings. It changes
which questions the user sees everywhere.

---

## 6. Starting a session — the one endpoint

```http
POST /practice/session
```

**optional token** — required for every mode except `demo`

Called from exactly one place in the app: the **Start** button on S4.

### The seven bodies

```jsonc
// 1. by_level — office, discipline and level all required
{ "mode": "by_level", "office": "USPTO",
  "subject": "Patents", "level": "Beginner" }

// 2. by_theme — NEVER send "level" here, it is a 400
{ "mode": "by_theme", "office": "USPTO",
  "subject": "Patents", "theme": "Priority" }

// 3. random — "subject" optional; leave it out for the whole office
{ "mode": "random", "office": "USPTO", "subject": "Patents" }

// 4. theme_across_offices — note "offices" (plural array), min 2.
//    There is no "office" key in this body.
{ "mode": "theme_across_offices", "subject": "Patents",
  "theme": "Priority", "offices": ["USPTO", "EPO", "IPI"] }

// 5. review_mistakes — "office" optional, narrows to one office
{ "mode": "review_mistakes" }

// 6. learning_path — office and discipline; no level, no theme
{ "mode": "learning_path", "office": "USPTO", "subject": "Patents" }

// 7. demo — the only one that works signed out.
//    profileType and deviceId only matter when there is no token.
{ "mode": "demo", "office": "USPTO",
  "profileType": "Attorney", "deviceId": "<stable device id>" }
```

Required / forbidden, at a glance:

| mode | required | optional | forbidden | token |
|---|---|---|---|---|
| `by_level` | `office`, `subject`, `level` | — | — | yes |
| `by_theme` | `office`, `subject`, `theme` | — | **`level`** | yes |
| `random` | `office` | `subject` | — | yes |
| `theme_across_offices` | `subject`, `theme`, `offices` (≥2) | — | `WIPO`, `UPC` in `offices` | yes |
| `review_mistakes` | — | `office` | — | yes |
| `learning_path` | `office`, `subject` | — | — | yes |
| `demo` | `office` | `profileType`, `deviceId` | — | **no** |

### The response — identical for all seven

HTTP **201**.

```json
{
  "sessionId": "6ae1b5b3c87d747a54a725e7",
  "mode": "by_level",
  "profileType": "Attorney",
  "office": "USPTO",
  "subject": "Patents",
  "level": "Beginner",
  "totalQuestions": 20,
  "timeLimitMinutes": 20,
  "poolSize": 200,
  "isShortSession": false,
  "note": null,
  "questions": [
    {
      "id": "6ae0...",
      "number": 1,
      "progress": "1 / 20",
      "office": "USPTO",
      "discipline": "Patents",
      "level": "Beginner",
      "theme": "Foundations & institutions",
      "questionText": "Which authority grants Swiss national patents?",
      "options": [
        { "key": "A", "text": "..." },
        { "key": "B", "text": "..." },
        { "key": "C", "text": "..." },
        { "key": "D", "text": "..." }
      ]
    }
  ]
}
```

Notes that matter:

* All questions come down in this one response. **Do not paginate or re-fetch
  per question** — hold the list in memory and page through it locally.
* `options` carries no correct-answer flag. The key is never sent during play.
  Do not try to grade locally; the server grades on submit.
* `options` arrives pre-shuffled. **Render in the order given**; do not sort or
  re-shuffle, or `key` will stop matching what the user sees.
* The top-level label fields (`office`, `subject`, `level`, `theme`) vary by
  mode — only the ones the mode actually used are present. Build the quiz
  header from the **per-question** fields (`office`, `discipline`, `level`,
  `theme`) instead, which are always there; this also handles mixed-level and
  mixed-office sessions, where the header legitimately changes from question to
  question.
* `totalQuestions` and `timeLimitMinutes` here are **authoritative**. They can
  differ from what S4 previewed, when the pool is smaller than the configured
  session length. Rebuild the timer and the "x / y" counter from this response.

---

## 7. Running, submitting and reviewing

### Resume a suspended session

Closing the app suspends a session rather than ending it. On relaunch, if you
hold an unfinished `sessionId`, restore it:

```http
GET /practice/session/{sessionId}
```

**optional token**

Returns the same question list plus the state so far, including
`remainingSeconds` and `remaining` (`"14:32"`), `elapsedSeconds`, `status`, and
each question's previously chosen answer.

`remainingSeconds` is a server-side wall clock and therefore counts the time
the app was closed. It is the **cap**, not the truth: prefer your own persisted
timer, and clamp it to this value.

### Submit

```http
POST /practice/session/{sessionId}/submit
```

**optional token**

```json
{
  "answers": [
    { "questionId": "6ae0...", "selectedKey": "D", "timeSpentSeconds": 12.4 },
    { "questionId": "6ae0...", "selectedKey": null, "timeSpentSeconds": 3.1 }
  ]
}
```

* `questionId` is the `id` from the start response.
* `selectedKey` is `"A" | "B" | "C" | "D"`, or `null` for skipped. Skipped
  counts as wrong.
* `timeSpentSeconds` is **required on every answer and must be greater than 0**.
  Fractions are expected and wanted: send `0.4`, do not round up to 1. Measure
  it per question in the app — the server cannot, because a suspended session
  would count the hours the phone sat in a pocket.
* Include **every** question, including skipped ones.
* Submitting twice returns 400 `This session was already submitted.`

Response:

```json
{
  "sessionId": "...",
  "score": 17,
  "totalQuestions": 20,
  "percentage": 85,
  "totalSeconds": 742.6
}
```

Show this on a result screen. **Do not label it passed or failed** and do not
apply a pass mark of your own — the client has explicitly ruled that out.

### Review

```http
GET /practice/session/{sessionId}/review
```

**optional token** — only after submit, otherwise 400

An array, one entry per question, in session order, unanswered ones included:

```json
[
  {
    "number": 1,
    "questionText": "...",
    "options": [
      { "key": "A", "text": "...", "isCorrect": false, "isChosen": true },
      { "key": "D", "text": "...", "isCorrect": true, "isChosen": false }
    ],
    "selectedKey": "A",
    "isCorrect": false,
    "timeSpentSeconds": 12.4,
    "explanation": "...",
    "legalBasis": "Art. 1 PatA"
  }
]
```

Colour each option from `isCorrect` and `isChosen`; you do not need a separate
correct-answer field. `legalBasis` is plain text with no URL — render as text.

### Report a problem

The "Report a problem" link on the quiz screen:

```http
POST /report
```

**optional token** — deliberately open, so a demo user can report too

```json
{
  "questionId": "6ae0...",
  "message": "Option C looks wrong under current law."
}
```

* `questionId` accepts **either** the Mongo `id` from the start response **or**
  the readable workbook id such as `IPI-Patents_Beginner-1`. Send the `id` you
  already have; no extra lookup.
* `message` must be 5 to 4000 characters.
* Add `reporterEmail` only when there is no signed-in user and you asked for it.
* Do not ask the user to type a question id. Take it from the question on screen.

### History

```http
GET /practice/history?page=1&limit=10&mode=&office=
```

**token required**

`data` is the list of completed sessions; `meta` carries paging **and** a
`summary` object with `sessionsSubmitted`, `questionsAnswered`,
`successPercentage`, `failPercentage`, `averageScorePercentage` and a `time`
block. Use `meta.summary` for the header of a progress screen; it is computed
over the whole filtered record, not just the page.

---

## 8. Rules you must follow

**R1 — Never hardcode a menu.** Offices, disciplines, themes and levels all
come from the endpoints above. The content is still being imported, and a
combination with no questions must not be offered.

**R2 — Levels are not always four.** The administrator can switch a level off.
Count `levels` where `isAvailable === true`. Never print a literal "4 levels".

**R3 — Never hardcode session length or timer.** Use `questionsPerSession` and
`minutes` from the API, and then the authoritative `totalQuestions` and
`timeLimitMinutes` from the start response.

**R4 — Respect the three flags.**
`hasAccess: false` → office is locked, route to the paywall, do not start.
`isAvailable: false` → nothing imported, grey out and do not start.
`isShortSession: true` → show `note` before starting.

**R5 — Never send `level` with `by_theme`.** A theme runs across all four
levels. There must be no level control on N2.

**R6 — S4's numbers are a preview, the start response is the truth.** Rebuild
the counter and the timer from the response, not from what S4 displayed.

**R7 — Do not grade on the device, and do not invent a pass mark.** The server
returns `score` and `percentage`. There is no pass/fail in this product.

**R8 — Do not re-shuffle options.** They arrive shuffled; reordering breaks the
mapping between what is shown and the `key` you submit.

**R9 — Show the server's `message` on error.** It is written for the end user.
Do not replace it with a generic "Something went wrong".

**R10 — One quiz screen for all seven modes.** The start response is identical
in shape; branching the quiz UI by mode is a bug, not a feature.

**R11 — Send the token whenever you have one**, including on `optional token`
endpoints. Without it the user gets the anonymous view: no access flags, no
progress, no saved mistakes.

**R12 — Persist `sessionId` and your own per-question timer** so a session
survives the app being closed, and resume through
`GET /practice/session/{id}`.

---

## 9. Done checklist

- [ ] S2 renders all offices grouped by `type`, with `hasAccess` badges, and
      supports `?subscriptionId=` when the user has several plans
- [ ] S1 shows disciplines from the API and a level count derived from
      `isAvailable`, not a literal 4
- [ ] S1 has the new "Other ways to practise" section with a live mistake count
- [ ] N1 built, offering the four office+discipline modes
- [ ] N2 built, listing themes with counts and the short-session note, and with
      no level control anywhere on it
- [ ] N3 built, with a theme picker and an office multi-select that requires
      two or more
- [ ] S4 subtitle is generic and correct for all seven entry paths
- [ ] All seven bodies from section 6 start a session successfully
- [ ] `by_theme` never sends `level`
- [ ] `theme_across_offices` blocks Start under two offices
- [ ] Quiz screen is a single implementation reused by all seven modes
- [ ] Timer and counter come from the start response, not from S4
- [ ] Every answer submits a positive, fractional `timeSpentSeconds`, including
      skipped ones with `selectedKey: null`
- [ ] Result screen shows score and percentage and says nothing about passing
- [ ] Review screen colours options from `isCorrect` / `isChosen` and shows
      `explanation` and `legalBasis`
- [ ] "Report a problem" posts the on-screen question's id with no typing
- [ ] A suspended session resumes correctly after the app is killed
- [ ] Demo works with no account; every other mode shows the server's own
      message when a token is missing
