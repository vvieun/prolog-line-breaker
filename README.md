[English](README.md) · [Русский](README.ru.md)

# Line breaking in Prolog

This project splits a list of words into neat lines. The task is built from rules, and Prolog fits such tasks well. You write the rules as simple facts, and Prolog does the search on its own.

The repository is first of all a Prolog solution. A Python version is here for comparison, and a small survey (52 people) checks how readable each one is.

Short summary. People who already know Python find the Python version nicer to read. People who do not know any of the languages find Prolog about as clear, because its facts read almost like ordinary Russian. So Prolog is still a good choice for tasks like this, especially when the rules should stay easy to read.

## Contents

- [Task](#task)
- [How the program works](#how-the-program-works)
- [Extensions over the classic algorithm](#extensions-over-the-classic-algorithm)
- [Why Prolog](#why-prolog)
- [The solution in Prolog](#the-solution-in-prolog)
- [The same in Python](#the-same-in-python)
- [Files](#files)
- [How to run](#how-to-run)
- [Readability survey](#readability-survey)
- [Conclusions](#conclusions)

## Task

When you lay out documents, you often need to split text into short lines. This happens with titles, captions, work names, text in table cells, and short notes.

A limit on the number of characters is not enough by itself. The lines should also look neat:

- a one-word line is bad;
- a line that ends with a function word (a preposition, conjunction, particle or weak pronoun) is bad;
- a break next to brackets, abbreviations, signs or numbers is bad;
- a break right after a period or a comma is good.

You cannot always follow every rule at once. So some rules are soft. Breaking a soft rule adds a **penalty** instead of being forbidden. The program tries different ways to split the text and keeps the one with the smallest total penalty. It can also return a **report** that lists, for each line, why it got a penalty.

The idea comes from the line-breaking algorithm used in TeX, the Knuth-Plass algorithm. It looks at the whole text and chooses the split by a final quality score. Here the same idea is adapted for short Russian texts.

Example (width 24, "title" mode):

```
input:  разбиение слов на строки с учетом правил оформления
output:
  разбиение слов
  на строки с учетом
  правил оформления
```

## How the program works

- **Input.** A list of tokens (`Words`) and the maximum line length (`Width`). A token is a word, an abbreviation, a number, a sign or a punctuation mark.
- **Hard limits.** The token order stays the same, all tokens are used, and a line is never longer than the given width.
- **Soft rules (penalties).** A one-word line, a function word at the end, a break near brackets, abbreviations, signs or numbers. A break after strong punctuation gives a small bonus.
- **Line score.** The "badness" grows when a line is far from full. More empty space means more badness.
- **Total score.** It adds up the number of critical violations, the number of lines, the linguistic and punctuation penalties, and the typographic badness. The program keeps the split with the smallest total.
- **Modes.** `title`, `caption`, `table_cell` and `paragraph` use different weights. For example, a one-word line costs more in a title.

## Extensions over the classic algorithm

The classic TeX (Knuth-Plass) algorithm is made for justified paragraphs. It places breaks so the lines fill evenly, and its cost is mostly typographic, based on how much the spaces stretch or shrink. This project keeps the main idea, scoring the whole split at once, and adds rules for short Russian texts (titles, captions, table cells):

- **Hard width and underfill badness.** The width is a strict cap. The typographic cost grows with how empty a line is (the empty space, squared), and not with stretching.
- **Two tiers, critical and soft.** A one-word line is a critical violation with a very large weight, so any split without one always wins. Everything else is a soft penalty on top.
- **Linguistic rules for Russian.** A line that ends on a function word (a preposition, conjunction, particle or weak pronoun) is penalized. Such a word also forms an unbreakable group with the next token.
- **Punctuation and typographic boundaries.** The program penalizes breaks after opening punctuation, before closing punctuation, around abbreviations, and inside number and sign groups. A break right after strong punctuation (`. , ; : ! ?`) gets a bonus, a negative penalty.
- **Fewer lines are better.** The score also counts the number of lines, so the text is not split more than needed.
- **Modes.** Four weight profiles, `title`, `caption`, `table_cell` and `paragraph`, retune all of the above for the kind of text.
- **An explanation report.** For every line the program records which rules fired and with what weight, so you can explain a result and not just produce it.
- **Token model.** Visual length accounts for no space before closing punctuation and after opening punctuation. Before a word is classified, the token is normalized (outer punctuation is stripped and the case is lowered).

So the part taken from TeX is the idea of scoring the whole text by one total score. The linguistic rules, the critical and soft tiers, the punctuation rules, the modes and the report are added on top.

## Why Prolog

The task is a set of rules. Which words are function words, where a break is bad, where a break is good. In Prolog you write these rules almost as plain statements, and the language searches over all line splits by itself. There is no manual loop and no manual bookkeeping. You describe what a good split is, and Prolog finds it.

```prolog
предлог(в).   предлог(на).   предлог(с).
союз(и).      союз(но).
частица(не).  частица(ли).

служебное_слово(Слово) :- предлог(Слово).
служебное_слово(Слово) :- союз(Слово).
служебное_слово(Слово) :- частица(Слово).
```

You can read this even without knowing Prolog. "`в`, `на`, `с` are prepositions. A function word is a preposition, or a conjunction, or a particle." This closeness to ordinary language is the point.

## The solution in Prolog

Two Prolog files hold the same program, and only the names differ:

- `prolog_ru.pl` has short, clear Russian names (`разбить`, `служебное_слово`, `набрать`, `Ширина`);
- `prolog_en.pl` has the same logic with English names (`arrange_explain`, `function_word`, ...).

The whole program is facts (the rule base) and rules (what a penalty is and how to score a split). Prolog searches the splits, and `keysort` picks the best score.

## The same in Python

For comparison, `line_breaker.py` solves the same task in a pythonic style (dataclasses, generators, `min`). Where Prolog states rules, Python uses sets and a function:

```python
PREPOSITIONS = {"в", "на", "с"}
CONJUNCTIONS = {"и", "но"}
PARTICLES = {"не", "ли"}

def is_function_word(token: str) -> bool:
    return token in PREPOSITIONS or token in CONJUNCTIONS or token in PARTICLES
```

All three files use the same model: the same rule base, the same scoring function, the same search. On the same input they give the same result.

## Files

| file | what it is |
|---|---|
| `prolog_ru.pl` | Prolog version, short names in Russian |
| `prolog_en.pl` | Prolog version, names in English |
| `line_breaker.py` | Python version in a pythonic style |

## How to run

Prolog (needs SWI-Prolog):

```bash
swipl -q -g "consult('prolog_ru.pl'), разбить([разбиение,слов,на,строки,с,учетом,правил,оформления], 24, заголовок, Строки, Оценка, _), write(Строки), nl, halt."

swipl -q -g "consult('prolog_en.pl'), arrange_explain([разбиение,слов,на,строки,с,учетом,правил,оформления], 24, title, Lines, Score, _), write(Lines), nl, halt."
```

Python:

```bash
python3 line_breaker.py
```

All three print the same lines and the same score `(0, 3, 0, 0, 185, 4685)`.

## Readability survey

To check the idea that Prolog is readable too, 52 people saw pairs of fragments, A (Prolog with Russian names) and B (Python), that do the same thing, and rated each one from 0 to 5. They did not need to know the languages.

**Audience.** 52 people. Mostly IT (34), and also humanities, economists, creative fields and others. Most knew Python. Almost no one knew Prolog.

**Average clarity (0-5), and the same split by experience:**

| group | Prolog | Python | gap |
|---|---:|---:|---:|
| everyone (52) | 2.79 | 3.54 | 0.75 |
| people who know programming (40) | 2.91 | 3.85 | 0.94 |
| **people who do not program (12)** | **2.39** | **2.53** | **0.14** |

This is the main result. Python's lead comes mostly from familiarity. Among people who do not know the syntax, the gap almost disappears, and Prolog's facts are about as easy as Python's code.

**"Which one would you choose to explain the program to a beginner?"** Prolog wins overall, 25 against 21, and even among experienced people it is 22 against 17 for Prolog.

For everyday work people still pick Python (43 against 3), because of habit and the ecosystem. The biggest factors in readability were familiar syntax (32) and clear names (28), more than the language itself.

## Conclusions

- Prolog fits rule-based tasks like line breaking. The rules become plain facts, and the search is already built in.
- Python is more familiar, so programmers find it nicer to read, and it stays the practical choice for real work.
- Most of Python's readability lead is familiarity. People who do not know the language find Prolog just as understandable, and they pick it to explain such a program.
