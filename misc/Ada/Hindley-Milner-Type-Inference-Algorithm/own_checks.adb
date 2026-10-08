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
   Check_Unify (Arr (V (91), V (92)), Arr (Arr (V (92), Int_T), V (94)), True, "(a -> b) = ((b -> Int) -> d)");
   Put_Line ("own checks:" & Passed'Image & " passed (" & Typable'Length'Image & " hand-derived principal types,"
             & Ill_Typed'Length'Image & " ill-typed terms, unifier checks)");
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
