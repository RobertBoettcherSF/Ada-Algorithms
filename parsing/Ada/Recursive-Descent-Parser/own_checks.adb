pragma Ada_2022;
--  Own tests for Recursive_Descent_Parser (see tests/SOURCES.txt).
--  Evaluate on random expressions of the documented grammar (integers, + - * /, parentheses,
--  no spaces, no unary minus): the value must match an own expression tree evaluated with the usual
--  precedence, left associativity and Ada integer division; Is_Valid must accept them.
with Ada.Text_IO; use Ada.Text_IO;
with Recursive_Descent_Parser; use Recursive_Descent_Parser;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   type Node;
   type Node_Access is access Node;
   type Node is record
      Op : Character := ' ';   --  ' ' = literal
      Val : Integer := 0;
      L, R : Node_Access;
   end record;
   function Prec (C : Character) return Natural is (case C is when '+' | '-' => 1, when '*' | '/' => 2, when others => 3);
   function Eval (T : Node_Access) return Integer is
     (case T.Op is
         when '+' => Eval (T.L) + Eval (T.R),
         when '-' => Eval (T.L) - Eval (T.R),
         when '*' => Eval (T.L) * Eval (T.R),
         when '/' => Eval (T.L) / Eval (T.R),
         when others => T.Val);
   function Build (Depth : Natural) return Node_Access is
      T : constant Node_Access := new Node;
      Ops : constant String := "+-*/";
   begin
      if Depth = 0 or else Next (0, 3) = 0 then
         T.Val := Next (0, 20);
         return T;
      end if;
      T.Op := Ops (Next (1, 4));
      T.L := Build (Depth - 1);
      T.R := Build (Depth - 1);
      if T.Op = '/' and then Eval (T.R) = 0 then T.R := new Node'(' ', Next (1, 9), null, null); end if;
      return T;
   end Build;
   function Show (T : Node_Access) return String is
      function Side (C : Node_Access; Right : Boolean) return String is
        (if (C.Op /= ' ' and then (Prec (C.Op) < Prec (T.Op) or else (Right and then Prec (C.Op) = Prec (T.Op)))) or else Next (0, 9) = 0
         then "(" & Show (C) & ")" else Show (C));
   begin
      if T.Op = ' ' then
         declare S : constant String := Integer'Image (T.Val); begin return S (S'First + 1 .. S'Last); end;
      end if;
      return Side (T.L, False) & T.Op & Side (T.R, True);
   end Show;
begin
   for Run in 1 .. 20000 loop
      declare
         T : constant Node_Access := Build (Next (0, 4));
         S : constant String := Show (T);
         V : Integer;
      begin
         V := Integer (Evaluate (S));
         Report (V = Eval (T) and then Is_Valid (S), S & " gave" & V'Image & ", expected" & Eval (T)'Image);
      exception
         when Syntax_Error | Evaluation_Error => Report (False, S & " raised");
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
