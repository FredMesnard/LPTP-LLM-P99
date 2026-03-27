# LPTP Reference for Claude Code

What Claude Code needs to know to work with LPTP on this machine.

## 1. Installation

- **LPTP location**: `/Users/fred/lptp`
- **Binary**: `/Users/fred/lptp/bin/lptp` (Mach-O 64-bit, arm64)
- **Built with**: GNU Prolog 1.5.0
- **LPTP version**: 1.06 (July 21, 1999)
- **SWI-Prolog** is also installed (`/Applications/SWI-Prolog.app/Contents/MacOS/swipl`, version 10.0.0) and is used for running Prolog programs, but LPTP itself runs through the GNU Prolog binary.

## 2. Running LPTP

### Verifying a proof file

The command to verify a `.pr` file is:

```bash
cd /Users/fred/lptp
printf "io__exec_file('path/to/file.pr').\nhalt.\n" | /Users/fred/lptp/bin/lptp 2>&1
```

Do **not** use `consult/1` --- GNU Prolog will treat LPTP directives as unknown. Use `io__exec_file/1`, which is LPTP's own file loader.

### Success indicator

A successful verification produces:

```
! LPTP-Message: <module> o.k.
```

Errors appear as `! LPTP-Error: ...` and warnings as `! LPTP-Warning: ...`. The file is still reported as "o.k." even if there are warnings; errors indicate proof failures.

### Where to place files

LPTP resolves paths using two variables:

- `$(lib)` = `/Users/fred/lptp/lib`
- `$(tmp)` = `/Users/fred/lptp/tmp`

For user proof files, copy both the `.gr` and `.pr` files to `/Users/fred/lptp/tmp/` before running LPTP. In the `.pr` file, reference them as `$(tmp)/filename` (without extension).

## 3. Directory Structure

```
/Users/fred/lptp/
  bin/lptp              LPTP binary (GNU Prolog)
  src/                  Prolog source of LPTP itself (lptp.pl + modules)
  lib/                  Verified library
    nat/                Natural numbers, arithmetic, ordering
    list/               Lists, append, member, delete, length, permutation, reverse, suffix
    sort/               Sorting algorithms (mergesort, insertion sort)
    graph/              Transitive closure
    builtin/            Built-in predicate axioms
  examples/             Larger verified programs (alpha, avl, mgu, parser, taut)
  doc/                  Documentation (user.pdf, academic papers)
  tmp/                  Working directory for generated .tex and .thm files
  etc/                  Emacs mode, Perl scripts
  tex/                  TeX macros (proofmacros.tex)
```

## 4. File Types

| Extension | Purpose | Created by |
|-----------|---------|------------|
| `.pl` | Prolog source code | User |
| `.gr` | Ground representation file (variable-free clause encoding) | User (or LPTP tools) |
| `.pr` | Proof file (lemmas, theorems, corollaries) | User |
| `.thm` | Theorem database (generated, lists proven facts) | LPTP |
| `.tex` | TeX output for typesetting proofs | LPTP |

## 5. Proof File Structure

A `.pr` file follows this skeleton:

```prolog
/* Header comments */

:- initialize.

:- tex_file($(tmp)/modulename).
:- thm_file($(tmp)/modulename).

:- needs_gr($(tmp)/modulename).       % own ground representation file
:- needs_gr($(lib)/list/list).        % library dependencies
:- needs_thm($(lib)/list/list).       % library theorem imports

:- lemma(name, formula, proof).
:- theorem(name, formula, proof).
:- corollary(name, formula, proof).

:- bye(modulename).
```

### Naming convention

Hierarchical colon-separated names: `predicate:property` or `predicate:property:variant`.

Examples: `my_last_but_one:termination`, `append:types:1`, `delete:member:3`.

## 6. Ground Representation File Structure

A `.gr` file contains the **ground representation** of a Prolog program.
The name "gr" stands for "ground": every Prolog variable in the original
`.pl` source is replaced by a ground (variable-free) Prolog term using the
`$(name)` notation. This encoding allows LPTP to manipulate clauses as
ordinary Prolog data structures without interference from Prolog's own
unification mechanism.

For example, the Prolog clause:

```prolog
my_last_but_one(X, [X, _]).
```

becomes a ground term where the variable `X` is represented as `$(x)` and
the anonymous variable `_` as `$(y)`:

```prolog
clause([n(my_last_but_one,2), $(x), [n('.',2),$(x),[n('.',2),$(y),[n([],0)]]]],
  [&],
  [x,y]/0)
```

A `.gr` file declares these ground clauses using `assert_clauses/2`:

```prolog
:- assert_clauses(n(predicate_name, arity), [
  clause([n(predicate_name, arity), arg1, arg2, ...],
    [body_goals],
    [var_names]/0),
  ...
]).
```

### Ground encoding conventions

| Original Prolog | Ground representation | Explanation |
|-----------------|----------------------|-------------|
| Variable `X` | `$(x)` | Variable name as a ground atom wrapped in `$()` |
| Functor `f(A,B)` | `[n(f,2), $(a), $(b)]` | Functor name and arity via `n()`, arguments follow |
| List `[H\|T]` | `[n('.',2), $(h), $(t)]` | The list constructor `.` with arity 2 |
| Empty list `[]` | `[n([],0)]` | The empty list constant with arity 0 |
| Clause body `true` | `[&]` | A fact (no body goals) |

### Full example: `my_last_but_one/2`

The Prolog source:

```prolog
my_last_but_one(X, [X, _]).
my_last_but_one(X, [_ | T]) :- my_last_but_one(X, T).
```

Its ground representation:

```prolog
:- assert_clauses(n(my_last_but_one,2),[
 clause([n(my_last_but_one,2),$(x),[n('.',2),$(x),[n('.',2),$(y),[n([],0)]]]],
  [&],
  [x,y]/0),
 clause([n(my_last_but_one,2),$(x),[n('.',2),$(y),$(t)]],
  [n(my_last_but_one,2),$(x),$(t)],
  [x,y,t]/0)
]).
```

The trailing `[x,y]/0` and `[x,y,t]/0` record the variable names used in
each clause (the `/0` indicates no additional meta-information).

## 7. Formula Language

| Syntax | Meaning |
|--------|---------|
| `?x` | Logical variable (in `.pr` files) |
| `all [x,y]: F` | Universal quantification |
| `ex [x,y]: F` | Existential quantification |
| `=>` | Implication |
| `<=>` | Biconditional |
| `&` | Conjunction |
| `\/` | Disjunction |
| `~` | Negation |
| `<>` | Inequality |
| `ff` | Falsity (bottom) |
| `succeeds P` | Predicate P has a successful derivation |
| `fails P` | Predicate P fails |
| `terminates P` | Predicate P terminates |
| `gr(T)` | Term T is ground |

### Function symbols (defined via `definition_fun`)

| Symbol | Meaning | Module |
|--------|---------|--------|
| `@+` | Addition (Peano) | nat |
| `@*` | Multiplication (Peano) | nat |
| `**` | List append (functional) | list |
| `lh` | List length (functional) | list |

### Predicate symbols (defined via `definition_pred`)

| Symbol | Meaning | Module |
|--------|---------|--------|
| `sub` | Subset (membership inclusion) | list |

## 8. Proof Constructs

### Top-level declarations

```prolog
:- lemma(Name, Formula, Proof).
:- theorem(Name, Formula, Proof).
:- corollary(Name, Formula, Proof).
:- definition_fun(Op, Arity, Spec, existence by ..., uniqueness by ...).
:- definition_pred(Name, Arity, Spec).
```

### Proof terms

| Construct | Purpose |
|-----------|---------|
| `induction([Schema], [Steps])` | Structural induction |
| `step(Vars, Hypotheses, Body, Conclusion)` | One induction step |
| `assume(Premise, ProofSteps, Conclusion)` | Assume and derive |
| `cases(Case1, Proof1, Case2, Proof2, Conclusion)` | Case analysis |
| `exist(Var, Witness, ProofSteps, Conclusion)` | Existential elimination |
| `contra(Assumption, ProofSteps)` | Proof by contradiction |
| `indirect(Assumption, ProofSteps, Conclusion)` | Indirect proof |

### Justifications (the `by` keyword)

| Justification | Meaning |
|---------------|---------|
| `by completion` | Unfold predicate definition (Clark completion) |
| `by lemma(Name)` | Apply a previously proven lemma |
| `by theorem(Name)` | Apply a previously proven theorem |
| `by corollary(Name)` | Apply a previously proven corollary |
| `by existence(Fun, Arity)` | Use existence proof of a function |
| `by uniqueness(Fun, Arity)` | Use uniqueness proof of a function |
| `by introduction(Pred, Arity)` | Introduce a defined predicate |
| `by elimination(Pred, Arity)` | Eliminate a defined predicate |
| `by sld` | Direct SLD-resolution |
| `by gap` | Placeholder (proof obligation left open) |

## 9. Available Library Theorems

### From `nat` (natural numbers)

Key results available via `needs_thm($(lib)/nat/nat)`:

- `nat:termination`, `nat:ground`
- `plus:termination:1/2`, `plus:types:1/2/3`, `plus:ground:1/2/3`
- `plus:existence`, `plus:uniqueness`
- `plus:zero` (corollary: `0 @+ Y = Y`), `plus:successor`
- `plus:associative`, `plus:commutative`, `plus:injective:second`
- `times:*` (parallel results for multiplication)
- `less:*`, `leq:*` (ordering results including totality, transitivity, antisymmetry)

### From `list` (lists)

Key results available via `needs_thm($(lib)/list/list)`:

- **list**: `list:1/2/3` (concrete lists are lists), `list:cons`, `list:termination`
- **member**: `member:termination`, `member:ground`, `member:cons`
- **append**: `append:types:1/2/3/4`, `append:termination:1/2`, `append:ground:1/2`, `append:existence`, `append:uniqueness`
- **append function (`**`)**: `app:nil`, `app:cons`, `app:types:1/2`, `app:ground:1/2`, `app:associative`, `app:nil` (right identity)
- **length**: `length:types`, `length:termination`, `length:ground`, `length:existence`, `length:uniqueness`
- **length function (`lh`)**: `lh:nil`, `lh:cons`, `lh:types`, `lh:zero`, `lh:successor`
- **delete**: `delete:termination:1/2`, `delete:types:1/2`, `delete:length`, `delete:member:1/2/3`, `delete:member:existence`
- **subset (`sub`)**: `sub:reflexive`, `sub:transitive`, `sub:nil`, `sub:cons`, `sub:member`, `sub:cons:both`
- **cross-cutting**: `member:append`, `append:member:1/2/3`, `app:member:1/2/3`, `append:cons:different`, `append:equal:nil`, `append:uniqueness:1/2`

Also in separate modules under `lib/list/`:
- `permutation.pr` (permutation properties)
- `reverse.pr` (list reversal)
- `suffix.pr` (suffix relation)

## 10. Common Pitfalls

### Variable shadowing in existentials

When the base case of an induction introduces variables (e.g., `step([x,y], ...)`) and the conclusion contains an existential `ex [l1,y]: ...`, the bound `?y` clashes with the free `?y` from the step. **Fix**: rename the existential variable (e.g., use `?w` instead of `?y`).

### Induction on predicates with compound arguments

LPTP generates induction schemas from clause structure. If the predicate call in the induction formula has a compound term in an argument position (e.g., `succeeds append(?l1, [?x,?w], ?l)`), LPTP cannot generate the schema and reports:

```
! LPTP-Error: [...] cannot be used for induction.
```

**Fix**: induct on a simpler predicate instead. The standard workaround is to induct on `succeeds list(...)` for one of the arguments, then derive the list precondition from a type lemma (e.g., `append:types:1`). Structure the proof as:

1. An auxiliary lemma with the extra `succeeds list(...)` hypothesis, proved by induction on `list`.
2. A main theorem that derives `succeeds list(...)` from the predicate call, then applies the auxiliary lemma.

### Avoid anonymous variables (`_`) in LPTP-verified code

Using `_` (anonymous variable) in a clause head produces an existential
variable in the ground representation (e.g., `[0,l,n]/1` instead of
`[x,l,n]/0`). This complicates induction schemas because the existential
variable requires special handling in proof steps.

**Fix**: use a named variable (e.g., `X`) even if it only appears in the
head. The Prolog semantics are identical, but the `.gr` file has `/0`
(no existentials), making proofs structurally simpler.

Example: prefer `my_length([X|L], s(N)) :- my_length(L, N).` over
`my_length([_|L], s(N)) :- my_length(L, N).`

### Dual termination for multi-typed predicates

When a predicate has two arguments with distinct types (e.g., list and nat),
termination can be proved by induction on either argument. Use curried form:

- `all l: list(?l) => (all n: terminates p(?l,?n))` — induction on the list
- `all n: nat(?n) => (all l: terminates p(?l,?n))` — induction on the nat

Both proofs use `by completion` in the step, providing side conditions for
each clause's recursive call.

### The `by completion` tactic

`by completion` unfolds the Clark completion of a predicate. It works for both `succeeds` and `terminates` goals. It is the primary way to handle base cases and to decompose predicate calls in induction steps via `def succeeds P by completion`.

### The `by sld` tactic

`by sld` performs direct SLD-resolution (Prolog computation). Use it for simple goals that can be resolved in one or two resolution steps. It is less common than `by completion` but useful for existential witnesses.

### Proof ordering: types before termination

When a predicate's body calls another predicate whose termination requires
type information (e.g., `append` needs `list` on its first argument), the
type lemma must be proved BEFORE the termination lemma. The termination
proof references the type lemma to derive preconditions for body goals.

Example: `my_reverse` calls `append(L2,[X],L3)` which needs `list(L2)`.
The types lemma derives `list(L2)` from `succeeds my_reverse(L1,L2)`.

### Conjunction termination (body with multiple goals)

When a clause body has two goals `G1, G2`, the termination proof uses
`terminates G1` + `assume(succeeds G1, [terminates G2])`:

```prolog
terminates G1 by ...,
assume(succeeds G1,
 [postcondition of G1,
  terminates G2 by ...],
 terminates G2),
terminates (G1 & G2)
```

**No `assume(fails G1, ...)` branch is needed.** LPTP's internal rule
`t intro s` handles both outcomes: it checks that `terminates G1` and
`succeeds G1 => terminates G2` are both derivable.

In the success branch, postconditions of `G1` (from type lemmas) provide
preconditions for `G2`'s termination.

For **triple conjunctions** `G1 & G2 & G3`, nest the second level inside
the first assume:

```prolog
terminates G1 by ...,
assume(succeeds G1,
 [terminates G2 by ...,
  assume(succeeds G2,
   [terminates G3 by ...],
   terminates G3),
  terminates (G2 & G3)],
 terminates (G2 & G3)),
terminates (G1 & G2 & G3)
```

Inside `assume(succeeds G1, ...)`, derive `terminates (G2 & G3)`,
**not** `terminates (G1 & G2 & G3)`. LPTP combines G1 + (G2 & G3)
at the outer level.

### Self-contained `.pl` with library `.gr`

When a predicate uses library predicates (e.g., `append/3`) in its body:

- Include the library predicate in `.pl` for standalone testing
- Remove it from `.gr` to avoid duplication with `needs_gr($(lib)/...)`
- The `.gr` file should only contain the new predicate's clauses

### Library theorem reuse via equivalence

Once equivalence with a library predicate is proved (forward + backward),
any library theorem transfers in three lines:

```prolog
:- lemma(my_pred:some_property,
all [x,y]: succeeds my_pred(?x,?y) => succeeds my_pred(?y,?x),
assume(succeeds my_pred(?x,?y),
 [succeeds lib_pred(?x,?y) by lemma(my_pred:equiv:forward),
  succeeds lib_pred(?y,?x) by theorem(lib_pred:some_property),
  succeeds my_pred(?y,?x) by lemma(my_pred:equiv:backward)],
 succeeds my_pred(?y,?x))
).
```

This is the primary motivation for proving equivalence lemmas with library
predicates — it gives free access to all their theorems.

### Completion with compound output patterns

When a clause head has a compound term in the output position (e.g.,
`pred([X|L1], [X,X|L2]) :- pred(L1, L2)`), the completed definition
includes an **equality constraint**. After `def ... by completion`:

```prolog
% The existential formula: equality BEFORE body predicate
ex l4: ?l3 = [?x,?x|?l4] & succeeds pred(?l1,?l4),
exist(l4,
 ?l3 = [?x,?x|?l4] & succeeds pred(?l1,?l4),
 [...],
 conclusion)
```

Two rules:
1. The equality must come **before** the body predicate in the conjunction.
2. The `ex ...` formula must be stated **explicitly** as an intermediate
   step between `def ... by completion` and `exist(...)`.

See library `append:uniqueness` (line 292 of `list.pr`) for the reference
pattern.

### Strengthened IH for multi-element stride

When a recursion removes N > 1 elements per step (e.g., `pred([X|L1],
[X,X|L2]) :- pred(L1, L2)` removes 2 from the second argument), simple
list induction on that argument fails. The IH covers removing 1 element,
but the completion needs the IH for removing N.

Fix: strengthen the IH to a conjunction that "looks ahead" by N − 1
elements. For N = 2:

```prolog
induction(
  [all l2: succeeds list(?l2) =>
    (all l1: terminates pred(?l1,?l2)) &
    (all [l1,z]: terminates pred(?l1,[?z|?l2]))],
  [step([], [], [...base...],
    (all l1: terminates pred(?l1,[])) &
    (all [l1,z]: terminates pred(?l1,[?z]))),
   step([x,l2],
    [(all l1: terminates pred(?l1,?l2)) &
     (all [l1,z]: terminates pred(?l1,[?z|?l2])),
     succeeds list(?l2)],
    [% Part 1: from IH part 2 with z:=?x
     terminates pred(?l1,[?x|?l2]),
     % Part 2: from IH part 1 + completion
     terminates pred(?l1,?l2),
     terminates pred(?l1,[?z,?x|?l2]) by completion],
    (all l1: terminates pred(?l1,[?x|?l2])) &
    (all [l1,z]: terminates pred(?l1,[?z,?x|?l2])))])
```

### Strengthened IH on nat with `@=<` bound

When a predicate recurses by subtracting D > 1 from N (e.g., `divides(D,N)`
subtracts D, or `quot(D,N,Q)` subtracts D), simple nat induction fails.
The standard technique is to prove `forall m @=< n: P(m)`:

```prolog
:- lemma(pred:termination,
all [d0, n, q]: succeeds nat(?d0) & succeeds nat(?n) =>
 terminates pred(s(?d0), ?n, ?q),
[induction(
  [all n: succeeds nat(?n) =>
    (all [d0, m, q]: succeeds nat(?d0) & succeeds ?m @=< ?n =>
      terminates pred(s(?d0), ?m, ?q))],
  [step([],
    [],
    assume(succeeds nat(?d0) & succeeds ?m @=< 0,
     [def succeeds ?m @=< 0 by completion,
      % m = 0, base case ...
      terminates pred(s(?d0), ?m, ?q)],
     terminates pred(s(?d0), ?m, ?q)),
    all [d0, m, q]: succeeds nat(?d0) & succeeds ?m @=< 0 =>
      terminates pred(s(?d0), ?m, ?q)),

   step([n],
    [all [d0, m, q]: succeeds nat(?d0) & succeeds ?m @=< ?n =>
       terminates pred(s(?d0), ?m, ?q),
     succeeds nat(?n)],
    assume(succeeds nat(?d0) & succeeds ?m @=< s(?n),
     [def succeeds ?m @=< s(?n) by completion,
      cases(
        ?m = 0,
        [% apply IH with 0 @=< ?n ...],
        ex m0: ?m = s(?m0) & succeeds ?m0 @=< ?n,
        [exist(m0, ?m = s(?m0) & succeeds ?m0 @=< ?n,
          [% For recursive arg m1: derive m1 @=< n, apply IH
           % Key chain: corollary(less:plus:first) + uniqueness(@+,2)
           %   => m1 @< m
           % less:axiom:successor => m1 @< m0 \/ m1 = m0
           % less:leq + leq:transitive => m1 @=< n
           % Apply IH
           terminates pred(s(?d0), ?m, ?q)],
          terminates pred(s(?d0), ?m, ?q))],
        terminates pred(s(?d0), ?m, ?q))],
     terminates pred(s(?d0), ?m, ?q)),
    all [d0, m, q]: succeeds nat(?d0) & succeeds ?m @=< s(?n) =>
      terminates pred(s(?d0), ?m, ?q))]),
 assume(succeeds nat(?d0) & succeeds nat(?n),
  [all [d0, m, q]: succeeds nat(?d0) & succeeds ?m @=< ?n =>
    terminates pred(s(?d0), ?m, ?q),
   succeeds ?n @=< ?n by theorem(leq:reflexive),
   terminates pred(s(?d0), ?n, ?q)],
  terminates pred(s(?d0), ?n, ?q))]
).
```

The wrapup instantiates the IH with `?m = ?n` using `leq:reflexive`.
All universally quantified variables in the conclusion (here `?q`) must
also be universally quantified in the IH `all` — otherwise the IH
cannot be applied to clause-local variables.

Used in P31 (`divides:termination`), P35 (`quot:termination`,
`quot:types`, `quot:strict_bound`, `prime_factors:termination`).

### Pass-through arguments and type lemmas

When an argument appears in the head but is NOT constrained in every clause
(e.g., base case `pred([], N, [])` doesn't recurse on N), the type lemma
CANNOT claim type properties for that argument. Example: `dupli([], foo, [])`
succeeds but `foo` is not a nat. The type lemma must only cover arguments
that are structurally constrained by every clause.

### Variable shadowing in uniqueness proofs

When a clause variable (e.g., `l3`) conflicts with the universally quantified
variable in the curried uniqueness formula, rename the quantified variable:

```prolog
% BAD: l3 is both a step var and the quantified var
all [l1,n,l2]: succeeds pred(?l1,?n,?l2) =>
  (all l3: succeeds pred(?l1,?n,?l3) => ?l2 = ?l3)

% GOOD: use l4 to avoid shadowing
all [l1,n,l2]: succeeds pred(?l1,?n,?l2) =>
  (all l4: succeeds pred(?l1,?n,?l4) => ?l2 = ?l4)
```

LPTP's error "mismatch in induction step" signals this problem.

### Non-recursive wrapper proofs (no induction)

When a predicate is a simple wrapper (1 clause, body calls a different
predicate), proofs don't need induction. Use direct `assume` +
`def ... by completion` to unfold, then delegate:

```prolog
% Types for a wrapper: pred(L,N,R) :- aux(L,N,N,R).
:- lemma(pred:types,
all [l,n,r]: succeeds pred(?l,?n,?r) => succeeds list(?l) & succeeds list(?r),
assume(succeeds pred(?l,?n,?r),
 [def succeeds pred(?l,?n,?r) by completion,
  succeeds aux(?l,?n,?n,?r),
  succeeds list(?l) & succeeds list(?r) by lemma(aux:types)],
 succeeds list(?l) & succeeds list(?r))
).

% Termination for a wrapper
:- lemma(pred:termination,
all [l,n,r]: succeeds list(?l) => terminates pred(?l,?n,?r),
assume(succeeds list(?l),
 [terminates aux(?l,?n,?n,?r) by lemma(aux:termination),
  terminates pred(?l,?n,?r) by completion],
 terminates pred(?l,?n,?r))
).
```

### Explicit completion for type decomposition

When you have `succeeds list([?x|?l])` as an assumption (from an `assume`
or an induction step), you **cannot** directly derive `succeeds list(?l)`.
You must first unfold the definition:

```prolog
assume(succeeds list([?x|?l]),
 [def succeeds list([?x|?l]) by completion,
  succeeds list(?l),         % now available
  ...],
 conclusion)
```

This applies to any compound type: `nat(s(?n))` → needs completion to get
`nat(?n)`, `list([?x|?l])` → needs completion to get `list(?l)`.

### Derivation in `assume`: list form vs. atomic form

Inside an `assume(Premise, Derivation, Conclusion)`, the derivation can be
either a **single step** (atomic) or a **list of steps**. The list form is
required when you need to derive the conclusion directly from the premise:

```prolog
% FAILS — atomic form, LPTP cannot derive succeeds list(?l)
assume(succeeds list(?l),
  succeeds list(?l),          % rejected!
  succeeds list(?l))

% WORKS — list form, the premise is available in the derivation context
assume(succeeds list(?l),
  [succeeds list(?l)],        % accepted!
  succeeds list(?l))
```

This matters when a clause maps two arguments to the same variable
(e.g., `select_group(0, L, [], L)` where R=L), creating an identity proof
obligation `P => P`. Always use the **list form** `[P]` in such cases.

### Negation in termination: groundness requirement

LPTP's `terminates (~ P)` requires **both** `terminates P` **and** groundness
(`gr`) of all free variables in `P`. This is because Prolog's negation-as-failure
(`\+`) only works correctly on ground goals.

Concretely, `terminates (~ pred(?x,?y))` expands internally to:
```prolog
terminates pred(?x,?y) & gr(?x) & gr(?y)
```

This means `terminates (~ P & Q)` requires the `gr` conditions to be derivable.
Consequently, **termination lemmas for predicates with negation in clause bodies
must include `gr` preconditions**, matching sort.pr's pattern:

```prolog
% sort.pr: insert:termination requires gr
all [x,l1,l2]: succeeds nat_list(?l1) & succeeds nat(?x) & gr(?l1) & gr(?x) =>
  terminates insert(?x,?l1,?l2)

% P28: linsert:termination requires gr
all [x,s,z]: succeeds list(?x) & succeeds list(?s) & gr(?x) & gr(?s) =>
  terminates linsert(?x,?s,?z)
```

This also means you typically need companion **ground preservation lemmas**
(`insert:ground`, `linsert:ground`, `lsort:ground`) so that the `gr` conditions
can be established for recursive calls and callers.

### How `terminates (~ P & Q)` is derived internally

LPTP derives `terminates (~ P & Q)` via the rule at `pr.pl` line 248-261.
The conjunction `[&, [~, P], Q]` triggers three attempts in order:

1. **t intro t** (line 251): Derive `terminates (~ P)` expanded as
   `terminates P & gr(v1) & ... & gr(vn)`, THEN derive `terminates Q`.
2. **t intro s** (line 254): Derive `terminates (~ P)`, THEN derive
   `fails P => terminates Q`.
3. **t intro f** (line 258): Derive `terminates (~ P)`, THEN derive
   `succeeds P` (contradiction makes the conjunction vacuously true).

For rule 1 (the usual case), LPTP needs all of these in the derivation
context (Gamma):
- `terminates P` — from a previous derivation step
- `gr(?v)` for each free variable v in P — from the assume premise or
  derivable via `gr_intro_variable` (e.g., `gr(?h)` from `gr([?h|?t])`)
- `terminates Q` — from a previous derivation step

The `gr_intro_variable` rule (`pr.pl` line 236) extracts `gr(?v)` from
any `gr(compound_term)` in Gamma where `?v` occurs as a sub-term. It
has no depth limitation (the depth parameter is `_`).

**Proof pattern** for a clause `pred(X, [Y|S], [Y|S1]) :- \+ test(X,Y), pred(X, S, S1)`:

```prolog
assume(preconditions & gr([?y|?s]) & gr(?x),
  [terminates test(?x,?y) by lemma(test:termination),  % step 1
   terminates pred(?x,?s,?s1),                          % step 2 (from IH)
   terminates (~ test(?x,?y) & pred(?x,?s,?s1)),        % step 3 (automatic!)
   terminates pred(?x,[?y|?s],?s1) by completion],
  terminates pred(?x,[?y|?s],?s1))
```

Steps 1 and 2 add `terminates test(...)` and `terminates pred(...)` to
Gamma. Step 3 is derived automatically: LPTP expands `terminates ~ test`
as `terminates test & gr(?x) & gr(?y)`, checks all three from Gamma
(with `gr(?y)` from `gr([?y|?s])`), then checks `terminates pred`.

### Termination by nat induction

When recursion decreases a nat argument (N → N') rather than a list,
induct on `succeeds nat(?n)` with curried form over other arguments:

```prolog
:- lemma(pred:termination,
all [l,n,l1,l2]: succeeds nat(?n) => terminates pred(?l,?n,?l1,?l2),
[induction(
  [all n: succeeds nat(?n) =>
    (all [l,l1,l2]: terminates pred(?l,?n,?l1,?l2))],
  [step([],
    [],
    terminates pred(?l,0,?l1,?l2) by completion,
    all [l,l1,l2]: terminates pred(?l,0,?l1,?l2)),
   step([n],
    [all [l,l1,l2]: terminates pred(?l,?n,?l1,?l2),
     succeeds nat(?n)],
    [terminates pred(?l,?n,?l1,?l2),
     terminates pred(?l,s(?n),?l1,?l2) by completion],
    all [l,l1,l2]: terminates pred(?l,s(?n),?l1,?l2))]),
 assume(succeeds nat(?n),
  [all [l,l1,l2]: terminates pred(?l,?n,?l1,?l2),
   terminates pred(?l,?n,?l1,?l2)],
  terminates pred(?l,?n,?l1,?l2))]
).
```

### Two-output uniqueness

When a predicate has two output arguments (e.g., `pred(L,N,L1,L2)`),
the uniqueness lemma proves a conjunction of equalities:

```prolog
all [l,n,l1,l2,l3,l4]: succeeds pred(?l,?n,?l1,?l2) &
  succeeds pred(?l,?n,?l3,?l4) => ?l1 = ?l3 & ?l2 = ?l4
```

In each step, completion may produce existentials for compound outputs.
Use `exist(...)` to eliminate them and reconstruct both equalities.

### Two-level head patterns require strengthened IH

When a clause head contains `s(s(K))` (two levels of `s`) for a nat
argument, naive nat induction fails because LPTP's `by completion`
cannot resolve that the body's argument equals the induction variable.
Example:

```prolog
% Head: s(s(K)), Body: s(K)
% Induction step proves for s(?k): s(s(K')) = s(?k) → K'=..., s(K')=?k
% But LPTP cannot simplify s(K') to ?k in completion
pred([X|L], s(s(K)), ...) :- pred(L, s(K), ...).
```

**Workaround 1**: Use list induction instead (L decreases by exactly one
cons cell, matching the induction structure).

**Workaround 2**: Strengthen the IH to cover both `?k` and `s(?k)`:

```prolog
induction(
  [all k: succeeds nat(?k) =>
    (all [x,l,r]: terminates pred(?x,?l,?k,?r)) &
    (all [x,l,r]: terminates pred(?x,?l,s(?k),?r))],
  [step([],
    [],
    [terminates pred(?x,?l,0,?r) by completion,
     terminates pred(?x,?l,s(0),?r) by completion],
    (all [x,l,r]: terminates pred(?x,?l,0,?r)) &
    (all [x,l,r]: terminates pred(?x,?l,s(0),?r))),
   step([k],
    [(all [x,l,r]: terminates pred(?x,?l,?k,?r)) &
     (all [x,l,r]: terminates pred(?x,?l,s(?k),?r)),
     succeeds nat(?k)],
    [terminates pred(?x,?l,s(?k),?r),        % from IH part 2
     terminates pred(?x,?l,s(s(?k)),?r) by completion],  % body s(?k) = IH part 2
    (all [x,l,r]: terminates pred(?x,?l,s(?k),?r)) &
    (all [x,l,r]: terminates pred(?x,?l,s(s(?k)),?r)))])
```

In the step, `s(s(?k))` matches the head `s(s(K'))` directly with K'=?k,
and the body `s(K')` = `s(?k)` matches IH part 2. This is the same
strengthened IH technique used for multi-element stride in P14.

### Structural induction rejected for complex heads

LPTP's structural induction on `succeeds P(complex_term, ...)` fails
with `[all ...] cannot be used for induction` when the first argument of
the predicate head has nested constructors. For example:

```prolog
% FAILS: LPTP rejects this
induction(
  [all [d1, n, q]: succeeds quot(s(s(?d1)), ?n, ?q) => ...],
  ...)
```

The error occurs because `s(s(?d1))` is a complex term. **Workaround**:
use strengthened induction on `nat(?n)` instead:

```prolog
induction(
  [all n: succeeds nat(?n) =>
    (all [d1, q, m]: succeeds nat(?d1) & succeeds ?m @=< ?n &
      succeeds quot(s(s(?d1)), ?m, ?q) => ...)],
  ...)
```

### Completion format: call-argument variable on the LEFT

After `def succeeds P(args) by completion`, LPTP generates equalities
with the **call-argument variable** on the left side:

```prolog
% Correct: ?m = s(?d0)  (call variable ?m on the left)
% Wrong:   s(?d0) = ?m  (causes "underivable formula")
```

This is critical when writing `cases(...)` branches after completion.
The disjunction formula must exactly match LPTP's internal format.

### No existential when all clause variables determined

In `def succeeds P(args) by completion`, existential quantifiers are
only needed for clause variables that are NOT determined by head matching.
When all clause variables appear in the head and are fully determined by
unification with the call pattern, the completion has no `ex`:

```prolog
% smallest_factor(N, D, s(K), F) :- \+ divides(D,N), smallest_factor(N,s(D),K,F).
% Call: smallest_factor(?n, s(?d0), s(?k), ?f)
% Head unification determines all clause vars: N=?n, D=s(?d0), K=?k, F=?f
% Completion (NO existential):
fails divides(s(?d0), ?n) &
 succeeds smallest_factor(?n, s(s(?d0)), ?k, ?f)
```

Compare with `quot` where clause 2 introduces body-only variables `?m1`
and `?q0`, which DO require `ex [q0, m1]: ...`.

### Substitution not automatic inside `exist` blocks

Inside `exist(v, ?x = expr, [...])`, LPTP does **not** automatically
substitute `?x` with `expr` in intermediate steps. You must use `expr`
directly:

```prolog
% Have: ?f = s(s(?f1))   from smallest_factor:lower_bound2
% WRONG: LPTP won't substitute ?f → s(s(?f1)) in derived formulas
exist(f1, ?f = s(s(?f1)),
 [terminates quot(?f, ?n, ?q),       % FAILS: ?f not substituted
  ...],
 ...)

% CORRECT: use s(s(?f1)) explicitly in intermediate steps
exist(f1, ?f = s(s(?f1)),
 [terminates quot(s(s(?f1)), ?n, ?q),   % OK: concrete term
  assume(succeeds quot(s(s(?f1)), ?n, ?q),
   [...],
   ...),
  terminates (quot(s(s(?f1)), ?n, ?q) & ...)],
 terminates (quot(?f, ?n, ?q) & ...))   % substitution at boundary OK
```

LPTP handles the substitution only at the `exist` conclusion boundary.

### IH list for success induction must include ALL body goals

When doing structural induction on `succeeds P(args)`, the step's
hypothesis list must include **all body goals** of the matching clause,
not just the inductive hypothesis:

```prolog
% Clause: prime_factors(s(s(X)), [F|L]) :-
%   smallest_factor(s(s(X)), s(s(0)), X, F),
%   quot(F, s(s(X)), Q),
%   prime_factors(Q, L).

step([x, f, l, q],
 [succeeds nat(?q) => succeeds list(?l),      % IH (for recursive call)
  succeeds smallest_factor(...),               % body goal 1
  succeeds quot(?f, s(s(?x)), ?q),             % body goal 2
  succeeds prime_factors(?q, ?l)],             % body goal 3
 ...)
```

Missing body goals causes "mismatch in induction step" warnings.
The body goals are needed in the context to extract type information
(e.g., `nat(?f)` from `smallest_factor:types`).

### IH in success induction reflects the recursive call

In a success induction, the IH comes from applying the lemma to the
**recursive call**, not the current clause's destructured head. Example:

```prolog
% Clause: pred([X|L], s(0), s(s(K)), [X|S]) :- pred(L, s(0), s(K), S).
% Lemma: succeeds pred(...) => nat(?i) & nat(?k) & list(?s)
%
% IH for this step (from recursive call pred(L, s(0), s(K), S)):
%   nat(s(0)) & nat(s(?k)) & list(?s)    ← CORRECT (s(?k), not ?k)
%   nat(s(0)) & nat(?k) & list(?s)       ← WRONG
```

### Explicit substitution after equality derivation

After deriving equalities like `?l1 = ?l3` and `?l2 = ?l4`, LPTP does
**not** automatically substitute these into other formulas. To apply a
lemma that expects matching arguments, you must explicitly re-state the
formula with substituted variables:

```prolog
% After: ?l1 = ?l3, ?l2 = ?l4
% Have: succeeds append(?l4, ?l3, ?r2)
% Need: succeeds append(?l2, ?l1, ?r2)  ← add this explicitly
succeeds append(?l2, ?l1, ?r2),
?r1 = ?r2 by lemma(append:uniqueness)   % now works
```

### Conjunction encoding in ground representation

A conjunction body `G1, G2` is encoded as `[&, [G1_args], [G2_args]]`
where each goal is wrapped in a sub-list:

```prolog
clause([n(pred,3),$(l),$(n),$(r)],
 [&,[n(goal1,4),$(l),$(n),$(l1),$(l2)],[n(goal2,3),$(l2),$(l1),$(r)]],
 [l,n,r,l1,l2]/0)
```

Body-only variables (like `l1`, `l2` above) appear in the variable list
but not in the head, and become existential in the completion.

### Cross-module theorem reuse

To reference another problem's theorems, use:
```prolog
:- needs_gr($(tmp)/p17).    % for split/4 definition
:- needs_thm($(tmp)/p17).   % for split's lemmas
```

All lemmas from the referenced module become available via
`by lemma(split:types:1)`, etc.

### Proof file must end with `:- bye(modulename).`

Omitting this causes LPTP to not finalize the module, and the `.thm` file may not be generated.

## 11. Standard Proof Patterns

### Termination proof (induction on `list`)

```prolog
:- lemma(pred:termination,
all [x,l]: succeeds list(?l) => terminates pred(?x,?l),
[induction(
  [all l: succeeds list(?l) =>
    (all x: terminates pred(?x,?l))],
  [step([],
    [],
    terminates pred(?x,[]) by completion,
    all x: terminates pred(?x,[])),
   step([y,l],
    [all x: terminates pred(?x,?l),
     succeeds list(?l)],
    terminates pred(?x,[?y|?l]) by completion,
    all x: terminates pred(?x,[?y|?l]))]),
 assume(succeeds list(?l),
  [all x: terminates pred(?x,?l),
   terminates pred(?x,?l)],
  terminates pred(?x,?l))]
).
```

### Type preservation proof (induction on success)

```prolog
:- lemma(pred:types,
all [x,l]: succeeds pred(?x,?l) => succeeds list(?l),
induction(
 [all [x,l]: succeeds pred(?x,?l) => succeeds list(?l)],
 [step([...], [], [...build list...], succeeds list(...)),
  step([...],
   [succeeds list(?l), succeeds pred(?x,?l)],
   [],
   succeeds list([?y|?l]))])
).
```

### Membership proof (induction on success)

```prolog
:- lemma(pred:member,
all [x,l]: succeeds pred(?x,?l) => succeeds member(?x,?l),
induction(
 [all [x,l]: succeeds pred(?x,?l) => succeeds member(?x,?l)],
 [step([...], [], succeeds member(?x,[?x,...]), ...),
  step([...],
   [succeeds member(?x,?l), succeeds pred(?x,?l)],
   [],
   succeeds member(?x,[?y|?l]))])
).
```

### Existential witness proof

```prolog
exist(var,
 witness_formula,
 [derive_from_witness,
  existential_conclusion],
 existential_conclusion)
```

**Limitation**: `exist(Var, Body, Steps, Conclusion)` does not support
quantifier `ex` in Body. In other words, you cannot directly eliminate
a nested multi-variable existential `ex p: (ex s: F(p,s))` via
`exist(p, ex s: F(p,s), ...)` — LPTP produces the error
`quantifier 'ex' not allowed in term`.

**Workaround**: reformulate the lemma as a universal statement. Instead
of proving `succeeds P(...) => ex [p,s]: G(p,s)`, prove the equivalent
version without existentials in the conclusion:

```prolog
all [...,p,s]: succeeds P(...) & succeeds Q(?p,...) & succeeds R(?s,...) =>
  succeeds G(?p,?s,...)
```

See P20 `remove_at:append` for a concrete example.

### Induction on `length` for cross-predicate properties

When the relationship between two predicates involves the length of a
prefix, induction on `succeeds length(?p,?n)` is a natural choice. It
provides:

- The prefix structure: `[]` (base) vs `[?z|?p]` (step)
- The counter decrement: `0` (base) vs `s(?n)` (step)

In each step, use `def ... by completion` on `append` and the target
predicate to obtain single-variable existentials (each eliminable by
`exist`).

```prolog
% Exemple : P20 remove_at:append:converse
% append(P,[X|S],L) & append(P,S,R) & length(P,N) => remove_at(X,L,s(N),R)
induction(
  [all [p,n]: succeeds length(?p,?n) =>
    (all [x,l,s,r]: succeeds append(?p,[?x|?s],?l) &
      succeeds append(?p,?s,?r) =>
      succeeds remove_at(?x,?l,s(?n),?r))],
  [step([],  % P=[], N=0
    [],
    assume(...,
     [def succeeds append([],[?x|?s],?l) by completion,
      ?l = [?x|?s],
      def succeeds append([],?s,?r) by completion,
      ?r = ?s,
      succeeds remove_at(?x,[?x|?s],s(0),?s)],  % clause 1
     ...),
    ...),
   step([z,p,n],  % P=[Z|P'], N=s(N')
    [IH, succeeds length(?p,?n)],
    assume(...,
     [def succeeds append([?z|?p],...,?l) by completion,
      ex l1: ?l = [?z|?l1] & ...,         % single-var exist: OK
      exist(l1, ...,
       [def succeeds append([?z|?p],...,?r) by completion,
        ex r1: ?r = [?z|?r1] & ...,       % single-var exist: OK
        exist(r1, ...,
         [IH => remove_at(X,L1,s(N'),R1),
          succeeds remove_at(?x,[?z|?l1],s(s(?n)),[?z|?r1])],  % clause 2
         ...)],
       ...)],
     ...),
    ...)])
```

### Completion unfolding in an assumption

```prolog
assume(succeeds pred(?x, [?y|?l]),
 [def succeeds pred(?x, [?y|?l]) by completion,
  ... use the unfolded definition ...],
 conclusion)
```

### Overlapping clauses and completion disjunction

When two clause heads can unify with the same goal (e.g., `range(N,N,[N])`
and `range(N,K,[N|L]) :- N @< K, ...` both match `range(?n,?n,?l2)`),
`def succeeds P by completion` produces a **disjunction**. You must handle
both branches with `cases`:

```prolog
def succeeds range(?n,?k,?l2) by completion,
(?k = ?n & ?l2 = [?n]) \/
  (ex l3: ?l2 = [?n|?l3] & succeeds ?n @< ?k & succeeds range(s(?n),?k,?l3)),
cases(?k = ?n & ?l2 = [?n],
  [... dismiss via contradiction ...],
  ex l3: ?l2 = [?n|?l3] & succeeds ?n @< ?k & succeeds range(s(?n),?k,?l3),
  exist(l3,
    ?l2 = [?n|?l3] & succeeds ?n @< ?k & succeeds range(s(?n),?k,?l3),
    [... use IH ...],
    conclusion),
  conclusion)
```

The disjunction formula must be stated **explicitly** as an intermediate
step between `def ... by completion` and `cases(...)`.

### Deriving `ff` from `succeeds P` and `fails P`

LPTP can derive `ff` (falsity) when both `succeeds P` and `fails P` are
in the context for the **exact same term** P. This is checked by
`pr__inconsistent` in `src/pr.pl` (line 375), which performs **purely
syntactic** matching — no equality substitution.

**Critical pitfall**: if the context contains `succeeds ?n @< ?k` and
`?k = ?n`, you might expect `fails ?n @< ?n` to produce `ff`. It does
**not**, because the `succeeds` term has `?k` while the `fails` term has
`?n`. You must first derive `succeeds ?n @< ?n` explicitly (LPTP's CET
unification handles the equality `?k = ?n`), then `fails ?n @< ?n`, then
`ff`:

```prolog
% Inside cases(?k = ?n & ..., [...], ...)
cases(?k = ?n & ?l2 = [?n],
  [succeeds ?n @< ?n,                       % CET derives from ?k=?n + succeeds ?n @< ?k
   fails ?n @< ?n by lemma(less:failure),   % by lemma
   ff],                                     % NOW works: same term on both sides
  ...)
```

This pattern applies whenever dismissing a contradictory branch from
overlapping clause completion.

### Algebraic uniqueness proofs (avoiding induction)

When a predicate computes a value that can be characterized algebraically,
uniqueness can be proven without induction. Pattern:

1. Prove a "functional equation": e.g., `quot(s(d0), n, q) => s(d0) @* q = n`
2. For uniqueness: from two calls, derive `s(d0) @* q1 = s(d0) @* q2`
3. Use `leq:times:inverse` (or `plus:injective:second` etc.) to get
   `q1 @=< q2` and `q2 @=< q1`
4. Apply `leq:antisymmetric` to conclude `q1 = q2`

This avoids complex case analyses on the completion (mixed clause cases,
vacuous failure on zero, etc.).

Key nat library lemmas for this pattern:
- `leq:times:inverse`: `nat(x) & nat(y) & nat(z) & s(x) @* y @=< s(x) @* z => y @=< z`
- `plus:injective:second`: `nat(x) & x @+ y = x @+ z => y = z`
- `leq:antisymmetric`: `x @=< y & y @=< x => x = y`

### Ensure prerequisites before `def succeeds ... by completion`

`def succeeds nat(s(?f0)) by completion` requires that `succeeds nat(s(?f0))`
is in context (or derivable from it). Inside `exist(f0, ?f = s(?f0), ...)`,
this works only if `succeeds nat(?f)` was established **before** entering
the exist block. Always derive type facts (`nat`, `list`, etc.) as early
as possible, before entering exist blocks that specialize them.

### Difference induction for increasing arguments

When the recursive argument **increases** (N → s(N)) toward a fixed bound K,
standard nat induction on K fails because K doesn't change. Introduce a
"difference" variable D = K − N with `K = N @+ D`, and induct on `nat(D)`:

```prolog
:- lemma(pred:termination,
all [d,n,k,l]: succeeds nat(?d) & succeeds nat(?n) & ?k = ?n @+ ?d =>
  terminates pred(?n,?k,?l),
[induction(
  [all d: succeeds nat(?d) =>
    (all [n,k,l]: succeeds nat(?n) & ?k = ?n @+ ?d =>
      terminates pred(?n,?k,?l))],
  [step([],       % D=0: K = N+0 = N
    [],
    assume(succeeds nat(?n) & ?k = ?n @+ 0,
      [succeeds nat(?n),
       ?n @+ 0 = ?n by lemma(plus:zero),
       ?k = ?n,
       ... base case ...],
      terminates pred(?n,?k,?l)),
    ...),
   step([d],      % D=s(D'): K = N+s(D') = s(N)+D'
    [all [n,k,l]: succeeds nat(?n) & ?k = ?n @+ ?d =>
      terminates pred(?n,?k,?l),
     succeeds nat(?d)],
    assume(succeeds nat(?n) & ?k = ?n @+ s(?d),
      [succeeds nat(?n),
       ?n @+ s(?d) = s(?n) @+ ?d by lemma(plus:successor),
       ?k = s(?n) @+ ?d,
       succeeds nat(s(?n)),
       succeeds nat(s(?n)) & ?k = s(?n) @+ ?d,
       terminates pred(s(?n),?k,?l),        % IH with n:=s(N), d:=D'
       ...],
      terminates pred(?n,?k,?l)),
    ...)]),
 ... unwrap ...]
).
```

Key library lemmas: `plus:zero` (N+0 = N), `plus:successor` (N+s(D) = s(N)+D).

### Fact clauses in termination completion

When a predicate has a fact clause (no body), `terminates P by completion` still
requires a contribution for that clause. The contribution is just the head
unification constraints, wrapped in `terminates(...)`.

Example: `totient_phi(s(0), s(0)).` is a fact (body = `true`). In the termination
proof for `totient_phi(?m, ?phi)`:

```prolog
  /* Clause 1 (fact): just unification constraints */
  terminates (?m = s(0) & ?phi = s(0)),
  /* Clause 2 (recursive): show body terminates */
  all x: ?m = s(s(?x)) =>
   terminates totient_count(s(s(?x)), s(0), s(?x), ?phi),
  /* Combine */
  terminates (?m = s(0) & ?phi = s(0)) &
  (all x: ?m = s(s(?x)) =>
    terminates totient_count(s(s(?x)), s(0), s(?x), ?phi)),
  terminates totient_phi(?m, ?phi) by completion
```

This differs from recursive clauses where the main work is showing body
termination. For facts, `terminates (head-unification)` is trivially true but
must be stated explicitly.

## 12. Workflow Summary

1. Write the Prolog program (`foo.pl`).
2. Create the ground representation file (`foo.gr`) encoding the clauses as variable-free terms.
3. Create the proof file (`foo.pr`) with the standard header.
4. Copy `.gr` and `.pr` to `/Users/fred/lptp/tmp/`.
5. Run: `cd /Users/fred/lptp && printf "io__exec_file('tmp/foo.pr').\nhalt.\n" | bin/lptp 2>&1`
6. Check for "o.k." message; fix any errors and re-run.
7. Copy generated `.thm` and `.tex` back to the project directory if desired.
