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

\nc\pitem{\pause \item}

%%%%

% \setbeameroption{show notes} % un-comment to see the notes

\begin{document}

\frame{\titlepage}

\framet{Laziness}{

\begin{itemize} \itemsep 3ex
\item Value computed only when inspected.
\item Saved for reuse.
\item Every part of a data structure.
\item Insulate definition from use: \emph{modularity}.
\item Routinely program with infinite structures.
\end{itemize}
}

\framet{What about functions?}{

\begin{itemize} \itemsep 3ex
\item Functions as indexed collections.
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
\pitem Preferably incremental.
\pitem How?
\end{itemize}
}

\framet{Convenient notation}{

I'll use some non-standard (for Haskell) type notation:

> type Unit  = ()
> data Void  -- no values
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
% \item Functions as indexed collections.
\item
  Different shape for each domain type.
\item
  Consider domain types systematically\pause:\\
  |Void|, |Unit|, |a :+ b|, |a :* b|, |a -> b|, |data|.
\end{itemize}
}

\framet{What's really going on here?}{

\begin{itemize} \itemsep 3ex
\item Goal: capture all of a function's information.
\item Make precise: \pause ability to convert back. \emph{Isomorphism.}
\pitem Domain type drives the memo structure.
\end{itemize}

}

\nc{\iso}[2]{\pause #1 \to a &\cong& \pause #2 \\}
\nc{\equi}[2]{a^{#1} &=& #2 \\}

\framet{Type isomorphisms}{

$$\begin{array}{rcl}
\iso{\Void}{\Unit}
\iso{\Unit}{a}
\iso{(b + c)}{(b \to a) \times (c \to a)}
\iso{(b \times c)}{b \to (c \to a)}
\end{array}$$

\pause

\vspace{1ex}

Compare with laws of exponents:

$$\begin{array}{rcl}
\equi{0}{1}
\equi{1}{a}
\equi{b + c}{a^b \times a^c}
\equi{b \times c}{(a ^ c) ^ b}
\end{array}$$

\vspace{2ex}

\pause These rules form a memoization algorithm.
% \pause Termination?

\vspace{1ex}

\pause
\emph{Catch:} |undefined|.

}

\framet{An implementation of memoization}{

From \href{http://hackage.haskell.org/package/MemoTrie}{|MemoTrie|}:

> class HasTrie a where
>   type (:->:) a :: * -> *
>   trie    :: (a   ->   t)  -> (a :->: t)
>   untrie  :: (a  :->:  t)  -> (a  ->  t)

Law: |trie| and |untrie| are inverses (modulo |undefined|).
%% \\ \pause (Really, |untrie . trie <<= id|, and |trie . untrie == id|.)

\vspace{3ex}

Memoization:

\pause

> memo :: HasTrie a => (a -> t) -> (a -> t)
> memo = untrie . trie

}

\framet{Unit}{

> instance HasTrie Unit where
>   type Unit :->: t = t
>   trie f = f ()
>   untrie x = \ () -> x

}

\framet{Boolean}{

> instance HasTrie Bool where
>   type Bool :->: t = t :* t
>   trie f = (f False, f True)
>   untrie (x,y) = \ c -> if c then y else x

}

\framet{Sums}{

> instance (HasTrie a, HasTrie b) => HasTrie (a :+ b) where
>   type (a :+ b) :->: t = (a :->: t) :* (b :->: t)
>   trie f = (trie (f . Left), trie (f . Right))
>   untrie (s,t) = untrie s ||| untrie t

where

> (g ||| h) (Left   a)  = g a
> (g ||| h) (Right  b)  = h b

}

\framet{Products}{

> instance (HasTrie a, HasTrie b) => HasTrie (a,b) where
>   type (a,b) :->: x = a :->: (b :->: x)
>   trie f = trie (trie . curry f)
>   untrie t = uncurry (untrie .  untrie t)

where

> curry    g x y    = g (x,y)
> uncurry  h (x,y)  = h x y

}

\framet{Data types}{

Handle other types via isomorphism:

\vspace{2ex}

> (u, v, w) =~ (u :* v) :* w
> SPACE
> [u] =~ Unit :+ u :* [u]
> SPACE
> T u =~ u :+ T u :* T u
> SPACE
> Bool =~ Unit :+ Unit

}

% \rnc{\equi}[2]{a^{#1} &=& #2 \\}

\nc{\logEqui}[2]{\log_a #2 &=& #1 \\}

\framet{Turn it around}{

Exponentials:

$$\begin{array}{rcl}
\equi{0}{1}
\equi{1}{a}
\equi{b + c}{a^b \times a^c}
\equi{b \times c}{(a ^ c) ^ b}
\end{array}$$

\pause\vspace{2ex}
Take logarithms, and flip equations:

$$\begin{array}{rcl}
\logEqui{0}{1}
\logEqui{1}{a}
\logEqui{b + c}{a^b \times a^c}
\logEqui{b \times c}{(a ^ c) ^ b}
\end{array}$$

}

\framet{Logarithms}{

$$\begin{array}{rcl}
\logEqui{0}{1}
\logEqui{1}{a}
\logEqui{b + c}{a^b \times a^c}
\logEqui{b \times c}{(a ^ c) ^ b}
\end{array}$$

\pause\vspace{2ex} Game: whose memo trie is it?

\pause

\setlength{\fboxsep}{-1ex}

\begin{center}
\fbox{\begin{minipage}[c]{0.53\textwidth}

> BACK data P  a = P a a
> BACK data S  a = C a (S a)
> BACK data T  a = B a (P (T a))

\end{minipage}}
\pause
\fbox{\begin{minipage}[c]{0.46\textwidth}

> P  a =~ a :* a
> S  a =~ a :* S a
> T  a =~ a :* P (T a)

\end{minipage}}
\end{center}

\pause

\begin{center}
\fbox{\begin{minipage}[c]{0.53\textwidth}

> BACK data LP  = False  | True
> BACK data LS  = Zero   | Succ LS
> BACK data LT  = Empty  | Dig LT LP

\end{minipage}}
% \pause
\fbox{\begin{minipage}[c]{0.46\textwidth}

> LP  =~ Unit :+ Unit
> LS  =~ Unit :+ SL
> LT  =~ Unit :+ LT :* LP

\end{minipage}}
\end{center}

}

\setlength{\fboxsep}{1.5ex}

\framet{Memoization via higher-order types}{

Functor combinators:

> data     Const b      a = Const b
> newtype  Id           a = Id a
> data     (f  :+:  g)  a = Sum   (f a :+ g a)
> data     (f  :*:  g)  a = Prod  (f a :* g a)
> newtype  (g  :.   f)  a = Comp  (g (f a))

%\vspace{1ex}

\pause

\fbox{\begin{minipage}[c]{0.45\textwidth} \small
Exponents:

> Exp     Void   = Const Unit
> Exp     Unit   = Id
> Exp (a  :+ b)  = Exp a  :*:  Exp b
> Exp (a  :* b)  = Exp a  :.   Exp b

\end{minipage}}
\pause
\fbox{\begin{minipage}[c]{0.45\textwidth} \small
Logarithms:

> Log (Const b)    =        Void
> Log Id           =        Unit
> Log (f  :*:  g)  = Log f  :+ Log g
> Log (g  :.   f)  = Log g  :* Log f

\end{minipage}}
}

\setlength{\fboxsep}{-2ex}

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

\framet{Some memoization challenges}{

\begin{itemize} \itemsep 3ex
\item
  Non-strict
\item
  Higher-order
\item
  Polymorphic
\item
  Deep
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

\framet{Correctness Proofs}{}

\framet{Unit}{

> instance HasTrie Unit where
>   type Unit :->: t = t
>   trie f = f ()
>   untrie x = \ () -> x

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

>      trie (untrie x)
> ===  trie (\ () -> x)
> ===  (\ () -> x) ()
> ===  x

\end{minipage}}
\end{center}
}

\framet{Boolean}{

> instance HasTrie Bool where
>   type Bool :->: t = (t,t)
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
>   type (a :+ b) :->: t = (a :->: t) :* (b :->: t)
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
>   type (a :+ b) :->: t = (a :->: t) :* (b :->: t)
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

> curry    g x y    = g (x,y)
> uncurry  h (x,y)  = h x y

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

\end{document}
