(*<*)theory Overloading2 = Overloading1:(*>*)

text{*
Of course this is not the only possible definition of the two relations.
Componentwise comparison of lists of equal length also makes sense. This time
the elements of the list must also be of class @{text ordrel} to permit their
comparison:
*}

instance list :: (ordrel)ordrel
by intro_classes

defs (overloaded)
le_list_def: "xs <<= (ys::'a::ordrel list) \<equiv>
              size xs = size ys \<and> (\<forall>i<size xs. xs!i <<= ys!i)"

text{*\noindent
The infix function @{text"!"} yields the nth element of a list.
*}

subsubsection{*Predefined overloading*}

text{*
HOL comes with a number of overloaded constants and corresponding classes.
The most important ones are listed in Table~\ref{tab:overloading}. They are
defined on all numeric types and somtimes on other types as well, for example
@{text"-"}, @{text"\<le>"} and @{text"<"} on sets.

\begin{table}[htbp]
\begin{center}
\begin{tabular}{lll}
Constant & Type & Syntax \\
\hline
@{term 0} & @{text "'a::zero"} \\
@{text"+"} & @{text "('a::plus) \<Rightarrow> 'a \<Rightarrow> 'a"} & (infixl 65) \\
@{text"-"} & @{text "('a::minus) \<Rightarrow> 'a \<Rightarrow> 'a"} &  (infixl 65) \\
@{text"*"} & @{text "('a::times) \<Rightarrow> 'a \<Rightarrow> 'a"} & (infixl 70) \\
@{text"^"} & @{text "('a::power) \<Rightarrow> nat \<Rightarrow> 'a"} & (infixr 80) \\
@{text"-"} & @{text "('a::minus) \<Rightarrow> 'a"} \\
@{term abs} &  @{text "('a::minus) \<Rightarrow> 'a"} & $\mid~\mid$\\
@{text"\<le>"} & @{text "('a::ord) \<Rightarrow> 'a \<Rightarrow> bool"} & (infixl 50) \\
@{text"<"} & @{text "('a::ord) \<Rightarrow> 'a \<Rightarrow> bool"} & (infixl 50) \\
@{term min} &  @{text "('a::ord) \<Rightarrow> 'a \<Rightarrow> 'a"} \\
@{term max} &  @{text "('a::ord) \<Rightarrow> 'a \<Rightarrow> 'a"}
\end{tabular}
\caption{Overloaded constants in HOL}
\label{tab:overloading}
\end{center}
\end{table}
*}(*<*)end(*>*)
