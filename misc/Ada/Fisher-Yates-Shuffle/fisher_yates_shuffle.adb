--  Fisher_Yates_Shuffle body — modern in-place Fisher–Yates (Durstenfeld).

pragma Ada_2022;

with Interfaces; use Interfaces;

package body Fisher_Yates_Shuffle
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- 64-bit LCG (Knuth MMIX multiplier)
   --   State := State * 6364136223846793005 + 1
   -- Period 2^64; good enough for educational reproducible shuffles.
   ---------------------------------------------------------------------------

   Multiplier : constant Unsigned_64 := 6_364_136_223_846_793_005;
   Increment  : constant Unsigned_64 := 1;

   procedure Next_State (Seed : in out Unsigned_64) is
   begin
      Seed := Seed * Multiplier + Increment;
   end Next_State;

   --  Uniform integer in Lo .. Hi inclusive from the LCG stream.
   function Next_Index
     (Seed : in out Unsigned_64; Lo, Hi : Natural) return Natural
   is
      Span : constant Natural := Hi - Lo;
      R    : Unsigned_64;
      Off  : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      Next_State (Seed);
      R := Seed;
      --  Modular reduction: exact when (Hi−Lo+1) | 2^64; negligible bias
      --  for educational sizes ≪ 2^64. Algorithm itself is unbiased iff
      --  each draw is uniform on A'First .. I.
      Off := Natural (R mod Unsigned_64 (Span + 1));
      return Lo + Off;
   end Next_Index;

   procedure Swap (A : in out Element_Array; X, Y : Natural) is
      T : constant Integer := A (X);
   begin
      A (X) := A (Y);
      A (Y) := T;
   end Swap;

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument;
      end if;
   end Check_Length;

   ---------------------------------------------------------------------------
   -- Shuffle (seeded LCG)
   ---------------------------------------------------------------------------

   procedure Shuffle
     (A    : in out Element_Array;
      Seed : in out Unsigned_64)
   is
      J : Natural;
   begin
      Check_Length (A);
      if A'Length <= 1 then
         return;
      end if;

      for I in reverse A'First + 1 .. A'Last loop
         J := Next_Index (Seed, A'First, I);
         if J /= I then
            Swap (A, X => J, Y => I);
         end if;
      end loop;
   end Shuffle;

   ---------------------------------------------------------------------------
   -- Shuffle (access-to-function RNG)
   ---------------------------------------------------------------------------

   procedure Shuffle
     (A    : in out Element_Array;
      Next : access function (Lo, Hi : Natural) return Natural)
   is
      J : Natural;
   begin
      Check_Length (A);
      if Next = null then
         raise Invalid_Argument;
      end if;
      if A'Length <= 1 then
         return;
      end if;

      for I in reverse A'First + 1 .. A'Last loop
         J := Next (A'First, I);
         if J < A'First or else J > I then
            raise Invalid_Argument;
         end if;
         if J /= I then
            Swap (A, X => J, Y => I);
         end if;
      end loop;
   end Shuffle;

   ---------------------------------------------------------------------------
   -- Is_Permutation_Of (same multiset)
   ---------------------------------------------------------------------------

   procedure Sort_Copy (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Integer := A (I);
            J   : Integer := Integer (I) - 1;
         begin
            while J >= Integer (A'First) and then A (J) > Key loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
   end Sort_Copy;

   function Is_Permutation_Of
     (A, Original : Element_Array) return Boolean
   is
   begin
      if A'Length /= Original'Length then
         return False;
      end if;
      if A'Length = 0 then
         return True;
      end if;

      declare
         X : Element_Array := A;
         Y : Element_Array := Original;
      begin
         Sort_Copy (X);
         Sort_Copy (Y);
         for I in X'Range loop
            if X (I) /= Y (I - X'First + Y'First) then
               return False;
            end if;
         end loop;
         return True;
      end;
   end Is_Permutation_Of;

end Fisher_Yates_Shuffle;
