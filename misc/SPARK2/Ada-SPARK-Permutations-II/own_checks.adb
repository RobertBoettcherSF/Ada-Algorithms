pragma Ada_2022;
--  Own checks for Permutations_II (see tests/SOURCES.txt). No expected
--  value comes from the program:
--  * an own recursive generator lists the distinct arrangements of a
--    multiset in dictionary order (at each position, each distinct value
--    still available, smallest first); stepping from the sorted list must
--    give the same sequence and then wrap around, on seeded random lists
--    of up to 7 items over few values;
--  * Count_Distinct against an own N! / (m1! m2! ..) in Long_Long_Integer
--    on seeded random lists of up to 12 items, and against the length of
--    the own enumeration;
--  * the ghost Fact_Table regenerated.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Permutations_II; use Permutations_II;

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
      Name : constant String := "Ada-SPARK-Permutations-II";
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

   function Own_Fact (N : Natural) return Long_Long_Integer is
      F : Long_Long_Integer := 1;
   begin
      for K in 2 .. N loop
         F := F * Long_Long_Integer (K);
      end loop;
      return F;
   end Own_Fact;

   function Own_Count (L : Value_Array) return Long_Long_Integer is
      D    : Long_Long_Integer := 1;
      Done : array (L'Range) of Boolean := [others => False];
      M    : Natural;
   begin
      for I in L'Range loop
         if not Done (I) then
            M := 0;
            for J in L'Range loop
               if L (J) = L (I) then
                  M := M + 1;
                  Done (J) := True;
               end if;
            end loop;
            D := D * Own_Fact (M);
         end if;
      end loop;
      return Own_Fact (L'Length) / D;
   end Own_Count;

   procedure Sort (L : in out Value_Array) is
      X : Integer;
   begin
      for I in L'Range loop
         for J in I + 1 .. L'Last loop
            if L (J) < L (I) then
               X := L (I);
               L (I) := L (J);
               L (J) := X;
            end if;
         end loop;
      end loop;
   end Sort;

   function Random_List (N, Spread : Natural) return Value_Array is
     ([for K in 1 .. N => Integer (Next mod Spread) - 1]);

   --  1. Own generator against stepping.
   procedure Enumerate (L : Value_Array) is
      Sorted : Value_Array := L;
      A      : Arrangement (L'Length);
      Buf    : Value_Array (1 .. L'Length);
      Left   : Value_Array (1 .. L'Length);
      Used   : array (1 .. L'Length) of Boolean := [others => False];
      Seen_N : Long_Long_Integer := 0;
      Done   : Boolean := False;
      procedure Visit (I : Positive) is
         Found : Boolean;
      begin
         if I > L'Length then
            Seen_N := Seen_N + 1;
            Report (not Done and then Values (A) = Buf, "enumeration #" & Seen_N'Image);
            Next_Permutation (A, Found);
            Report (Found = (Seen_N < Own_Count (L)), "Found #" & Seen_N'Image);
            Done := not Found;
         else
            for V in Left'Range loop
               --  Each distinct value once: skip a copy whose previous
               --  equal copy is still unused.
               if not Used (V) and then (V = Left'First or else Left (V - 1) /= Left (V) or else Used (V - 1)) then
                  Used (V) := True;
                  Buf (I) := Left (V);
                  Visit (I + 1);
                  Used (V) := False;
               end if;
            end loop;
         end if;
      end Visit;
   begin
      Sort (Sorted);
      Left := Sorted;
      A := Start (Sorted);
      Visit (1);
      Report (Seen_N = Own_Count (L) and then Done, "enumeration size");
      Report (Values (A) = Sorted, "wrap to sorted");
      if L'Length <= 12 then
         Report (Long_Long_Integer (Count_Distinct (Sorted)) = Seen_N, "Count_Distinct = enumeration");
      end if;
   end Enumerate;
begin
   for T in 1 .. 300 loop
      Enumerate (Random_List (Next mod 8, 1 + Next mod 4));
   end loop;

   --  2. Count_Distinct against the own formula, lists of up to 12 items.
   for T in 1 .. 2_000 loop
      declare
         L : constant Value_Array := Random_List (Next mod 13, 1 + Next mod 6);
      begin
         Report (Long_Long_Integer (Count_Distinct (L)) = Own_Count (L), "Count_Distinct" & L'Length'Image);
      end;
   end loop;

   --  3. The ghost table.
   for N in Count_Range loop
      pragma Assert (Long_Long_Integer (Fact_Table (N)) = Own_Fact (N));
      Checked := Checked + 1;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
