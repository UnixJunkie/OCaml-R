(* This module is an ugly work in progress. It is supposed to be ugly...
   The purpose of this module is to investigate how to make proper function
   calls via the eval function of eval.c. *)

external unsafe_eval : lang sxp -> sexp = "r_reveng_eval_sxp"
external promise_args : pairlist sxp -> sexp = "r_reveng_promise_args"
type context
external global_context : unit -> context = "r_global_context"
external inspect_context_callflag : context -> int = "inspect_context_callflag"
external inspect_context_callfun : context -> sexp = "inspect_context_callfun"
external inspect_context_sysparent : context -> sexp = "inspect_context_sysparent"
external begin_context : int -> sexp -> sexp -> sexp -> sexp -> sexp -> context =
  "r_reveng_begin_context_bytecode" "r_reveng_begin_context_native"
external end_context : context -> unit = "r_reveng_end_context"
external match_args : pairlist sxp -> pairlist sxp -> lang sxp -> sexp = "r_reveng_match_args"
external new_environment : sexp -> sexp -> sexp -> sexp = "r_reveng_new_environment"
external mkPROMISE : sexp -> sexp -> sexp = "r_reveng_mkPROMISE"
external set_missing : sexp -> int -> unit = "r_reveng_SET_MISSING"
external define_var : sexp -> sexp -> sexp -> unit = "r_reveng_define_var"
external apply_closure : lang sxp -> clos sxp -> pairlist sxp -> sexp = "r_apply_closure"
external pointer_protection_stack_top : unit -> int = "r_reveng_PPStackTop"
type ccode
external primfun : sexp -> ccode = "r_reveng_PRIMFUN"
external execute_primfun : ccode -> sexp -> sexp -> sexp -> sexp -> sexp = "r_reveng_execute_primfun" 
(*external primprint : sexp -> int = "r_reveng_PRIMPRINT"*)
type protection_pointer
external vmaxget : unit -> protection_pointer = "r_reveng_vmaxget"
external vmaxset : protection_pointer -> unit = "r_reveng_vmaxset" 

exception Feedback of string * sexp

type trace_element = Val of sexp
let trace_stack : trace_element list ref = ref []
let clear_trace () = trace_stack := []
let track x = trace_stack := x::!trace_stack
let trace () = List.map begin function
  | Val x -> Pretty.t_of_sexp x
  end !trace_stack

let rec ml_apply_closure call closure arglist rho supplied_env =
  track (Val closure);
  let formals   = inspect_closxp_formals closure in
  let body      = inspect_closxp_body    closure in
  let saved_rho = inspect_closxp_env     closure in
  let cntxt     = begin_context (* CTXT_RETURN = *) 12 call saved_rho rho arglist closure in
  let actuals   = match_args formals arglist call in
  let new_rho   = new_environment formals actuals saved_rho in
  let actuals_cursor = ref actuals in
  List.iter begin function (_, value) ->
    if (sexp_equality (inspect_listsxp_carval !actuals_cursor) (missing_arg_creator ()))
    && (not (sexp_equality value (missing_arg_creator ())))
    then begin
      write_listsxp_carval !actuals_cursor (mkPROMISE value new_rho);
      set_missing !actuals_cursor 2
    end;
    actuals_cursor := inspect_listsxp_cdrval !actuals_cursor
  end (list_of_lisplist formals);
  begin match sexp_equality supplied_env (null_creator ()) with
  | true -> () | false -> List.iter begin function (tag, v) ->
      try ignore (List.find begin function (t, _) -> sexp_equality tag t end
        (list_of_lisplist actuals))
      with Not_found -> define_var tag v new_rho
      end (list_of_lisplist (inspect_envsxp_frame supplied_env)) end;
  end_context cntxt;
  let sysparent = begin match inspect_context_callflag (global_context ()) with
                  | (* CTXT_GENERIC = *) 20 -> inspect_context_sysparent (global_context ())
                  | _ -> rho end in
  let cntxt = begin_context (* CTXT_RETURN = *) 12 call new_rho sysparent arglist closure in
  (* We will have to reimplement the SETJMP in the source code. *)
  let tmp = ml_unsafe_eval body new_rho in
  end_context cntxt;
  tmp

and ml_unsafe_eval call rho =
  track (Val call);
  print_endline "Entering ml_unsafe_eval.";
  (*let srcrefsave = R.srcref_creator () *)
  (* int depthsave = R_EvalDepth++; *)
  (* ... autres ... *) 
  match sexptype call with
  | CloSxp -> call
  | LangSxp ->
      let op = begin match sexptype (inspect_listsxp_carval call) with
               | SymSxp -> findfun (inspect_listsxp_carval call)
               | _      -> ml_unsafe_eval (inspect_listsxp_carval call) rho
               end in
      begin match sexptype op with
      | SpecialSxp -> let save = pointer_protection_stack_top () in
                      (* let flag = primprint op*) (* We do not care about R
                         autoprinting stuff at the moment. *)
                      let vmax = vmaxget () in
                      (* We forget PROTECT for now... *)
                      (* We do not care about Visibility... *)
                      let tmp = execute_primfun (primfun op) call op (inspect_listsxp_cdrval op) rho in
                      vmaxset vmax;
                      tmp
   (* | BuiltinSxp -> *)
      | CloSxp     -> let pr_args = promise_args (inspect_listsxp_cdrval call) in
                      ml_apply_closure call op pr_args rho (base_env_creator ())
      | _ -> raise (Feedback ("Attempt to apply non-function.", op)) 
      end
  | _ -> failwith "Wrong sexptype for call."

