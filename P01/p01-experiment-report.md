# Formal Verification of P01 with LPTP: An Experiment Report

## 1. Introduction

This report describes the formal verification of Problem P01 from the 99
Prolog Problems ("Find the last element of a list") using the LPTP (Logic
Program Theorem Prover) system. This is the simplest problem in the series:
a two-clause recursive predicate with no negation and no auxiliary predicates.

## 2. The Prolog Program

```prolog
% P01: Find the last element of a list.
my_last(X, [X]).
my_last(X, [_|L]) :- my_last(X, L).
```

- **Clause 1** (base case): `X` is the last element of the singleton list
  `[X]`.
- **Clause 2** (recursive case): skip the head and recurse on the tail.

Examples:

```
?- my_last(X, [a,b,c,d]).
X = d

?- my_last(X, []).
no

?- my_last(X, [z]).
X = z
```

## 3. LPTP File Structure

| File | Role |
|------|------|
| `p01.pl` | Prolog source defining `my_last/2` |
| `p01.gr` | Ground representation file: variable-free clause encoding for LPTP |
| `p01.pr` | Proof file: formal proofs of six properties |
| `p01.thm` | Theorem file: generated database of proven facts |
| `p01.tex` | TeX file: generated typeset proofs |

The proof file depends on the LPTP standard library module:

- `lib/list/list` for `list/1`, `member/2`, `append/3` and their associated
  theorems.

## 4. Ground Representation

```prolog
:- assert_clauses(n(my_last,2),[
 clause([n(my_last,2),$(x),[n('.',2),$(x),[n([],0)]]],
  [&],
  [x]/0),
 clause([n(my_last,2),$(x),[n('.',2),$(y),$(l)]],
  [n(my_last,2),$(x),$(l)],
  [x,y,l]/0)
]).
```

Key observations:

- **Clause 1.** The singleton list `[X]` is encoded as
  `[n('.',2),$(x),[n([],0)]]` — a cons cell whose head is `$(x)` and
  whose tail is `[]`. The variable `$(x)` appears both as the first
  argument and as the head of the list, capturing the unification
  `my_last(X, [X])`.

- **Clause 2.** The anonymous variable `_` in `[_|L]` is represented as
  the named variable `$(y)`. Since `Y` only appears in the head (not in
  the body), it acts as a don't-care variable. The variable list is
  `[x,y,l]/0` — no existential variables.

## 5. Properties Proved

Six properties were formally proved and machine-checked.

### 5.1 Termination

**Lemma `my_last:termination`.**
If `L` is a proper list, then `my_last(X, L)` terminates.

```
all [x,l]: succeeds list(?l) => terminates my_last(?x,?l)
```

*Proof method:* Induction on `succeeds list(?l)`, with the induction
formula in curried form:
`all l: succeeds list(?l) => (all x: terminates my_last(?x,?l))`.

- **Base** (`L = []`): By completion, `terminates my_last(?x,[])` holds
  trivially since no clause head matches `my_last(X, [])`.

- **Step** (`L = [Y|L']`): By completion, LPTP checks that clause 1
  terminates when `L' = []` and clause 2 terminates using the IH for `L'`.

### 5.2 Type Preservation

**Lemma `my_last:types`.**
If `my_last(X, L)` succeeds, then `L` is a proper list.

```
all [x,l]: succeeds my_last(?x,?l) => succeeds list(?l)
```

*Proof method:* Induction on `succeeds my_last(?x,?l)`, with two steps.

- **Step 1** (clause 1, `L = [X]`): Construct `list([])` then `list([X])`.

- **Step 2** (clause 2, `L = [Y|L']`): The IH gives `list(L')`, and
  `list([Y|L'])` follows.

### 5.3 Membership

**Lemma `my_last:member`.**
If `my_last(X, L)` succeeds, then `X` is a member of `L`.

```
all [x,l]: succeeds my_last(?x,?l) => succeeds member(?x,?l)
```

*Proof method:* Induction on `succeeds my_last(?x,?l)`, with two steps.

- **Step 1** (clause 1, `L = [X]`): `member(X, [X])` holds directly.

- **Step 2** (clause 2, `L = [Y|L']`): The IH gives `member(X, L')`,
  and `member(X, [Y|L'])` follows by the second clause of `member`.

### 5.4 Groundness

**Lemma `my_last:ground`.**
If `my_last(X, L)` succeeds and `L` is ground, then `X` is ground.

```
all [x,l]: succeeds my_last(?x,?l) & gr(?l) => gr(?x)
```

*Proof method:* Induction on `succeeds my_last(?x,?l)`, curried form.

- **Step 1** (clause 1, `L = [X]`): From `gr([X])`, derive `gr(X)`.

- **Step 2** (clause 2, `L = [Y|L']`): From `gr([Y|L'])`, derive
  `gr(L')`. The IH gives `gr(X)`.

### 5.5 Characterization via Append

**Theorem `my_last:append`.**
If `my_last(X, L)` succeeds, then `L` can be decomposed as
`append(L1, [X], L)` for some prefix `L1`.

```
all [x,l]: succeeds my_last(?x,?l) =>
 (ex l1: succeeds append(?l1,[?x],?l))
```

*Proof method:* Induction on `succeeds my_last(?x,?l)`, with two steps.

- **Step 1** (clause 1, `L = [X]`): The witness is `L1 = []`:
  `append([], [X], [X])` holds directly.

- **Step 2** (clause 2, `L = [Y|L']`): The IH gives some `L1` with
  `append(L1, [X], L')`. Construct `append([Y|L1], [X], [Y|L'])`, and
  the witness is `[Y|L1]`.

### 5.6 Converse Characterization

**Theorem `my_last:append:converse`.**
If `append(L1, [X], L)` succeeds, then `my_last(X, L)` succeeds.

```
all [x,l1,l]: succeeds append(?l1,[?x],?l) =>
 succeeds my_last(?x,?l)
```

Together with §5.5, this establishes that `my_last(X, L)` holds if and
only if `L` can be decomposed as `append(L1, [X], L)` for some `L1`.

*Proof method:* Two-step approach (same pattern as P02).

1. **Auxiliary lemma `my_last:append:converse:aux`**: Adds `list(L1)`
   as a precondition and inducts on `succeeds list(?l1)`.

   - **Base** (`L1 = []`): Unfold `append([], [X], L)` by completion
     to get `L = [X]`. Then `my_last(X, [X])` by clause 1.

   - **Step** (`L1 = [Z|L1']`): Unfold `append([Z|L1'], [X], L)` by
     completion to get `L = [Z|L3]` and `append(L1', [X], L3)` for
     some `L3`. The IH gives `my_last(X, L3)`. Then
     `my_last(X, [Z|L3])` by clause 2, hence `my_last(X, L)`.

2. **Main theorem**: From `succeeds append(?l1,[?x],?l)`, derive
   `succeeds list(?l1)` using the library lemma `append:types:1`.
   Then apply the auxiliary lemma.

## 6. Two-Clause Induction Schema

### 6.1 Schema Structure

| Step | Clause | Variables | IH count | Extra Hypotheses |
|------|--------|-----------|----------|------------------|
| 1 | `my_last(X, [X])` | `x` | 0 | (none) |
| 2 | `my_last(X, [Y\|L])` | `x,y,l` | 1 | `succeeds my_last(X,L)` |

This is the simplest possible induction schema: a base case with no
recursive calls and an inductive step with one recursive call.

### 6.2 Comparison with P02

P01 and P02 share the same two-clause structure:

| Aspect | P01 (`my_last`) | P02 (`my_last_but_one`) |
|--------|-----------------|-------------------------|
| Base case | `[X]` (singleton) | `[X,Y]` (two elements) |
| Recursive case | `[_\|L]` | `[_\|T]` |
| Result position | Last element | Second-to-last |
| Append characterization | `append(L1,[X],L)` | `append(L1,[X,W],L)` |
| Negation | None | None |
| Properties proved | 6 | 6 |

## 7. Verification

All proofs were verified by running LPTP:

```
$ cd ~/lptp
$ echo "io__exec_file('tmp/p01.pr'). halt." | bin/lptp
LPTP, Version 1.06, July 21, 1999.
...
! LPTP-Message: p01 o.k.
```

The message "p01 o.k." confirms that all six proofs were checked without
errors or warnings.

## 8. Summary

| Metric | Value |
|--------|-------|
| Prolog predicates verified | 1 (`my_last/2`) |
| Properties proven | 6 |
| Lines of proof (p01.pr) | 190 |
| LPTP verification time | < 4 ms |
| Errors encountered | 0 |
| All passed on first attempt? | Yes |

## 9. Conclusions

P01 establishes the baseline patterns for the 99 Prolog Problems series:

1. **Curried induction for termination.** The termination proof uses a
   curried formula `all l: list(L) => (all x: terminates my_last(X,L))`
   because `X` is not part of the list structure being inducted on. This
   pattern recurs in all subsequent problems.

2. **Completion handles simple base cases automatically.** For `my_last`,
   both the empty-list base case (no matching clause) and the cons step
   (matching clauses 1 and 2) are resolved by LPTP's completion mechanism
   without explicit case analysis.

3. **Existential witnesses for append characterization.** The
   `my_last:append` theorem requires constructing explicit witnesses for
   the existential quantifier: `[]` in the base case and `[Y|L1]` in the
   inductive step. The `exist(vars, formula, proof, conclusion)` construct
   is the standard LPTP mechanism for this.

4. **Two-step converse proofs.** The converse theorem
   `my_last:append:converse` uses an auxiliary lemma with a strengthened
   precondition (`list(L1)`) to enable induction. The main theorem then
   derives this precondition from a library fact (`append:types:1`). This
   pattern — strengthen, induct, then weaken — recurs in P02 and beyond.

5. **Bidirectional characterization.** The forward (§5.5) and converse
   (§5.6) theorems together give a complete characterization:
   `my_last(X, L)` holds if and only if `L = L1 ++ [X]` for some `L1`.
   This is a strong correctness guarantee: the predicate computes exactly
   the last element.
