--  Own checks (see tests/SOURCES.txt). Assume type inference is wrong or
--  does nothing. Expected principal types of small closed lambda terms were
--  derived by hand (not taken from the program's output) and are compared
--  up to renaming of type variables: inferred types are canonicalised by
--  naming variables t0, t1, ... in order of first occurrence and printing
--  every arrow fully parenthesised. Ill-typed terms (self-application,
--  occurs-check failures, unbound variables) must be rejected. Unify's
--  answer is applied to both types and the results compared syntactically.
pragma Ada_2022;
with Ada.Environment_Variables;
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

   function Parse_Expr return Expr_Ref;

   function Parse_Atom return Expr_Ref is
   begin
      Skip;
      if Peek = '(' then
         Pos := Pos + 1;
         declare
            E : constant Expr_Ref := Parse_Expr;
         begin
            Expect (')');
            return E;
         end;
      else
         return Make_Var_Expr (Ident);
      end if;
   end Parse_Atom;

   function Parse_Expr return Expr_Ref is
   begin
      Skip;
      if Peek = '\' then
         Pos := Pos + 1;
         declare
            X : constant String := Ident;
         begin
            Expect ('.');
            return Make_Abs_Expr (X, Parse_Expr);
         end;
      elsif Pos + 3 <= Length (Src) and then Slice (Src, Pos, Pos + 3) = "let " then
         Pos := Pos + 4;
         declare
            X : constant String := Ident;
         begin
            Expect ('=');
            declare
               V : constant Expr_Ref := Parse_Expr;
            begin
               Skip;
               if Slice (Src, Pos, Pos + 1) /= "in" then
                  raise Program_Error with "parse: expected in";
               end if;
               Pos := Pos + 2;
               return Make_Let_Expr (X, V, Parse_Expr);
            end;
         end;
      else
         declare
            E : Expr_Ref := Parse_Atom;
         begin
            loop
               Skip;
               exit when Peek in ')' | ASCII.NUL
                 or else (Pos + 1 <= Length (Src) and then Slice (Src, Pos, Pos + 1) = "in");
               E := Make_App_Expr (E, Parse_Atom);
            end loop;
            return E;
         end;
      end if;
   end Parse_Expr;

   function Parse (S : String) return Expr_Ref is
   begin
      Src := To_Unbounded_String (S);
      Pos := 1;
      return Parse_Expr;
   end Parse;

   --  canonical form up to renaming of type variables
   Keys  : array (1 .. 4096) of Unbounded_String;   --  joint renaming of whole traces
   NKeys : Natural := 0;

   function Num (N : Natural) return String is
      Img : constant String := N'Image;
   begin
      return Img (Img'First + 1 .. Img'Last);
   end Num;

   function Canon (T : Type_Ref) return String is
   begin
      case T.Kind is
         when Kind_Var =>
            declare
               Key : constant Unbounded_String := To_Unbounded_String (Num (Natural (T.Id)));
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
         when Kind_Const =>
            return To_String (T.Name);
         when Kind_Arrow =>
            return "(" & Canon (T.Left) & " -> " & Canon (T.Right) & ")";
      end case;
   end Canon;

   function Canonical (T : Type_Ref) return String is
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



   Ctx : Context;
   --  terms of the fixed let cases, replayed in the trace comparison below
   Hand_Terms : array (1 .. 64) of Unbounded_String;
   N_Hand : Natural := 0;
   procedure Keep_Hand (Term : Unbounded_String) is
   begin
      N_Hand := N_Hand + 1;
      Hand_Terms (N_Hand) := Term;
   end Keep_Hand;
   Empty_Env : Environment;
   function Infer_Poly (E : Expr_Ref) return Type_Ref is (Algorithm_W (Ctx, Empty_Env, E).T);

   --  Algorithm M (top-down) must accept the term against its principal
   --  type, agree on the principal type from a fresh expected variable, and
   --  reject the term against Int (no closed lambda term has a base type)
   procedure Check_M (Term : String; Want : String) is
      E : constant Expr_Ref := Parse (Term);
      Fresh : constant Type_Ref := Make_Var_Type (Var_Id (5000));
   begin
      declare
         S : constant Substitution := Algorithm_M (Ctx, Empty_Env, E, Fresh);
      begin
         if Canonical (Apply (S, Fresh)) /= Want then
            Fail (Term & ": Algorithm_M gives " & Canonical (Apply (S, Fresh)) & ", principal type " & Want);
         else
            Passed := Passed + 1;
         end if;
      end;
      declare
         S : constant Substitution := Algorithm_M (Ctx, Empty_Env, E, Make_Const_Type ("Int"));
         pragma Unreferenced (S);
      begin
         Fail (Term & ": Algorithm_M accepts it at type Int");
      end;
   exception
      when Unification_Error => Passed := Passed + 1;
      when Ex : others => Fail (Term & ": Algorithm_M raised " & Ada.Exceptions.Exception_Name (Ex));
   end Check_M;

   procedure Check_Unify (A, B : Type_Ref; Should_Unify : Boolean; Label : String) is
   begin
      declare
         S : constant Substitution := Unify (A, B);
         RA : constant Type_Ref := Apply (S, A);
         RB : constant Type_Ref := Apply (S, B);
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

   function V (N : Natural) return Type_Ref is (Make_Var_Type (Var_Id (N + 1000)));
   function Arr (A, B : Type_Ref) return Type_Ref is (Make_Arrow_Type (A, B));
   Int_T  : constant Type_Ref := Make_Const_Type ("Int");
   Bool_T : constant Type_Ref := Make_Const_Type ("Bool");
begin
   for C of Typable loop
      declare
         Term : constant String := To_String (C.Term);
      begin
         declare
            T : constant Type_Ref := Infer_Poly (Parse (Term));
            Got : constant String := Canonical (T);
         begin
            if Got /= To_String (C.Want) then
               Fail (Term & ": inferred " & Got & ", hand-derived principal type " & To_String (C.Want));
            else
               Passed := Passed + 1;
               Check_M (Term, To_String (C.Want));
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
            T : constant Type_Ref := Infer_Poly (Parse (Term));
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
   for C of Ill_Typed loop
      begin
         declare
            S : constant Substitution := Algorithm_M (Ctx, Empty_Env, Parse (To_String (C)), Make_Var_Type (Var_Id (5001)));
            pragma Unreferenced (S);
         begin
            Fail (To_String (C) & ": Algorithm_M accepts an ill-typed term");
         end;
      exception
         when Unification_Error | Unbound_Variable_Error => Passed := Passed + 1;
      end;
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
   --  Types_Equal: structural equality by definition
   if not Types_Equal (Arr (V (91), Int_T), Arr (V (91), Int_T))
     or else Types_Equal (Arr (V (91), Int_T), Arr (V (91), Bool_T))
     or else Types_Equal (Arr (Int_T, V (91)), Arr (Bool_T, V (91)))
     or else Types_Equal (V (91), V (92)) or else Types_Equal (Int_T, Bool_T)
     or else Types_Equal (Arr (Int_T, Int_T), Int_T)
     or else not Types_Equal (null, null)
     or else Types_Equal (Int_T, null) or else Types_Equal (null, Int_T)
   then
      Fail ("Types_Equal");
   else
      Passed := Passed + 1;
   end if;
   --  To_String of a type variable: "a" followed by the decimal Id with no
   --  space (Var_Id'Image without its leading blank); distinct Ids print
   --  differently; arrows print both sides
   declare
      S5  : constant String := To_String (Make_Var_Type (5));
      S15 : constant String := To_String (Make_Var_Type (15));
      SA  : constant String := To_String (Arr (Make_Var_Type (5), Int_T));
   begin
      if S5 /= "a5" or else S15 /= "a15" or else (for some C of SA => C = ASCII.NUL)
        or else SA'Length <= S5'Length + 3
      then
         Fail ("To_String of type variables: got """ & S5 & """, """ & S15 & """");
      else
         Passed := Passed + 1;
      end if;
   end;
   --  Exhaustive range check for the variable rendering: Ids 0 .. 20000,
   --  expected text built digit by digit here (no 'Image).
   declare
      function Dec (N : Natural) return String is
        (if N < 10 then [Character'Val (Character'Pos ('0') + N)]
         else Dec (N / 10) & [Character'Val (Character'Pos ('0') + N mod 10)]);
      Bad : Natural := 0;
   begin
      for I in 0 .. 20000 loop
         if To_String (Make_Var_Type (Var_Id (I))) /= "a" & Dec (I) then
            Bad := Bad + 1;
         end if;
      end loop;
      if Bad > 0 then
         Fail ("To_String of type variables 0 .. 20000:" & Bad'Image & " wrong");
      else
         Passed := Passed + 1;
      end if;
   end;
   --  Fixed let-polymorphism cases (room list), with constants one : Int
   --  and tt : Bool in the environment and K = \a.\b.a for a pair:
   --  (a) let id = \x.x in K (id one) (id tt) : Int (id used at Int, Bool);
   --  (b) \x. let y = x in K (y one) (y tt) must be rejected (y's type is
   --      still free in the environment, so it must not be generalized);
   --  (c) \x. x x must be rejected (occurs check; also in Ill_Typed).
   declare
      Env : Environment;
      function Infer_Env (S : String) return Type_Ref is (Algorithm_W (Ctx, Env, Parse (S)).T);
      Let_Order_Cases : Natural := 0;
   begin
      Env.Insert (To_Unbounded_String ("one"), (Bound => Var_Sets.Empty_Set, T => Make_Const_Type ("Int")));
      Env.Insert (To_Unbounded_String ("tt"), (Bound => Var_Sets.Empty_Set, T => Make_Const_Type ("Bool")));
      for C of Pair_List'((+"let id = \x.x in (\a.\b.a) (id one) (id tt)", +"Int"),
                          (+"let id = \x.x in (\a.\b.b) (id one) (id tt)", +"Bool"),
                          (+"let k = \a.\b.a in k (k one tt) (k tt one)", +"Int"))
      loop
         begin
            declare
               Got : constant String := Canonical (Infer_Env (To_String (C.Term)));
            begin
               Keep_Hand (C.Term);
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
      --  Substitution order of let (hand-derived): in \f. let y = f E1 in
      --  y E2 the let value fixes f : T1 -> b and the body fixes b : T2 -> c,
      --  so the let must return the body's substitution composed AFTER the
      --  value's: f : T1 -> (T2 -> c). Generated over E1, E2 in {one, tt}
      --  and four body shapes (direct, K-pair, nested let, extra lambda g).
      declare
         subtype Base is Positive range 1 .. 2;   --  1 = one : Int, 2 = tt : Bool
         Lit : constant array (Base) of Unbounded_String := [+"one", +"tt"];
         Ty  : constant array (Base) of Unbounded_String := [+"Int", +"Bool"];
      begin
         for E1 in Base loop
            for E2 in Base loop
               declare
                  A : constant String := To_String (Lit (E1));
                  B : constant String := To_String (Lit (E2));
                  F : constant String := "(" & To_String (Ty (E1)) & " -> (" & To_String (Ty (E2)) & " -> t0))";
               begin
                  for C of Pair_List'
                    ((+("\f.let y = f " & A & " in y " & B), +("(" & F & " -> t0)")),
                     (+("\f.let y = f " & A & " in (\a.\b.a) (y " & B & ") (y " & B & ")"), +("(" & F & " -> t0)")),
                     (+("\f.let y = f " & A & " in let z = y " & B & " in z"), +("(" & F & " -> t0)")),
                     (+("\f.\g.let y = f " & A & " in g (y " & B & ")"), +("(" & F & " -> ((t0 -> t1) -> t1))")))
                  loop
                     begin
                        declare
                           Got : constant String := Canonical (Infer_Env (To_String (C.Term)));
                        begin
                           Keep_Hand (C.Term);
                           if Got /= To_String (C.Want) then
                              Fail ("let order " & To_String (C.Term) & ": inferred " & Got & ", expected " & To_String (C.Want));
                           else
                              Passed := Passed + 1;
                              Let_Order_Cases := Let_Order_Cases + 1;
                           end if;
                        end;
                     exception
                        when E : others =>
                           Fail ("let order " & To_String (C.Term) & " rejected: " & Ada.Exceptions.Exception_Name (E));
                     end;
                  end loop;
               end;
            end loop;
         end loop;
         Put_Line ("own checks: let substitution order:" & Let_Order_Cases'Image & " / 16 hand-derived cases");
         if Let_Order_Cases /= 16 then
            Fail ("let substitution order cases incomplete");
         end if;
      end;
      for S of Term_List'(+"\x.let y = x in (\a.\b.a) (y one) (y tt)",
                          +"\x.x x",
                          +"\f.let g = f in (\a.\b.a) (g one) (g tt)",
                          +"one tt")
      loop
         begin
            declare
               T : constant Type_Ref := Infer_Env (To_String (S));
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
      --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
      function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
         V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
         S : Long_Long_Integer := Default;
      begin
         if V /= "" then
            S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
         end if;
         Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
         return S;
      end AA_Seed;
      Seed : Long_Long_Integer := AA_Seed (20261008);
      function Rand (Lo, Hi : Integer) return Integer is
      begin
         Seed := (Seed * 16807) mod 2147483647;
         return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
      end Rand;
      Int_B  : constant Type_Ref := Make_Const_Type ("Int");
      Bool_B : constant Type_Ref := Make_Const_Type ("Bool");
      function Rand_Type (D : Natural) return Type_Ref is
        (if D = 0 or else Rand (1, 3) = 1 then (if Rand (0, 1) = 0 then Int_B else Bool_B)
         else Make_Arrow_Type (Rand_Type (D - 1), Rand_Type (D - 1)));
      function Same (X, Y : Type_Ref) return Boolean is
        (X.Kind = Y.Kind and then
           (case X.Kind is
              when Kind_Var   => Num (Natural (X.Id)) = Num (Natural (Y.Id)),
              when Kind_Const  => To_String (X.Name) = To_String (Y.Name),
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
      --  Copy (I): node I is a let value root reached again through the
      --  let's substitution (a copy); the trace records the original only
      type Flag_Arr is array (Positive range <>) of Boolean;
      type Flag_Ptr is access Flag_Arr;
      Copy : constant Flag_Ptr := new Flag_Arr'(1 .. 200_000 => False);
      function Node (K : R_Kind; Name : String; A, B : Natural) return Positive is
      begin
         if N_Tree = Tree'Last then
            raise Too_Big;
         end if;
         N_Tree := N_Tree + 1;
         Tree (N_Tree) := (K, To_Unbounded_String (Name), A, B);
         Copy (N_Tree) := False;
         return N_Tree;
      end Node;
      function To_Engine (N : Positive) return Expr_Ref is
        (case Tree (N).Kind is
           when R_Var => Make_Var_Expr (To_String (Tree (N).Name)),
           when R_Abs => Make_Abs_Expr (To_String (Tree (N).Name), To_Engine (Tree (N).A)),
           when R_App => Make_App_Expr (To_Engine (Tree (N).A), To_Engine (Tree (N).B)),
           when R_Let => Make_Let_Expr (To_String (Tree (N).Name), To_Engine (Tree (N).A), To_Engine (Tree (N).B)));

      --  generation context: monomorphic variables, and polymorphic id / k
      Ctx_Names : array (1 .. 60) of Unbounded_String;
      Ctx_Types : array (1 .. 60) of Type_Ref;   --  null for id / k
      Ctx_Poly  : array (1 .. 60) of Character;   --  'm', 'i' (id), 'k' (k)
      N_Ctx : Natural := 0;
      Fresh : Natural := 0;
      Lets_Poly, Lets_Mono : Natural := 0;
      Failed : exception;
      procedure Push (Name : String; T : Type_Ref; P : Character) is
      begin
         N_Ctx := N_Ctx + 1;
         Ctx_Names (N_Ctx) := To_Unbounded_String (Name);
         Ctx_Types (N_Ctx) := T;
         Ctx_Poly (N_Ctx) := P;
      end Push;
      function Fits (I : Positive; T : Type_Ref) return Boolean is
        (case Ctx_Poly (I) is
           when 'i' => T.Kind = Kind_Arrow and then Same (T.Left, T.Right),
           when 'k' => T.Kind = Kind_Arrow and then T.Right.Kind = Kind_Arrow
                         and then Same (T.Left, T.Right.Right),
           when others => Same (Ctx_Types (I), T));
      function Gen (T : Type_Ref; D : Natural) return Positive is
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
               VT : constant Type_Ref := Rand_Type (1);
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
               Arg_T : constant Type_Ref := Rand_Type (1);
               Fn : constant Positive := Gen (Make_Arrow_Type (Arg_T, T), D - 1);
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
      --  reference trace, in the engine's documented order: per let the
      --  value's type and the lambda-variable types in scope (the scheme's
      --  bound variables are worked out after inference has finished), per
      --  application its result type; copies made by let expansion skipped
      Max_Ev : constant := 4_000;
      Ev_Let : array (1 .. Max_Ev) of Boolean;
      Ev_T, Ev_Env_First, Ev_Env_Len : array (1 .. Max_Ev) of Natural;
      N_Ev : Natural := 0;
      type Pos_Arr is array (Positive range <>) of Positive;
      type Pos_Ptr is access Pos_Arr;
      Env_Store : constant Pos_Ptr := new Pos_Arr (1 .. 100_000);
      N_Env_Store : Natural := 0;
      Copy_Depth : Natural := 0;
      procedure Record_Event (Is_Let : Boolean; T : Positive) is
      begin
         if Copy_Depth > 0 then
            return;
         end if;
         if N_Ev = Max_Ev or else N_Env_Store + N_R > Env_Store'Last then
            raise Too_Big;
         end if;
         N_Ev := N_Ev + 1;
         Ev_Let (N_Ev) := Is_Let;
         Ev_T (N_Ev) := T;
         Ev_Env_First (N_Ev) := N_Env_Store + 1;
         Ev_Env_Len (N_Ev) := (if Is_Let then N_R else 0);
         if Is_Let then
            for I in 1 .. N_R loop
               N_Env_Store := N_Env_Store + 1;
               Env_Store (N_Env_Store) := R_Types (I);
            end loop;
         end if;
      end Record_Event;
      function Q_Infer_Node (N : Positive) return Positive;
      function Q_Infer (N : Positive) return Positive is
      begin
         if not Copy (N) then
            return Q_Infer_Node (N);
         end if;
         Copy_Depth := Copy_Depth + 1;
         declare
            T : constant Positive := Q_Infer_Node (N);
         begin
            Copy_Depth := Copy_Depth - 1;
            return T;
         end;
      end Q_Infer;
      function Q_Infer_Node (N : Positive) return Positive is
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
                  Record_Event (False, Res);
                  return Res;
               end;
            when R_Let =>
               declare
                  Value_T : constant Positive := Q_Infer (Tree (N).A);   --  the value must be typable
               begin
                  Record_Event (True, Value_T);
                  Copy (Tree (N).A) := True;
                  return Q_Infer (Subst (Tree (N).B, To_String (Tree (N).Name), Tree (N).A));
               end;
         end case;
      end Q_Infer_Node;
      function Q_To_Engine (T : Positive) return Type_Ref is
         F : constant Positive := Find (T);
      begin
         case Q (F).Kind is
            when Q_Var => return Make_Var_Type (Var_Id (900_000 + F));
            when Q_Base => return (if Q (F).Base = 'I' then Int_B else Bool_B);
            when Q_Arrow => return Make_Arrow_Type (Q_To_Engine (Q (F).L), Q_To_Engine (Q (F).R));
         end case;
      end Q_To_Engine;
      type Verdict is (Typed, Mismatch, Occurs_Fail, Unbound);
      Ref_Type : Type_Ref;
      function Reference (N : Positive) return Verdict is
      begin
         N_R := 0;
         N_Ev := 0;
         N_Env_Store := 0;
         Copy_Depth := 0;
         Ref_Type := Q_To_Engine (Q_Infer (N));
         return Typed;
      exception
         when Ref_Mismatch => return Mismatch;
         when Ref_Occurs => return Occurs_Fail;
         when Ref_Unbound => return Unbound;
      end Reference;

      Keys2 : array (1 .. 64) of Unbounded_String;
      Vals2 : array (1 .. 64) of Type_Ref;
      NK2 : Natural := 0;
      function Match (P, T : Type_Ref) return Boolean is
      begin
         case P.Kind is
            when Kind_Var =>
               for I in 1 .. NK2 loop
                  if Keys2 (I) = To_Unbounded_String (Num (Natural (P.Id))) then
                     return Same (Vals2 (I), T);
                  end if;
               end loop;
               NK2 := NK2 + 1;
               Keys2 (NK2) := To_Unbounded_String (Num (Natural (P.Id)));
               Vals2 (NK2) := T;
               return True;
            when Kind_Const => return T.Kind = Kind_Const and then To_String (P.Name) = To_String (T.Name);
            when Kind_Arrow => return T.Kind = Kind_Arrow and then Match (P.Left, T.Left) and then Match (P.Right, T.Right);
         end case;
      end Match;
      Env : Environment;
      Sound, Same_As_Ref, Generated, With_Let : Natural := 0;
      Rej : array (Verdict) of Natural := [others => 0];
      Ill_Total : Natural := 0;
      Msg_Agree : Natural := 0;
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
               S : constant Type_Ref := Algorithm_W (Ctx, Env, To_Engine (N)).T;
            begin
               Fail (Label & " (" & V'Image & ") accepted at " & Canonical (S));
            end;
         exception
            when E : Unification_Error =>
               Rej (V) := Rej (V) + 1;
               declare
                  M : constant String := Ada.Exceptions.Exception_Message (E);
               begin
                  if (V = Occurs_Fail and then M'Length >= 6 and then M (M'First .. M'First + 5) = "Occurs")
                    or else (V = Mismatch and then M'Length >= 4 and then M (M'First .. M'First + 3) = "Type")
                  then
                     Msg_Agree := Msg_Agree + 1;
                  end if;
               end;
         end;
      end Check_Ill;

      --  Trace comparison. Both traces are printed with one joint renaming
      --  of type variables across all events (so a variable shared between
      --  two events must be shared in both), "!" marking a let scheme's
      --  bound variables, followed by "=" and the final type.
      function Ev_Str (T : Type_Ref; Bound : Var_Sets.Set) return String is
        (case T.Kind is
           when Kind_Var => (if Bound.Contains (T.Id) then "!" else "") & Canon (T),
           when Kind_Const => To_String (T.Name),
           when Kind_Arrow => "(" & Ev_Str (T.Left, Bound) & " -> " & Ev_Str (T.Right, Bound) & ")");
      procedure Own_Vars (T : Type_Ref; Into : in out Var_Sets.Set) is
      begin
         case T.Kind is
            when Kind_Var => Into.Include (T.Id);
            when Kind_Const => null;
            when Kind_Arrow =>
               Own_Vars (T.Left, Into);
               Own_Vars (T.Right, Into);
         end case;
      end Own_Vars;
      Ref_Lets, Ref_Apps : Natural := 0;
      function Ref_Trace return String is
         R : Unbounded_String;
      begin
         NKeys := 0;
         Ref_Lets := 0;
         Ref_Apps := 0;
         for I in 1 .. N_Ev loop
            declare
               T : constant Type_Ref := Q_To_Engine (Ev_T (I));
               In_Env, Bound : Var_Sets.Set;
            begin
               if Ev_Let (I) then
                  Ref_Lets := Ref_Lets + 1;
                  for J in Ev_Env_First (I) .. Ev_Env_First (I) + Ev_Env_Len (I) - 1 loop
                     Own_Vars (Q_To_Engine (Env_Store (J)), In_Env);
                  end loop;
                  Own_Vars (T, Bound);
                  Bound.Difference (In_Env);
                  Append (R, "L:" & Ev_Str (T, Bound) & "; ");
               else
                  Ref_Apps := Ref_Apps + 1;
                  Append (R, "A:" & Ev_Str (T, Var_Sets.Empty_Set) & "; ");
               end if;
            end;
         end loop;
         return To_String (R) & "= " & Ev_Str (Ref_Type, Var_Sets.Empty_Set);
      end Ref_Trace;
      function Own_Apply (Sub : Substitution; T : Type_Ref; Bound : Var_Sets.Set) return Type_Ref is
        (case T.Kind is
           when Kind_Var =>
             (if not Bound.Contains (T.Id) and then Sub.Contains (T.Id) then Sub.Element (T.Id) else T),
           when Kind_Const => T,
           when Kind_Arrow => Make_Arrow_Type (Own_Apply (Sub, T.Left, Bound), Own_Apply (Sub, T.Right, Bound)));
      --  the final substitution is applied once to every recorded type (its
      --  idempotence is checked separately)
      function Engine_Trace (Res : Inference_Result; Tr : Trace_Vectors.Vector) return String is
         R : Unbounded_String;
      begin
         NKeys := 0;
         for Ev of Tr loop
            Append (R, (if Ev.Kind = Trace_Let then "L:" else "A:")
                    & Ev_Str (Own_Apply (Res.Subst, Ev.T, Ev.Bound), Ev.Bound) & "; ");
         end loop;
         return To_String (R) & "= " & Ev_Str (Res.T, Var_Sets.Empty_Set);
      end Engine_Trace;
      Trace_Same, Trace_Lets, Trace_Apps, Hand_Traced, Invariant_Ok : Natural := 0;
      procedure Compare_Trace (E : Positive; Label : String) is
         V : constant Verdict := Reference (E);
      begin
         if V /= Typed then
            Fail ("trace " & Label & ": reference rejects (" & V'Image & ")");
            return;
         end if;
         declare
            Ref_S : constant String := Ref_Trace;
            Res : Inference_Result;
            Tr : Trace_Vectors.Vector;
         begin
            Algorithm_W_Traced (Ctx, Env, To_Engine (E), Res, Tr);
            declare
               Eng_S : constant String := Engine_Trace (Res, Tr);
            begin
               --  W's invariant: the returned type already has the final
               --  substitution applied, and the substitution is idempotent
               if not Same (Own_Apply (Res.Subst, Res.T, Var_Sets.Empty_Set), Res.T) then
                  Fail ("trace " & Label & ": W's result type is not closed under its substitution");
               else
                  Invariant_Ok := Invariant_Ok + 1;
               end if;
               for Img of Res.Subst loop
                  if not Same (Own_Apply (Res.Subst, Img, Var_Sets.Empty_Set), Img) then
                     Fail ("trace " & Label & ": final substitution is not idempotent");
                     exit;
                  end if;
               end loop;
               if Eng_S = Ref_S then
                  Trace_Same := Trace_Same + 1;
                  Trace_Lets := Trace_Lets + Ref_Lets;
                  Trace_Apps := Trace_Apps + Ref_Apps;
               else
                  Fail ("trace " & Label & ": engine " & Eng_S & " | reference " & Ref_S);
               end if;
            end;
         exception
            when Unification_Error | Unbound_Variable_Error =>
               Fail ("trace " & Label & ": engine rejects a typable term");
         end;
      end Compare_Trace;
      --  hand terms into the own tree, binders renamed apart (h1, h2, ...)
      Ren_From, Ren_To : array (1 .. 200) of Unbounded_String;
      N_Ren, Fresh_H : Natural := 0;
      function From_Engine (E : Expr_Ref) return Positive is
      begin
         case E.Kind is
            when Expr_Var =>
               for I in reverse 1 .. N_Ren loop
                  if Ren_From (I) = E.Var_Name then
                     return Node (R_Var, To_String (Ren_To (I)), 0, 0);
                  end if;
               end loop;
               return Node (R_Var, To_String (E.Var_Name), 0, 0);
            when Expr_App =>
               declare
                  F : constant Positive := From_Engine (E.Func);
                  A : constant Positive := From_Engine (E.Arg);
               begin
                  return Node (R_App, "", F, A);
               end;
            when Expr_Abs | Expr_Let =>
               declare
                  Value : constant Natural := (if E.Kind = Expr_Let then From_Engine (E.Let_Value) else 0);
               begin
                  Fresh_H := Fresh_H + 1;
                  N_Ren := N_Ren + 1;
                  Ren_From (N_Ren) := (if E.Kind = Expr_Let then E.Let_Var else E.Param_Name);
                  Ren_To (N_Ren) := +("h" & Num (Fresh_H));
                  declare
                     Body_N : constant Positive :=
                       From_Engine (if E.Kind = Expr_Let then E.Let_Body else E.Body_Expr);
                     Name : constant String := To_String (Ren_To (N_Ren));
                  begin
                     N_Ren := N_Ren - 1;
                     return (if E.Kind = Expr_Let then Node (R_Let, Name, Value, Body_N)
                             else Node (R_Abs, Name, Body_N, 0));
                  end;
               end;
         end case;
      end From_Engine;
      K_Term : Positive;
   begin
      Env.Insert (To_Unbounded_String ("one"), (Bound => Var_Sets.Empty_Set, T => Int_B));
      Env.Insert (To_Unbounded_String ("tt"), (Bound => Var_Sets.Empty_Set, T => Bool_B));
      for H in 1 .. N_Hand loop
         N_Tree := 0;
         N_Q := 0;
         N_Ren := 0;
         Compare_Trace (From_Engine (Parse (To_String (Hand_Terms (H)))), To_String (Hand_Terms (H)));
         Hand_Traced := Hand_Traced + 1;
      end loop;
      Put_Line ("own checks: traces of the" & Hand_Traced'Image & " fixed let terms compared, equal" & Trace_Same'Image
                & " (lets" & Trace_Lets'Image & ", applications" & Trace_Apps'Image & ")");
      if N_Hand /= 19 or else Trace_Same /= 19 then
         Fail ("fixed let terms: expected 19 equal traces");
      end if;
      Trace_Same := 0;
      Trace_Lets := 0;
      Trace_Apps := 0;
      for Round in 1 .. 3000 loop
         declare
            T : constant Type_Ref := Make_Arrow_Type (Rand_Type (2), Rand_Type (2));
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
               Compare_Trace (E, "random term");
               V := Reference (E);
               if V /= Typed then
                  Fail ("reference checker rejects a generated term (" & V'Image & ")");
               end if;
               begin
                  declare
                     S : constant Type_Ref := Algorithm_W (Ctx, Env, To_Engine (E)).T;
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
      Put_Line ("own checks: random-term traces equal to the reference" & Trace_Same'Image
                & " (let schemes" & Trace_Lets'Image & ", application types" & Trace_Apps'Image & ")");
      Put_Line ("own checks: result type closed under its idempotent final substitution" & Invariant_Ok'Image
                & " (fixed and random terms)");
      if Trace_Same < Generated - Generated / 10 or else Trace_Lets < 200 or else Trace_Apps < 200 then
         Fail ("too few random traces compared");
      end if;
      Put_Line ("own checks: ill-typed variants" & Ill_Total'Image & " rejected by reason (reference): mismatch"
                & Rej (Mismatch)'Image & ", occurs check" & Rej (Occurs_Fail)'Image & "; engine message names the same reason" & Msg_Agree'Image);
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
