# CLAUDE.md — 99 Prolog Problems (LPTP Verification)

## Project

Formal verification of the 99 Prolog Problems using LPTP (Logic Program Theorem Prover) v1.06. The goal is to provide Prolog code, a test file, and LPTP proofs of properties for some of the 99 Prolog Problems.

## Reference

Read `/Users/fred/Desktop/P99/lptp-reference.md` before writing or debugging any `.pr` file. Update this reference if a new proof tip has been found.

## Structure

The problems are listed in `P-99.html`.  Each problem lives in a `Pxx/` directory containing:
- `pXX.pl` — Prolog program
- `pXX.gr` — ground representation (variable-free clause encoding for LPTP)
- `pXX.pr` — proof file (lemmas, theorems)
- `pXX_test.pl` — SWI-Prolog test file (see Testing below)
- `pXX-experiment-report.md` — experiment report
- `CLAUDE.md` — problem specification

## Conventions

- **Prolog** strictly ISO-compatible, `=` (unification with occurs-check),  `\+` (negation as failure), and `( Test -> Then ; Else)` (the `if-then-else`construct) are allowed, but no cut, no other built-in.
- Use predicates from the LPTP lib when available, as it will help for the proofs.
- Peano naturals: `0`, `s(0)`, `s(s(0))`, ... using the LPTP nat library.
- Hierarchical lemma names: `predicate:property` or `predicate:property:variant`.
- The predicates defined in `pXX.pl` and `pXX.gr` must correspond exactly.
- Copy `.gr` and `.pr` to `/Users/fred/lptp/tmp/` before verification.
- Command: `cd /Users/fred/lptp && printf "io__exec_file('tmp/pXX.pr').\nhalt.\n" | bin/lptp 2>&1`
- If `pXX.pr` uses lemmas from another problem (e.g., P35 imports P31), declare the dependency via `:- needs_gr` / `:- needs_thm` and document it in the local `CLAUDE.md`.

## Testing

For each problem Pxx, create a test file `pXX_test.pl` that:
- Starts with `:- set_prolog_flag(occurs_check,true).` as the very first line.
- Loads the program via `:- [pXX].`
- Includes helpers for Peano conversion (`to_peano/2`, `from_peano/2`, etc.) when needed.
- Tests each predicate defined in `pXX.pl` with representative cases: typical inputs, edge cases (empty list, 0, single element), and expected failures.
- Tests each semantic property proved in `pXX.pr` (types, uniqueness, ordered, product, etc.) as a runtime check.
- Prints `OK` or `FAIL` for each test case.
- Ends with `:- halt.`
- Run with: `/Applications/SWI-Prolog.app/Contents/MacOS/swipl pXX_test.pl`

## Properties to verify systematically

1. **Types** (`pred:types`) — type preservation (list, nat, etc.)
2. **Groundness** (`pred:ground`) — ground inputs => ground outputs
3. **Termination** (`pred:termination`) — termination under preconditions
4. **Uniqueness** (`pred:uniqueness`) — determinism of the result
5. **Existence** (`pred:existence`) - existence of the result
6. **Functional Correctness** - any link with library predicates or previously solved exercises

## Experiment Report

Each `pXX-experiment-report.md` should contain:
- **Problem statement** — what the predicate does
- **Prolog code** — summary of the predicates defined
- **Properties proved** — list of lemmas with their statement and proof technique (completion, structural induction, strengthened induction, algebraic, etc.)
- **Statistics** — line counts (`.pl`, `.gr`, `.pr`), number of lemmas, proof-to-code ratio
- **Difficulties and lessons learned** — LPTP pitfalls encountered, proof strategies that worked

## Language

- Code, lemma names, and LPTP proofs: English.
- Experiment reports and documentation: English.

