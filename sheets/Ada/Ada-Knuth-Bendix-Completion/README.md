# Knuth–Bendix completion algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Knuth–Bendix
completion algorithm** over **words** (the free monoid / string rewriting):
orient a finite set of equations into rewrite rules under a **shortlex**
(length-lex) reduction order, reduce words to normal forms, enumerate
**critical pairs** from overlaps of left-hand sides, and attempt to grow a
finite **convergent** rewrite system that decides the **word problem**. See
[Wikipedia: Knuth–Bendix completion algorithm](https://en.wikipedia.org/wiki/Knuth–Bendix_completion_algorithm).

This package is a **classroom sketch** on small bounded words and rule sets
(`Max_Word_Len`, `Max_Rules_Cap`). It is **not** a production term-rewriting
or computational-group-theory engine (no AC matching, no sophisticated
termination orders beyond shortlex, no huge presentations).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Word problem, termination, confluence

Given a monoid presentation $\langle X \mid E \rangle$, the **word problem**
asks whether two words $u,v \in X^*$ represent the same element — i.e.
whether $u \mathrel{{}^{*}\!\leftrightarrow_{E}} v$ in the equational theory.

A rewrite system $R$ **terminates** when every rewrite sequence is finite
(here guaranteed by shortlex: each rule strictly decreases the order). It is
**confluent** when $u \mathrel{{}^{*}\!\rightarrow_{R}} x$ and
$u \mathrel{{}^{*}\!\rightarrow_{R}} y$ imply $x$ and $y$ join to a common
descendant. Termination + confluence $\Rightarrow$ unique **normal forms**,
so $u$ and $v$ are equivalent iff
$\mathrm{NF}_R(u)=\mathrm{NF}_R(v)$.

**Newman's lemma:** a terminating system is confluent iff it is *locally*
confluent. The **critical pair lemma** reduces local confluence to checking
finitely many overlaps of left-hand sides. Knuth–Bendix adds oriented rules
until every critical pair joins — or runs forever / hits a bound
(**semi-decision**).

## Critical pairs (strings)

For rules $\ell_1 \to r_1$ and $\ell_2 \to r_2$:

- **Proper overlap:** $\ell_1 = AB$, $\ell_2 = BC$ with $A,B,C$ nonempty.
  Peak $ABC$ rewrites to $r_1 C$ and $A r_2$.
- **Inclusion:** $\ell_2$ occurs inside $\ell_1$ (or vice versa). Peak is the
  longer LHS; rewrites use the outer rule vs. the inner factor.

If the two reducts have distinct normal forms, orient the residual equation
by shortlex and add it.

## Relation to Buchberger

[Buchberger's algorithm](https://en.wikipedia.org/wiki/Buchberger%27s_algorithm)
for Gröbner bases is the same completion idea in polynomial rings: S-polynomials
play the role of critical pairs, and a monomial order plays the role of the
reduction order. Knuth–Bendix is the general equational / term-rewriting form;
Buchberger is its instantiation for commutative polynomials.

## Shortlex order

$$
u <_{\mathrm{sl}} v \iff |u| < |v| \;\text{or}\; \bigl(|u|=|v| \land u <_{\mathrm{lex}} v\bigr).
$$

Empty word is minimal. Orientation: larger side $\to$ smaller side.

## API sketch

| Operation | Role |
| --- | --- |
| `To_Word` / `Image` / `Make_Equation` / `Make_Rule` | Constructors / views |
| `Shortlex_Less` / `Orient` | Reduction order and rule orientation |
| `Rewrite_Step` / `Reduce` / `Normal_Form` | Leftmost-outermost rewriting |
| `Equivalent` | Same normal form under a rule set |
| `Critical_Pairs` | Overlap + inclusion critical pairs for rules $i,j$ |
| `Complete` | Knuth–Bendix; returns `Success` or `Did_Not_Complete` |
| `Is_Locally_Confluent` | All enumerated critical pairs join |

`Complete (Equations, Max_Rules, Max_Steps)` may return
`Kind => Did_Not_Complete` when bounds are exceeded — completion is only a
**semi-decision** procedure. Raises `Invalid_Argument` on empty / ill-formed
input (oversized words, empty equation set, empty rule LHS, bounds outside
capacity).

## Tiny examples

- Commutativity $ba=ab$ orients to $ba \to ab$ and is already convergent;
  normal forms are sorted words.
- $ab=c$, $bc=a$ produces the overlap peak $abc$ with critical pair
  $\{aa,cc\}$; completion adds $cc \to aa$ (under $a<c$).
- Involutions $aa=\varepsilon$, $bb=\varepsilon$ complete to those two rules.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.

## SPARK / GNATprove (Level 2)

`SPARK_Mode => On` on the package. Exception-raising constructors, rewrite/completion
drivers, and critical-pair search are `SPARK_Mode => Off`. Pure shortlex helpers remain
in SPARK.

```bash
make prove   # gnatprove --level=2
```

**Bar:** Level 2, all SPARK-analyzed checks proved. `make test` stays green (`-gnatwa`).
