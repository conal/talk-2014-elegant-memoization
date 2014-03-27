%% -*- latex -*-

%% %let atwork = True

% Presentation
\documentclass{beamer}

\usefonttheme{serif}

\usepackage{beamerthemesplit}

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
\institute{\href{http://tabula.com/}{Tabula}}
% Abbreviate date/venue to fit in infolines space
\date{\href{http://www.meetup.com/haskellhackersathackerdojo/events/132372202/}{April 3, 2014}}

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
\item Value not computed until inspected.
\item Saved for reuse.
\item Every level of a data structure.
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

\begin{itemize} \itemsep 5ex
\pitem Mutable hash tables?
\pitem My definition: \emph{conversion of functions into data structures}.
\pitem Challenge: how to capture?
\end{itemize}
}

\framet{Convenient notation}{

I'll use some non-standard (for Haskell) type notation:

> type Unit  = ()
> type (:+)  = Either
> type (:*)  = (,)
>
> infixl 7 :*
> infixl 6 :+

}

\framet{Examples}{

> f :: Bool -> Int
> f x = if x then 3 else 5

\pause

> g :: () -> String
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

\begin{itemize} \itemsep 3ex
\item
  Remember: memoization is the conversion of functions into data structures.
\item
  We can think of a function as an indexed collection.
\item
  But a differently shaped collection for each domain type.
\item
  Look at these domain types systematically:\\ |Unit|, |a :+ b|, |a :* b|, |a -> b|, |data|.
\end{itemize}
}

\framet{Type isomorphisms}{

\begin{itemize} \itemsep 3ex
\item Goal: capture all of a function's information.
\item Make precise: \pause ability to convert back (isomorphism).
\item Domain type drives the memo structure.
\end{itemize}

}

\framet{Type isomorphisms}{

$$\begin{array}{rcl}
1 \to a &\cong& a \\
(a + b) \to c &\cong& (a \to c) \times (b \to c) \\
(a \times b) \to c &\cong& a \to (b \to c)
\end{array}$$

\pause

\vspace{3ex}

Compare with laws of exponents:

$$\begin{array}{rcl}
a ^ 1 &=& a \\
c^{a + b} &=& c^a \times c^b \\
c^{a \times b} &=& (c ^ b) ^ a
\end{array}$$

\vspace{4ex}

\pause
\emph{Catch:} bottoms.

}

\framet{An implementation of memoization}{

> class HasTrie a where
>     type (:->:) a :: * -> *
>     trie    :: (a   ->   b)  -> (a :->: b)
>     untrie  :: (a  :->:  b)  -> (a  ->  b)

Law: |trie| and |untrie| are inverses \pause (modulo |undefined|).

\pause

\vspace{3ex}

Memoization:

> memo :: HasTrie t => (t -> a) -> (t -> a)
> memo = untrie . trie

}

\framet{Unit}{

> instance HasTrie () where
>     type () :->: a = a
>     trie f = f ()
>     untrie a = \ () -> a

\pause
Laws:
\begin{center}
\fbox{\begin{minipage}[t]{0.45\textwidth}

>     untrie (trie f)
> ==  untrie (f ())
> ==  \ () -> f ()
> ==  f   

\end{minipage}}
\fbox{\begin{minipage}[t]{0.45\textwidth}

>     trie (untrie a)
> ==  trie (\ () -> a)
> ==  (\ () -> a) ()
> ==  a

\end{minipage}}
\end{center}
}

\framet{Boolean}{

> instance HasTrie Bool where
>   type Bool :->: x = (x,x)
>   trie f = (f False, f True)
>   untrie (x,y) = \ c -> if c then y else x

\pause
Laws:
\begin{center}
\fbox{\begin{minipage}[t]{0.45\textwidth}

>     untrie (trie f)
> ==  untrie (f False, f True)
> ==  \ c -> if c then f True else f False
> ==  \ c -> if c then f c else f c
> ==  \ c -> f c
> ==  f

\end{minipage}}
\fbox{\begin{minipage}[t]{0.45\textwidth}

>     trie (untrie (x,y))
> ==  trie (\ c -> if c then y else x)
> ==  (if False then y else x, if True then y else x)
> ==  (x,y)

\end{minipage}}
\end{center}
}



\framet{Memoization via higher-order types}{
}

\framet{A beautiful story}{

\begin{itemize} \itemsep 3ex
\item
  Memoization is conversion of functions into data structures.
\item
  Purely functional, directed by type isomorphisms.
\item
  Practical in a non-strict language!
\item
  Best of both worlds: incremental tabulation and simple denotation.
  Operational optimization/messiness (mutation) to the language
  \emph{implementation}. Contrast with an eager or imperative setting.
\end{itemize}
}

\framet{An \emph{almost} beautiful story}{

\begin{itemize} \itemsep 3ex
\item
  However, there's an ironic flaw in this story: the type isomorphisms only hold for a \emph{strict} language.
\end{itemize}
}

\framet{Some challenges}{

\begin{itemize} \itemsep 3ex
\item
  Non-strict memoization
\item
  Higher-order memoization
\item
  Polymorphic memoization
\end{itemize}
}

\framet{References}{

\begin{itemize} \itemsep 3ex
\item Ralf Hinze's paper \href{http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.43.3272}{\emph{Memo functions, polytypically!}}.
\item \href{http://conal.net/talks/elegant-memoization/}{These slides}
\item |MemoTrie|: \href{http://hackage.haskell.org/package/MemoTrie}{Hackage}, \href{https://github.com/conal/MemoTrie}{GitHub}
\item |Data.MemoCombinators|
\item \href{Memoization blog posts}{http://conal.net/blog/tag/trie/}
\item 
\end{itemize}

}

\end{document}
