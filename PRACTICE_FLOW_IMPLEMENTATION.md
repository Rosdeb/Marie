# Practice flow implementation

The app now treats the selected office as the source of truth for the practice
menu. Changing office reloads `GET /practice/offices/{office}/disciplines`; the
home topic cards and Practice discipline cards render that response instead of
a fixed Patents/Trademarks/Designs list.

## User flow

1. Select an office.
2. Select one of the disciplines returned for that office.
3. Choose a practice mode on **How do you want to practise?**:
   - **By level** opens the API-provided available levels.
   - **By theme** opens the API-provided themes for the selected office and
     discipline. It never displays or sends a level.
   - **Random mix** goes to the shared confirmation screen.
   - **Learning path** goes to the shared confirmation screen.
4. The shared **Exam Ready** screen builds its subtitle and request from the
   selected mode.
5. Its Start button calls the existing `POST /practice/session` integration and
   every mode continues into the same active quiz screen.

## Data rules implemented

- Discipline and home-topic rows are dynamic and refresh after office changes.
- Level counts include only `isAvailable: true` levels.
- Level cards use `questionsPerSession` and `minutes` from the API.
- Disabled levels cannot be selected.
- Theme cards show `questions`, `sessionLength`, and the required short-session
  `note` when present.
- `by_theme` sends `office`, `subject`, and `theme`; it does not send `level`.
- `random` and `learning_path` do not send a stale level or theme.
- Optional-auth menu calls send the access token when it exists, while still
  working without one.
- Confirmation values are previews. The existing quiz provider rebuilds the
  timer and question count from the authoritative session-start response.

## Routes

- `/practice/choose-mode`
- `/practice/choose-theme`
- `/practice/choose-level`
- `/practice/exam-ready`

The cross-office comparison and mistakes rows described in the larger backend
brief are separate global modes. They are intentionally not represented as
discipline topic cards because they are not scoped to one selected office and
discipline.
