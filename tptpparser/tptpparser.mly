
%{
open Problem
open Str

let getNumArgs arg_str =
  let rec count lst paren = match lst with
    | [] -> 0
    | hd :: tl -> begin match hd with
      | Text(_) ->
        if paren = 0 then 1 + count tl 0
        else count tl paren
      | Delim(p) when p = "(" -> count tl (paren + 1)
      | Delim(p) when p = ")" -> 
        if paren = 1 then (1 + count tl 0)
        else (count tl (paren - 1))
      | Delim(s) when s = " " -> count tl paren
      | Delim(d) -> print_endline ("Wrong delimiter: " ^ d); exit 4
    end
  in
  let str_lst = Str.full_split (regexp "[() ]") arg_str in
  count str_lst 0

let add_var v lst = match List.mem v !lst with
  | true -> ()
  | false -> lst := v :: !lst

let theoryToString thr = match thr with
  | FOF -> "fof"
  | CNF -> "cnf"
  | THF -> "thf"
  | TFF -> "tff"
  | TPI -> "tpi"
  | _ -> failwith "Unknown theory."

let problem = Sequent.create [] [] ;;
let info = [] ;;

let quantified_vars = ref [] ;;
let used_vars = ref [] ;;

%}

%token THF TFF FOF CNF TPI EoF
%token AXIOM HYPOTHESIS CONJECTURE NEG_CONJECTURE PLAIN
%token <string> ATOM COMMENT
%token FILE INFERENCE STATUS
       OR NOT AND IMP BIMP FORALL EXISTS EQ NEQ FALSE TRUE
       LPAREN RPAREN COMMA DOT COLON LBRACKET RBRACKET
       FILEPATH
       THM CTH
%token <string> WORD VAR
%token <int> INTEGER

%start file /* the entry point */
%type <Problem.Sequent.t * (string list) > file

%%

file:
| COMMENT file { let (p, i) = $2 in (p, $1 :: i) } 
| problem file { let (p, i) = $2 in 
                 let (role, form) = $1 in 
                 match role with
                   | HYP -> (Sequent.add_hypothesis p form, i)
                   | GOAL -> (Sequent.add_goal p form, i)
               }
| EoF          { (problem, info) }

problem:
| theory LPAREN name COMMA role COMMA formula RPAREN DOT {
  match $1 with
    | FOF | CNF -> ($5, $7)
    | _ -> print_endline ("Unsupported theory: " ^ (theoryToString $1)); exit 4
}
| theory LPAREN name COMMA role COMMA formula COMMA WORD RPAREN DOT {
  print_endline ("Formula with annotation."); exit 4
}

theory:
| FOF { FOF }
| CNF { CNF }
| THF { THF }
| TFF { TFF }
| TPI { TPI }

name:
| WORD    { $1 }
| INTEGER { string_of_int $1 }

/* There are further roles defined on the TPTP syntax. Add as needed. */
role:
| AXIOM          { HYP }
| HYPOTHESIS     { HYP }
| CONJECTURE     { GOAL }
| NEG_CONJECTURE { HYP }

formula:
| LPAREN formula RPAREN { $2 }
| atom                  { $1 }
| formula AND formula   { AND( $1, $3 ) }
| formula OR formula    { OR( $1, $3 ) }
| formula IMP formula   { IMP( $1, $3 ) }
| formula BIMP formula  { AND( IMP( $1, $3 ), IMP( $3, $1 ) ) }
| NOT formula           { NEG( $2 ) }
/* Propositional only
| FORALL LBRACKET qvar RBRACKET COLON formula   { FORALL( $3, $6 ) }
| EXISTS LBRACKET qvar RBRACKET COLON formula   { EXISTS( $3, $6 ) } */
| FALSE                 { FALSE }
| TRUE                  { TRUE }

atom:
| LPAREN atom RPAREN { $2 }
| WORD LPAREN args RPAREN { ATOM( $1, $3 ) }
| WORD                    { ATOM( $1, [] ) }

args:
| term            { [$1] }
| term COMMA args { $1 :: $3 }

term:
| VAR         { add_var $1 used_vars; VAR( $1 ) }
| WORD        { FUN( $1, [] ) }
| WORD LPAREN args RPAREN { FUN( $1, $3 ) }

qvar:
| VAR  { add_var $1 quantified_vars; $1 }


