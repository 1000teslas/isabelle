(*
  Title:     HOL/Algebra/CIdeal.thy
  Id:        $Id$
  Author:    Stephan Hohe, TU Muenchen
*)

theory Ideal
imports Ring AbelCoset
begin

section {* Ideals *}

subsection {* General definition *}

locale ideal = additive_subgroup I R + ring R +
  assumes I_l_closed: "\<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> x \<otimes> a \<in> I"
      and I_r_closed: "\<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> a \<otimes> x \<in> I"

interpretation ideal \<subseteq> abelian_subgroup I R
apply (intro abelian_subgroupI3 abelian_group.intro)
  apply (rule ideal.axioms, rule ideal_axioms)
 apply (rule abelian_group.axioms, rule ring.axioms, rule ideal.axioms, rule ideal_axioms)
apply (rule abelian_group.axioms, rule ring.axioms, rule ideal.axioms, rule ideal_axioms)
done

lemma (in ideal) is_ideal:
  "ideal I R"
by (rule ideal_axioms)

lemma idealI:
  fixes R (structure)
  assumes "ring R"
  assumes a_subgroup: "subgroup I \<lparr>carrier = carrier R, mult = add R, one = zero R\<rparr>"
      and I_l_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> x \<otimes> a \<in> I"
      and I_r_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> a \<otimes> x \<in> I"
  shows "ideal I R"
proof -
  interpret ring [R] by fact
  show ?thesis  apply (intro ideal.intro ideal_axioms.intro additive_subgroupI)
     apply (rule a_subgroup)
    apply (rule is_ring)
   apply (erule (1) I_l_closed)
  apply (erule (1) I_r_closed)
  done
qed

subsection {* Ideals Generated by a Subset of @{term [locale=ring] "carrier R"} *}

constdefs (structure R)
  genideal :: "('a, 'b) ring_scheme \<Rightarrow> 'a set \<Rightarrow> 'a set"  ("Idl\<index> _" [80] 79)
  "genideal R S \<equiv> Inter {I. ideal I R \<and> S \<subseteq> I}"


subsection {* Principal Ideals *}

locale principalideal = ideal +
  assumes generate: "\<exists>i \<in> carrier R. I = Idl {i}"

lemma (in principalideal) is_principalideal:
  shows "principalideal I R"
by (rule principalideal_axioms)

lemma principalidealI:
  fixes R (structure)
  assumes "ideal I R"
  assumes generate: "\<exists>i \<in> carrier R. I = Idl {i}"
  shows "principalideal I R"
proof -
  interpret ideal [I R] by fact
  show ?thesis  by (intro principalideal.intro principalideal_axioms.intro) (rule is_ideal, rule generate)
qed

subsection {* Maximal Ideals *}

locale maximalideal = ideal +
  assumes I_notcarr: "carrier R \<noteq> I"
      and I_maximal: "\<lbrakk>ideal J R; I \<subseteq> J; J \<subseteq> carrier R\<rbrakk> \<Longrightarrow> J = I \<or> J = carrier R"

lemma (in maximalideal) is_maximalideal:
 shows "maximalideal I R"
by (rule maximalideal_axioms)

lemma maximalidealI:
  fixes R
  assumes "ideal I R"
  assumes I_notcarr: "carrier R \<noteq> I"
     and I_maximal: "\<And>J. \<lbrakk>ideal J R; I \<subseteq> J; J \<subseteq> carrier R\<rbrakk> \<Longrightarrow> J = I \<or> J = carrier R"
  shows "maximalideal I R"
proof -
  interpret ideal [I R] by fact
  show ?thesis by (intro maximalideal.intro maximalideal_axioms.intro)
    (rule is_ideal, rule I_notcarr, rule I_maximal)
qed

subsection {* Prime Ideals *}

locale primeideal = ideal + cring +
  assumes I_notcarr: "carrier R \<noteq> I"
      and I_prime: "\<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"

lemma (in primeideal) is_primeideal:
 shows "primeideal I R"
by (rule primeideal_axioms)

lemma primeidealI:
  fixes R (structure)
  assumes "ideal I R"
  assumes "cring R"
  assumes I_notcarr: "carrier R \<noteq> I"
      and I_prime: "\<And>a b. \<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"
  shows "primeideal I R"
proof -
  interpret ideal [I R] by fact
  interpret cring [R] by fact
  show ?thesis by (intro primeideal.intro primeideal_axioms.intro)
    (rule is_ideal, rule is_cring, rule I_notcarr, rule I_prime)
qed

lemma primeidealI2:
  fixes R (structure)
  assumes "additive_subgroup I R"
  assumes "cring R"
  assumes I_l_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> x \<otimes> a \<in> I"
      and I_r_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> a \<otimes> x \<in> I"
      and I_notcarr: "carrier R \<noteq> I"
      and I_prime: "\<And>a b. \<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"
  shows "primeideal I R"
proof -
  interpret additive_subgroup [I R] by fact
  interpret cring [R] by fact
  show ?thesis apply (intro_locales)
    apply (intro ideal_axioms.intro)
    apply (erule (1) I_l_closed)
    apply (erule (1) I_r_closed)
    apply (intro primeideal_axioms.intro)
    apply (rule I_notcarr)
    apply (erule (2) I_prime)
    done
qed

section {* Properties of Ideals *}

subsection {* Special Ideals *}

lemma (in ring) zeroideal:
  shows "ideal {\<zero>} R"
apply (intro idealI subgroup.intro)
      apply (rule is_ring)
     apply simp+
  apply (fold a_inv_def, simp)
 apply simp+
done

lemma (in ring) oneideal:
  shows "ideal (carrier R) R"
apply (intro idealI  subgroup.intro)
      apply (rule is_ring)
     apply simp+
  apply (fold a_inv_def, simp)
 apply simp+
done

lemma (in "domain") zeroprimeideal:
 shows "primeideal {\<zero>} R"
apply (intro primeidealI)
   apply (rule zeroideal)
  apply (rule domain.axioms, rule domain_axioms)
 defer 1
 apply (simp add: integral)
proof (rule ccontr, simp)
  assume "carrier R = {\<zero>}"
  from this have "\<one> = \<zero>" by (rule one_zeroI)
  from this and one_not_zero
      show "False" by simp
qed


subsection {* General Ideal Properies *}

lemma (in ideal) one_imp_carrier:
  assumes I_one_closed: "\<one> \<in> I"
  shows "I = carrier R"
apply (rule)
apply (rule)
apply (rule a_Hcarr, simp)
proof
  fix x
  assume xcarr: "x \<in> carrier R"
  from I_one_closed and this
      have "x \<otimes> \<one> \<in> I" by (intro I_l_closed)
  from this and xcarr
      show "x \<in> I" by simp
qed

lemma (in ideal) Icarr:
  assumes iI: "i \<in> I"
  shows "i \<in> carrier R"
using iI by (rule a_Hcarr)


subsection {* Intersection of Ideals *}

text {* \paragraph{Intersection of two ideals} The intersection of any
  two ideals is again an ideal in @{term R} *}
lemma (in ring) i_intersect:
  assumes "ideal I R"
  assumes "ideal J R"
  shows "ideal (I \<inter> J) R"
proof -
  interpret ideal [I R] by fact
  interpret ideal [J R] by fact
  show ?thesis
apply (intro idealI subgroup.intro)
      apply (rule is_ring)
     apply (force simp add: a_subset)
    apply (simp add: a_inv_def[symmetric])
   apply simp
  apply (simp add: a_inv_def[symmetric])
 apply (clarsimp, rule)
  apply (fast intro: ideal.I_l_closed ideal.intro assms)+
apply (clarsimp, rule)
 apply (fast intro: ideal.I_r_closed ideal.intro assms)+
done
qed

subsubsection {* Intersection of a Set of Ideals *}

text {* The intersection of any Number of Ideals is again
        an Ideal in @{term R} *}
lemma (in ring) i_Intersect:
  assumes Sideals: "\<And>I. I \<in> S \<Longrightarrow> ideal I R"
    and notempty: "S \<noteq> {}"
  shows "ideal (Inter S) R"
apply (unfold_locales)
apply (simp_all add: Inter_def INTER_def)
      apply (rule, simp) defer 1
      apply rule defer 1
      apply rule defer 1
      apply (fold a_inv_def, rule) defer 1
      apply rule defer 1
      apply rule defer 1
proof -
  fix x
  assume "\<forall>I\<in>S. x \<in> I"
  hence xI: "\<And>I. I \<in> S \<Longrightarrow> x \<in> I" by simp

  from notempty have "\<exists>I0. I0 \<in> S" by blast
  from this obtain I0 where I0S: "I0 \<in> S" by auto

  interpret ideal ["I0" "R"] by (rule Sideals[OF I0S])

  from xI[OF I0S] have "x \<in> I0" .
  from this and a_subset show "x \<in> carrier R" by fast
next
  fix x y
  assume "\<forall>I\<in>S. x \<in> I"
  hence xI: "\<And>I. I \<in> S \<Longrightarrow> x \<in> I" by simp
  assume "\<forall>I\<in>S. y \<in> I"
  hence yI: "\<And>I. I \<in> S \<Longrightarrow> y \<in> I" by simp

  fix J
  assume JS: "J \<in> S"
  interpret ideal ["J" "R"] by (rule Sideals[OF JS])
  from xI[OF JS] and yI[OF JS]
      show "x \<oplus> y \<in> J" by (rule a_closed)
next
  fix J
  assume JS: "J \<in> S"
  interpret ideal ["J" "R"] by (rule Sideals[OF JS])
  show "\<zero> \<in> J" by simp
next
  fix x
  assume "\<forall>I\<in>S. x \<in> I"
  hence xI: "\<And>I. I \<in> S \<Longrightarrow> x \<in> I" by simp

  fix J
  assume JS: "J \<in> S"
  interpret ideal ["J" "R"] by (rule Sideals[OF JS])

  from xI[OF JS]
      show "\<ominus> x \<in> J" by (rule a_inv_closed)
next
  fix x y
  assume "\<forall>I\<in>S. x \<in> I"
  hence xI: "\<And>I. I \<in> S \<Longrightarrow> x \<in> I" by simp
  assume ycarr: "y \<in> carrier R"

  fix J
  assume JS: "J \<in> S"
  interpret ideal ["J" "R"] by (rule Sideals[OF JS])

  from xI[OF JS] and ycarr
      show "y \<otimes> x \<in> J" by (rule I_l_closed)
next
  fix x y
  assume "\<forall>I\<in>S. x \<in> I"
  hence xI: "\<And>I. I \<in> S \<Longrightarrow> x \<in> I" by simp
  assume ycarr: "y \<in> carrier R"

  fix J
  assume JS: "J \<in> S"
  interpret ideal ["J" "R"] by (rule Sideals[OF JS])

  from xI[OF JS] and ycarr
      show "x \<otimes> y \<in> J" by (rule I_r_closed)
qed


subsection {* Addition of Ideals *}

lemma (in ring) add_ideals:
  assumes idealI: "ideal I R"
      and idealJ: "ideal J R"
  shows "ideal (I <+> J) R"
apply (rule ideal.intro)
  apply (rule add_additive_subgroups)
   apply (intro ideal.axioms[OF idealI])
  apply (intro ideal.axioms[OF idealJ])
 apply (rule is_ring)
apply (rule ideal_axioms.intro)
 apply (simp add: set_add_defs, clarsimp) defer 1
 apply (simp add: set_add_defs, clarsimp) defer 1
proof -
  fix x i j
  assume xcarr: "x \<in> carrier R"
     and iI: "i \<in> I"
     and jJ: "j \<in> J"
  from xcarr ideal.Icarr[OF idealI iI] ideal.Icarr[OF idealJ jJ]
      have c: "(i \<oplus> j) \<otimes> x = (i \<otimes> x) \<oplus> (j \<otimes> x)" by algebra
  from xcarr and iI
      have a: "i \<otimes> x \<in> I" by (simp add: ideal.I_r_closed[OF idealI])
  from xcarr and jJ
      have b: "j \<otimes> x \<in> J" by (simp add: ideal.I_r_closed[OF idealJ])
  from a b c
      show "\<exists>ha\<in>I. \<exists>ka\<in>J. (i \<oplus> j) \<otimes> x = ha \<oplus> ka" by fast
next
  fix x i j
  assume xcarr: "x \<in> carrier R"
     and iI: "i \<in> I"
     and jJ: "j \<in> J"
  from xcarr ideal.Icarr[OF idealI iI] ideal.Icarr[OF idealJ jJ]
      have c: "x \<otimes> (i \<oplus> j) = (x \<otimes> i) \<oplus> (x \<otimes> j)" by algebra
  from xcarr and iI
      have a: "x \<otimes> i \<in> I" by (simp add: ideal.I_l_closed[OF idealI])
  from xcarr and jJ
      have b: "x \<otimes> j \<in> J" by (simp add: ideal.I_l_closed[OF idealJ])
  from a b c
      show "\<exists>ha\<in>I. \<exists>ka\<in>J. x \<otimes> (i \<oplus> j) = ha \<oplus> ka" by fast
qed


subsection {* Ideals generated by a subset of @{term [locale=ring]
  "carrier R"} *}

subsubsection {* Generation of Ideals in General Rings *}

text {* @{term genideal} generates an ideal *}
lemma (in ring) genideal_ideal:
  assumes Scarr: "S \<subseteq> carrier R"
  shows "ideal (Idl S) R"
unfolding genideal_def
proof (rule i_Intersect, fast, simp)
  from oneideal and Scarr
  show "\<exists>I. ideal I R \<and> S \<le> I" by fast
qed

lemma (in ring) genideal_self:
  assumes "S \<subseteq> carrier R"
  shows "S \<subseteq> Idl S"
unfolding genideal_def
by fast

lemma (in ring) genideal_self':
  assumes carr: "i \<in> carrier R"
  shows "i \<in> Idl {i}"
proof -
  from carr
      have "{i} \<subseteq> Idl {i}" by (fast intro!: genideal_self)
  thus "i \<in> Idl {i}" by fast
qed

text {* @{term genideal} generates the minimal ideal *}
lemma (in ring) genideal_minimal:
  assumes a: "ideal I R"
      and b: "S \<subseteq> I"
  shows "Idl S \<subseteq> I"
unfolding genideal_def
by (rule, elim InterD, simp add: a b)

text {* Generated ideals and subsets *}
lemma (in ring) Idl_subset_ideal:
  assumes Iideal: "ideal I R"
      and Hcarr: "H \<subseteq> carrier R"
  shows "(Idl H \<subseteq> I) = (H \<subseteq> I)"
proof
  assume a: "Idl H \<subseteq> I"
  from Hcarr have "H \<subseteq> Idl H" by (rule genideal_self)
  from this and a
      show "H \<subseteq> I" by simp
next
  fix x
  assume HI: "H \<subseteq> I"

  from Iideal and HI
      have "I \<in> {I. ideal I R \<and> H \<subseteq> I}" by fast
  from this
      show "Idl H \<subseteq> I"
      unfolding genideal_def
      by fast
qed

lemma (in ring) subset_Idl_subset:
  assumes Icarr: "I \<subseteq> carrier R"
      and HI: "H \<subseteq> I"
  shows "Idl H \<subseteq> Idl I"
proof -
  from HI and genideal_self[OF Icarr] 
      have HIdlI: "H \<subseteq> Idl I" by fast

  from Icarr
      have Iideal: "ideal (Idl I) R" by (rule genideal_ideal)
  from HI and Icarr
      have "H \<subseteq> carrier R" by fast
  from Iideal and this
      have "(H \<subseteq> Idl I) = (Idl H \<subseteq> Idl I)"
      by (rule Idl_subset_ideal[symmetric])

  from HIdlI and this
      show "Idl H \<subseteq> Idl I" by simp
qed

lemma (in ring) Idl_subset_ideal':
  assumes acarr: "a \<in> carrier R" and bcarr: "b \<in> carrier R"
  shows "(Idl {a} \<subseteq> Idl {b}) = (a \<in> Idl {b})"
apply (subst Idl_subset_ideal[OF genideal_ideal[of "{b}"], of "{a}"])
  apply (fast intro: bcarr, fast intro: acarr)
apply fast
done

lemma (in ring) genideal_zero:
  "Idl {\<zero>} = {\<zero>}"
apply rule
 apply (rule genideal_minimal[OF zeroideal], simp)
apply (simp add: genideal_self')
done

lemma (in ring) genideal_one:
  "Idl {\<one>} = carrier R"
proof -
  interpret ideal ["Idl {\<one>}" "R"] by (rule genideal_ideal, fast intro: one_closed)
  show "Idl {\<one>} = carrier R"
  apply (rule, rule a_subset)
  apply (simp add: one_imp_carrier genideal_self')
  done
qed


subsubsection {* Generation of Principal Ideals in Commutative Rings *}

constdefs (structure R)
  cgenideal :: "('a, 'b) monoid_scheme \<Rightarrow> 'a \<Rightarrow> 'a set"  ("PIdl\<index> _" [80] 79)
  "cgenideal R a \<equiv> { x \<otimes> a | x. x \<in> carrier R }"

text {* genhideal (?) really generates an ideal *}
lemma (in cring) cgenideal_ideal:
  assumes acarr: "a \<in> carrier R"
  shows "ideal (PIdl a) R"
apply (unfold cgenideal_def)
apply (rule idealI[OF is_ring])
   apply (rule subgroup.intro)
      apply (simp_all add: monoid_record_simps)
      apply (blast intro: acarr m_closed)
      apply clarsimp defer 1
      defer 1
      apply (fold a_inv_def, clarsimp) defer 1
      apply clarsimp defer 1
      apply clarsimp defer 1
proof -
  fix x y
  assume xcarr: "x \<in> carrier R"
     and ycarr: "y \<in> carrier R"
  note carr = acarr xcarr ycarr

  from carr
      have "x \<otimes> a \<oplus> y \<otimes> a = (x \<oplus> y) \<otimes> a" by (simp add: l_distr)
  from this and carr
      show "\<exists>z. x \<otimes> a \<oplus> y \<otimes> a = z \<otimes> a \<and> z \<in> carrier R" by fast
next
  from l_null[OF acarr, symmetric] and zero_closed
      show "\<exists>x. \<zero> = x \<otimes> a \<and> x \<in> carrier R" by fast
next
  fix x
  assume xcarr: "x \<in> carrier R"
  note carr = acarr xcarr

  from carr
      have "\<ominus> (x \<otimes> a) = (\<ominus> x) \<otimes> a" by (simp add: l_minus)
  from this and carr
      show "\<exists>z. \<ominus> (x \<otimes> a) = z \<otimes> a \<and> z \<in> carrier R" by fast
next
  fix x y
  assume xcarr: "x \<in> carrier R"
     and ycarr: "y \<in> carrier R"
  note carr = acarr xcarr ycarr
  
  from carr
      have "y \<otimes> a \<otimes> x = (y \<otimes> x) \<otimes> a" by (simp add: m_assoc, simp add: m_comm)
  from this and carr
      show "\<exists>z. y \<otimes> a \<otimes> x = z \<otimes> a \<and> z \<in> carrier R" by fast
next
  fix x y
  assume xcarr: "x \<in> carrier R"
     and ycarr: "y \<in> carrier R"
  note carr = acarr xcarr ycarr

  from carr
      have "x \<otimes> (y \<otimes> a) = (x \<otimes> y) \<otimes> a" by (simp add: m_assoc)
  from this and carr
      show "\<exists>z. x \<otimes> (y \<otimes> a) = z \<otimes> a \<and> z \<in> carrier R" by fast
qed

lemma (in ring) cgenideal_self:
  assumes icarr: "i \<in> carrier R"
  shows "i \<in> PIdl i"
unfolding cgenideal_def
proof simp
  from icarr
      have "i = \<one> \<otimes> i" by simp
  from this and icarr
      show "\<exists>x. i = x \<otimes> i \<and> x \<in> carrier R" by fast
qed

text {* @{const "cgenideal"} is minimal *}

lemma (in ring) cgenideal_minimal:
  assumes "ideal J R"
  assumes aJ: "a \<in> J"
  shows "PIdl a \<subseteq> J"
proof -
  interpret ideal [J R] by fact
  show ?thesis unfolding cgenideal_def
    apply rule
    apply clarify
    using aJ
    apply (erule I_l_closed)
    done
qed

lemma (in cring) cgenideal_eq_genideal:
  assumes icarr: "i \<in> carrier R"
  shows "PIdl i = Idl {i}"
apply rule
 apply (intro cgenideal_minimal)
  apply (rule genideal_ideal, fast intro: icarr)
 apply (rule genideal_self', fast intro: icarr)
apply (intro genideal_minimal)
 apply (rule cgenideal_ideal [OF icarr])
apply (simp, rule cgenideal_self [OF icarr])
done

lemma (in cring) cgenideal_eq_rcos:
 "PIdl i = carrier R #> i"
unfolding cgenideal_def r_coset_def
by fast

lemma (in cring) cgenideal_is_principalideal:
  assumes icarr: "i \<in> carrier R"
  shows "principalideal (PIdl i) R"
apply (rule principalidealI)
apply (rule cgenideal_ideal [OF icarr])
proof -
  from icarr
      have "PIdl i = Idl {i}" by (rule cgenideal_eq_genideal)
  from icarr and this
      show "\<exists>i'\<in>carrier R. PIdl i = Idl {i'}" by fast
qed


subsection {* Union of Ideals *}

lemma (in ring) union_genideal:
  assumes idealI: "ideal I R"
      and idealJ: "ideal J R"
  shows "Idl (I \<union> J) = I <+> J"
apply rule
 apply (rule ring.genideal_minimal)
   apply (rule R.is_ring)
  apply (rule add_ideals[OF idealI idealJ])
 apply (rule)
 apply (simp add: set_add_defs) apply (elim disjE) defer 1 defer 1
 apply (rule) apply (simp add: set_add_defs genideal_def) apply clarsimp defer 1
proof -
  fix x
  assume xI: "x \<in> I"
  have ZJ: "\<zero> \<in> J"
      by (intro additive_subgroup.zero_closed, rule ideal.axioms[OF idealJ])
  from ideal.Icarr[OF idealI xI]
      have "x = x \<oplus> \<zero>" by algebra
  from xI and ZJ and this
      show "\<exists>h\<in>I. \<exists>k\<in>J. x = h \<oplus> k" by fast
next
  fix x
  assume xJ: "x \<in> J"
  have ZI: "\<zero> \<in> I"
      by (intro additive_subgroup.zero_closed, rule ideal.axioms[OF idealI])
  from ideal.Icarr[OF idealJ xJ]
      have "x = \<zero> \<oplus> x" by algebra
  from ZI and xJ and this
      show "\<exists>h\<in>I. \<exists>k\<in>J. x = h \<oplus> k" by fast
next
  fix i j K
  assume iI: "i \<in> I"
     and jJ: "j \<in> J"
     and idealK: "ideal K R"
     and IK: "I \<subseteq> K"
     and JK: "J \<subseteq> K"
  from iI and IK
     have iK: "i \<in> K" by fast
  from jJ and JK
     have jK: "j \<in> K" by fast
  from iK and jK
     show "i \<oplus> j \<in> K" by (intro additive_subgroup.a_closed) (rule ideal.axioms[OF idealK])
qed


subsection {* Properties of Principal Ideals *}

text {* @{text "\<zero>"} generates the zero ideal *}
lemma (in ring) zero_genideal:
  shows "Idl {\<zero>} = {\<zero>}"
apply rule
apply (simp add: genideal_minimal zeroideal)
apply (fast intro!: genideal_self)
done

text {* @{text "\<one>"} generates the unit ideal *}
lemma (in ring) one_genideal:
  shows "Idl {\<one>} = carrier R"
proof -
  have "\<one> \<in> Idl {\<one>}" by (simp add: genideal_self')
  thus "Idl {\<one>} = carrier R" by (intro ideal.one_imp_carrier, fast intro: genideal_ideal)
qed


text {* The zero ideal is a principal ideal *}
corollary (in ring) zeropideal:
  shows "principalideal {\<zero>} R"
apply (rule principalidealI)
 apply (rule zeroideal)
apply (blast intro!: zero_closed zero_genideal[symmetric])
done

text {* The unit ideal is a principal ideal *}
corollary (in ring) onepideal:
  shows "principalideal (carrier R) R"
apply (rule principalidealI)
 apply (rule oneideal)
apply (blast intro!: one_closed one_genideal[symmetric])
done


text {* Every principal ideal is a right coset of the carrier *}
lemma (in principalideal) rcos_generate:
  assumes "cring R"
  shows "\<exists>x\<in>I. I = carrier R #> x"
proof -
  interpret cring [R] by fact
  from generate
      obtain i
        where icarr: "i \<in> carrier R"
        and I1: "I = Idl {i}"
      by fast+

  from icarr and genideal_self[of "{i}"]
      have "i \<in> Idl {i}" by fast
  hence iI: "i \<in> I" by (simp add: I1)

  from I1 icarr
      have I2: "I = PIdl i" by (simp add: cgenideal_eq_genideal)

  have "PIdl i = carrier R #> i"
      unfolding cgenideal_def r_coset_def
      by fast

  from I2 and this
      have "I = carrier R #> i" by simp

  from iI and this
      show "\<exists>x\<in>I. I = carrier R #> x" by fast
qed


subsection {* Prime Ideals *}

lemma (in ideal) primeidealCD:
  assumes "cring R"
  assumes notprime: "\<not> primeideal I R"
  shows "carrier R = I \<or> (\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I)"
proof (rule ccontr, clarsimp)
  interpret cring [R] by fact
  assume InR: "carrier R \<noteq> I"
     and "\<forall>a. a \<in> carrier R \<longrightarrow> (\<forall>b. a \<otimes> b \<in> I \<longrightarrow> b \<in> carrier R \<longrightarrow> a \<in> I \<or> b \<in> I)"
  hence I_prime: "\<And> a b. \<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I" by simp
  have "primeideal I R"
      apply (rule primeideal.intro [OF is_ideal is_cring])
      apply (rule primeideal_axioms.intro)
       apply (rule InR)
      apply (erule (2) I_prime)
      done
  from this and notprime
      show "False" by simp
qed

lemma (in ideal) primeidealCE:
  assumes "cring R"
  assumes notprime: "\<not> primeideal I R"
  obtains "carrier R = I"
    | "\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I"
proof -
  interpret R: cring [R] by fact
  assume "carrier R = I ==> thesis"
    and "\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I \<Longrightarrow> thesis"
  then show thesis using primeidealCD [OF R.is_cring notprime] by blast
qed

text {* If @{text "{\<zero>}"} is a prime ideal of a commutative ring, the ring is a domain *}
lemma (in cring) zeroprimeideal_domainI:
  assumes pi: "primeideal {\<zero>} R"
  shows "domain R"
apply (rule domain.intro, rule is_cring)
apply (rule domain_axioms.intro)
proof (rule ccontr, simp)
  interpret primeideal ["{\<zero>}" "R"] by (rule pi)
  assume "\<one> = \<zero>"
  hence "carrier R = {\<zero>}" by (rule one_zeroD)
  from this[symmetric] and I_notcarr
      show "False" by simp
next
  interpret primeideal ["{\<zero>}" "R"] by (rule pi)
  fix a b
  assume ab: "a \<otimes> b = \<zero>"
     and carr: "a \<in> carrier R" "b \<in> carrier R"
  from ab
      have abI: "a \<otimes> b \<in> {\<zero>}" by fast
  from carr and this
      have "a \<in> {\<zero>} \<or> b \<in> {\<zero>}" by (rule I_prime)
  thus "a = \<zero> \<or> b = \<zero>" by simp
qed

corollary (in cring) domain_eq_zeroprimeideal:
  shows "domain R = primeideal {\<zero>} R"
apply rule
 apply (erule domain.zeroprimeideal)
apply (erule zeroprimeideal_domainI)
done


subsection {* Maximal Ideals *}

lemma (in ideal) helper_I_closed:
  assumes carr: "a \<in> carrier R" "x \<in> carrier R" "y \<in> carrier R"
      and axI: "a \<otimes> x \<in> I"
  shows "a \<otimes> (x \<otimes> y) \<in> I"
proof -
  from axI and carr
     have "(a \<otimes> x) \<otimes> y \<in> I" by (simp add: I_r_closed)
  also from carr
     have "(a \<otimes> x) \<otimes> y = a \<otimes> (x \<otimes> y)" by (simp add: m_assoc)
  finally
     show "a \<otimes> (x \<otimes> y) \<in> I" .
qed

lemma (in ideal) helper_max_prime:
  assumes "cring R"
  assumes acarr: "a \<in> carrier R"
  shows "ideal {x\<in>carrier R. a \<otimes> x \<in> I} R"
proof -
  interpret cring [R] by fact
  show ?thesis apply (rule idealI)
    apply (rule cring.axioms[OF is_cring])
    apply (rule subgroup.intro)
    apply (simp, fast)
    apply clarsimp apply (simp add: r_distr acarr)
    apply (simp add: acarr)
    apply (simp add: a_inv_def[symmetric], clarify) defer 1
    apply clarsimp defer 1
    apply (fast intro!: helper_I_closed acarr)
  proof -
    fix x
    assume xcarr: "x \<in> carrier R"
      and ax: "a \<otimes> x \<in> I"
    from ax and acarr xcarr
    have "\<ominus>(a \<otimes> x) \<in> I" by simp
    also from acarr xcarr
    have "\<ominus>(a \<otimes> x) = a \<otimes> (\<ominus>x)" by algebra
    finally
    show "a \<otimes> (\<ominus>x) \<in> I" .
    from acarr
    have "a \<otimes> \<zero> = \<zero>" by simp
  next
    fix x y
    assume xcarr: "x \<in> carrier R"
      and ycarr: "y \<in> carrier R"
      and ayI: "a \<otimes> y \<in> I"
    from ayI and acarr xcarr ycarr
    have "a \<otimes> (y \<otimes> x) \<in> I" by (simp add: helper_I_closed)
    moreover from xcarr ycarr
    have "y \<otimes> x = x \<otimes> y" by (simp add: m_comm)
    ultimately
    show "a \<otimes> (x \<otimes> y) \<in> I" by simp
  qed
qed

text {* In a cring every maximal ideal is prime *}
lemma (in cring) maximalideal_is_prime:
  assumes "maximalideal I R"
  shows "primeideal I R"
proof -
  interpret maximalideal [I R] by fact
  show ?thesis apply (rule ccontr)
    apply (rule primeidealCE)
    apply (rule is_cring)
    apply assumption
    apply (simp add: I_notcarr)
  proof -
    assume "\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I"
    from this
    obtain a b
      where acarr: "a \<in> carrier R"
      and bcarr: "b \<in> carrier R"
      and abI: "a \<otimes> b \<in> I"
      and anI: "a \<notin> I"
      and bnI: "b \<notin> I"
      by fast
    def J \<equiv> "{x\<in>carrier R. a \<otimes> x \<in> I}"
    
    from R.is_cring and acarr
    have idealJ: "ideal J R" unfolding J_def by (rule helper_max_prime)
    
    have IsubJ: "I \<subseteq> J"
    proof
      fix x
      assume xI: "x \<in> I"
      from this and acarr
      have "a \<otimes> x \<in> I" by (intro I_l_closed)
      from xI[THEN a_Hcarr] this
      show "x \<in> J" unfolding J_def by fast
    qed
    
    from abI and acarr bcarr
    have "b \<in> J" unfolding J_def by fast
    from bnI and this
    have JnI: "J \<noteq> I" by fast
    from acarr
    have "a = a \<otimes> \<one>" by algebra
    from this and anI
    have "a \<otimes> \<one> \<notin> I" by simp
    from one_closed and this
    have "\<one> \<notin> J" unfolding J_def by fast
    hence Jncarr: "J \<noteq> carrier R" by fast
    
    interpret ideal ["J" "R"] by (rule idealJ)
    
    have "J = I \<or> J = carrier R"
      apply (intro I_maximal)
      apply (rule idealJ)
      apply (rule IsubJ)
      apply (rule a_subset)
      done
    
    from this and JnI and Jncarr
    show "False" by simp
  qed
qed

subsection {* Derived Theorems Involving Ideals *}

--"A non-zero cring that has only the two trivial ideals is a field"
lemma (in cring) trivialideals_fieldI:
  assumes carrnzero: "carrier R \<noteq> {\<zero>}"
      and haveideals: "{I. ideal I R} = {{\<zero>}, carrier R}"
  shows "field R"
apply (rule cring_fieldI)
apply (rule, rule, rule)
 apply (erule Units_closed)
defer 1
  apply rule
defer 1
proof (rule ccontr, simp)
  assume zUnit: "\<zero> \<in> Units R"
  hence a: "\<zero> \<otimes> inv \<zero> = \<one>" by (rule Units_r_inv)
  from zUnit
      have "\<zero> \<otimes> inv \<zero> = \<zero>" by (intro l_null, rule Units_inv_closed)
  from a[symmetric] and this
      have "\<one> = \<zero>" by simp
  hence "carrier R = {\<zero>}" by (rule one_zeroD)
  from this and carrnzero
      show "False" by simp
next
  fix x
  assume xcarr': "x \<in> carrier R - {\<zero>}"
  hence xcarr: "x \<in> carrier R" by fast
  from xcarr'
      have xnZ: "x \<noteq> \<zero>" by fast
  from xcarr
      have xIdl: "ideal (PIdl x) R" by (intro cgenideal_ideal, fast)

  from xcarr
      have "x \<in> PIdl x" by (intro cgenideal_self, fast)
  from this and xnZ
      have "PIdl x \<noteq> {\<zero>}" by fast
  from haveideals and this
      have "PIdl x = carrier R"
      by (blast intro!: xIdl)
  hence "\<one> \<in> PIdl x" by simp
  hence "\<exists>y. \<one> = y \<otimes> x \<and> y \<in> carrier R" unfolding cgenideal_def by blast
  from this
      obtain y
        where ycarr: " y \<in> carrier R"
        and ylinv: "\<one> = y \<otimes> x"
      by fast+
  from ylinv and xcarr ycarr
      have yrinv: "\<one> = x \<otimes> y" by (simp add: m_comm)
  from ycarr and ylinv[symmetric] and yrinv[symmetric]
      have "\<exists>y \<in> carrier R. y \<otimes> x = \<one> \<and> x \<otimes> y = \<one>" by fast
  from this and xcarr
      show "x \<in> Units R"
      unfolding Units_def
      by fast
qed

lemma (in field) all_ideals:
  shows "{I. ideal I R} = {{\<zero>}, carrier R}"
apply (rule, rule)
proof -
  fix I
  assume a: "I \<in> {I. ideal I R}"
  with this
      interpret ideal ["I" "R"] by simp

  show "I \<in> {{\<zero>}, carrier R}"
  proof (cases "\<exists>a. a \<in> I - {\<zero>}")
    assume "\<exists>a. a \<in> I - {\<zero>}"
    from this
        obtain a
          where aI: "a \<in> I"
          and anZ: "a \<noteq> \<zero>"
        by fast+
    from aI[THEN a_Hcarr] anZ
        have aUnit: "a \<in> Units R" by (simp add: field_Units)
    hence a: "a \<otimes> inv a = \<one>" by (rule Units_r_inv)
    from aI and aUnit
        have "a \<otimes> inv a \<in> I" by (simp add: I_r_closed del: Units_r_inv)
    hence oneI: "\<one> \<in> I" by (simp add: a[symmetric])

    have "carrier R \<subseteq> I"
    proof
      fix x
      assume xcarr: "x \<in> carrier R"
      from oneI and this
          have "\<one> \<otimes> x \<in> I" by (rule I_r_closed)
      from this and xcarr
          show "x \<in> I" by simp
    qed
    from this and a_subset
        have "I = carrier R" by fast
    thus "I \<in> {{\<zero>}, carrier R}" by fast
  next
    assume "\<not> (\<exists>a. a \<in> I - {\<zero>})"
    hence IZ: "\<And>a. a \<in> I \<Longrightarrow> a = \<zero>" by simp

    have a: "I \<subseteq> {\<zero>}"
    proof
      fix x
      assume "x \<in> I"
      hence "x = \<zero>" by (rule IZ)
      thus "x \<in> {\<zero>}" by fast
    qed

    have "\<zero> \<in> I" by simp
    hence "{\<zero>} \<subseteq> I" by fast

    from this and a
        have "I = {\<zero>}" by fast
    thus "I \<in> {{\<zero>}, carrier R}" by fast
  qed
qed (simp add: zeroideal oneideal)

--"Jacobson Theorem 2.2"
lemma (in cring) trivialideals_eq_field:
  assumes carrnzero: "carrier R \<noteq> {\<zero>}"
  shows "({I. ideal I R} = {{\<zero>}, carrier R}) = field R"
by (fast intro!: trivialideals_fieldI[OF carrnzero] field.all_ideals)


text {* Like zeroprimeideal for domains *}
lemma (in field) zeromaximalideal:
  "maximalideal {\<zero>} R"
apply (rule maximalidealI)
  apply (rule zeroideal)
proof-
  from one_not_zero
      have "\<one> \<notin> {\<zero>}" by simp
  from this and one_closed
      show "carrier R \<noteq> {\<zero>}" by fast
next
  fix J
  assume Jideal: "ideal J R"
  hence "J \<in> {I. ideal I R}"
      by fast

  from this and all_ideals
      show "J = {\<zero>} \<or> J = carrier R" by simp
qed

lemma (in cring) zeromaximalideal_fieldI:
  assumes zeromax: "maximalideal {\<zero>} R"
  shows "field R"
apply (rule trivialideals_fieldI, rule maximalideal.I_notcarr[OF zeromax])
apply rule apply clarsimp defer 1
 apply (simp add: zeroideal oneideal)
proof -
  fix J
  assume Jn0: "J \<noteq> {\<zero>}"
     and idealJ: "ideal J R"
  interpret ideal ["J" "R"] by (rule idealJ)
  have "{\<zero>} \<subseteq> J" by (rule ccontr, simp)
  from zeromax and idealJ and this and a_subset
      have "J = {\<zero>} \<or> J = carrier R" by (rule maximalideal.I_maximal)
  from this and Jn0
      show "J = carrier R" by simp
qed

lemma (in cring) zeromaximalideal_eq_field:
  "maximalideal {\<zero>} R = field R"
apply rule
 apply (erule zeromaximalideal_fieldI)
apply (erule field.zeromaximalideal)
done

end
