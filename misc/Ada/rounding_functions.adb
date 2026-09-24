--  Rounding_Functions body — directed + tie-breaking modes (educational).

pragma Ada_2022;

package body Rounding_Functions
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Internal domain / conversion helpers
   ---------------------------------------------------------------------------

   procedure Require_In_Domain (X : Long_Float) is
   begin
      if not In_Domain (X) then
         raise Out_Of_Range;
      end if;
   end Require_In_Domain;

   --  Toward-zero integer image.
   --  IMPORTANT (teaching point): Ada's Integer (X) for a floating X
   --  *rounds* (typically half-away-from-zero), it does NOT truncate.
   --  Use Long_Float'Truncation, then convert the exact integer-valued
   --  Long_Float to Integer. Call only after Require_In_Domain.
   function Toward_Zero (X : Long_Float) return Integer is
   begin
      return Integer (Long_Float'Truncation (X));
   end Toward_Zero;

   --  True when X equals its toward-zero integer image exactly.
   function Exact_Integer_Image (X : Long_Float; T : Integer) return Boolean is
   begin
      return X = Long_Float (T);
   end Exact_Integer_Image;

   --  Even / odd test on Integer (works for negatives: (−4) mod 2 = 0).
   function Is_Even (K : Integer) return Boolean is
   begin
      return K mod 2 = 0;
   end Is_Even;

   ---------------------------------------------------------------------------
   -- Public helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float;
      Tol  : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Sign (X : Long_Float) return Long_Float is
   begin
      if X > 0.0 then
         return 1.0;
      elsif X < 0.0 then
         return -1.0;
      else
         return 0.0;
      end if;
   end Sign;

   function In_Domain (X : Long_Float) return Boolean is
   begin
      return abs (X) <= Max_Abs_Arg;
   end In_Domain;

   function Truncate (X : Long_Float) return Integer is
   begin
      Require_In_Domain (X);
      return Toward_Zero (X);
   end Truncate;

   function Frac (X : Long_Float) return Long_Float is
      T : Integer;
   begin
      Require_In_Domain (X);
      T := Toward_Zero (X);
      return X - Long_Float (T);
   end Frac;

   function Floor (X : Long_Float) return Integer is
      T : Integer;
   begin
      Require_In_Domain (X);
      --  Educational definition from truncate:
      --    ⌊X⌋ = Truncate(X)           if X ≥ 0 or X is integer
      --    ⌊X⌋ = Truncate(X) − 1       if X < 0 and not integer
      --  Equivalently: largest integer ≤ X (toward −∞).
      T := Toward_Zero (X);
      if X >= 0.0 or else Exact_Integer_Image (X, T) then
         return T;
      else
         return T - 1;
      end if;
   end Floor;

   function Ceiling (X : Long_Float) return Integer is
      T : Integer;
   begin
      Require_In_Domain (X);
      --  Educational definition from truncate:
      --    ⌈X⌉ = Truncate(X)           if X ≤ 0 or X is integer
      --    ⌈X⌉ = Truncate(X) + 1       if X > 0 and not integer
      --  Equivalently: smallest integer ≥ X (toward +∞).
      --  Duality: ⌈X⌉ = −⌊−X⌋.
      T := Toward_Zero (X);
      if X <= 0.0 or else Exact_Integer_Image (X, T) then
         return T;
      else
         return T + 1;
      end if;
   end Ceiling;

   function Floor_Frac (X : Long_Float) return Long_Float is
   begin
      return X - Long_Float (Floor (X));
   end Floor_Frac;

   function Is_Integer (X : Long_Float) return Boolean is
      T : Integer;
   begin
      if not In_Domain (X) then
         return False;
      end if;
      T := Toward_Zero (X);
      return Exact_Integer_Image (X, T);
   end Is_Integer;

   function Is_Half_Tie (X : Long_Float) return Boolean is
   begin
      if not In_Domain (X) then
         return False;
      end if;
      --  {X} = X − ⌊X⌋ equals 1/2 exactly on a half-tie.
      return Floor_Frac (X) = 0.5;
   end Is_Half_Tie;

   function Round_Away_From_Zero (X : Long_Float) return Integer is
   begin
      Require_In_Domain (X);
      --  sgn(X)·⌈|X|⌉ : if X ≥ 0 then Ceiling else Floor.
      if X >= 0.0 then
         return Ceiling (X);
      else
         return Floor (X);
      end if;
   end Round_Away_From_Zero;

   ---------------------------------------------------------------------------
   -- Tie-breaking nearest modes
   ---------------------------------------------------------------------------

   function Round_Half_Up (X : Long_Float) return Integer is
   begin
      --  ⌊X + 1/2⌋ — ties always move toward +∞.
      --  Examples: 23.5 → 24, −23.5 → −23.
      return Floor (X + 0.5);
   end Round_Half_Up;

   function Round_Half_Down (X : Long_Float) return Integer is
   begin
      --  ⌈X − 1/2⌉ — ties always move toward −∞.
      --  Examples: 23.5 → 23, −23.5 → −24.
      return Ceiling (X - 0.5);
   end Round_Half_Down;

   function Round_Half_Away_From_Zero (X : Long_Float) return Integer is
   begin
      Require_In_Domain (X);
      --  School rule: on a .5 tie, step away from zero.
      --  Equiv.: sgn(X)·⌊|X| + 1/2⌋.
      if X >= 0.0 then
         return Floor (X + 0.5);
      else
         return Ceiling (X - 0.5);
      end if;
   end Round_Half_Away_From_Zero;

   function Round_Half_Toward_Zero (X : Long_Float) return Integer is
   begin
      Require_In_Domain (X);
      --  On a .5 tie, step toward zero.
      --  Equiv.: sgn(X)·⌈|X| − 1/2⌉.
      if X >= 0.0 then
         return Ceiling (X - 0.5);
      else
         return Floor (X + 0.5);
      end if;
   end Round_Half_Toward_Zero;

   function Round_Half_To_Even (X : Long_Float) return Integer is
      F : Integer;
      R : Long_Float;
   begin
      Require_In_Domain (X);
      --  Banker's / convergent / Gaussian rounding:
      --    let F = ⌊X⌋, r = X − F ∈ [0,1)
      --    if r < 1/2 → F; if r > 1/2 → F+1;
      --    if r = 1/2 → even of {F, F+1}.
      F := Floor (X);
      R := X - Long_Float (F);
      if R < 0.5 then
         return F;
      elsif R > 0.5 then
         return F + 1;
      else
         --  Exact half-tie: choose the even neighbour.
         if Is_Even (F) then
            return F;
         else
            return F + 1;
         end if;
      end if;
   end Round_Half_To_Even;

   function Round_Half_To_Odd (X : Long_Float) return Integer is
      F : Integer;
      R : Long_Float;
   begin
      Require_In_Domain (X);
      F := Floor (X);
      R := X - Long_Float (F);
      if R < 0.5 then
         return F;
      elsif R > 0.5 then
         return F + 1;
      else
         if not Is_Even (F) then
            return F;
         else
            return F + 1;
         end if;
      end if;
   end Round_Half_To_Odd;

   ---------------------------------------------------------------------------
   -- Decimal-place rounding
   ---------------------------------------------------------------------------

   function Ten_Pow (N : Decimal_Count) return Long_Float is
      P : Long_Float := 1.0;
   begin
      for I in 1 .. N loop
         P := P * 10.0;
      end loop;
      return P;
   end Ten_Pow;

   function Round_To_Decimals
     (X : Long_Float;
      N : Decimal_Count) return Long_Float
   is
      Scale : constant Long_Float := Ten_Pow (N);
      Y     : constant Long_Float := X * Scale;
   begin
      --  Half-away-from-zero on the scaled value (common display rule).
      return Long_Float (Round_Half_Away_From_Zero (Y)) / Scale;
   end Round_To_Decimals;

   function Round_To_Decimals_Even
     (X : Long_Float;
      N : Decimal_Count) return Long_Float
   is
      Scale : constant Long_Float := Ten_Pow (N);
      Y     : constant Long_Float := X * Scale;
   begin
      return Long_Float (Round_Half_To_Even (Y)) / Scale;
   end Round_To_Decimals_Even;

end Rounding_Functions;
