# Formal Verification of P01 with LPTP: Experiment Report

## 1. Problem Statement

P01: Find the last element of a list. The predicate `my_last(X, L)` unifies
`X` with the last element of `L`, or fails if `L` is empty.

## 2. Prolog Code

```prolog
my_last(X, [X]).
my_last(X, [Y|L]) :- my_last(X, L).
```

Two clauses: base case on a singleton list, recursive case skipping the head.

## 3. Properties Proved

Ten lemmas/theorems were formally verified.

### 3.1 Termination (`my_last:termination`)

```
all [x,l]: succeeds list(?l) => terminates my_last(?x,?l)
```

Induction on `succeeds list(?l)`, curried form. Base: no clause matches
`my_last(?,[])`; step: completion handles both clauses with IH on the tail.

### 3.2 Type Preservation (`my_last:types`)

```
all [x,l]: succeeds my_last(?x,?l) => succeeds list(?l)
```

Induction on `succeeds my_last(?x,?l)`. Base: `list([X])` from `list([])`
and the cons clause. Step: IH gives `list(L)`, then `list([Y|L])`.

### 3.3 Groundness (`my_last:ground`)

```
all [x,l]: succeeds my_last(?x,?l) & gr(?l) => gr(?x)
```

Induction on `succeeds my_last(?x,?l)`, curried with `gr(?l) => gr(?x)`.
LPTP's `gr_intro_variable` extracts `gr(?x)` from `gr([?x])` (base) and
`gr(?l)` from `gr([?y|?l])` (step).

### 3.4 Membership (`my_last:member`)

```
all [x,l]: succeeds my_last(?x,?l) => succeeds member(?x,?l)
```

Induction on `succeeds my_last(?x,?l)`. Base: `member(X,[X])` directly.
Step: IH gives `member(X,L)`, then `member(X,[Y|L])` by the member
recursive clause.

### 3.5 Uniqueness (`my_last:uniqueness`)

```
all [x,l]: succeeds my_last(?x,?l) => (all y: succeeds my_last(?y,?l) => ?x = ?y)
```

Induction on `succeeds my_last(?x,?l)`, curried. Each step unfolds the
second `succeeds my_last(?y,...)` by completion and uses case analysis:

- **Step 1** (`L = [X]`): completion gives `?y = ?x` or
  `succeeds my_last(?y,[])`. The second case gives `ff` (no clause
  matches the empty list).

- **Step 2** (`L = [Z|L']`): completion gives `?w = ?z & ?l = []` or
  `succeeds my_last(?w,?l)`. In the first case, `?l = []` contradicts
  `succeeds my_last(?x,?l)` (from the step hypothesis) since `my_last`
  fails on `[]`. In the second case, the IH applies directly.

### 3.6 Existence Auxiliary (`my_last:existence:aux`)

```
all [z,l]: succeeds list(?l) => (ex x: succeeds my_last(?x,[?z|?l]))
```

Induction on `succeeds list(?l)`, curried over `?z`. Base (`L = []`):
witness `?z`, since `my_last(?z,[?z])` succeeds. Step (`L = [Y|L']`):
IH with `z := ?y` gives a witness `?x` with `my_last(?x,[?y|?l])`;
then `my_last(?x,[?z,?y|?l])` by clause 2.

### 3.7 Existence (`my_last:existence`)

```
all l: succeeds list(?l) & ?l <> [] => (ex x: succeeds my_last(?x,?l))
```

No induction. Unfold `list(?l)` by completion: if `?l = []`, contradicts
`?l <> []`; otherwise `?l = [?z|?l1]` and the auxiliary lemma applies.

### 3.8 Append Characterization — Forward (`my_last:append`)

```
all [x,l]: succeeds my_last(?x,?l) => (ex l1: succeeds append(?l1,[?x],?l))
```

Induction on `succeeds my_last(?x,?l)`. Base (`L = [X]`): witness `L1 = []`,
since `append([], [X], [X])` succeeds directly. Step (`L = [Y|L']`): IH
gives some `L1` with `append(L1, [X], L')`. Construct
`append([Y|L1], [X], [Y|L'])` by the recursive clause of append; witness
is `[Y|L1]`.

### 3.9 Append Characterization — Converse Auxiliary (`my_last:append:converse:aux`)

```
all [x,l1,l]: succeeds list(?l1) & succeeds append(?l1,[?x],?l) =>
 succeeds my_last(?x,?l)
```

Induction on `succeeds list(?l1)`, curried. Base (`L1 = []`): unfold
`append([], [X], L)` by completion to get `L = [X]`. Then `my_last(X, [X])`
by clause 1. Step (`L1 = [Z|L1']`): unfold `append([Z|L1'], [X], L)` by
completion to get `L = [Z|L3]` and `append(L1', [X], L3)` for some `L3`.
IH gives `my_last(X, L3)`. Then `my_last(X, [Z|L3])` by clause 2, hence
`my_last(X, L)`.

### 3.10 Append Characterization — Converse (`my_last:append:converse`)

```
all [x,l1,l]: succeeds append(?l1,[?x],?l) => succeeds my_last(?x,?l)
```

No induction. From `succeeds append(?l1,[?x],?l)`, derive
`succeeds list(?l1)` via library lemma `append:types:1`. Then apply
the auxiliary lemma.

Together, theorems 3.8 and 3.10 establish the full equivalence:
`my_last(X, L)` holds if and only if `L = L1 ++ [X]` for some `L1`.

## 4. Statistics

| Metric | Value |
|--------|-------|
| Lines in `p01.pl` | 3 |
| Lines in `p01.gr` | 8 |
| Lines in `p01.pr` | 288 |
| Lemmas/theorems | 10 |
| Proof-to-code ratio | 96:1 |
| LPTP verification time | 7 ms |
| Errors on first attempt | 1 (existence, fixed on 2nd attempt) |

## 5. Difficulties and Lessons Learned

### Substitution after `cases` equality

The initial existence proof attempted induction with `?l <> []` in the IH
formula and used `cases(?l = [], ...)`. After deriving
`succeeds my_last(?z,[?z])` in the `?l = []` branch, LPTP could not derive
`ex x: succeeds my_last(?x,[?z|?l])` because it does not automatically
substitute `?l` with `[]` inside the branch.

**Fix**: reformulate existence as a two-step proof:
1. An auxiliary lemma `my_last:existence:aux` proving
   `all [z,l]: succeeds list(?l) => ex x: succeeds my_last(?x,[?z|?l])`.
   This avoids the `<>` condition entirely by always working with `[?z|?l]`.
2. A main theorem that unfolds `list(?l)`, handles the empty case by
   contradiction with `?l <> []`, and delegates the non-empty case to
   the auxiliary.

### Uniqueness via contradiction on empty list

The uniqueness proof's key insight is that in both induction steps, one
branch of the completion produces `succeeds my_last(?,[])`  which always
fails (no clause matches). The `def succeeds my_last(?y,[]) by completion`
step yields `ff`, eliminating that branch. This is simpler than a four-way
case analysis over two completions.

### Success induction for uniqueness

Inducting on the first `succeeds my_last(?x,?l)` is cleaner than inducting
on `list(?l)` for uniqueness, because it avoids the need to unfold *both*
success calls simultaneously. The IH naturally provides `?x = ?w` for
any `?w` satisfying the recursive call on the tail.

### Two-step converse proof for append characterization

Cannot induct directly on `succeeds append(?l1,[?x],?l)` because the
second argument `[?x]` is a compound term (LPTP rejects compound terms
in induction schemas). The workaround is a two-step proof:
1. An auxiliary lemma with `succeeds list(?l1)` as precondition, proved
   by induction on `list`.
2. A main theorem that derives `list(?l1)` from `append:types:1` and
   then applies the auxiliary.


