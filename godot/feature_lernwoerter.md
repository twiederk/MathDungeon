# Feature: Lernwörter (German Word-Forms Exercise)

## Goal

Add a new quiz exercise type that drills German spelling/grammar — verb conjugation (principal
parts), past participles, noun plurals, and pronoun/determiner declension plus other tricky
standalone words — as a counterpart to the existing `EnglishVocabularyExerciseGenerator`
(translation) and `NumberRiddleExerciseGenerator` (math riddles).

## Source data

The following answers were supplied as the target word list and were analysed into four groups:

```
die Liebe
lieben-liebt-liebten
der Friede
dies-diesem-diesen
das Fieber
hier
lesen-liest-lasen
scheinen-scheint-schienen
schlafen-schläft-schliefen
schreiben-schreibt-schrieben
geschrieben
zielen-zielt-zielten

oben
ab
der Fisch-die Fische
gegen
gleich
mich-mir
die Nase-die Nasen
nicht
ob
die Tür-die Türen
springen-springt-sprangen
rufen-ruft-riefen
```

| Group | Entries | Pattern |
|---|---|---|
| Verb principal parts | lieben, lesen, scheinen, schlafen, schreiben, zielen, springen, rufen | `infinitive,present_3sg,preterite_3pl` |
| Participle | geschrieben | `infinitive,participle` |
| Noun singular↔plural | der Fisch-die Fische, die Nase-die Nasen, die Tür-die Türen | `singular_with_article,plural_with_article` |
| Catch-all curated Q/A | dies-diesem-diesen, mich-mir, die Liebe, der Friede, das Fieber, hier, oben, ab, gegen, gleich, nicht, ob | no generic template fits; author `question,answer` directly |

## Decisions

| Topic | Decision |
|---|---|
| Generator shape | One generator, `class_name GermanWordFormsExerciseGenerator`, duck-typed `create_exercise() -> Exercise` like all other generators (no inheritance) |
| Sub-type dispatch | `enum FormType { VERB_FORM, PARTICIPLE, NOUN_PLURAL, WORD_FORM }`, random pick per `create_exercise()` call, mirroring `NumberRiddleExerciseGenerator`'s `match` pattern |
| Data storage | New `.txt` files in `quiz/dictionaries/`, loaded at `_init()` like `EnglishVocabularyExerciseGenerator._load_dictionary()` |
| Verb form question | Always give the infinitive; randomly ask for the present-3sg form or the preterite-3pl form |
| Noun plural question | Randomly ask singular→plural or plural→singular |
| Pronoun/standalone words | No algorithmic generation — fully authored `question,answer` pairs (same philosophy as the riddle generator's hardcoded entries), because a generic template risks trivial or ambiguous questions for this heterogeneous, small set |
| Answer format | Includes article where the source data has one (e.g. `die Fische`, `der Friede`) — exact string match against `Exercise.result`, matching `quiz_dialog._check_answer()` |
| Integration | New `EnemyStats.ArithmeticType` value `GERMAN_WORD_FORMS`, registered in `quiz_dialog.gd` like the other generators |

## Example questions

- Verb form: "Wie lautet die er/sie/es-Form (Präsens) von *lesen*?" → `liest`
- Verb form: "Wie lautet die Vergangenheitsform (Mehrzahl) von *schlafen*?" → `schliefen`
- Participle: "Wie heißt das Wort nach „ich habe“, wenn man „schreiben“ verwendet?" → `geschrieben`
- Noun plural: "Wie lautet die Mehrzahl von *der Fisch*?" → `die Fische`
- Noun plural: "Wie lautet die Einzahl von *die Türen*?" → `die Tür`
- Catch-all: "Wie lautet die Dativform (Einzahl) von „dies“?" → `diesem`
- Catch-all: "Ergänze mit Artikel: Fr___e (Gegenteil von Streit)" → `der Friede`
- Catch-all: "Ergänze die Präposition: Das Spiel steht 2:1 ___ uns." → `gegen`

## Current state

- `quiz/english_vocabulary_exercise_generator.gd` loads comma-separated `german,english` pairs from
  `quiz/dictionaries/*.txt` and builds translation questions.
- `quiz/number_riddle_exercise_generator.gd` hardcodes several riddle sub-types selected via
  `riddle_types` + `match`.
- `quiz/exercise.gd` is the shared `Exercise` data holder (`question`, `result`), with no base class
  for generators — they're duck-typed.
- `quiz/quiz_dialog.gd` instantiates one generator instance per exercise variant and dispatches on
  `EnemyStats.ArithmeticType` in `_create_exercise()`. Answer checking is a plain string equality
  check against `Exercise.result` typed into `answer_line_edit`.
- `enemies/enemy_stats.gd` defines the `ArithmeticType` enum consumed by `quiz_dialog.gd` and
  assigned per-enemy via `.tres` stats resources.

## Phases

Each phase is independently shippable.

### Phase 1 — Data files

Create the four dictionary files under `quiz/dictionaries/`:

- `german_verb_forms.txt` — lines `infinitive,present_3sg,preterite_3pl`:
  ```
  lieben,liebt,liebten
  lesen,liest,lasen
  scheinen,scheint,schienen
  schlafen,schläft,schliefen
  schreiben,schreibt,schrieben
  zielen,zielt,zielten
  springen,springt,sprangen
  rufen,ruft,riefen
  ```
- `german_participles.txt` — lines `infinitive,participle`:
  ```
  schreiben,geschrieben
  ```
- `german_noun_plurals.txt` — lines `singular_with_article,plural_with_article`:
  ```
  der Fisch,die Fische
  die Nase,die Nasen
  die Tür,die Türen
  ```
- `german_word_forms.txt` — lines `question,answer`, fully authored, e.g.:
  ```
  Wie lautet die Dativform (Einzahl) von „dies“?,diesem
  Wie lautet die Akkusativform (Mehrzahl) von „dies“?,diesen
  Wie lautet die Akkusativform von „ich“ (mich oder mir)?,mich
  Wie lautet die Dativform von „ich“ (mich oder mir)?,mir
  Ergänze mit Artikel: Fr___e (Gegenteil von Streit)?,der Friede
  Ergänze mit Artikel: L___e (ein Gefühl)?,die Liebe
  Ergänze mit Artikel: F___er (hohe Körpertemperatur)?,das Fieber
  Wie lautet das Gegenteil von „dort“?,hier
  Wie lautet das Gegenteil von „unten“?,oben
  Wie lautet das Gegenteil von „auf“ (z. B. den Knopf ___ machen)?,ab
  Ergänze die Präposition: Das Spiel steht 2:1 ___ uns.,gegen
  Wie lautet ein Wort für „genauso/sofort“?,gleich
  Verneine: „Das ist richtig.“ → „Das ist ___ richtig.“,nicht
  Ergänze die Fragepartikel: Ich weiß nicht, ___ das stimmt.,ob
  ```

### Phase 2 — Generator

Create `quiz/german_word_forms_exercise_generator.gd`:

- `class_name GermanWordFormsExerciseGenerator`
- `enum FormType { VERB_FORM, PARTICIPLE, NOUN_PLURAL, WORD_FORM }`
- `_init()` loads all 4 txt files into `Array[Dictionary]` members, skipping malformed lines (log
  `push_error` on missing file, same as `EnglishVocabularyExerciseGenerator`)
- `create_exercise() -> Exercise` picks a random non-empty `FormType` and dispatches to:
  - `_create_verb_form_exercise()` — random infinitive, random present/preterite target
  - `_create_participle_exercise()` — random infinitive→participle entry
  - `_create_noun_plural_exercise()` — random entry, random direction (singular→plural or reverse)
  - `_create_word_form_exercise()` — random authored `question,answer` entry, returned as-is

### Phase 3 — Integration

- Add `GERMAN_WORD_FORMS` to the `ArithmeticType` enum in `enemies/enemy_stats.gd`.
- In `quiz/quiz_dialog.gd`:
  - add `var german_word_forms_exercise_generator = GermanWordFormsExerciseGenerator.new()`
  - add a `GERMAN_WORD_FORMS` branch in `_create_exercise()` calling
    `german_word_forms_exercise_generator.create_exercise()`
- Assign `GERMAN_WORD_FORMS` to the same enemy `.tres` stats resources that currently use
  `VOCABULARY` / `VOCABULARY_COLOR` (or to new enemies, to be decided during implementation).

## Verification

1. Run the game, fight an enemy whose stats include `GERMAN_WORD_FORMS`, confirm questions render
   correctly and both correct and incorrect text answers behave like existing exercises.
2. If GUT tests exist for other generators (see `addons/gut`, `test/`), add an analogous test file
   for `GermanWordFormsExerciseGenerator` asserting `create_exercise()` returns a non-empty
   question/result across many repeated calls and covers all four `FormType` branches.

## Open questions

1. Which enemies should get `GERMAN_WORD_FORMS` assigned — mirror the enemies currently using
   `VOCABULARY` / `VOCABULARY_COLOR`, or pick new ones?
2. The verb list (8 entries) and noun-plural list (3 entries) are small, so repeats will be frequent
   until the lists grow — same situation as `dictionary.txt` when it started out.
