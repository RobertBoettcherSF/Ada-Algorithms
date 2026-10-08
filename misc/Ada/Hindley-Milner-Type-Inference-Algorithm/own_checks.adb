--  Own checks (see tests/SOURCES.txt). Assume type inference is wrong or
--  does nothing. Expected principal types of small closed lambda terms were
--  derived by hand (not taken from the program's output) and are compared
--  up to renaming of type variables: inferred types are canonicalised by
--  naming variables t0, t1, ... in order of first occurrence and printing
--  every arrow fully parenthesised. Ill-typed terms (self-application,
--  occurs-check failures, unbound variables) must be rejected. Unify's
--  answer is applied to both types and the results compared syntactically.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Exceptions;
with Hindley_Milner; use Hindley_Milner;

procedure Own_Checks is
   type Pair_Row is record
      Term, Want : Unbounded_String;
   end record;
   type Pair_List is array (Positive range <>) of Pair_Row;
   type Term_List is array (Positive range <>) of Unbounded_String;
   Failures, Passed : Natural := 0;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   --  tiny parser: \x.e   let x = e in e   application by juxtaposition
   Src : Unbounded_String;
   Pos : Positive := 1;

   function Peek return Character is
     (if Pos <= Length (Src) then Element (Src, Pos) else ASCII.NUL);

   procedure Skip is
   begin
      while Peek = ' ' loop
         Pos := Pos + 1;
      end loop;
   end Skip;

   function Ident return String is
      Start : constant Positive := Pos;
   begin
      Skip;
      declare
         S : constant Positive := Pos;
      begin
         while Peek in 'a' .. 'z' | '0' .. '9' | '_' loop
            Pos := Pos + 1;
         end loop;
         if Pos = S then
            raise Program_Error with "parse error at" & Start'Image;
         end if;
         return Slice (Src, S, Pos - 1);
      end;
   end Ident;

   procedure Expect (C : Character) is
   begin
      Skip;
      if Peek /= C then
         raise Program_Error with "parse: expected " & C;
      end if;
      Pos := Pos + 1;
   end Expect;

   function Parse_Expr return Expr_Access;

   function Parse_Atom return Expr_Access is
   begin
      Skip;
      if Peek = '(' then
         Pos := Pos + 1;
         declare
            E : constant Expr_Access := Parse_Expr;
         begin
            Expect (')');
            return E;
         end;
      else
         return Make_Expr_Var (Ident);
      end if;
   end Parse_Atom;

   function Parse_Expr return Expr_Access is
   begin
      Skip;
      if Peek = '\' then
         Pos := Pos + 1;
         declare
            X : constant String := Ident;
         begin
            Expect ('.');
            return Make_Expr_Abs (X, Parse_Expr);
         end;
      elsif Pos + 3 <= Length (Src) and then Slice (Src, Pos, Pos + 3) = "let " then
         Pos := Pos + 4;
         declare
            X : constant String := Ident;
         begin
            Expect ('=');
            declare
               V : constant Expr_Access := Parse_Expr;
            begin
               Skip;
               if Slice (Src, Pos, Pos + 1) /= "in" then
                  raise Program_Error with "parse: expected in";
               end if;
               Pos := Pos + 2;
               return Make_Expr_Let (X, V, Parse_Expr);
            end;
         end;
      else
         declare
            E : Expr_Access := Parse_Atom;
         begin
            loop
               Skip;
               exit when Peek in ')' | ASCII.NUL
                 or else (Pos + 1 <= Length (Src) and then Slice (Src, Pos, Pos + 1) = "in");
               E := Make_Expr_App (E, Parse_Atom);
            end loop;
            return E;
         end;
      end if;
   end Parse_Expr;

   function Parse (S : String) return Expr_Access is
   begin
      Src := To_Unbounded_String (S);
      Pos := 1;
      return Parse_Expr;
   end Parse;

   --  canonical form up to renaming of type variables
   Keys  : array (1 .. 64) of Unbounded_String;
   NKeys : Natural := 0;

   function Num (N : Natural) return String is
      Img : constant String := N'Image;
   begin
      return Img (Img'First + 1 .. Img'Last);
   end Num;

   function Canon (T : Type_Access) return String is
   begin
      case T.Kind is
         when Kind_Var =>
            declare
               Key : constant Unbounded_String := To_Unbounded_String (To_String (T.Var_Name));
            begin
               for I in 1 .. NKeys loop
                  if Keys (I) = Key then
                     return "t" & Num (I - 1);
                  end if;
               end loop;
               NKeys := NKeys + 1;
               Keys (NKeys) := Key;
               return "t" & Num (NKeys - 1);
            end;
         when Kind_Base =>
            return To_String (T.Base_Name);
         when Kind_Arrow =>
            return "(" & Canon (T.Left) & " -> " & Canon (T.Right) & ")";
      end case;
   end Canon;

   function Canonical (T : Type_Access) return String is
   begin
      NKeys := 0;
      return Canon (T);
   end Canonical;

   type Case_Row is record
      Term, Want : Unbounded_String;
   end record;
   function "+" (S : String) return Unbounded_String renames To_Unbounded_String;

   --  hand-derived principal types (canonical form)
   Typable : constant array (Positive range <>) of Case_Row :=
     [(+"\x.x",                          +"(t0 -> t0)"),
      (+"\x.\y.x",                       +"(t0 -> (t1 -> t0))"),
      (+"\x.\y.y",                       +"(t0 -> (t1 -> t1))"),
      (+"\f.\x.f x",                     +"((t0 -> t1) -> (t0 -> t1))"),
      (+"\f.\g.\x.f (g x)",              +"((t0 -> t1) -> ((t2 -> t0) -> (t2 -> t1)))"),
      (+"\x.\y.\z.x z (y z)",            +"((t0 -> (t1 -> t2)) -> ((t0 -> t1) -> (t0 -> t2)))"),
      (+"\f.\x.f (f x)",                 +"((t0 -> t0) -> (t0 -> t0))"),
      (+"\x.\y.y (y x)",                 +"(t0 -> ((t0 -> t0) -> t0))"),
      (+"\f.\x.\y.f y x",                +"((t0 -> (t1 -> t2)) -> (t1 -> (t0 -> t2)))"),
      (+"let id = \x.x in id id",        +"(t0 -> t0)"),
      (+"let id = \x.x in id",           +"(t0 -> t0)"),
      (+"let k = \x.\y.x in k (\z.z)",   +"(t0 -> (t1 -> t1))"),
      (+"\x.let y = x in y",             +"(t0 -> t0)"),
      (+"\x.let f = \y.x in f x",        +"(t0 -> t0)"),
      (+"let c = \f.\g.\x.f (g x) in let i = \x.x in c i i", +"(t0 -> t0)"),
      (+"\x.\f.f x x",                   +"(t0 -> ((t0 -> (t0 -> t1)) -> t1))"),
      (+"\f.(\x.f x) (\y.y)",            +"(((t0 -> t0) -> t1) -> t1)")];

   Ill_Typed : constant array (Positive range <>) of Unbounded_String :=
     [+"\x.x x",                         --  occurs check: a = a -> b
      +"(\x.x x) (\x.x x)",
      +"\f.\x.f (f x) x",               --  f (f x) : a, applied to x: a = a -> c
      +"\x.\y.y (y x) x",               --  y : a -> a, result a applied to x: a = a -> b
      +"\f.f f",
      +"\x.y",                           --  unbound variable
      +"\x.x (\y.y) x"];                 --  x : (b -> b) -> a -> c and x : a: occurs

   --  rejected only without let-polymorphism
   Mono_Ill : constant array (Positive range <>) of Unbounded_String :=
     [+"let id = \x.x in id id",
      +"let k = \x.\y.x in k k"];

   St : Infer_State;
   Empty_Env : Environment;
   function Infer_Poly (E : Expr_Access) return Type_Access is (Infer_Type (Empty_Env, E, St));
   function Infer_Mono (E : Expr_Access) return Type_Access is (Infer_Type_Monomorphic (Empty_Env, E, St));

   procedure Check_Unify (A, B : Type_Access; Should_Unify : Boolean; Label : String) is
   begin
      declare
         S : constant Substitution := Unify (A, B);
         RA : constant Type_Access := Apply_Subst_Type (S, A);
         RB : constant Type_Access := Apply_Subst_Type (S, B);
      begin
         NKeys := 0;
         declare
            CA : constant String := Canon (RA);
            CB : constant String := Canon (RB);
         begin
            if not Should_Unify then
               Fail ("Unify accepted " & Label);
            elsif CA /= CB then
               Fail ("Unify " & Label & ": applying the answer gives " & CA & " and " & CB);
            else
               Passed := Passed + 1;
            end if;
         end;
      end;
   exception
      when Unification_Error =>
         if Should_Unify then
            Fail ("Unify rejected " & Label);
         else
            Passed := Passed + 1;
         end if;
   end Check_Unify;

   function V (N : Natural) return Type_Access is (Make_Type_Var ("v" & Num (N)));
   function Arr (A, B : Type_Access) return Type_Access is (Make_Type_Arrow (A, B));
   Int_T  : constant Type_Access := Make_Type_Base ("Int");
   Bool_T : constant Type_Access := Make_Type_Base ("Bool");
begin
   for C of Typable loop
      declare
         Term : constant String := To_String (C.Term);
      begin
         declare
            T : constant Type_Access := Infer_Poly (Parse (Term));
            Got : constant String := Canonical (T);
         begin
            if Got /= To_String (C.Want) then
               Fail (Term & ": inferred " & Got & ", hand-derived principal type " & To_String (C.Want));
            else
               Passed := Passed + 1;
            end if;
         end;
      exception
         when E : others =>
            Fail (Term & ": raised " & Ada.Exceptions.Exception_Name (E) & " (typable, " & To_String (C.Want) & ")");
      end;
   end loop;
   for C of Ill_Typed loop
      declare
         Term : constant String := To_String (C);
      begin
         declare
            T : constant Type_Access := Infer_Poly (Parse (Term));
         begin
            Fail (Term & ": ill-typed term accepted with type " & Canonical (T));
         end;
      exception
         when Unification_Error | Unbound_Variable_Error =>
            Passed := Passed + 1;
         when E : others =>
            Fail (Term & ": raised " & Ada.Exceptions.Exception_Name (E) & " instead of a type error");
      end;
   end loop;
   for C of Mono_Ill loop
      begin
         declare
            T : constant Type_Access := Infer_Mono (Parse (To_String (C)));
         begin
            Fail (To_String (C) & ": accepted without let-polymorphism, type " & Canonical (T));
         end;
      exception
         when Unification_Error => Passed := Passed + 1;
      end;
   end loop;
   for C of Typable loop   --  terms without let infer the same type monomorphically
      if Index (C.Term, "let") = 0 then
         begin
            if Canonical (Infer_Mono (Parse (To_String (C.Term)))) /= To_String (C.Want) then
               Fail (To_String (C.Term) & ": monomorphic inference differs");
            else
               Passed := Passed + 1;
            end if;
         exception
            when others => Fail (To_String (C.Term) & ": monomorphic inference raised");
         end;
      end if;
   end loop;
   Check_Unify (Arr (V (91), Int_T), Arr (Bool_T, V (92)), True, "(a -> Int) = (Bool -> b)");
   Check_Unify (Arr (V (91), V (91)), Arr (V (92), Arr (V (93), V (93))), True, "(a -> a) = (b -> (c -> c))");
   Check_Unify (Arr (V (91), V (92)), Arr (V (92), Arr (V (93), V (91))), False, "(a -> b) = (b -> (c -> a))");
   Check_Unify (V (91), Arr (V (91), V (92)), False, "a = (a -> b)");
   Check_Unify (Int_T, Bool_T, False, "Int = Bool");
   Check_Unify (Int_T, Int_T, True, "Int = Int");
   Check_Unify (Arr (V (91), Int_T), Arr (Bool_T, Int_T), True, "(a -> Int) = (Bool -> Int)");
   Check_Unify (Arr (V (91), Int_T), Int_T, False, "(a -> Int) = Int");
   Check_Unify (Arr (V (91), V (92)), Arr (Arr (V (92), Int_T), V (94)), True, "(a -> b) = ((b -> Int) -> d)");
   --  Fixed let-polymorphism cases (room list), with constants one : Int
   --  and tt : Bool in the environment and K = \a.\b.a for a pair:
   --  (a) let id = \x.x in K (id one) (id tt) : Int (id used at Int, Bool);
   --  (b) \x. let y = x in K (y one) (y tt) must be rejected (y's type is
   --      still free in the environment, so it must not be generalized);
   --  (c) \x. x x must be rejected (occurs check; also in Ill_Typed).
   declare
      Env : Environment;
      function Infer_Env (S : String) return Type_Access is (Infer_Type (Env, Parse (S), St));
   begin
      Env.Insert ("one", (Bound_Vars => String_Sets.Empty_Set, T => Make_Type_Base ("Int")));
      Env.Insert ("tt", (Bound_Vars => String_Sets.Empty_Set, T => Make_Type_Base ("Bool")));
      for C of Pair_List'((+"let id = \x.x in (\a.\b.a) (id one) (id tt)", +"Int"),
                          (+"let id = \x.x in (\a.\b.b) (id one) (id tt)", +"Bool"),
                          (+"let k = \a.\b.a in k (k one tt) (k tt one)", +"Int"))
      loop
         begin
            declare
               Got : constant String := Canonical (Infer_Env (To_String (C.Term)));
            begin
               if Got /= To_String (C.Want) then
                  Fail ("(a) " & To_String (C.Term) & ": inferred " & Got & ", expected " & To_String (C.Want));
               else
                  Passed := Passed + 1;
               end if;
            end;
         exception
            when E : others =>
               Fail ("(a) " & To_String (C.Term) & " rejected: " & Ada.Exceptions.Exception_Name (E));
         end;
      end loop;
      for S of Term_List'(+"\x.let y = x in (\a.\b.a) (y one) (y tt)",
                          +"\x.x x",
                          +"\f.let g = f in (\a.\b.a) (g one) (g tt)",
                          +"one tt")
      loop
         begin
            declare
               T : constant Type_Access := Infer_Env (To_String (S));
            begin
               Fail ("(b)/(c) " & To_String (S) & " accepted at " & Canonical (T));
            end;
         exception
            when Unification_Error => Passed := Passed + 1;
            when E : others =>
               Fail ("(b)/(c) " & To_String (S) & " raised " & Ada.Exceptions.Exception_Name (E));
         end;
      end loop;
   end;

   --  Random soundness check. Terms are generated in this file's own syntax
   --  tree from a target type over the base types Int and Bool (constants
   --  one : Int, tt : Bool in the environment), so they are well-typed by
   --  construction. Lets are generated too: polymorphic id = \x.x and
   --  k = \x.\y.x used at several types, and monomorphic lets of generated
   --  values. Two independent references:
   --  * one-way matching (own code): the inferred type must be at least as
   --    general as the generating type;
   --  * a separate checker: every let is expanded by substitution (after
   --    checking its value), then plain monomorphic inference with an own
   --    unifier gives the principal type, which must equal the engine's up
   --    to renaming, and a rejection reason (mismatch or occurs check).
   --  Ill-typed variants: occurs check by embedding a self-application
   --  (\yy. E (yy yy)); mismatch only by applying a constant (one E) and by
   --  using a lambda-bound variable at two types (\zz. K (zz one) (zz E));
   --  the reference must agree they are ill-typed, and must report >0
   --  rejections for each reason.
   declare
      Seed : Long_Long_Integer := 20261008;
      function Rand (Lo, Hi : Integer) return Integer is
      begin
         Seed := (Seed * 16807) mod 2147483647;
         return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
      end Rand;
      Int_B  : constant Type_Access := Make_Type_Base ("Int");
      Bool_B : constant Type_Access := Make_Type_Base ("Bool");
      function Rand_Type (D : Natural) return Type_Access is
        (if D = 0 or else Rand (1, 3) = 1 then (if Rand (0, 1) = 0 then Int_B else Bool_B)
         else Make_Type_Arrow (Rand_Type (D - 1), Rand_Type (D - 1)));
      function Same (X, Y : Type_Access) return Boolean is
        (X.Kind = Y.Kind and then
           (case X.Kind is
              when Kind_Var   => To_String (X.Var_Name) = To_String (Y.Var_Name),
              when Kind_Base  => To_String (X.Base_Name) = To_String (Y.Base_Name),
              when Kind_Arrow => Same (X.Left, Y.Left) and then Same (X.Right, Y.Right)));

      --  own syntax tree
      type R_Kind is (R_Var, R_Abs, R_App, R_Let);
      type R_Node is record
         Kind : R_Kind := R_Var;
         Name : Unbounded_String;
         A, B : Natural := 0;
      end record;
      type Tree_Arr is array (Positive range <>) of R_Node;
      type Tree_Ptr is access Tree_Arr;
      Tree : constant Tree_Ptr := new Tree_Arr (1 .. 200_000);
      N_Tree : Natural := 0;
      Too_Big : exception;
      function Node (K : R_Kind; Name : String; A, B : Natural) return Positive is
      begin
         if N_Tree = Tree'Last then
            raise Too_Big;
         end if;
         N_Tree := N_Tree + 1;
         Tree (N_Tree) := (K, To_Unbounded_String (Name), A, B);
         return N_Tree;
      end Node;
      function To_Engine (N : Positive) return Expr_Access is
        (case Tree (N).Kind is
           when R_Var => Make_Expr_Var (To_String (Tree (N).Name)),
           when R_Abs => Make_Expr_Abs (To_String (Tree (N).Name), To_Engine (Tree (N).A)),
           when R_App => Make_Expr_App (To_Engine (Tree (N).A), To_Engine (Tree (N).B)),
           when R_Let => Make_Expr_Let (To_String (Tree (N).Name), To_Engine (Tree (N).A), To_Engine (Tree (N).B)));

      --  generation context: monomorphic variables, and polymorphic id / k
      Ctx_Names : array (1 .. 60) of Unbounded_String;
      Ctx_Types : array (1 .. 60) of Type_Access;   --  null for id / k
      Ctx_Poly  : array (1 .. 60) of Character;   --  'm', 'i' (id), 'k' (k)
      N_Ctx : Natural := 0;
      Fresh : Natural := 0;
      Lets_Poly, Lets_Mono : Natural := 0;
      Failed : exception;
      procedure Push (Name : String; T : Type_Access; P : Character) is
      begin
         N_Ctx := N_Ctx + 1;
         Ctx_Names (N_Ctx) := To_Unbounded_String (Name);
         Ctx_Types (N_Ctx) := T;
         Ctx_Poly (N_Ctx) := P;
      end Push;
      function Fits (I : Positive; T : Type_Access) return Boolean is
        (case Ctx_Poly (I) is
           when 'i' => T.Kind = Kind_Arrow and then Same (T.Left, T.Right),
           when 'k' => T.Kind = Kind_Arrow and then T.Right.Kind = Kind_Arrow
                         and then Same (T.Left, T.Right.Right),
           when others => Same (Ctx_Types (I), T));
      function Gen (T : Type_Access; D : Natural) return Positive is
         R : constant Integer := Rand (1, 12);
      begin
         if R <= 4 or else D = 0 or else T.Kind /= Kind_Arrow then
            for I in reverse 1 .. N_Ctx loop
               if Fits (I, T) and then (D = 0 or else Rand (0, 2) > 0) then
                  return Node (R_Var, To_String (Ctx_Names (I)), 0, 0);
               end if;
            end loop;
         end if;
         if D > 0 and then R = 5 then            --  polymorphic let
            Fresh := Fresh + 1;
            declare
               Name : constant String := "p" & Num (Fresh);
               Is_K : constant Boolean := Rand (0, 1) = 1;
               X : constant String := "x" & Num (Fresh);
               Y : constant String := "y" & Num (Fresh);
               Val : constant Positive :=
                 (if Is_K then Node (R_Abs, X, Node (R_Abs, Y, Node (R_Var, X, 0, 0), 0), 0)
                  else Node (R_Abs, X, Node (R_Var, X, 0, 0), 0));
            begin
               Push (Name, null, (if Is_K then 'k' else 'i'));
               declare
                  Body_N : constant Positive := Gen (T, D - 1);
               begin
                  N_Ctx := N_Ctx - 1;
                  Lets_Poly := Lets_Poly + 1;
                  return Node (R_Let, Name, Val, Body_N);
               end;
            end;
         elsif D > 0 and then R = 6 then         --  monomorphic let
            Fresh := Fresh + 1;
            declare
               Name : constant String := "m" & Num (Fresh);
               VT : constant Type_Access := Rand_Type (1);
               Val : constant Positive := Gen (VT, D - 1);
            begin
               Push (Name, VT, 'm');
               declare
                  Body_N : constant Positive := Gen (T, D - 1);
               begin
                  N_Ctx := N_Ctx - 1;
                  Lets_Mono := Lets_Mono + 1;
                  return Node (R_Let, Name, Val, Body_N);
               end;
            end;
         end if;
         if T.Kind = Kind_Arrow and then (D = 0 or else R <= 9) then
            Fresh := Fresh + 1;
            declare
               Name : constant String := "v" & Num (Fresh);
            begin
               Push (Name, T.Left, 'm');
               declare
                  Body_N : constant Positive := Gen (T.Right, (if D = 0 then 0 else D - 1));
               begin
                  N_Ctx := N_Ctx - 1;
                  return Node (R_Abs, Name, Body_N, 0);
               end;
            end;
         elsif D = 0 then
            raise Failed;
         else
            declare
               Arg_T : constant Type_Access := Rand_Type (1);
               Fn : constant Positive := Gen (Make_Type_Arrow (Arg_T, T), D - 1);
               Ar : constant Positive := Gen (Arg_T, D - 1);
            begin
               return Node (R_App, "", Fn, Ar);
            end;
         end if;
      end Gen;

      --  reference checker: own types with bindings, own unifier
      type Q_Kind is (Q_Var, Q_Base, Q_Arrow);
      type Q_Node is record
         Kind : Q_Kind := Q_Var;
         Base : Character := ' ';     --  'I' Int, 'B' Bool
         L, R : Natural := 0;
         Bound : Natural := 0;        --  for Q_Var: 0 = unbound
      end record;
      type Q_Arr is array (Positive range <>) of Q_Node;
      type Q_Ptr is access Q_Arr;
      Q : constant Q_Ptr := new Q_Arr (1 .. 200_000);
      N_Q : Natural := 0;
      Ref_Mismatch, Ref_Occurs, Ref_Unbound : exception;
      function Q_New (N : Q_Node) return Positive is
      begin
         if N_Q = Q'Last then
            raise Too_Big;
         end if;
         N_Q := N_Q + 1;
         Q (N_Q) := N;
         return N_Q;
      end Q_New;
      function Find (T : Positive) return Positive is
        (if Q (T).Kind = Q_Var and then Q (T).Bound /= 0 then Find (Q (T).Bound) else T);
      function Occurs (V, T : Positive) return Boolean is
         F : constant Positive := Find (T);
      begin
         return F = V or else
           (Q (F).Kind = Q_Arrow and then (Occurs (V, Q (F).L) or else Occurs (V, Q (F).R)));
      end Occurs;
      procedure Q_Unify (A, B : Positive) is
         FA : constant Positive := Find (A);
         FB : constant Positive := Find (B);
      begin
         if FA = FB then
            return;
         elsif Q (FA).Kind = Q_Var then
            if Occurs (FA, FB) then
               raise Ref_Occurs;
            end if;
            Q (FA).Bound := FB;
         elsif Q (FB).Kind = Q_Var then
            Q_Unify (FB, FA);
         elsif Q (FA).Kind = Q_Base and then Q (FB).Kind = Q_Base then
            if Q (FA).Base /= Q (FB).Base then
               raise Ref_Mismatch;
            end if;
         elsif Q (FA).Kind = Q_Arrow and then Q (FB).Kind = Q_Arrow then
            Q_Unify (Q (FA).L, Q (FB).L);
            Q_Unify (Q (FA).R, Q (FB).R);
         else
            raise Ref_Mismatch;
         end if;
      end Q_Unify;
      --  substitution of a let value for its name (binder names are unique
      --  in generated terms, so no capture can occur)
      function Subst (N : Positive; X : String; V : Positive) return Positive is
        (case Tree (N).Kind is
           when R_Var => (if To_String (Tree (N).Name) = X then V else N),
           when R_Abs => (if To_String (Tree (N).Name) = X then N
                          else Node (R_Abs, To_String (Tree (N).Name), Subst (Tree (N).A, X, V), 0)),
           when R_App => Node (R_App, "", Subst (Tree (N).A, X, V), Subst (Tree (N).B, X, V)),
           when R_Let => Node (R_Let, To_String (Tree (N).Name), Subst (Tree (N).A, X, V),
                               (if To_String (Tree (N).Name) = X then Tree (N).B
                                else Subst (Tree (N).B, X, V))));
      R_Names : array (1 .. 200) of Unbounded_String;
      R_Types : array (1 .. 200) of Positive;
      N_R : Natural := 0;
      function Q_Infer (N : Positive) return Positive is
      begin
         case Tree (N).Kind is
            when R_Var =>
               for I in reverse 1 .. N_R loop
                  if R_Names (I) = Tree (N).Name then
                     return R_Types (I);
                  end if;
               end loop;
               if To_String (Tree (N).Name) = "one" then
                  return Q_New ((Kind => Q_Base, Base => 'I', others => <>));
               elsif To_String (Tree (N).Name) = "tt" then
                  return Q_New ((Kind => Q_Base, Base => 'B', others => <>));
               end if;
               raise Ref_Unbound;
            when R_Abs =>
               declare
                  P : constant Positive := Q_New ((Kind => Q_Var, others => <>));
               begin
                  N_R := N_R + 1;
                  R_Names (N_R) := Tree (N).Name;
                  R_Types (N_R) := P;
                  declare
                     B : constant Positive := Q_Infer (Tree (N).A);
                  begin
                     N_R := N_R - 1;
                     return Q_New ((Kind => Q_Arrow, L => P, R => B, others => <>));
                  end;
               end;
            when R_App =>
               declare
                  F : constant Positive := Q_Infer (Tree (N).A);
                  A : constant Positive := Q_Infer (Tree (N).B);
                  Res : constant Positive := Q_New ((Kind => Q_Var, others => <>));
               begin
                  Q_Unify (F, Q_New ((Kind => Q_Arrow, L => A, R => Res, others => <>)));
                  return Res;
               end;
            when R_Let =>
               declare
                  Discard : constant Positive := Q_Infer (Tree (N).A);   --  the value must be typable
                  pragma Unreferenced (Discard);
               begin
                  return Q_Infer (Subst (Tree (N).B, To_String (Tree (N).Name), Tree (N).A));
               end;
         end case;
      end Q_Infer;
      function Q_To_Engine (T : Positive) return Type_Access is
         F : constant Positive := Find (T);
      begin
         case Q (F).Kind is
            when Q_Var => return Make_Type_Var ("q" & Num (F));
            when Q_Base => return (if Q (F).Base = 'I' then Int_B else Bool_B);
            when Q_Arrow => return Make_Type_Arrow (Q_To_Engine (Q (F).L), Q_To_Engine (Q (F).R));
         end case;
      end Q_To_Engine;
      type Verdict is (Typed, Mismatch, Occurs_Fail, Unbound);
      Ref_Type : Type_Access;
      function Reference (N : Positive) return Verdict is
      begin
         N_R := 0;
         Ref_Type := Q_To_Engine (Q_Infer (N));
         return Typed;
      exception
         when Ref_Mismatch => return Mismatch;
         when Ref_Occurs => return Occurs_Fail;
         when Ref_Unbound => return Unbound;
      end Reference;

      Keys2 : array (1 .. 64) of Unbounded_String;
      Vals2 : array (1 .. 64) of Type_Access;
      NK2 : Natural := 0;
      function Match (P, T : Type_Access) return Boolean is
      begin
         case P.Kind is
            when Kind_Var =>
               for I in 1 .. NK2 loop
                  if Keys2 (I) = To_Unbounded_String (To_String (P.Var_Name)) then
                     return Same (Vals2 (I), T);
                  end if;
               end loop;
               NK2 := NK2 + 1;
               Keys2 (NK2) := To_Unbounded_String (To_String (P.Var_Name));
               Vals2 (NK2) := T;
               return True;
            when Kind_Base => return T.Kind = Kind_Base and then To_String (P.Base_Name) = To_String (T.Base_Name);
            when Kind_Arrow => return T.Kind = Kind_Arrow and then Match (P.Left, T.Left) and then Match (P.Right, T.Right);
         end case;
      end Match;
      Env : Environment;
      Sound, Same_As_Ref, Generated, With_Let : Natural := 0;
      Rej : array (Verdict) of Natural := [others => 0];
      Ill_Total : Natural := 0;
      
      procedure Check_Ill (N : Positive; Label : String) is
         V : constant Verdict := Reference (N);
      begin
         Ill_Total := Ill_Total + 1;
         if V = Typed then
            Fail ("reference checker accepts the ill-typed variant " & Label);
            return;
         end if;
         begin
            declare
               S : constant Type_Access := Infer_Type (Env, To_Engine (N), St);
            begin
               Fail (Label & " (" & V'Image & ") accepted at " & Canonical (S));
            end;
         exception
            when E : Unification_Error =>
               Rej (V) := Rej (V) + 1;
               pragma Unreferenced (E);
         end;
      end Check_Ill;
      K_Term : Positive;
   begin
      Env.Insert ("one", (Bound_Vars => String_Sets.Empty_Set, T => Int_B));
      Env.Insert ("tt", (Bound_Vars => String_Sets.Empty_Set, T => Bool_B));
      for Round in 1 .. 1500 loop
         declare
            T : constant Type_Access := Make_Type_Arrow (Rand_Type (2), Rand_Type (2));
            Lets_Before : constant Natural := Lets_Poly + Lets_Mono;
         begin
            N_Ctx := 0;
            N_Tree := 0;
            N_Q := 0;
            declare
               E : constant Positive := Gen (T, 4);
               V : Verdict;
            begin
               Generated := Generated + 1;
               if Lets_Poly + Lets_Mono > Lets_Before then
                  With_Let := With_Let + 1;
               end if;
               V := Reference (E);
               if V /= Typed then
                  Fail ("reference checker rejects a generated term (" & V'Image & ")");
               end if;
               begin
                  declare
                     S : constant Type_Access := Infer_Type (Env, To_Engine (E), St);
                  begin
                     NK2 := 0;
                     if Match (S, T) then
                        Sound := Sound + 1;
                     else
                        Fail ("random term of type " & Canonical (T) & ": inferred " & Canonical (S) & ", not more general");
                     end if;
                     if V = Typed then
                        if Canonical (S) = Canonical (Ref_Type) then
                           Same_As_Ref := Same_As_Ref + 1;
                        else
                           Fail ("random term: engine type " & Canonical (S) & ", reference type " & Canonical (Ref_Type));
                        end if;
                     end if;
                  end;
               exception
                  when Unification_Error | Unbound_Variable_Error =>
                     Fail ("random well-typed term of type " & Canonical (T) & " rejected");
               end;
               --  ill-typed variants
               K_Term := Node (R_Abs, "ka", Node (R_Abs, "kb", Node (R_Var, "ka", 0, 0), 0), 0);
               Check_Ill (Node (R_Abs, "yy", Node (R_App, "", E,
                            Node (R_App, "", Node (R_Var, "yy", 0, 0), Node (R_Var, "yy", 0, 0))), 0),
                          "self-application");
               Check_Ill (Node (R_App, "", Node (R_Var, "one", 0, 0), E), "constant applied");
               Check_Ill (Node (R_Abs, "zz",
                            Node (R_App, "", Node (R_App, "", K_Term,
                                    Node (R_App, "", Node (R_Var, "zz", 0, 0), Node (R_Var, "one", 0, 0))),
                                  Node (R_App, "", Node (R_Var, "zz", 0, 0), E)), 0),
                          "lambda-bound variable at two types");
            end;
         exception
            when Failed | Too_Big => null;
         end;
      end loop;
      Put_Line ("own checks: random well-typed terms" & Generated'Image & " (" & With_Let'Image
                & " with let; lets: polymorphic" & Lets_Poly'Image & ", monomorphic" & Lets_Mono'Image
                & "): at least as general as the generating type" & Sound'Image
                & ", equal to the let-expanding reference" & Same_As_Ref'Image);
      Put_Line ("own checks: ill-typed variants" & Ill_Total'Image & " rejected by reason (reference): mismatch"
                & Rej (Mismatch)'Image & ", occurs check" & Rej (Occurs_Fail)'Image );
      if Generated < 100 or else With_Let < 50 or else Lets_Poly < 50 then
         Fail ("too few random terms / lets generated");
      end if;
      if Rej (Mismatch) = 0 or else Rej (Occurs_Fail) = 0 then
         Fail ("ill-typed variants did not exercise both rejection reasons");
      end if;
   end;
   Put_Line ("own checks:" & Passed'Image & " passed (" & Typable'Length'Image & " hand-derived principal types,"
             & Ill_Typed'Length'Image & " ill-typed terms, unifier checks)");
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
