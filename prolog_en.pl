preposition(в).
preposition(во).
preposition(на).
preposition(к).
preposition(ко).
preposition(с).
preposition(со).
preposition(у).
preposition(о).
preposition(об).
preposition(от).
preposition(до).
preposition(за).
preposition(из).
preposition(по).
preposition(под).
preposition(над).
preposition(при).
preposition(про).
preposition(для).
preposition(без).
preposition(перед).
preposition(через).
preposition(между).

conjunction(и).
conjunction(а).
conjunction(но).
conjunction(или).
conjunction(либо).
conjunction(если).
conjunction(что).
conjunction(чтобы).
conjunction(как).

particle(не).
particle(ни).
particle(же).
particle(ли).
particle(бы).
particle(даже).
particle(только).
particle(лишь).

weak_pronoun(это).
weak_pronoun(этот).
weak_pronoun(эта).
weak_pronoun(эти).
weak_pronoun(его).
weak_pronoun(ее).
weak_pronoun(их).

abbreviation('рис.').
abbreviation('табл.').
abbreviation('г.').
abbreviation('стр.').
abbreviation('т.е.').
abbreviation('т.д.').
abbreviation('т.п.').
abbreviation('им.').
abbreviation('см.').

sign_token('№').
sign_token('§').
sign_token('=').
sign_token('>').
sign_token('<').
sign_token('>=').
sign_token('<=').
sign_token('+').
sign_token('-').
sign_token('*').
sign_token('/').

closing_punctuation(')').
closing_punctuation(']').
closing_punctuation('}').
closing_punctuation('»').
closing_punctuation(',').
closing_punctuation('.').
closing_punctuation(';').
closing_punctuation(':').
closing_punctuation('!').
closing_punctuation('?').

opening_punctuation('(').
opening_punctuation('[').
opening_punctuation('{').
opening_punctuation('«').

removable_punctuation('(').
removable_punctuation(')').
removable_punctuation('[').
removable_punctuation(']').
removable_punctuation('{').
removable_punctuation('}').
removable_punctuation('«').
removable_punctuation('»').
removable_punctuation('"').
removable_punctuation(',').
removable_punctuation('.').
removable_punctuation(';').
removable_punctuation(':').
removable_punctuation('!').
removable_punctuation('?').

good_break_punctuation('.').
good_break_punctuation('!').
good_break_punctuation('?').
good_break_punctuation(';').
good_break_punctuation(':').
good_break_punctuation(',').

mode_weight(default, one_word_line, 8000).
mode_weight(default, ends_with_function_word, 4000).
mode_weight(default, unbreakable_group, 6000).
mode_weight(default, abbreviation_boundary, 3000).
mode_weight(default, break_after_opening_punctuation, 5000).
mode_weight(default, break_before_closing_punctuation, 5000).
mode_weight(default, number_sign_boundary, 4000).
mode_weight(default, good_punctuation_break, -600).
mode_weight(default, badness_factor, 1).
mode_weight(default, line_count, 1000).
mode_weight(default, critical_violation, 100000).

mode_weight(title, one_word_line, 12000).
mode_weight(title, ends_with_function_word, 7000).
mode_weight(title, unbreakable_group, 9000).
mode_weight(title, abbreviation_boundary, 4000).
mode_weight(title, break_after_opening_punctuation, 7000).
mode_weight(title, break_before_closing_punctuation, 7000).
mode_weight(title, number_sign_boundary, 5000).
mode_weight(title, good_punctuation_break, -800).
mode_weight(title, badness_factor, 1).
mode_weight(title, line_count, 1500).
mode_weight(title, critical_violation, 100000).

mode_weight(caption, ends_with_function_word, 5000).
mode_weight(caption, unbreakable_group, 8000).
mode_weight(caption, good_punctuation_break, -900).
mode_weight(caption, line_count, 1200).

mode_weight(table_cell, ends_with_function_word, 3000).
mode_weight(table_cell, unbreakable_group, 5000).
mode_weight(table_cell, good_punctuation_break, -400).
mode_weight(table_cell, line_count, 2500).

mode_weight(paragraph, ends_with_function_word, 2500).
mode_weight(paragraph, unbreakable_group, 4000).
mode_weight(paragraph, good_punctuation_break, -1000).
mode_weight(paragraph, line_count, 800).

function_word(Word) :- preposition(Word).
function_word(Word) :- conjunction(Word).
function_word(Word) :- particle(Word).
function_word(Word) :- weak_pronoun(Word).

:- dynamic best_cache/6.

penalty_weight(Mode, Rule, Weight) :-
    mode_weight(Mode, Rule, Weight),
    !.
penalty_weight(_, Rule, Weight) :-
    mode_weight(default, Rule, Weight).

arrange_explain(Words, CharsInLine, Mode, Lines, Score, Report) :-
    retractall(best_cache(_, _, _, _, _, _)),
    best_from(Words, CharsInLine, Mode, Lines, Score, RawReport),
    reindex_report(RawReport, 1, Report).

best_from(Words, CharsInLine, Mode, Lines, Score, Report) :-
    best_cache(Words, CharsInLine, Mode, Lines, Score, Report),
    !.

best_from([], CharsInLine, Mode, [], Score, []) :-
    !,
    empty_score(Mode, CharsInLine, Score),
    assertz(best_cache([], CharsInLine, Mode, [], Score, [])).

best_from(Words, CharsInLine, Mode, Lines, Score, Report) :-
    findall(Score0-result(Lines0, Report0), candidate_from(Words, CharsInLine, Mode, Lines0, Score0, Report0), Candidates),
    Candidates \= [],
    keysort(Candidates, [Score-result(Lines, Report)|_]),
    assertz(best_cache(Words, CharsInLine, Mode, Lines, Score, Report)).

candidate_from(Words, CharsInLine, Mode, [Line|RestLines], Score, [LineReport|RestReport]) :-
    take_prefix_line(Words, CharsInLine, Line, Rest),
    best_from(Rest, CharsInLine, Mode, RestLines, RestScore, RestReport),
    line_quality(Line, RestLines, CharsInLine, Mode, 0, LineReport, LineCritical, LineLinguistic, LinePunctuation, LineTypographic),
    add_score(Mode, LineCritical, LineLinguistic, LinePunctuation, LineTypographic, RestScore, Score).

take_prefix_line(Words, CharsInLine, Line, Rest) :-
    take_prefix_line_tail(Words, CharsInLine, [], 0, Line, Rest).

take_prefix_line_tail([Word|Tail], CharsInLine, Acc, Length, Line, Tail) :-
    add_token_length(Acc, Word, Length, NewLength),
    NewLength =< CharsInLine,
    reverse([Word|Acc], Line).

take_prefix_line_tail([Word|Tail], CharsInLine, Acc, Length, Line, Rest) :-
    add_token_length(Acc, Word, Length, NewLength),
    NewLength =< CharsInLine,
    take_prefix_line_tail(Tail, CharsInLine, [Word|Acc], NewLength, Line, Rest).

add_token_length([], Word, _, Length) :-
    !,
    atom_length(Word, Length).

add_token_length([Prev|_], Word, Length, NewLength) :-
    atom_length(Word, WordLength),
    token_gap(Prev, Word, Gap),
    NewLength is Length + Gap + WordLength.

empty_score(Mode, CharsInLine, Score) :-
    build_score(Mode, CharsInLine, 0, 0, 0, 0, 0, Score).

add_score(Mode, Critical, Linguistic, Punctuation, Typographic, score(RestCritical, RestLineCount, RestLinguistic, RestPunctuation, RestTypographic, _), Score) :-
    TotalCritical is Critical + RestCritical,
    TotalLineCount is RestLineCount + 1,
    TotalLinguistic is Linguistic + RestLinguistic,
    TotalPunctuation is Punctuation + RestPunctuation,
    TotalTypographic is Typographic + RestTypographic,
    build_score(Mode, _, TotalCritical, TotalLineCount, TotalLinguistic, TotalPunctuation, TotalTypographic, Score).

build_score(Mode, _, Critical, LineCount, Linguistic, Punctuation, Typographic, Score) :-
    penalty_weight(Mode, critical_violation, CriticalWeight),
    penalty_weight(Mode, line_count, LineWeight),
    Demerits is Critical * CriticalWeight + LineCount * LineWeight + Linguistic + Punctuation + Typographic,
    Score = score(Critical, LineCount, Linguistic, Punctuation, Typographic, Demerits).

reindex_report([], _, []).

reindex_report([line(_, Line, Length, Badness, Critical, Linguistic, Punctuation, Reasons)|Tail], Index, [line(Index, Line, Length, Badness, Critical, Linguistic, Punctuation, Reasons)|ResultTail]) :-
    NextIndex is Index + 1,
    reindex_report(Tail, NextIndex, ResultTail).

line_quality(Line, Tail, CharsInLine, Mode, Index, line(Index, Line, length(Length), badness(Badness), critical(Critical), linguistic(Linguistic), punctuation(Punctuation), reasons(Reasons)), Critical, Linguistic, Punctuation, Typographic) :-
    visual_line_length(Line, Length),
    Slack is CharsInLine - Length,
    RawBadness is Slack * Slack,
    penalty_weight(Mode, badness_factor, BadnessFactor),
    Badness is RawBadness * BadnessFactor,
    line_reasons(Line, Tail, Mode, Critical, Linguistic, Punctuation, Reasons),
    Typographic = Badness.

line_reasons(Line, Tail, Mode, Critical, Linguistic, Punctuation, Reasons) :- findall(reason(Type, Component, Value), reason_for_line(Line, Tail, Mode, Type, Component, Value), Reasons),
    sum_component(Reasons, critical, Critical),
    sum_component(Reasons, linguistic, Linguistic),
    sum_component(Reasons, punctuation, Punctuation).

sum_component([], _, 0).

sum_component([reason(_, Component, Value)|Tail], Component, Sum) :-
    !,
    sum_component(Tail, Component, TailSum),
    Sum is Value + TailSum.

sum_component([_|Tail], Component, Sum) :-
    sum_component(Tail, Component, Sum).

reason_for_line(Line, _, _, one_word_line, critical, 1) :-
    length(Line, 1).

reason_for_line(Line, _, Mode, one_word_line, linguistic, Weight) :-
    length(Line, 1),
    penalty_weight(Mode, one_word_line, Weight).

reason_for_line(Line, _, Mode, ends_with_function_word(Last), linguistic, Weight) :-
    last_word(Line, Last),
    normalized_token(Last, Normalized),
    function_word(Normalized),
    penalty_weight(Mode, ends_with_function_word, Weight).

reason_for_line(Line, [NextLine|_], Mode, unbreakable_group(Last, Next), linguistic, Weight) :-
    last_word(Line, Last),
    first_word(NextLine, Next),
    unbreakable_boundary(Last, Next),
    penalty_weight(Mode, unbreakable_group, Weight).

reason_for_line(Line, [NextLine|_], Mode, abbreviation_boundary(Last, Next), punctuation, Weight) :-
    last_word(Line, Last),
    first_word(NextLine, Next),
    abbreviation_boundary(Last, Next),
    penalty_weight(Mode, abbreviation_boundary, Weight).

reason_for_line(Line, [NextLine|_], Mode, break_after_opening_punctuation(Last, Next), punctuation, Weight) :-
    last_word(Line, Last),
    first_word(NextLine, Next),
    ends_with_opening_punctuation(Last),
    penalty_weight(Mode, break_after_opening_punctuation, Weight).

reason_for_line(Line, [NextLine|_], Mode, break_before_closing_punctuation(Last, Next), punctuation, Weight) :-
    last_word(Line, Last),
    first_word(NextLine, Next),
    starts_with_closing_punctuation(Next),
    penalty_weight(Mode, break_before_closing_punctuation, Weight).

reason_for_line(Line, [NextLine|_], Mode, number_sign_boundary(Last, Next), punctuation, Weight) :-
    last_word(Line, Last),
    first_word(NextLine, Next),
    number_sign_boundary(Last, Next),
    penalty_weight(Mode, number_sign_boundary, Weight).

reason_for_line(Line, [NextLine|_], Mode, good_punctuation_break(Last, Next), punctuation, Weight) :-
    last_word(Line, Last),
    first_word(NextLine, Next),
    good_punctuation_break(Last),
    \+ abbreviation_token(Last),
    \+ starts_with_closing_punctuation(Next),
    penalty_weight(Mode, good_punctuation_break, Weight).

unbreakable_boundary(Left, _) :-
    normalized_token(Left, Normalized),
    function_word(Normalized).

unbreakable_boundary(Left, Right) :-
    abbreviation_boundary(Left, Right).

unbreakable_boundary(Left, Right) :-
    number_sign_boundary(Left, Right).

abbreviation_boundary(Left, Right) :-
    abbreviation_token(Left),
    is_number_token(Right).

abbreviation_boundary(Left, _) :-
    abbreviation_token(Left).

number_sign_boundary(Left, Right) :-
    sign_or_number(Left),
    sign_or_number(Right).

number_sign_boundary(Left, Right) :-
    sign_token_raw(Left),
    \+ punctuation_token(Right).

number_sign_boundary(Left, Right) :-
    sign_token_raw(Right),
    \+ punctuation_token(Left).

sign_or_number(Token) :-
    is_number_token(Token).
sign_or_number(Token) :-
    sign_token_raw(Token).

sign_token_raw(Token) :-
    normalized_token(Token, Normalized),
    sign_token(Normalized).

abbreviation_token(Token) :-
    downcase_atom(Token, Lower),
    abbreviation(Lower).

good_punctuation_break(Token) :-
    atom_chars(Token, TokenChars),
    last_word(TokenChars, Last),
    good_break_punctuation(Last).

visual_line_length([], 0).

visual_line_length([Word|Tail], Length) :-
    atom_length(Word, FirstLength),
    visual_line_length_tail(Tail, Word, FirstLength, Length).

visual_line_length_tail([], _, Acc, Acc).

visual_line_length_tail([Word|Tail], Prev, Acc, Length) :-
    atom_length(Word, WordLength),
    token_gap(Prev, Word, Gap),
    NewAcc is Acc + Gap + WordLength,
    visual_line_length_tail(Tail, Word, NewAcc, Length).

token_gap(Prev, Word, 0) :-
    no_space_between(Prev, Word),
    !.

token_gap(_, _, 1).

no_space_between(Prev, Word) :-
    starts_with_closing_punctuation(Word); punctuation_token(Word); ends_with_opening_punctuation(Prev).

punctuation_token(Token) :-
    closing_punctuation(Token).

starts_with_closing_punctuation(Token) :-
    atom_chars(Token, [First|_]),
    closing_punctuation(First).

ends_with_opening_punctuation(Token) :-
    atom_chars(Token, TokenChars),
    last_word(TokenChars, Last),
    opening_punctuation(Last).

normalized_token(Token, Normalized) :-
    atom_chars(Token, Chars),
    strip_left_punctuation(Chars, LeftStripped),
    strip_right_punctuation(LeftStripped, CoreChars),
    CoreChars \= [],
    !,
    atom_chars(Core, CoreChars),
    downcase_atom(Core, Normalized).

normalized_token(Token, Normalized) :-
    downcase_atom(Token, Normalized).

strip_left_punctuation([Char|Tail], Result) :-
    removable_punctuation(Char),
    !,
    strip_left_punctuation(Tail, Result).

strip_left_punctuation(List, List).

strip_right_punctuation(List, Result) :-
    reverse(List, Reversed),
    strip_left_punctuation(Reversed, StrippedReversed),
    reverse(StrippedReversed, Result).

is_number_token(Token) :-
    normalized_token(Token, Normalized),
    atom_chars(Normalized, Chars),
    Chars \= [],
    all_digits(Chars).

all_digits([]).

all_digits([Char|Tail]) :-
    char_type(Char, digit),
    all_digits(Tail).

first_word([Word|_], Word).

last_word([Word], Word) :-
    !.

last_word([_|Tail], Word) :-
    last_word(Tail, Word).
