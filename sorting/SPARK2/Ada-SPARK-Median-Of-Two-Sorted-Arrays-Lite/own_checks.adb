--  Own tests for Median_Of_Two_Sorted_Arrays_Lite (written for this
--  repository; see tests/SOURCES.txt). Assumption: Median returns the
--  wrong middle values or mean for some pair of sorted arrays, miscounts
--  its comparisons, or Sorted_Array accepts or rejects the wrong arrays.
--  Reference: all 32 values sorted by insertion (16th and 17th); for the
--  predicate, a neighbour-by-neighbour test.
--  Inputs: 3,000 random pairs over 0 .. 100, 3,000 over 0 .. 3 (many
--  ties), 1,000 pairs with one array shifted above the other; exact
--  counts for three hand-worked pairs; 3,000 random arrays (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Median_Of_Two_Sorted_Arrays_Lite; use Median_Of_Two_Sorted_Arrays_Lite;

procedure Own_Checks is
   Failures   : Natural := 0;
   Cases      : Natural := 0;
   Max_Probes : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646;
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   Bound : constant Natural := Floor_Log2 (2 * Length) + 2;

   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;

   function Ref_Sorted (A : Input_Array) return Boolean is
     (for all K in 1 .. Length - 1 => A (K) <= A (K + 1));

   function Random_Sorted (Lo, Hi : Value) return Input_Array is
      X : IArr (1 .. Length);
      A : Input_Array;
   begin
      for I in X'Range loop
         X (I) := Next (Lo, Hi);
      end loop;
      Ins_Sort (X);
      for I in Index loop
         A (I) := X (I);
      end loop;
      return A;
   end Random_Sorted;

   procedure Check_Pair (A, B : Input_Array; Label : String) is
      E : IArr (1 .. 2 * Length);
      R : Median_Result;
   begin
      for I in Index loop
         E (I) := A (I);
         E (Length + I) := B (I);
      end loop;
      Ins_Sort (E);
      R := Median (A, B);
      Report (R.Lower = E (Length) and then R.Upper = E (Length + 1)
              and then R.Median = (E (Length) + E (Length + 1)) / 2,
              Label & ":" & R.Lower'Image & R.Upper'Image & R.Median'Image
              & ", expected" & E (Length)'Image & E (Length + 1)'Image);
      Report (R.Probes <= Bound, Label & ":" & R.Probes'Image & " comparisons");
      Max_Probes := Natural'Max (Max_Probes, R.Probes);
   end Check_Pair;

   --  Exact counts worked by hand. Left wholly below Right: every cut
   --  below 16 fails, the search moves right (16 7 3 1 0: 4 comparisons)
   --  to I = 16, J = 0, where Lower and Upper need no comparison: 4.
   --  Right wholly below Left (or all equal): every cut holds, the search
   --  moves left (16 8 4 2 1 0: 5) to I = 0, J = 16: 5.
   procedure Check_Count (A, B : Input_Array; Want : Natural; Label : String) is
      R : constant Median_Result := Median (A, B);
   begin
      Report (R.Probes = Want, Label & ":" & R.Probes'Image & " comparisons counted, made" & Want'Image);
   end Check_Count;
begin
   Check_Count ([for I in Index => I], [for I in Index => 50 + I], 4, "Left below Right");
   Check_Count ([for I in Index => 50 + I], [for I in Index => I], 5, "Right below Left");
   Check_Count ([others => 9], [others => 9], 5, "all equal");
   --  Paths with a comparison in the Lower and the Upper choice.
   --  Left odd 1 .. 31, Right even 2 .. 32: the cut holds from I = 8 on
   --  (Right (16 - I) = 32 - 2 I <= Left (I + 1) = 2 I + 1); the search
   --  takes Mid 8 (holds), 4, 6, 7 (fail): 4, ends at I = J = 8. Lower:
   --  Left (8) = 15 < Right (8) = 16, the Right branch, 1; Upper:
   --  Left (9) = 17 <= Right (9) = 18, the Left branch, 1: 6.
   Check_Count ([for I in Index => 2 * I - 1], [for I in Index => 2 * I], 6, "Left odd, Right even");
   --  Left even, Right odd: the cut holds from I = 8 on (31 - 2 I <=
   --  2 I + 2); same search, 4; Lower: Left (8) = 16 >= Right (8) = 15,
   --  the Left branch, 1; Upper: Left (9) = 18 > Right (9) = 17, the
   --  Right branch, 1: 6.
   Check_Count ([for I in Index => 2 * I], [for I in Index => 2 * I - 1], 6, "Left even, Right odd");
   --  J = 1: Left 2, 4 .. 30, 100; Right 1, 52 .. 66. The cut fails up to
   --  I = 14 (Right (2) = 52 > Left (15) = 30) and holds at I = 15
   --  (Right (1) = 1 <= Left (16) = 100); the search takes Mid 8, 12, 14
   --  (fail), 15 (holds): 4. Lower: Left (15) = 30 >= Right (1) = 1, the
   --  Left branch with I > 0 and J > 0, 1; Upper: Left (16) = 100 >
   --  Right (2) = 52, the Right branch, 1: 6.
   Check_Count ([for I in Index => (if I = Length then 100 else 2 * I)],
                [for I in Index => (if I = 1 then 1 else 50 + I)], 6, "J = 1");
   for K in 1 .. 3_000 loop
      Check_Pair (Random_Sorted (0, 100), Random_Sorted (0, 100), "random" & K'Image);
      Check_Pair (Random_Sorted (0, 3), Random_Sorted (0, 3), "ties" & K'Image);
   end loop;
   for K in 1 .. 500 loop
      Check_Pair (Random_Sorted (0, 40), Random_Sorted (60, 100), "Left lower" & K'Image);
      Check_Pair (Random_Sorted (60, 100), Random_Sorted (0, 40), "Right lower" & K'Image);
   end loop;
   for K in 1 .. 3_000 loop
      declare
         A : Input_Array := [for I in Index => Next (0, 100)];
      begin
         if K mod 2 = 0 then
            A := Random_Sorted (0, 100);
            A (Next (1, Length)) := Next (0, 100);
         end if;
         Report ((A in Sorted_Array) = Ref_Sorted (A), "Sorted_Array membership" & K'Image);
      end;
   end loop;
   --  Measured worst case 6, below the proved 7: 5 comparisons in the
   --  search happen only when it moves left every time (16 8 4 2 1 0),
   --  which ends at I = 0, where Lower and Upper need none; any other
   --  path takes at most 4, plus 2.
   Report (Max_Probes = 6, "worst case comparisons" & Max_Probes'Image & ", expected 6");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image
     & " checks (7,000 pairs vs an insertion sort of all 32 values: Lower, Upper, Median; comparisons <= 7, worst case 6; exact counts on 6 hand-worked paths; predicate)");
end Own_Checks;
