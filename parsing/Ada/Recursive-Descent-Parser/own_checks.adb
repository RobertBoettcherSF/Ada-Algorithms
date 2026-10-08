pragma Ada_2022;
--  Own tests for Recursive_Descent_Parser (see tests/SOURCES.txt).
--  Evaluate on random expressions of the documented grammar (integers, + - * /, parentheses,
--  no spaces, no unary minus): the value must match an own expression tree evaluated with the usual
--  precedence, left associativity and Ada integer division; Is_Valid must accept them.
--  Trees with a node value outside Integer must raise Constraint_Error (see spec).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Recursive_Descent_Parser; use Recursive_Descent_Parser;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
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
   --  Value of T in wide arithmetic, with Ok = False as soon as any node
   --  (the parser computes one Value_Type per node, same tree: printing
   --  only drops parentheses the grammar re-inserts) leaves Integer.
   --  Children are in Integer when combined, so Long_Long_Integer never
   --  overflows here. Depth 4 with literals up to 20 reaches 20**16, so
   --  out-of-range trees are a real part of the input space: AA_SEED 1,
   --  2 and 22 drew one, and the old Integer oracle could not express it.
   function Eval_Wide (T : Node_Access; Ok : in out Boolean) return Long_Long_Integer is
      L, R, V : Long_Long_Integer;
   begin
      if not Ok then
         return 0;
      end if;
      if T.Op = ' ' then
         return Long_Long_Integer (T.Val);
      end if;
      L := Eval_Wide (T.L, Ok);
      R := Eval_Wide (T.R, Ok);
      if not Ok then
         return 0;
      end if;
      V := (case T.Op is
              when '+' => L + R,
              when '-' => L - R,
              when '*' => L * R,
              when others => L / R);
      if V not in Long_Long_Integer (Integer'First) .. Long_Long_Integer (Integer'Last) then
         Ok := False;
         return 0;
      end if;
      return V;
   end Eval_Wide;
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
      declare
         R_Ok : Boolean := True;
      begin
         if T.Op = '/' and then Eval_Wide (T.R, R_Ok) = 0 and then R_Ok then
            T.R := new Node'(' ', Next (1, 9), null, null);
         end if;
      end;
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
   In_Range_Count, Overflow_Count : Natural := 0;
   type String_Access is access constant String;
   Overflows : constant array (1 .. 4) of String_Access :=
     [new String'("65536*65536"), new String'("2147483647+1"),
      new String'("0-2147483647-2"), new String'("(46341*46341)/2")];
begin
   --  Fixed overflow cases: a node outside Value_Type raises Constraint_Error
   --  (documented in the spec); the text is still grammatical.
   for S of Overflows loop
      declare
         V : Value_Type;
      begin
         V := Evaluate (S.all);
         Report (False, S.all & " gave" & V'Image & ", expected Constraint_Error");
      exception
         when Constraint_Error => Report (Is_Valid (S.all), S.all & " overflow raised; Is_Valid");
         when Syntax_Error | Evaluation_Error => Report (False, S.all & " raised Syntax/Evaluation_Error");
      end;
   end loop;
   Report (Evaluate ("46340*46340") = 2147395600, "46340*46340 in range");
   Report (Evaluate ("2147483647-1+1") = 2147483647, "Integer'Last reached left to right");
   for Run in 1 .. 20000 loop
      declare
         T  : constant Node_Access := Build (Next (0, 4));
         S  : constant String := Show (T);
         Ok : Boolean := True;
         W  : constant Long_Long_Integer := Eval_Wide (T, Ok);
         V  : Value_Type;
      begin
         if Ok then
            In_Range_Count := In_Range_Count + 1;
         else
            Overflow_Count := Overflow_Count + 1;
         end if;
         V := Evaluate (S);
         Report (Ok and then Long_Long_Integer (V) = W and then Is_Valid (S),
                 S & " gave" & V'Image & (if Ok then ", expected" & W'Image else ", expected Constraint_Error"));
      exception
         when Constraint_Error =>
            Report (not Ok and then Is_Valid (S), S & " raised Constraint_Error"
                    & (if Ok then ", expected" & W'Image else " but Is_Valid rejected it"));
         when Syntax_Error | Evaluation_Error => Report (False, S & " raised");
      end;
   end loop;
   Put_Line ("own checks: random trees in Integer range" & In_Range_Count'Image
             & ", overflowing" & Overflow_Count'Image);
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
