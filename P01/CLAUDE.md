# CLAUDE.md

## Project Overview

This is **P01** from the 99 Prolog Problems series. The task is to find the last element of a list.

## Problem Specification

- **Predicate**: `my_last/2`
- **Goal**: Unify the first argument with the last element of the given list.
- **Behavior**:
  - `my_last(X, [a,b,c,d])` → `X = d`
  - `my_last(X, [])` → `no`
  - `my_last(X, list)` → `no`


## Language

- **Prolog** strictly ISO-compatible, `=` (equality, i.e., unification),  `\+` (negation as failure), and `( Test -> Then ; Else)` (the `if-then-else`construct) are allowed, but no cut, no other built-in.
- Use predicates from the LPTP lib when available, as it will help for the proofs.

## Conventions

- Solutions should define the predicate specified in the problem description.