with Interfaces;
use type Interfaces.Unsigned_64;

package body Hamming_Distance is

   -----------------------------------------------------
   -- Variant 1: General String Hamming Distance
   -----------------------------------------------------
   function Distance (S1, S2 : String) return Natural is
      Dist : Natural := 0;
      Idx2 : Integer := S2'First; -- Track index separately to support slice mismatches
   begin
      if S1'Length /= S2'Length then
         raise Length_Mismatch_Error;
      end if;

      for Idx1 in S1'Range loop
         if S1 (Idx1) /= S2 (Idx2) then
            Dist := Dist + 1;
         end if;
         Idx2 := Idx2 + 1;
      end loop;

      return Dist;
   end Distance;

   -----------------------------------------------------
   -- Variant 2: Bit Array Hamming Distance
   -----------------------------------------------------
   function Distance (B1, B2 : Bit_Array) return Natural is
      Dist : Natural := 0;
      Idx2 : Integer := B2'First;
   begin
      if B1'Length /= B2'Length then
         raise Length_Mismatch_Error;
      end if;

      for Idx1 in B1'Range loop
         if B1 (Idx1) /= B2 (Idx2) then
            Dist := Dist + 1;
         end if;
         Idx2 := Idx2 + 1;
      end loop;

      return Dist;
   end Distance;

   -----------------------------------------------------
   -- Variant 3: Integer XOR Popcount (Brian Kernighan's Algorithm)
   -----------------------------------------------------
   function Distance (U1, U2 : Interfaces.Unsigned_64) return Natural is
      Diff  : Interfaces.Unsigned_64 := U1 xor U2;
      Count : Natural := 0;
   begin
      -- Helper logic: efficiently count set bits (popcount)
      -- This clears the lowest set bit in each iteration.
      while Diff /= 0 loop
         Diff  := Diff and (Diff - 1);
         Count := Count + 1;
      end loop;
      
      return Count;
   end Distance;

   -----------------------------------------------------
   -- Variant 4: Hamming Weight
   -----------------------------------------------------
   function Weight (S : String; Zero_Char : Character := ' ') return Natural is
      Count : Natural := 0;
   begin
      for Idx in S'Range loop
         if S (Idx) /= Zero_Char then
            Count := Count + 1;
         end if;
      end loop;
      
      return Count;
   end Weight;

end Hamming_Distance;
