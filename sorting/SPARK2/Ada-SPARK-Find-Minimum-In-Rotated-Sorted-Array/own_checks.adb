--  Own tests for Find_Minimum_In_Rotated_Sorted_Array (written for this
--  repository; see tests/SOURCES.txt). Assumption: Find_Minimum returns
--  a position that does not hold the minimum, or Minimum returns a value
--  that is not the minimum, for some rotated strictly increasing array.
--  Reference: a linear scan for the smallest value, and the rotation
--  itself (the array is built by turning a known increasing Base by S
--  places, so Base (1) must be found at position ((32 - S) mod 32) + 1).
--  Inputs: every one of the 32 rotations of 4 fixed increasing arrays
--  and of 300 random increasing arrays (32 distinct values out of
--  0 .. 100, chosen by selection sampling). Is_Rotated_Sorted is checked
--  against a second rule (exactly one cyclic position K with
--  Data (K) >= Data (K mod 32 + 1)) on the rotations, on rotations with
--  two neighbours swapped or one value copied onto its neighbour, and on
--  random arrays.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Find_Minimum_In_Rotated_Sorted_Array; use Find_Minimum_In_Rotated_Sorted_Array;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646;
      end if;
      Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default)" else " (from AA_SEED)"));
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
         if Failures <= 10 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Second rule for "rotated strictly increasing": going round the
   --  array once, exactly one step does not increase.
   function One_Cyclic_Descent (D : Data_Array) return Boolean is
      Steps : Natural := 0;
   begin
      for K in Index loop
         if D (K) >= D (K mod Length + 1) then
            Steps := Steps + 1;
         end if;
      end loop;
      return Steps = 1;
   end One_Cyclic_Descent;

   function Linear_Min (D : Data_Array) return Value is
      M : Value := D (1);
   begin
      for K in Index loop
         if D (K) < M then
            M := D (K);
         end if;
      end loop;
      return M;
   end Linear_Min;

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

   function Turn (Base : Data_Array; S : Natural) return Data_Array is
     [for I in Index => Base (((I - 1 + S) mod Length) + 1)];

   procedure Check_Predicate (D : Data_Array; Label : String) is
   begin
      Report (Is_Rotated_Sorted (D) = One_Cyclic_Descent (D), "Is_Rotated_Sorted " & Label);
   end Check_Predicate;

   procedure Check_Base (Base : Data_Array; Label : String) is
   begin
      for S in 0 .. Length - 1 loop
         declare
            D     : constant Data_Array := Turn (Base, S);
            Where : constant Index := ((Length - S) mod Length) + 1;
            Tag   : constant String := Label & " turned" & S'Image;
            R     : Search_Result;
         begin
            Report (One_Cyclic_Descent (D) and then Is_Rotated_Sorted (D), "rotation accepted " & Tag);
            if Is_Rotated_Sorted (D) then
               R := Find_Minimum (D);
               Report (R.Position = Where, "position " & Tag & " got" & R.Position'Image);
               Report (D (R.Position) = Linear_Min (D) and then D (R.Position) = Base (1),
                       "value at position " & Tag);
               --  Cost bound for distinct values: floor (log2 N) + 2 probes
               --  (Floor_Log2 computed here by halving); with 32 = 2 ** 5
               --  candidates halved per probe it is exactly 5.
               Report (R.Probes <= Floor_Log2 (Length) + 2, "probe bound " & Tag & " got" & R.Probes'Image);
               Report (R.Probes = 5, "probes " & Tag & " got" & R.Probes'Image);
               Report (Minimum (D) = Linear_Min (D), "Minimum " & Tag);
            end if;
            --  Broken copies: two neighbours swapped, a value copied onto
            --  its neighbour.
            declare
               J : constant Index := Next (1, Length);
               N : constant Index := J mod Length + 1;
               X : Data_Array := D;
               T : Value;
            begin
               T := X (J);
               X (J) := X (N);
               X (N) := T;
               Check_Predicate (X, "swap " & Tag);
               X := D;
               X (N) := X (J);
               Check_Predicate (X, "copy " & Tag);
               Report (not Is_Rotated_Sorted (X), "copy rejected " & Tag);
            end;
         end;
      end loop;
   end Check_Base;

   function Random_Increasing return Data_Array is
      Result : Data_Array := [others => 0];
      Need   : Natural := Length;
      Pos    : Natural := 0;
   begin
      for V in Value loop
         if Need > 0 and then Next (1, Value'Last - V + 1) <= Need then
            Pos := Pos + 1;
            Result (Pos) := V;
            Need := Need - 1;
         end if;
      end loop;
      return Result;
   end Random_Increasing;
begin
   Check_Base ([for I in Index => I - 1], "0 .. 31");
   Check_Base ([for I in Index => 2 * (I - 1)], "0, 2 .. 62");
   Check_Base ([for I in Index => 68 + I], "69 .. 100");
   Check_Base ([for I in Index => 3 * I + 4], "7, 10 .. 100");
   for Run in 1 .. 300 loop
      declare
         B : constant Data_Array := Random_Increasing;
         Ok : Boolean := True;
      begin
         for K in 1 .. Length - 1 loop
            Ok := Ok and then B (K) < B (K + 1);
         end loop;
         Report (Ok, "random base" & Run'Image & " increasing");
         Check_Base (B, "random" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 2000 loop
      Check_Predicate ([for I in Index => Next (0, 100)], "random array" & Run'Image);
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (all 32 rotations of 304 increasing arrays: position, value, probes <= floor (log2 N) + 2 and = 5, Minimum; predicate on rotations, broken copies and random arrays)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
