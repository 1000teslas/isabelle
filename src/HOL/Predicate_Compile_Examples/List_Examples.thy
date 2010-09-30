theory List_Examples
imports Main "Predicate_Compile_Quickcheck" "Code_Prolog"
begin

setup {* Context.theory_map (Quickcheck.add_generator ("prolog", Code_Prolog.quickcheck)) *}

setup {* Code_Prolog.map_code_options (K 
  {ensure_groundness = true,
   limit_globally = NONE,
   limited_types = [(@{typ nat}, 2), (@{typ "nat list"}, 4)],
   limited_predicates = [(["appendP"], 4), (["revP"], 4)],
   replacing =
     [(("appendP", "limited_appendP"), "quickcheck"),
      (("revP", "limited_revP"), "quickcheck"),
      (("appendP", "limited_appendP"), "lim_revP")],
   manual_reorder = []}) *}

lemma "(xs :: nat list) = ys @ ys --> rev xs = xs"
quickcheck[generator = code, iterations = 200000, expect = counterexample]
quickcheck[generator = predicate_compile_wo_ff, iterations = 1, expect = counterexample]
quickcheck[generator = prolog, expect = counterexample]
oops

end