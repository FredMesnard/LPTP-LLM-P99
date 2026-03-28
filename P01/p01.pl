% P01: Find the last element of a list.
my_last(X, [X]).
my_last(X, [Y|L]) :- my_last(X, L).
