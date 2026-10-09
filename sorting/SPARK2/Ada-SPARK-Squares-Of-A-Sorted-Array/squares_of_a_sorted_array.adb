pragma Ada_2022;
package body Squares_Of_A_Sorted_Array with SPARK_Mode => On is
   --  The loop invariants, assertions and the lemmas' contracts of this
   --  body count over all 1,025 square values at every step; they are
   --  proved by gnatprove and not checked at run time. The Post of Squares
   --  in the spec (sorted, same squares as A) is checked on every call.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);
   --  X <= Y implies X * X <= Y * Y for magnitudes
   procedure Lemma_Square_Mono (X, Y : Natural)
     with Ghost, Global => null, Pre => X <= Y and then Y <= 32, Post => X * X <= Y * Y
   is
   begin
      pragma Assert (X * X <= X * Y);
      pragma Assert (X * Y <= Y * Y);
   end Lemma_Square_Mono;

   --  Sq_Count can also be split at the low end
   procedure Sq_Left (A : Int_Array; Lo, Hi : Integer)
     with Ghost, Global => null,
          Pre  => Lo in Index and then Hi in Lo .. Length,
          Post => (for all V in Square_Value =>
                     Sq_Count (A, Lo, Hi, V)
                     = (if A (Lo) * A (Lo) = V then 1 else 0) + Sq_Count (A, Lo + 1, Hi, V)),
          Subprogram_Variant => (Decreases => Hi)
   is
   begin
      if Lo < Hi then
         Sq_Left (A, Lo, Hi - 1);
      end if;
   end Sq_Left;

   --  Count_Of only looks at R (Lo .. Hi)
   procedure Count_Frame (R1, R2 : Square_Array; Lo, Hi : Integer)
     with Ghost, Global => null,
          Pre  => Lo in 1 .. Length + 1 and then Hi in Lo - 1 .. Length
                  and then (for all K in Lo .. Hi => R1 (K) = R2 (K)),
          Post => (for all V in Square_Value =>
                     Count_Of (R1, Lo, Hi, V) = Count_Of (R2, Lo, Hi, V)),
          Subprogram_Variant => (Decreases => Hi - Lo)
   is
   begin
      if Lo <= Hi then
         Count_Frame (R1, R2, Lo + 1, Hi);
      end if;
   end Count_Frame;

   function Squares (A : Sorted_Array) return Square_Array is
      Result : Square_Array := [others => 0];
      L : Index := 1;          --  A (L .. R) is still to be placed
      R : Index := Length;
      Mag : Natural range 0 .. 32;             --  magnitude placed now
      Last_Mag : Natural range 0 .. 32 := 32;  --  magnitude placed at Pos + 1
   begin
      for Pos in reverse Index loop
         pragma Loop_Invariant (R - L = Pos - 1);
         pragma Loop_Invariant (for all K in L .. R => abs A (K) <= Last_Mag);
         pragma Loop_Invariant (Pos = Length or else Result (Pos + 1) = Last_Mag * Last_Mag);
         pragma Loop_Invariant (for all K in Pos + 1 .. Length - 1 => Result (K) <= Result (K + 1));
         pragma Loop_Invariant
           (for all V in Square_Value =>
              Count_Of (Result, Pos + 1, Length, V) + Sq_Count (A, L, R, V)
              = Sq_Count (A, 1, Length, V));
         declare
            Before : constant Square_Array := Result with Ghost;
            Old_L  : constant Index := L with Ghost;
            Old_R  : constant Index := R with Ghost;
         begin
         if abs A (L) > abs A (R) then
            Mag := abs A (L);
            pragma Assert (Mag * Mag = A (L) * A (L));
            if L < R then
               Sq_Left (A, L, R);
               L := L + 1;
            end if;
         else
            Mag := abs A (R);
            pragma Assert (Mag * Mag = A (R) * A (R));
            if L < R then
               R := R - 1;
            end if;
         end if;
         pragma Assert (Mag <= Last_Mag);
         Lemma_Square_Mono (Mag, Last_Mag);
         Result (Pos) := Mag * Mag;
         Last_Mag := Mag;
         Count_Frame (Before, Result, Pos + 1, Length);
         --  The square just placed left the window (or, at Pos = 1, was its
         --  last element)
         pragma Assert
           (for all V in Square_Value =>
              Count_Of (Result, Pos, Length, V)
              = (if Mag * Mag = V then 1 else 0) + Count_Of (Before, Pos + 1, Length, V));
         pragma Assert
           (if Pos > 1 then
              (for all V in Square_Value =>
                 Count_Of (Result, Pos, Length, V) + Sq_Count (A, L, R, V)
                 = Sq_Count (A, 1, Length, V)));
         pragma Assert
           (if Pos = 1 then
              Old_L = Old_R
              and then (for all V in Square_Value =>
                          Sq_Count (A, Old_L, Old_R, V) = (if Mag * Mag = V then 1 else 0))
              and then (for all V in Square_Value =>
                          Count_Of (Result, 1, Length, V) = Sq_Count (A, 1, Length, V)));
         end;
      end loop;
      return Result;
   end Squares;
end Squares_Of_A_Sorted_Array;
