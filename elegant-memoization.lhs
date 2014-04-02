%% -*- latex -*-

%% %let atwork = True

% Presentation
\documentclass{beamer}

\usefonttheme{serif}

\usepackage{beamerthemesplit}
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{color}
\DeclareGraphicsExtensions{.pdf,.png,.jpg}

\usepackage{wasysym}

\useinnertheme[shadow]{rounded}
% \useoutertheme{default}
\useoutertheme{shadow}
\useoutertheme{infolines}
% Suppress navigation arrows
\setbeamertemplate{navigation symbols}{}

\input{macros}

%include polycode.fmt
%include forall.fmt
%include greek.fmt
%include mine.fmt

\title{Elegant memoization}
\author{\href{http://conal.net}{Conal Elliott}}
\institute{\href{http://www.tabula.com/}{Tabula}}
% Abbreviate date/venue to fit in infolines space
\date{\href{http://www.meetup.com/haskellhackersathackerdojo/events/151894212/}{April 3, 2014}}

\setlength{\itemsep}{2ex}
\setlength{\parskip}{1ex}

\setlength{\blanklineskip}{1.5ex}

\setlength{\fboxsep}{-2ex}

\nc\pitem{\pause \item}

%%%%

% \setbeameroption{show notes} % un-comment to see the notes

\begin{document}

\frame{\titlepage}

\framet{Laziness}{

\begin{itemize} \itemsep 3ex
\item Value computed only when inspected.
\item Saved for reuse.
\item At every level of a data structure.
\item Insulate definition from use: \emph{modularity}.
\item Routinely program with infinite structures.
\end{itemize}
}

\framet{What about functions?}{

\begin{itemize} \itemsep 3ex
\item Functions are indexed collections.
\item Are ``accesses'' cached?
\pitem Why not?
\end{itemize}
}

\framet{What is memoization?}{

\begin{itemize} \itemsep 4ex
\pitem Conventional story: mutable hash tables.
\pitem Ironic flaw: only correct for pure functions.
\pitem My definition: \emph{conversion of functions into data structures}
\pitem ... without loss of information.
\pitem How?
\end{itemize}
}

\framet{Convenient notation}{

I'll use some non-standard (for Haskell) type notation:

> type Unit  = ()
> type (:*)  = (,)
> type (:+)  = Either
>
> infixl 7 :*
> infixl 6 :+

}

\framet{Examples}{

> f :: Bool -> Int
> f x = if x then 3 else 5

\pause

> g :: Unit -> String
> g () = map toUpper "memoize!"

\pause

> h :: Bool :* Bool -> Int
> h (x,y) = f (x && y) + f (x || y)

\pause

> k :: Bool :+ Bool -> Int
> k (Left   x)  = if x then 3 else 5
> k (Right  y)  = if y then 4 else 6

}

\framet{More examples}{

\begin{itemize} \itemsep 4ex
\item |Bool :+ Bool :* Bool -> ...|
\item |Nat -> ...|
\item |[a] -> ...|
\end{itemize}
}

\framet{What's really going on here?}{

\begin{itemize} \itemsep 4ex
\item
  Remember: conversion of functions into data structures.
\item
  Functions as indexed collections.
\item
  Differently shaped collection for each domain type.
\item
  Consider domain types systematically\pause:\\
  |Unit|, |a :+ b|, |a :* b|, |a -> b|, |data|.
\end{itemize}
}

\framet{What's really going on here?}{

\begin{itemize} \itemsep 3ex
\item Goal: capture all of a function's information.
\item Make precise: \pause ability to convert back. \emph{Isomorphism.}
\pitem Domain type drives the memo structure.
\end{itemize}

}

\nc{\iso}[2]{\pause #1 \to c &\cong& \pause #2 \\}
\nc{\equi}[2]{\pause c^{#1} &=& #2 \\}

\framet{Type isomorphisms}{

$$\begin{array}{rcl}
\iso{1}{c}
\iso{(a + b)}{(a \to c) \times (b \to c)}
\iso{(a \times b)}{a \to (b \to c)}
\end{array}$$

\pause

\vspace{2ex}

Compare with laws of exponents:

$$\begin{array}{rcl}
\equi{1}{c}
\equi{a + b}{c^a \times c^b}
\equi{a \times b}{(c ^ b) ^ a}
\end{array}$$

\vspace{3ex}

\pause These rules form a memoization algorithm.
\pause Termination?

\vspace{2ex}

\pause
\emph{Catch:} bottoms.

}

\framet{An implementation of memoization}{

From \href{http://hackage.haskell.org/package/MemoTrie}{|MemoTrie|}:

> class HasTrie a where
>   type (:->:) a :: * -> *
>   trie    :: (a   ->   c)  -> (a :->: c)
>   untrie  :: (a  :->:  c)  -> (a  ->  c)

Law: |trie| and |untrie| are inverses (modulo |undefined|).
%% \\ \pause (Really, |untrie . trie <<= id|, and |trie . untrie == id|.)

\vspace{3ex}

Memoization:

\pause

> memo :: HasTrie a => (a -> c) -> (a -> c)
> memo = untrie . trie

}

\framet{Unit}{

> instance HasTrie Unit where
>   type Unit :->: c = c
>   trie f = f ()
>   untrie c = \ () -> c

\pause

Laws:\vspace{-1ex}
\begin{center}
\fbox{\begin{minipage}[t]{0.47\textwidth}

>      untrie (trie f)
> ===  untrie (f ())
> ===  \ () -> f ()
> ===  f   

\end{minipage}}
\fbox{\begin{minipage}[t]{0.47\textwidth}

>      trie (untrie c)
> ===  trie (\ () -> c)
> ===  (\ () -> c) ()
> ===  c

\end{minipage}}
\end{center}
}

\framet{Boolean}{

> instance HasTrie Bool where
>   type Bool :->: x = (x,x)
>   trie f = (f False, f True)
>   untrie (x,y) = if' x y
>     where if' x y c = if c then y else x

\vspace{-5ex}
\pause
\begin{center}
\fbox{\begin{minipage}[t]{0.45\textwidth}

>      untrie (trie f)
> ===  untrie (f False, f True)
> ===  if' (f False) (f True)
> ===  f

\end{minipage}}
\fbox{\begin{minipage}[t]{0.5\textwidth}

>      trie (untrie (x,y))
> ===  trie (if' x y)
> ===  (if' x y False, if' y x True)
> ===  (x,y)

\end{minipage}}
\end{center}

\vspace{-1ex}

\begin{minipage}[c]{0.1\textwidth}
\emph{Note:}
\end{minipage}
\begin{minipage}[c]{0.47\textwidth}

>      if' (f True) (f False)
> ===  \ c -> if c then f True else f False
> ===  \ c -> if c then f c else f c
> ===  f

\end{minipage}
}

\framet{Sums}{

> instance (HasTrie a, HasTrie b) => HasTrie (a :+ b) where
>   type (a :+ b) :->: x = (a :->: x) :* (b :->: x)
>   trie f = (trie (f . Left), trie (f . Right))
>   untrie (s,t) = untrie s ||| untrie t

where

> (g ||| h) (Left   a)  = g a
> (g ||| h) (Right  b)  = h b

\vspace{-5ex}
\pause
\begin{center}
\fbox{\begin{minipage}[t]{0.8\textwidth}

>      untrie (trie f)
> ===  untrie (trie (f . Left), trie (f . Right))
> ===  untrie (trie (f . Left)) ||| untrie (trie (f . Right))
> ===  f . Left ||| f . Right
> ===  f
> SPACE

\end{minipage}}
\end{center}
}

\framet{Sums}{

> instance (HasTrie a, HasTrie b) => HasTrie (a :+ b) where
>   type (a :+ b) :->: x = (a :->: x) :* (b :->: x)
>   trie f = (trie (f . Left), trie (f . Right))
>   untrie (s,t) = untrie s ||| untrie t

where

> (g ||| h) (Left   a)  = g a
> (g ||| h) (Right  b)  = h b

\vspace{-5ex}
\begin{center}
\fbox{\begin{minipage}[t]{0.8\textwidth}

>      trie (untrie (s,t))
> ===  trie (untrie s ||| untrie t)
> ===  (  trie ((untrie s ||| untrie t) . Left  )
>      ,  trie ((untrie s ||| untrie t) . Right ))
> ===  (trie (untrie s), trie (untrie t))
> ===  (s,t)

\end{minipage}}
\end{center}
}

\framet{Products}{

> instance (HasTrie a, HasTrie b) => HasTrie (a,b) where
>   type (a,b) :->: x = a :->: (b :->: x)
>   trie f = trie (trie . curry f)
>   untrie t = uncurry (untrie .  untrie t)

where

> curry    g x y   = g (x,y)
> uncurry  h (x,y) = h x y

\vspace{-5ex}
\pause
\begin{center}
\fbox{\begin{minipage}[t]{0.8\textwidth}

>      untrie (trie f)
> ===  untrie (trie (trie . curry f))
> ===  uncurry (untrie . untrie (trie (trie . curry f)))
> ===  uncurry (untrie . trie . curry f)
> ===  uncurry (curry f)
> ===  f

\end{minipage}}
\end{center}
}

\framet{Products}{

> instance (HasTrie a, HasTrie b) => HasTrie (a,b) where
>   type (a,b) :->: x = a :->: (b :->: x)
>   trie f = trie (trie . curry f)
>   untrie t = uncurry (untrie .  untrie t)

where

> curry    g x y   = g (x,y)
> uncurry  h (x,y) = h x y

\vspace{-5ex}
\begin{center}
\fbox{\begin{minipage}[t]{0.8\textwidth}

>      trie (untrie t)
> ===  trie (uncurry (untrie .  untrie t))
> ===  trie (trie . curry (uncurry (untrie .  untrie t)))
> ===  trie (trie . untrie .  untrie t)
> ===  trie (untrie t)
> ===  t

\end{minipage}}
\end{center}
}

\framet{Data types}{

Handle other types via isomorphism:

> a :* b :* c =~ (a :* b) :* c
>
> [a] =~ Unit :+ a :* [a]
>
> T a =~ a :+ T a :* T a
> 
> Bool =~ Unit :+ Unit

}

\framet{Memoization via higher-order types}{

Functor combinators:

> newtype  Id           a = Id a
> data     (f  :*:  g)  a = Prod  (f a :* g a)
> newtype  (g  :.   f)  a = Comp  (g (f a))

\vspace{1ex}

\pause
Associated functors:

> Trie Unit      = Id
> Trie (a :+ b)  = Trie a  :*:  Trie b
> Trie (a :* b)  = Trie a  :.   Trie b

}

\framet{Logarithms}{

Type isomorphisms:
\begin{minipage}[c]{0.6\textwidth}

>    Unit   :->: c =~ c
> (a :+ b)  :->: c =~ (a :->: c) :* (b :->: c)
> (a :* b)  :->: c =~ a :->: (b :->: c)

\end{minipage}

\pause
Re-interpret as recipe for \emph{logarithms}.
(Whose memo trie?)

\pause\vspace{3ex}

Examples:

\begin{center}
\fbox{\begin{minipage}[c]{0.53\textwidth}

> BACK data P  a = P a a
> BACK data S  a = C a (S a)
> BACK data T  a = B a (P (T a))

\end{minipage}}
\pause
\fbox{\begin{minipage}[c]{0.46\textwidth}

> BACK P  a = a :* a
> BACK S  a = a :* S a
> BACK T  a = a :* P (T a)

\end{minipage}}
\end{center}

\pause

\begin{center}
\fbox{\begin{minipage}[c]{0.53\textwidth}

> BACK data PL  = False  | True
> BACK data SL  = Zero   | Succ SL
> BACK data TL  = Empty  | Dig PL TL

\end{minipage}}
\pause
\fbox{\begin{minipage}[c]{0.46\textwidth}

> BACK PL  = F :+ T
> BACK SL  = Unit :+ SL
> BACK TL  = Unit :+ PL :* TL

\end{minipage}}
\end{center}

}

\framet{An \emph{almost} beautiful story}{

\begin{itemize} \itemsep 3ex
\item
  Memoization: \emph{conversion of functions into data structures}.
\item
  Purely functional, directed by type isomorphisms.
\item
  Practical in a non-strict language!
\item
  Simple denotation \emph{and} incremental tabulation.
\end{itemize}

\vspace{3ex}

However, an ironic flaw:

\pause

\begin{center}
The type isomorphisms only hold for a \emph{strict} language.
\end{center}

%% \pause 
%% Recall: imperative memoization has the opposite irony.

}

\framet{Some challenges}{

\begin{itemize} \itemsep 3ex
\item
  Non-strict memoization
\item
  Higher-order memoization
\item
  Polymorphic memoization
\item
  Deep memoization
\end{itemize}
}

\hypersetup{colorlinks=true,urlcolor=blue}

\framet{References}{

\begin{itemize} \itemsep 3ex
\item Ralf Hinze's paper \href{http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.43.3272}{\emph{Memo functions, polytypically!}}.
\item \href{http://conal.net/talks/elegant-memoization/}{These slides}
\item |MemoTrie|: \href{http://hackage.haskell.org/package/MemoTrie}{Hackage}, \href{https://github.com/conal/MemoTrie}{GitHub}
\item \href{http://hackage.haskell.org/package/data-memocombinators}{data-memocombinators}
\item \href{http://conal.net/blog/tag/trie/}{Memoization blog posts}
\end{itemize}

}

\end{document}
