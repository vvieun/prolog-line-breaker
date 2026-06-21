from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable, Literal, Sequence


Mode = Literal["default", "title", "caption", "table_cell", "paragraph"]
Component = Literal["critical", "linguistic", "punctuation"]


PREPOSITIONS = {
    "в", "во", "на", "к", "ко", "с", "со", "у", "о", "об", "от", "до",
    "за", "из", "по", "под", "над", "при", "про", "для", "без", "перед",
    "через", "между",
}

CONJUNCTIONS = {"и", "а", "но", "или", "либо", "если", "что", "чтобы", "как"}

PARTICLES = {"не", "ни", "же", "ли", "бы", "даже", "только", "лишь"}

WEAK_PRONOUNS = {"это", "этот", "эта", "эти", "его", "ее", "их"}

ABBREVIATIONS = {"рис.", "табл.", "г.", "стр.", "т.е.", "т.д.", "т.п.", "им.", "см."}

SIGN_TOKENS = {"№", "§", "=", ">", "<", ">=", "<=", "+", "-", "*", "/"}

CLOSING_PUNCTUATION = {")", "]", "}", "»", ",", ".", ";", ":", "!", "?"}

OPENING_PUNCTUATION = {"(", "[", "{", "«"}

REMOVABLE_PUNCTUATION = {
    "(", ")", "[", "]", "{", "}", "«", "»", "\"", ",", ".", ";", ":", "!", "?"
}

GOOD_BREAK_PUNCTUATION = {".", "!", "?", ";", ":", ","}

MODE_WEIGHTS = {
    ("default", "one_word_line"): 8000,
    ("default", "ends_with_function_word"): 4000,
    ("default", "unbreakable_group"): 6000,
    ("default", "abbreviation_boundary"): 3000,
    ("default", "break_after_opening_punctuation"): 5000,
    ("default", "break_before_closing_punctuation"): 5000,
    ("default", "number_sign_boundary"): 4000,
    ("default", "good_punctuation_break"): -600,
    ("default", "badness_factor"): 1,
    ("default", "line_count"): 1000,
    ("default", "critical_violation"): 100000,
    ("title", "one_word_line"): 12000,
    ("title", "ends_with_function_word"): 7000,
    ("title", "unbreakable_group"): 9000,
    ("title", "abbreviation_boundary"): 4000,
    ("title", "break_after_opening_punctuation"): 7000,
    ("title", "break_before_closing_punctuation"): 7000,
    ("title", "number_sign_boundary"): 5000,
    ("title", "good_punctuation_break"): -800,
    ("title", "badness_factor"): 1,
    ("title", "line_count"): 1500,
    ("title", "critical_violation"): 100000,
    ("caption", "ends_with_function_word"): 5000,
    ("caption", "unbreakable_group"): 8000,
    ("caption", "good_punctuation_break"): -900,
    ("caption", "line_count"): 1200,
    ("table_cell", "ends_with_function_word"): 3000,
    ("table_cell", "unbreakable_group"): 5000,
    ("table_cell", "good_punctuation_break"): -400,
    ("table_cell", "line_count"): 2500,
    ("paragraph", "ends_with_function_word"): 2500,
    ("paragraph", "unbreakable_group"): 4000,
    ("paragraph", "good_punctuation_break"): -1000,
    ("paragraph", "line_count"): 800,
}


@dataclass(frozen=True)
class LineBreakTask:
    """Описание задачи разбиения текста на строки."""

    tokens: tuple[str, ...]
    width: int
    mode: Mode = "paragraph"

    @classmethod
    def from_words(cls, words: Sequence[str], width: int, mode: Mode = "paragraph") -> LineBreakTask:
        return cls(tuple(words), width, mode)


@dataclass(frozen=True, order=True)
class Score:
    critical: int
    line_count: int
    linguistic: int
    punctuation: int
    typographic: int
    demerits: int = field(compare=True)

    @classmethod
    def empty(cls, mode: Mode) -> Score:
        return cls.from_parts(mode, 0, 0, 0, 0, 0)

    @classmethod
    def from_parts(cls, mode: Mode, critical: int, line_count: int, linguistic: int, punctuation: int, typographic: int) -> Score:
        demerits = (
            critical * weight(mode, "critical_violation")
            + line_count * weight(mode, "line_count")
            + linguistic
            + punctuation
            + typographic
        )
        return cls(critical, line_count, linguistic, punctuation, typographic, demerits)

    def prepend_line(self, mode: Mode, line_score: LineScore) -> Score:
        return Score.from_parts(
            mode,
            self.critical + line_score.critical,
            self.line_count + 1,
            self.linguistic + line_score.linguistic,
            self.punctuation + line_score.punctuation,
            self.typographic + line_score.typographic,
        )

    def as_tuple(self) -> tuple[int, int, int, int, int, int]:
        return self.critical, self.line_count, self.linguistic, self.punctuation, self.typographic, self.demerits


@dataclass(frozen=True)
class Reason:
    name: str
    component: Component
    value: int
    boundary: tuple[str, ...] = ()

    def as_tuple(self) -> tuple[str | tuple[str, ...], Component, int]:
        if self.boundary:
            return (self.name, *self.boundary), self.component, self.value
        return self.name, self.component, self.value


@dataclass(frozen=True)
class LineScore:
    critical: int
    linguistic: int
    punctuation: int
    typographic: int


@dataclass(frozen=True)
class LineReport:
    index: int
    line: list[str]
    length: int
    badness: int
    critical: int
    linguistic: int
    punctuation: int
    reasons: list[Reason]

    def with_index(self, index: int) -> LineReport:
        return LineReport(index, self.line, self.length, self.badness, self.critical, self.linguistic, self.punctuation, self.reasons)

    def as_dict(self) -> dict[str, object]:
        return {
            "index": self.index,
            "line": self.line,
            "length": self.length,
            "badness": self.badness,
            "critical": self.critical,
            "linguistic": self.linguistic,
            "punctuation": self.punctuation,
            "reasons": [reason.as_tuple() for reason in self.reasons],
        }


@dataclass(frozen=True)
class LineWindow:
    start: int
    end: int
    length: int


@dataclass(frozen=True)
class Arrangement:
    lines: list[list[str]]
    score: Score
    report: list[LineReport]

    def reindexed(self) -> Arrangement:
        return Arrangement(self.lines, self.score, [item.with_index(index) for index, item in enumerate(self.report, start=1)])


class LineBreaker:
    def __init__(self, task: LineBreakTask) -> None:
        self.task = task
        self.tokens = task.tokens
        self.best_by_start: list[Arrangement | None] = [None] * (len(self.tokens) + 1)

    def solve(self) -> Arrangement:
        self.best_by_start[-1] = Arrangement([], Score.empty(self.task.mode), [])
        for start in range(len(self.tokens) - 1, -1, -1):
            self.best_by_start[start] = self._best_starting_at(start)
        result = self.best_by_start[0]
        if result is None:
            raise ValueError("no arrangement")
        return result.reindexed()

    def _best_starting_at(self, start: int) -> Arrangement | None:
        candidates = [candidate for window in self._line_windows(start) if (candidate := self._arrangement_for(window))]
        return min(candidates, key=lambda candidate: candidate.score) if candidates else None

    def _line_windows(self, start: int) -> Iterable[LineWindow]:
        length = 0
        for end in range(start, len(self.tokens)):
            token = self.tokens[end]
            length = len(token) if end == start else length + token_gap(self.tokens[end - 1], token) + len(token)
            if length > self.task.width:
                break
            yield LineWindow(start, end + 1, length)

    def _arrangement_for(self, window: LineWindow) -> Arrangement | None:
        tail = self.best_by_start[window.end]
        if tail is None:
            return None
        line = list(self.tokens[window.start:window.end])
        next_token = self.tokens[window.end] if window.end < len(self.tokens) else None
        report, line_score = self._assess_line(line, window.length, next_token)
        return Arrangement([line, *tail.lines], tail.score.prepend_line(self.task.mode, line_score), [report, *tail.report])

    def _assess_line(self, line: list[str], length: int, next_token: str | None) -> tuple[LineReport, LineScore]:
        slack = self.task.width - length
        badness = slack * slack * weight(self.task.mode, "badness_factor")
        reasons = list(self._reasons_for(line, next_token))
        critical = sum(reason.value for reason in reasons if reason.component == "critical")
        linguistic = sum(reason.value for reason in reasons if reason.component == "linguistic")
        punctuation = sum(reason.value for reason in reasons if reason.component == "punctuation")
        report = LineReport(0, line, length, badness, critical, linguistic, punctuation, reasons)
        return report, LineScore(critical, linguistic, punctuation, badness)

    def _reasons_for(self, line: list[str], next_token: str | None) -> Iterable[Reason]:
        last = line[-1]
        mode = self.task.mode
        if len(line) == 1:
            yield Reason("one_word_line", "critical", 1)
            yield Reason("one_word_line", "linguistic", weight(mode, "one_word_line"))
        if is_function_word(normalized(last)):
            yield Reason("ends_with_function_word", "linguistic", weight(mode, "ends_with_function_word"), (last,))
        if next_token is None:
            return
        if is_unbreakable_boundary(last, next_token):
            yield Reason("unbreakable_group", "linguistic", weight(mode, "unbreakable_group"), (last, next_token))
        if is_abbreviation(last):
            yield Reason("abbreviation_boundary", "punctuation", weight(mode, "abbreviation_boundary"), (last, next_token))
        if ends_with_opening_punctuation(last):
            yield Reason("break_after_opening_punctuation", "punctuation", weight(mode, "break_after_opening_punctuation"), (last, next_token))
        if starts_with_closing_punctuation(next_token):
            yield Reason("break_before_closing_punctuation", "punctuation", weight(mode, "break_before_closing_punctuation"), (last, next_token))
        if is_number_sign_boundary(last, next_token):
            yield Reason("number_sign_boundary", "punctuation", weight(mode, "number_sign_boundary"), (last, next_token))
        if is_good_punctuation_break(last) and not is_abbreviation(last) and not starts_with_closing_punctuation(next_token):
            yield Reason("good_punctuation_break", "punctuation", weight(mode, "good_punctuation_break"), (last, next_token))


def arrange_explain(words: Sequence[str], chars_in_line: int, mode: Mode = "paragraph") -> tuple[list[list[str]], tuple[int, int, int, int, int, int], list[dict[str, object]]]:
    task = LineBreakTask.from_words(words, chars_in_line, mode)
    result = LineBreaker(task).solve()
    return result.lines, result.score.as_tuple(), [item.as_dict() for item in result.report]


def weight(mode: Mode, rule: str) -> int:
    return MODE_WEIGHTS.get((mode, rule), MODE_WEIGHTS[("default", rule)])


def is_function_word(token: str) -> bool:
    return token in PREPOSITIONS or token in CONJUNCTIONS or token in PARTICLES or token in WEAK_PRONOUNS


def is_unbreakable_boundary(left: str, right: str) -> bool:
    return is_function_word(normalized(left)) or is_abbreviation(left) or is_number_sign_boundary(left, right)


def is_number_sign_boundary(left: str, right: str) -> bool:
    return (is_sign_or_number(left) and is_sign_or_number(right)) or (is_sign(left) and not is_punctuation_token(right)) or (is_sign(right) and not is_punctuation_token(left))


def is_sign_or_number(token: str) -> bool:
    return is_number(token) or is_sign(token)


def is_sign(token: str) -> bool:
    return normalized(token) in SIGN_TOKENS


def is_number(token: str) -> bool:
    value = normalized(token)
    return bool(value) and value.isdigit()


def is_abbreviation(token: str) -> bool:
    return token.lower() in ABBREVIATIONS


def is_good_punctuation_break(token: str) -> bool:
    return bool(token) and token[-1] in GOOD_BREAK_PUNCTUATION


def token_gap(left: str, right: str) -> int:
    return 0 if no_space_between(left, right) else 1


def no_space_between(left: str, right: str) -> bool:
    return starts_with_closing_punctuation(right) or is_punctuation_token(right) or ends_with_opening_punctuation(left)


def is_punctuation_token(token: str) -> bool:
    return token in CLOSING_PUNCTUATION


def starts_with_closing_punctuation(token: str) -> bool:
    return bool(token) and token[0] in CLOSING_PUNCTUATION


def ends_with_opening_punctuation(token: str) -> bool:
    return bool(token) and token[-1] in OPENING_PUNCTUATION


def normalized(token: str) -> str:
    stripped = token.strip("".join(REMOVABLE_PUNCTUATION))
    return stripped.lower() if stripped else token.lower()


if __name__ == "__main__":
    words = ["разбиение", "слов", "на", "строки", "с", "учетом", "правил", "оформления"]
    lines, score, report = arrange_explain(words, 24, "title")
    print(lines)
    print(score)
    print(report)
