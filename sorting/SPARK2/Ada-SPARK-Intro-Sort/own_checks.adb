--  Own property tests for Intro_Sort (written for this repository; see
--  tests/SOURCES.txt). Sort is checked as a sort. Partition_Range is the
--  Lomuto step Sort uses. Heapify is the Floyd build the heapsort
--  fallback uses. Sort_Limited (Depth_Budget) must not take that fallback;
--  Sort_Limited (0) and Sort_Limited (5) must.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Intro_Sort; use Intro_Sort;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   function Reference (A : Input_Array) return Input_Array is
      B : Input_Array := A;
      T : Value;
      J : Index;
   begin
      for I in Index'First + 1 .. Index'Last loop
         T := B (I);
         J := I;
         while J > Index'First and then B (J - 1) > T loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end Reference;

   function Heap_OK (A : Input_Array) return Boolean is
      Ok : Boolean := True;
   begin
      for I in Index loop
         if 2 * I in Index and then A (I) < A (2 * I) then
            Ok := False;
         end if;
         if 2 * I + 1 in Index and then A (I) < A (2 * I + 1) then
            Ok := False;
         end if;
      end loop;
      return Ok;
   end Heap_OK;

   function Sorted_OK (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1));

   Saw_Non_Heap : Boolean := False;
   Saw_Unsorted : Boolean := False;

   procedure Check_One (A : Input_Array; Label : String) is
      R : constant Input_Array := Sort (A);
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         if I < Index'Last and then R (I) > R (I + 1) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else R /= Reference (A) then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL own check (" & Label & ")");
         end if;
      end if;
   end Check_One;

   procedure Check_Partition (A : Input_Array; Label : String) is
      B : Input_Array := A;
      P : Index;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      Partition_Range (B, Index'First, Index'Last, P);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (B (I)) := C_Out (B (I)) + 1;
         if I < P and then B (I) > B (P) then
            Ok := False;
         end if;
         if I > P and then B (I) < B (P) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else B (P) /= A (Index'Last) then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL partition (" & Label & ")");
         end if;
      end if;
   end Check_Partition;

   procedure Check_Heap (A : Input_Array; Label : String) is
      B : Input_Array := A;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      if not Heap_OK (A) then
         Saw_Non_Heap := True;
      end if;
      Heapify (B);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (B (I)) := C_Out (B (I)) + 1;
      end loop;
      if C_In /= C_Out or else not Heap_OK (B) then
         Ok := False;
      end if;
      if Heap_OK (B) and then not Sorted_OK (B) then
         Saw_Unsorted := True;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL heapify (" & Label & ")");
         end if;
      end if;
   end Check_Heap;

   procedure Check_Budget (A : Input_Array; Limit : Depth; Expect_Fallback : Boolean; Label : String) is
      B : Input_Array;
      F : Natural;
   begin
      Cases := Cases + 1;
      Sort_Limited (A, Limit, B, F);
      if B /= Reference (A) or else (Expect_Fallback and then F < 1)
        or else (not Expect_Fallback and then F /= 0)
      then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL budget" & Limit'Image & " (" & Label & ") fallbacks" & F'Image);
         end if;
      end if;
   end Check_Budget;

   procedure Check_Layout_P
     (A : Input_Array; Expected : Input_Array; Expected_Pivot : Index; Label : String)
   is
      B : Input_Array := A;
      P : Index;
   begin
      Cases := Cases + 1;
      Partition_Range (B, Index'First, Index'Last, P);
      if B /= Expected or else P /= Expected_Pivot then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL partition layout (" & Label & ")");
         end if;
      end if;
   end Check_Layout_P;

   procedure Check_Layout_H (A, Expected : Input_Array; Label : String) is
      B : Input_Array := A;
   begin
      Cases := Cases + 1;
      Heapify (B);
      if Sorted_OK (Expected) or else B /= Expected or else not Heap_OK (B) then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL heapify layout (" & Label & ")");
         end if;
      else
         Saw_Unsorted := True;
      end if;
   end Check_Layout_H;

   A : Input_Array;
begin
   for Mask in 0 .. 2 ** Index'Last - 1 loop
      for I in Index loop
         A (I) := (if (Mask / 2 ** (I - 1)) mod 2 = 1 then 1 else 0);
      end loop;
      Check_One (A, "0/1 mask" & Mask'Image);
      Check_Partition (A, "0/1 mask" & Mask'Image);
      Check_Heap (A, "0/1 mask" & Mask'Image);
      Check_Budget (A, Depth_Budget, False, "0/1 mask" & Mask'Image);
      Check_Budget (A, 0, True, "0/1 depth 0" & Mask'Image);
   end loop;

   Check_One ([others => Value'First], "all First");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_One ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_One ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   Check_Partition ([others => Value'First], "all First");
   Check_Partition ([others => Value'Last], "all Last");
   Check_Partition ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_Partition ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_Partition ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   Check_Heap ([others => Value'First], "all First");
   Check_Heap ([others => Value'Last], "all Last");
   Check_Heap ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_Heap ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_Heap ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   Check_Budget ([1, 2, 3, 4, 5, 6, 7, 8], Depth_Budget, False, "ascending budget");
   Check_Budget ([8, 7, 6, 5, 4, 3, 2, 1], Depth_Budget, False, "reverse budget");
   Check_Budget ([1, 2, 3, 4, 5, 6, 7, 8], 0, True, "ascending heap fallback");
   Check_Budget ([1, 2, 3, 4, 5, 6, 7, 8], 5, True, "ascending slice heap");

   Check_Layout_P ([4, 1, 3, 2, 8, 5, 7, 6], [4, 1, 3, 2, 5, 6, 7, 8], 6, "hand 4 1 3 2 8 5 7 6");
   Check_Layout_P ([8, 7, 6, 5, 4, 3, 2, 1], [1, 7, 6, 5, 4, 3, 2, 8], 1, "hand reverse");
   Check_Layout_P ([23, 4, 17, 9, 1, 31, 12, 6], [4, 1, 6, 9, 23, 31, 12, 17], 3, "hand tests example");
   Check_Layout_H ([1, 2, 3, 4, 5, 6, 7, 8], [8, 5, 7, 4, 1, 6, 3, 2], "hand ascending");
   Check_Layout_H ([8, 7, 6, 5, 4, 3, 2, 1], [8, 7, 6, 5, 4, 3, 2, 1], "hand reverse");
   Check_Layout_H ([4, 1, 3, 2, 8, 5, 7, 6], [8, 6, 7, 4, 1, 5, 3, 2], "hand 4 1 3 2 8 5 7 6");
   Check_Layout_H ([23, 4, 17, 9, 1, 31, 12, 6], [31, 9, 23, 6, 1, 17, 12, 4], "hand tests example");
   if Heap_OK ([1, 2, 3, 4, 5, 6, 7, 8]) then
      Failures := Failures + 1;
      Put_Line ("  FAIL ascending input was already a max-heap");
   else
      Saw_Non_Heap := True;
   end if;
   Cases := Cases + 1;

   for K in 1 .. 2_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
      Check_Partition (A, "random" & K'Image);
      Check_Heap (A, "random" & K'Image);
      Check_Budget (A, Depth_Budget, False, "random" & K'Image);
   end loop;
   for K in 1 .. 1_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'First + 2);
      end loop;
      Check_One (A, "duplicates" & K'Image);
      Check_Partition (A, "duplicates" & K'Image);
      Check_Heap (A, "duplicates" & K'Image);
      Check_Budget (A, Depth_Budget, False, "duplicates" & K'Image);
   end loop;

   if not Saw_Non_Heap or else not Saw_Unsorted then
      Failures := Failures + 1;
      Cases := Cases + 1;
      Put_Line ("  FAIL heapify suite did not include a non-heap input and an unsorted heap");
   end if;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (sorted, permutation, own reference, partition, heapify, depth)");
end Own_Checks;
