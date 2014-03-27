---
title: Elegant memoization
substMap: [("&&&","△"), ("***", "×"), ("|||","▽"), ("+++","+"),(":+>","☞"),("Void","0"),("Unit","1"),("<>","⊕")]
...

 <!-- References -->

[*Memo Functions, Polytypically!*]: http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.43.3272 "paper by Ralf Hinze"

[MemoTrie]: http://hackage.haskell.org/package/MemoTrie "Haskell library"

 <!-- -->

# Abstract

 <blockquote>

Functional programming languages (FPLs) emphasize the use of (pure) functions, but they also carry an implementation bias against them.
In most functional programming languages, including Haskell, if you express a value and then access it twice, you'll pay only once.
For data structures, every component has this property.
For functions, however, an analogous property does not hold: if you apply a function twice to the same argument, the result will be recomputed.
Donald Michie invented a solution, which he called "[memoization](https://en.wikipedia.org/wiki/Memoization)".
The trick is to store function results in a lookup table for later reuse.
From this perspective, memoization is an imperative technique.
Ironically, the technique is only correct for pure functions.

I'm going to talk about purely functional memoization.
The idea, [due to Ralf Hinze][*Memo Functions, Polytypically!*], is to use a few simple type isomorphisms to guide and justify the memoization, leading to the systematic construction of *trie* data structures ("digital search trees") from first principles.
[One particularly elegant implementation][MemoTrie] of the idea in Haskell uses associated types.

 </blockquote>

# Outline

I'm going to give a talk on memoization for the [Haskell meetup on April 3, 2014](http://www.meetup.com/haskellhackersathackerdojo/events/151894212/).

*   Laziness:
    *   With laziness, we don't compute a value until inspected, and then the value is saved for reuse.
    *   For data structures, this operational behavior holds for every piece.
    *   Consequently, we routinely program with infinite structures.
    *   Big win for modularity: we needn't decide up front how much of a structure will really get used.
*   What about functions?
    *   Better question: what about the application of functions?
    *   Newbies often assume that functions also cache computed results.
    *   Why not?
*   What is memoization?
    *   I thought it was about mutable hash tables ....
    *   Instead: memoization is the conversion of functions into data structures.
    *   The trick is to find the right data structure, so that no information is lost.
*   Examples with domain:
    *   `Bool`
    *   `(Bool,Bool)`
    *   `Either Bool (Bool,Bool)`
    *   `Nat`
    *   `[a]`
*   What's really going on here?
    *   Remember: memoization is the conversion of functions into data structures.
    *   We can think of a function as an indexed collection.
    *   But a differently shaped collection for each domain type.
    *   So let's look at these domain types systematically, starting with *very* simple ones and building up.
        We'll start with `Unit`, `(:+)`, `(:*)`, and `(->)`.
*   Type isomorphisms
    *   We want to capture all of a function's information into a data structure.
    *   What does it mean to capture all information? The ability to convert back (isomorphism).
    *   Our examples suggest that the structure's shape depends only on the domain type.
        Let's look at type isomorphisms for various domains:
        *   `Unit`;
        *   `a :+ b`;
        *   `a :* b`;
        *   `a -> b` (oops);
        *   Other types.
        *   What about bottoms?
*   Algebra of exponents.
*   An implementation of memoization.
*   Memoization via higher-order types.
*   A beautiful story:
    *   Memoization is conversion of functions into data structures.
    *   Purely functional, directed by type isomorphisms.
    *   Practical in a non-strict language!
    *   Best of both worlds: incremental tabulation and simple denotation.
        Operational optimization/messiness (mutation) to the language *implementation*.
        Contrast with an eager or imperative setting.
*   An *almost* beautiful story:
    *   However, there's an ironic flaw in this story: the type isomorphisms only hold for a *strict* language.
*   Some challenges:
    *   Non-strict memoization
    *   Higher-order memoization
    *   Polymorphic memoization
