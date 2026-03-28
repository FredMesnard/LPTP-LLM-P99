# CLAUDE.md

## Project Overview

This is **P01** from the 99 Prolog Problems series. The task is to find the last element of a list.

## Problem Specification

- **Predicate**: `my_last/2`
- **Goal**: Unify the first argument with the last element of the given list.
- **Behavior**:
  - `my_last(X, [a,b,c,d])` -> `X = d`
  - `my_last(X, [])` -> `no` (fails -- empty list has no last element)

## Language

- **Prolog** (ISO-compatible)

## Conventions

- Solutions should define the predicate specified in the problem description.
