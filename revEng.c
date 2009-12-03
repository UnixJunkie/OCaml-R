/* For the purpose of reverse-engineering, here's the stub for eval.
   I'll drop it afterwards, since R_tryEval seems the only solution
   to forward R errors to OCaml. */

CAMLprim value r_reveng_eval_sxp (value call) {
  CAMLparam1(call);
  CAMLreturn(Val_sexp(Rf_eval(Sexp_val(call), R_GlobalEnv)));
}

SEXP Rf_promiseArgs (SEXP el, SEXP rho);
CAMLprim value r_reveng_promise_args (value args) {
  CAMLparam1(args);
  CAMLreturn(Val_sexp(Rf_promiseArgs(Sexp_val(args), R_GlobalEnv)));
}

/* Copy-pasted from Defn.h. */
/* The Various Context Types.

 * In general the type is a bitwise OR of the values below.
 * Note that CTXT_LOOP is already the or of CTXT_NEXT and CTXT_BREAK.
 * Only functions should have the third bit turned on;
 * this allows us to move up the context stack easily
 * with either RETURN's or GENERIC's or RESTART's.
 * If you add a new context type for functions make sure
 *   CTXT_NEWTYPE & CTXT_FUNCTION > 0
 */
enum {
    CTXT_TOPLEVEL = 0,
    CTXT_NEXT     = 1,
    CTXT_BREAK    = 2,
    CTXT_LOOP     = 3,  /* break OR next target */
    CTXT_FUNCTION = 4,
    CTXT_CCODE    = 8,
    CTXT_RETURN   = 12,
    CTXT_BROWSER  = 16,
    CTXT_GENERIC  = 20,
    CTXT_RESTART  = 32,
    CTXT_BUILTIN  = 64  /* used in profiling */
};

void Rf_begincontext (RCNTXT * cptr, int flags, SEXP syscall, SEXP env, SEXP sysp, SEXP promargs, SEXP callfun);
CAMLprim value r_reveng_begin_context_native (value flags, value syscall, value env, value sysp, value promargs, value callfun) {
  CAMLparam5(flags, syscall, env, sysp, promargs);
  CAMLxparam1(callfun);
  CAMLlocal1(result);
  result = caml_alloc(1, Abstract_tag);
  Rf_begincontext ( (context) Field(result, 0), Int_val(flags), Sexp_val(syscall), Sexp_val(env),
                    Sexp_val(sysp), Sexp_val(promargs), Sexp_val(callfun));
  CAMLreturn(result);
}
CAMLprim value r_reveng_begin_context_bytecode (value * argv, int argn) {
  return r_reveng_begin_context_native(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

void Rf_endcontext (RCNTXT * cptr);
CAMLprim value r_reveng_end_context (value ctxt) {
  CAMLparam1(ctxt);
  Rf_endcontext((context) Field(ctxt, 0));
  CAMLreturn(Val_unit);
} 

SEXP Rf_matchArgs (SEXP formals, SEXP supplied, SEXP call);
CAMLprim value r_reveng_match_args (value formals, value supplied, value call) {
  CAMLparam3(formals, supplied, call);
  CAMLreturn(Val_sexp(Rf_matchArgs(Sexp_val(formals), Sexp_val(supplied), Sexp_val(call))));
}

SEXP Rf_NewEnvironment (SEXP namelist, SEXP valuelist, SEXP rho);
CAMLprim value r_reveng_new_environment (value namelist, value valuelist, value rho) {
  CAMLparam3(namelist, valuelist, rho);
  CAMLreturn(Val_sexp(Rf_NewEnvironment(Sexp_val(namelist), Sexp_val(valuelist), Sexp_val(rho))));
}

SEXP Rf_mkPROMISE (SEXP expr, SEXP rho);
CAMLprim value r_reveng_mkPROMISE (value expr, value rho) {
  CAMLparam2(expr, rho);
  CAMLreturn(Val_sexp(Rf_mkPROMISE(Sexp_val(expr), Sexp_val(rho))));
}

void (SET_MISSING) (SEXP x, int v);
CAMLprim value r_reveng_SET_MISSING (value x, value v) {
  CAMLparam2(x, v);
  (SET_MISSING) (Sexp_val(x), Int_val(v));
  CAMLreturn(Val_unit);
}

void Rf_defineVar (SEXP symbol, SEXP v, SEXP rho);
CAMLprim value r_reveng_define_var (value symbol, value v, value rho) {
  CAMLparam3(symbol, v, rho);
  Rf_defineVar(Sexp_val(symbol), Sexp_val(v), Sexp_val(rho));
  CAMLreturn(Val_unit);
}