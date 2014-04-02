
 <!-- References -->

[*Memo Functions, Polytypically!*]: http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.43.3272 "paper by Ralf Hinze"

[MemoTrie]: http://hackage.haskell.org/package/MemoTrie "Haskell library"

 <!-- -->

# Elegant memoization

I gave this talk [at the Hacker Dojo in Mountain View, California on April 3, 2014](http://www.meetup.com/haskellhackersathackerdojo/events/151894212/).

You can find [the slides (PDF)](http://conal.net/talks/elegant-memoization.pdf) in [my talks folder](http://conal.net/talks/).

Abstract:

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
[One implementation][MemoTrie] of the idea in Haskell uses associated types.

 </blockquote>
