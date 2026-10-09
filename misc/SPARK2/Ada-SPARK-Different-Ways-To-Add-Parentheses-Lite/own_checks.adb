pragma Ada_2022;
--  Own checks for Different-Ways-To-Add-Parentheses-Lite (see
--  tests/SOURCES.txt). No expected value comes from the program:
--  * Number_Of_Ways (N) and the ghost table Ways (N) against the closed
--    Catalan count C (2 (N - 1), N - 1) / N (exact, Big_Integer) for
--    N <= 20, and the limit: the count for N = 21 exceeds Natural'Last;
--    the ghost Bound (L) against 99 multiplied L times;
--  * an own shift-reduce enumerator: every sequence of N shifts and
--    N - 1 reductions (a reduction combines the top two parts of the
--    stack with the operator between them) is one parenthesization, so
--    the multiset of their values (Big_Integer) must be the multiset of
--    All_Results;
--  * an own ordered reference (recursion over the last operator, values
--    in Big_Integer) for the order the spec states;
--  * seeded random expressions of 1 .. 8 operands (extremes -99 and 99
--    over-weighted) and the all -99 / all 99 products.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Ada.Containers.Vectors;
with Interfaces; use Interfaces;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Different_Ways_Parentheses; use Different_Ways_Parentheses;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function B (V : Long_Long_Integer) return Big_Integer is (From_String (V'Image));

   --  C (A, K) multiplicatively; every step is exact.
   function Binomial (A, K : Natural) return Big_Integer is
      R : Big_Integer := To_Big_Integer (1);
   begin
      for I in 1 .. K loop
         R := R * To_Big_Integer (A - K + I) / To_Big_Integer (I);
      end loop;
      return R;
   end Binomial;

   function Catalan_Count (N : Positive) return Big_Integer is
     (Binomial (2 * (N - 1), N - 1) / To_Big_Integer (N));

   package Big_Vectors is new Ada.Containers.Vectors (Positive, Big_Integer);
   use Big_Vectors;
   package Sorting is new Big_Vectors.Generic_Sorting;

   function Op_Of (Op : Operator; X, Y : Big_Integer) return Big_Integer is
     (case Op is when Plus => X + Y, when Minus => X - Y, when Times => X * Y);

   --  Shift-reduce enumeration. The stack holds parts (value, last operand).
   type Part is record
      Value : Big_Integer;
      Last  : Natural;
   end record;
   type Part_Stack is array (1 .. 8) of Part;

   procedure Shift_Reduce (Values : Operand_List; Ops : Operator_List;
                           Stack : Part_Stack; Depth, Shifted : Natural; Out_V : in out Vector) is
   begin
      if Shifted = Values'Length and then Depth = 1 then
         Out_V.Append (Stack (1).Value);
         return;
      end if;
      if Shifted < Values'Length then
         declare
            S : Part_Stack := Stack;
         begin
            S (Depth + 1) := (To_Big_Integer (Values (Shifted + 1)), Shifted + 1);
            Shift_Reduce (Values, Ops, S, Depth + 1, Shifted + 1, Out_V);
         end;
      end if;
      if Depth >= 2 then
         declare
            S : Part_Stack := Stack;
            --  The operator between the two parts follows the left part's last operand.
            K : constant Positive := Stack (Depth - 1).Last;
         begin
            S (Depth - 1) := (Op_Of (Ops (K), Stack (Depth - 1).Value, Stack (Depth).Value), Stack (Depth).Last);
            Shift_Reduce (Values, Ops, S, Depth - 1, Shifted, Out_V);
         end;
      end if;
   end Shift_Reduce;

   --  Ordered reference: last operator first, then left values, then right values.
   function Ordered (Values : Operand_List; Ops : Operator_List; I, J : Positive) return Vector is
      R : Vector;
   begin
      if I = J then
         R.Append (To_Big_Integer (Values (I)));
         return R;
      end if;
      for K in I .. J - 1 loop
         declare
            Left  : constant Vector := Ordered (Values, Ops, I, K);
            Right : constant Vector := Ordered (Values, Ops, K + 1, J);
         begin
            for X of Left loop
               for Y of Right loop
                  R.Append (Op_Of (Ops (K), X, Y));
               end loop;
            end loop;
         end;
      end loop;
      return R;
   end Ordered;

   procedure Check (Values : Operand_List; Ops : Operator_List; Label : String) is
      Got   : constant Value_List := All_Results (Values, Ops);
      Got_V : Vector;
      Ref   : Vector;
      Ord   : constant Vector := Ordered (Values, Ops, 1, Values'Length);
      Same  : Boolean;
      Empty : constant Part_Stack := [others => (To_Big_Integer (0), 0)];
   begin
      for V of Got loop
         Got_V.Append (B (V));
      end loop;
      Report (Got'First = 1, Label & " first index");
      Report (To_Big_Integer (Integer (Got'Length)) = Catalan_Count (Values'Length), Label & " count");
      Same := Natural (Ord.Length) = Got'Length;
      if Same then
         for M in 1 .. Got'Length loop
            Same := Same and then Element (Ord, M) = Element (Got_V, M);
         end loop;
      end if;
      Report (Same, Label & " order vs own ordered reference");
      Shift_Reduce (Values, Ops, Empty, 0, 0, Ref);
      Report (To_Big_Integer (Integer (Ref.Length)) = Catalan_Count (Values'Length), Label & " shift-reduce count");
      Sorting.Sort (Ref);
      Sorting.Sort (Got_V);
      Report (Ref = Got_V, Label & " multiset vs shift-reduce");
   end Check;

   Pow : Big_Integer := To_Big_Integer (1);
begin
   for N in 1 .. Max_Operands loop
      Report (To_Big_Integer (Number_Of_Ways (N)) = Catalan_Count (N), "Number_Of_Ways" & N'Image);
      --  Ghost code may only be read in an assertion (enabled by -gnata).
      pragma Assert (Ways (N) = Catalan_Count (N), "ghost Ways" & N'Image);
      Checked := Checked + 1;
   end loop;
   Report (Catalan_Count (Max_Operands + 1) > To_Big_Integer (Natural'Last), "limit: count for 21 overflows");
   Report (Catalan_Count (Max_Expression) = To_Big_Integer (Max_Results), "Max_Results is the count for 8");
   for L in 1 .. Max_Expression loop
      Pow := Pow * To_Big_Integer (99);
      pragma Assert (B (Bound (L)) = Pow, "ghost Bound" & L'Image);
      Checked := Checked + 1;
   end loop;
   Report (Pow < B (Long_Long_Integer'Last), "99 ** 8 fits Long_Long_Integer");

   Check ([1 .. 8 => -99], [1 .. 7 => Times], "all -99 times");
   Check ([1 .. 8 => 99], [1 .. 7 => Times], "all 99 times");
   Check ([1 .. 8 => 99], [1 .. 7 => Minus], "all 99 minus");
   Check ([7], [1 .. 0 => Plus], "single operand");

   for T in 1 .. 1_500 loop
      declare
         N      : constant Positive := 1 + Next mod Max_Expression;
         Values : Operand_List (1 .. N);
         Ops    : Operator_List (1 .. N - 1);
      begin
         for V of Values loop
            case Next mod 5 is
               when 0 => V := 99;
               when 1 => V := -99;
               when others => V := Next mod 199 - 99;
            end case;
         end loop;
         for O of Ops loop
            O := Operator'Val (Next mod 3);
         end loop;
         Check (Values, Ops, "random" & T'Image);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
