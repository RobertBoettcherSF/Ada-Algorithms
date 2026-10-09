pragma Ada_2022;
--  Own checks for Permutations (see tests/SOURCES.txt). No expected value
--  comes from the program:
--  * an own recursive generator (smallest unused item first) lists every
--    permutation of N <= 6 in dictionary order; stepping from Identity
--    must give the same list, then wrap around;
--  * an own rank (Lehmer code in the factorial number system, N <= 20 in
--    Long_Long_Integer): on seeded random permutations, the rank of the
--    next permutation is the rank plus 1, and the last one (rank N! - 1)
--    wraps to rank 0;
--  * Count against an own product, and the ghost Fact_Table regenerated.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Permutations; use Permutations;

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
      Name : constant String := "Ada-SPARK-Permutations";
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

   --  Own rank: the Lehmer code read in the factorial number system.
   function Own_Rank (A : Index_Array) return Long_Long_Integer is
      R : Long_Long_Integer := 0;
      Smaller : Natural;
   begin
      for I in A'Range loop
         Smaller := 0;
         for K in I + 1 .. A'Last loop
            if A (K) < A (I) then
               Smaller := Smaller + 1;
            end if;
         end loop;
         R := R * Long_Long_Integer (A'Last - I + 1) + Long_Long_Integer (Smaller);
      end loop;
      return R;
   end Own_Rank;

   function Own_Fact (N : Natural) return Long_Long_Integer is
      F : Long_Long_Integer := 1;
   begin
      for K in 2 .. N loop
         F := F * Long_Long_Integer (K);
      end loop;
      return F;
   end Own_Fact;

   --  1. Own generator against stepping, N = 0 .. 6.
   procedure Enumerate (N : Natural) is
      P     : Perm := Identity (N);
      Buf   : Index_Array (1 .. N);
      Used  : array (1 .. N) of Boolean := [others => False];
      Seen  : Natural := 0;
      Done  : Boolean := False;
      procedure Visit (I : Positive) is
         Found : Boolean;
      begin
         if I > N then
            Seen := Seen + 1;
            Report (not Done and then P.Order = Buf, "enumeration N =" & N'Image & " #" & Seen'Image);
            Next_Permutation (P, Found);
            Report (Found = (Long_Long_Integer (Seen) < Own_Fact (N)), "Found N =" & N'Image & " #" & Seen'Image);
            Done := not Found;
         else
            for V in 1 .. N loop
               if not Used (V) then
                  Used (V) := True;
                  Buf (I) := V;
                  Visit (I + 1);
                  Used (V) := False;
               end if;
            end loop;
         end if;
      end Visit;
   begin
      Visit (1);
      Report (Long_Long_Integer (Seen) = Own_Fact (N) and then Done, "count N =" & N'Image);
      Report (P.Order = Identity (N).Order, "wrap N =" & N'Image);
   end Enumerate;
begin
   for N in 0 .. 6 loop
      Enumerate (N);
   end loop;

   --  2. Rank + 1 on random permutations of 2 .. 20 items (own shuffle).
   for T in 1 .. 2_000 loop
      declare
         N  : constant Positive := 2 + Next mod 19;
         A  : Index_Array (1 .. N) := [for K in 1 .. N => K];
         Pl : Index_Array (1 .. N);
         Found : Boolean;
      begin
         if T mod 50 = 0 then
            A := [for K in 1 .. N => N + 1 - K];     --  the last one
         else
            for I in reverse 2 .. N loop
               declare
                  J : constant Positive := 1 + Next mod I;
                  X : constant Positive := A (I);
               begin
                  A (I) := A (J);
                  A (J) := X;
               end;
            end loop;
         end if;
         for K in 1 .. N loop
            Pl (A (K)) := K;
         end loop;
         declare
            P : Perm := (N => N, Order => A, Place => Pl);
            R : constant Long_Long_Integer := Own_Rank (A);
         begin
            Next_Permutation (P, Found);
            if R = Own_Fact (N) - 1 then
               Report (not Found and then Own_Rank (P.Order) = 0, "wrap rank N =" & N'Image);
            else
               Report (Found and then Own_Rank (P.Order) = R + 1, "rank + 1 N =" & N'Image & " T =" & T'Image);
            end if;
            for K in 1 .. N loop
               Report (P.Place (P.Order (K)) = K, "inverse kept");
            end loop;
         end;
      end;
   end loop;

   --  3. Count and the ghost table.
   for N in Count_Range loop
      Report (Long_Long_Integer (Count (N)) = Own_Fact (N), "Count" & N'Image);
      pragma Assert (Long_Long_Integer (Fact_Table (N)) = Own_Fact (N));
   end loop;
   Report (Own_Fact (13) > Long_Long_Integer (Natural'Last), "13! does not fit Natural");

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
