(*  Title:      HOL/MicroJava/J/Term.thy
    ID:         $Id$
    Author:     David von Oheimb
    Copyright   1999 Technische Universitaet Muenchen

Java expressions and statements
*)

Term = Value + 

datatype binop = Eq | Add	   (* function codes for binary operation *)

datatype expr
	= NewC	cname              (* class instance creation *)
	| Cast	cname expr         (* type cast *)
	| Lit	val                  (* literal value, also references *)
  | BinOp binop  expr expr   (* binary operation *)
	| LAcc vname               (* local (incl. parameter) access *)
	| LAss vname expr          (* local assign *) ("_::=_"   [      90,90]90)
	| FAcc cname expr vname    (* field access *) ("{_}_.._" [10,90,99   ]90)
	| FAss cname expr vname 
                    expr     (* field ass. *) ("{_}_.._:=_" [10,90,99,90]90)
	| Call expr mname 
    (ty list) (expr list)    (* method call*) ("_.._'({_}_')" [90,99,10,10] 90)

and stmt
	= Skip                     (* empty statement *)
  | Expr expr                (* expression statement *)
  | Comp stmt stmt       ("_;; _"             [61,60]60)
  | Cond expr stmt stmt  ("If '(_') _ Else _" [80,79,79]70)
  | Loop expr stmt       ("While '(_') _"     [80,79]70)

end
