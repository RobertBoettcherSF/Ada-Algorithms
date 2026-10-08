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
   Keys  : array (1 .. 64) of Unbounded_String;
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
   --  Random soundness check: terms are generated from a target type (so
   --  they are well-typed by construction, independently of the inference),
   --  over the rigid base types A and B. The inferred type must be at least
   --  as general as the target: one-way matching (own code) must find a
   --  substitution of the inferred type variables that yields the target.
   --  Embedding the ill-typed self-application (y y) of a lambda-bound y
   --  anywhere must make inference fail.
   declare
      Seed : Long_Long_Integer := 20261008;
      function Rand (Lo, Hi : Integer) return Integer is
      begin
         Seed := (Seed * 16807) mod 2147483647;
         return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
      end Rand;
      A_T : constant Type_Ref := Make_Const_Type ("A");
      B_T : constant Type_Ref := Make_Const_Type ("B");
      function Rand_Type (D : Natural) return Type_Ref is
        (if D = 0 or else Rand (1, 3) = 1 then (if Rand (0, 1) = 0 then A_T else B_T)
         else Make_Arrow_Type (Rand_Type (D - 1), Rand_Type (D - 1)));
      function Same (X, Y : Type_Ref) return Boolean is
        (X.Kind = Y.Kind and then
           (case X.Kind is
              when Kind_Var   => Num (Natural (X.Id)) = Num (Natural (Y.Id)),
              when Kind_Const  => To_String (X.Name) = To_String (Y.Name),
              when Kind_Arrow => Same (X.Left, Y.Left) and then Same (X.Right, Y.Right)));
      --  context of lambda-bound variables
      Ctx_Names : array (1 .. 40) of Unbounded_String;
      Ctx_Types : array (1 .. 40) of Type_Ref;
      N_Ctx : Natural := 0;
      Fresh : Natural := 0;
      Failed : exception;
      function Gen (T : Type_Ref; D : Natural) return Expr_Ref is
      begin
         --  a variable of exactly this type, sometimes
         if Rand (1, 3) = 1 or else D = 0 or else T.Kind /= Kind_Arrow then
            for I in reverse 1 .. N_Ctx loop
               if Same (Ctx_Types (I), T) then
                  return Make_Var_Expr (To_String (Ctx_Names (I)));
               end if;
            end loop;
         end if;
         if T.Kind = Kind_Arrow and then (D = 0 or else Rand (1, 2) = 1) then
            Fresh := Fresh + 1;
            N_Ctx := N_Ctx + 1;
            Ctx_Names (N_Ctx) := To_Unbounded_String ("v" & Num (Fresh));
            Ctx_Types (N_Ctx) := T.Left;
            declare
               Name : constant String := To_String (Ctx_Names (N_Ctx));
               Body_E : constant Expr_Ref := Gen (T.Right, (if D = 0 then 0 else D - 1));
            begin
               N_Ctx := N_Ctx - 1;
               return Make_Abs_Expr (Name, Body_E);
            end;
         elsif D = 0 then
            raise Failed;   --  no variable of this base type in scope
         else
            declare
               Arg_T : constant Type_Ref := Rand_Type (1);
               Fn : constant Expr_Ref := Gen (Make_Arrow_Type (Arg_T, T), D - 1);
               Ar : constant Expr_Ref := Gen (Arg_T, D - 1);
            begin
               return Make_App_Expr (Fn, Ar);
            end;
         end if;
      end Gen;
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
      Sound, Generated, Rejected, Ill : Natural := 0;
   begin
      for Round in 1 .. 1500 loop
         declare
            T : constant Type_Ref := Make_Arrow_Type (Rand_Type (2), Rand_Type (2));
         begin
            N_Ctx := 0;
            declare
               E : constant Expr_Ref := Gen (T, 4);
            begin
               Generated := Generated + 1;
               begin
                  declare
                     S : constant Type_Ref := Infer_Poly (E);
                  begin
                     NK2 := 0;
                     if Match (S, T) then
                        Sound := Sound + 1;
                     else
                        Fail ("random term of type " & Canonical (T) & ": inferred " & Canonical (S) & ", not more general");
                     end if;
                  end;
               exception
                  when Unification_Error | Unbound_Variable_Error =>
                     Fail ("random well-typed term of type " & Canonical (T) & " rejected");
               end;
               --  ill-typed: \y. E (y y)  (E's type is an arrow, so this is
               --  only wrong because of the self-application)
               begin
                  declare
                     S : constant Type_Ref := Infer_Poly
                       (Make_Abs_Expr ("yy", Make_App_Expr (E, Make_App_Expr (Make_Var_Expr ("yy"), Make_Var_Expr ("yy")))));
                  begin
                     Fail ("term with a self-application accepted at " & Canonical (S));
                  end;
               exception
                  when Unification_Error =>
                     Rejected := Rejected + 1;
               end;
               Ill := Ill + 1;
            end;
         exception
            when Failed => null;
         end;
      end loop;
      Put_Line ("own checks: random well-typed terms" & Sound'Image & " /" & Generated'Image
                & " inferred at least as general as their generating type; ill-typed variants rejected"
                & Rejected'Image & " /" & Ill'Image);
      if Generated < 100 then
         Fail ("too few random terms generated");
      end if;
   end;
   Put_Line ("own checks:" & Passed'Image & " passed (" & Typable'Length'Image & " hand-derived principal types,"
             & Ill_Typed'Length'Image & " ill-typed terms, unifier checks)");
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
