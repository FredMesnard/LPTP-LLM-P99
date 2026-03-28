:- set_prolog_flag(occurs_check,true).
:- [p01].

% --- Test my_last: basic functionality ---
test_last(L, Expected) :-
    (   my_last(X, L), X = Expected
    ->  format("my_last(~w) = ~w  OK~n", [L, Expected])
    ;   format("my_last(~w) = ~w  FAIL~n", [L, Expected])
    ).

test_last_fail(L) :-
    (   \+ my_last(_, L)
    ->  format("my_last(~w) fails  OK~n", [L])
    ;   format("my_last(~w) should fail  FAIL~n", [L])
    ).

:- test_last([a], a).
:- test_last([a,b], b).
:- test_last([a,b,c,d], d).
:- test_last([1], 1).
:- test_last([1,2,3], 3).
:- test_last_fail([]).

% --- Test types: my_last(X,L) => list(L) ---
test_types(L) :-
    (   my_last(_, L), is_list(L)
    ->  format("types(~w)  OK~n", [L])
    ;   format("types(~w)  FAIL~n", [L])
    ).

:- test_types([a]).
:- test_types([a,b,c]).
:- test_types([1,2,3,4,5]).

% --- Test ground: my_last(X,L) with ground L => ground X ---
test_ground(L) :-
    (   my_last(X, L), ground(X)
    ->  format("ground(~w)  OK~n", [L])
    ;   format("ground(~w)  FAIL~n", [L])
    ).

:- test_ground([a]).
:- test_ground([a,b,c]).
:- test_ground([1,2,3]).

% --- Test member: my_last(X,L) => member(X,L) ---
test_member(L) :-
    (   my_last(X, L), member(X, L)
    ->  format("member(~w)  OK~n", [L])
    ;   format("member(~w)  FAIL~n", [L])
    ).

:- test_member([a]).
:- test_member([a,b,c]).
:- test_member([1,2,3,4]).

% --- Test uniqueness: my_last returns a single answer ---
test_unique(L) :-
    findall(X, my_last(X, L), Xs),
    (   length(Xs, 1)
    ->  format("unique(~w)  OK~n", [L])
    ;   format("unique(~w)  FAIL (got ~w)~n", [L, Xs])
    ).

:- test_unique([a]).
:- test_unique([a,b]).
:- test_unique([a,b,c,d]).

% --- Test existence: non-empty list always has a last element ---
test_existence(L) :-
    (   my_last(_, L)
    ->  format("existence(~w)  OK~n", [L])
    ;   format("existence(~w)  FAIL~n", [L])
    ).

:- test_existence([x]).
:- test_existence([x,y]).
:- test_existence([x,y,z]).

:- halt.
