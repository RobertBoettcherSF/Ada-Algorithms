--  Body of Exponentiating_By_Squaring (binary / square-and-multiply).

pragma Ada_2022;

package body Exponentiating_By_Squaring
  with SPARK_Mode => Off
is

   Counting_On : Boolean := False;
   Mul_Count   : Natural := 0;

   procedure Note_Mul is
   begin
      if Counting_On then
         if Mul_Count < Natural'Last then
            Mul_Count := Mul_Count + 1;
         end if;
      end if;
   end Note_Mul;

   function Mul (A, B : Long_Integer) return Long_Integer is
   begin
      Note_Mul;
      return A * B;
   end Mul;

   function Mul_F (A, B : Float) return Float is
   begin
      Note_Mul;
      return A * B;
   end Mul_F;

   ------------------------------------------------------------------
   -- Counter API
   ------------------------------------------------------------------

   procedure Reset_Multiplication_Count is
   begin
      Mul_Count := 0;
   end Reset_Multiplication_Count;

   procedure Enable_Counting (Enabled : Boolean) is
   begin
      Counting_On := Enabled;
   end Enable_Counting;

   function Counting_Enabled return Boolean is
   begin
      return Counting_On;
   end Counting_Enabled;

   function Multiplication_Count return Natural is
   begin
      return Mul_Count;
   end Multiplication_Count;

   ------------------------------------------------------------------
   -- Helpers
   ------------------------------------------------------------------

   function Abs_LI (X : Long_Integer) return Long_Integer is
   begin
      if X < 0 then
         return -X;
      else
         return X;
      end if;
   end Abs_LI;

   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer is
      R : Long_Integer;
   begin
      R := A rem M;
      if R < 0 then
         R := R + M;
      end if;
      return R;
   end Mod_Nonneg;

   function Mod_Mul (A, B, M : Long_Integer) return Long_Integer is
      AA : constant Long_Integer := Mod_Nonneg (A, M);
      BB : constant Long_Integer := Mod_Nonneg (B, M);
   begin
      Note_Mul;
      return Mod_Nonneg (AA * BB, M);
   end Mod_Mul;

   ------------------------------------------------------------------
   -- Recursive
   ------------------------------------------------------------------

   function Power_Recursive
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
   is
   begin
      if Exp = 0 then
         return 1;
      elsif Exp rem 2 = 0 then
         return Power_Recursive (Mul (Base, Base), Exp / 2);
      else
         --  Odd: Base * (Base^2)^((Exp-1)/2)
         return Mul
           (Base, Power_Recursive (Mul (Base, Base), (Exp - 1) / 2));
      end if;
   end Power_Recursive;

   ------------------------------------------------------------------
   -- Iterative right-to-left
   ------------------------------------------------------------------

   function Power_Iterative
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
   is
      X : Long_Integer := Base;
      N : Natural      := Exp;
      Y : Long_Integer := 1;
   begin
      if N = 0 then
         return 1;
      end if;
      loop
         if N rem 2 = 1 then
            Y := Mul (Y, X);
         end if;
         N := N / 2;
         exit when N = 0;
         X := Mul (X, X);
      end loop;
      return Y;
   end Power_Iterative;

   ------------------------------------------------------------------
   -- Iterative left-to-right
   ------------------------------------------------------------------

   function Power_Left_To_Right
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
   is
      Result : Long_Integer := 1;
      Bit    : Natural;
      Mask   : Natural;
   begin
      if Exp = 0 then
         return 1;
      end if;

      --  Highest bit position of Exp (0 = LSB).
      Bit := 0;
      declare
         T : Natural := Exp;
      begin
         while T > 1 loop
            T := T / 2;
            Bit := Bit + 1;
         end loop;
      end;

      --  Scan from MSB down to LSB.
      for K in reverse 0 .. Bit loop
         Result := Mul (Result, Result);
         Mask := 2 ** K;
         if (Exp / Mask) rem 2 = 1 then
            Result := Mul (Result, Base);
         end if;
      end loop;
      return Result;
   end Power_Left_To_Right;

   ------------------------------------------------------------------
   -- Naive oracle
   ------------------------------------------------------------------

   function Power_Naive
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
   is
      Result : Long_Integer := 1;
      K      : Natural := 0;
   begin
      if Exp > Max_Naive_Exp then
         raise Invalid_Argument;
      end if;
      while K < Exp loop
         Result := Mul (Result, Base);
         K := K + 1;
      end loop;
      return Result;
   end Power_Naive;

   ------------------------------------------------------------------
   -- Modular
   ------------------------------------------------------------------

   function Pow_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
   is
      X : Long_Integer;
      N : Long_Integer;
      Y : Long_Integer := 1;
   begin
      if Modulus <= 1 or else Exp < 0 then
         raise Invalid_Argument;
      end if;

      if Exp = 0 then
         return Mod_Nonneg (1, Modulus);
      end if;

      X := Mod_Nonneg (Base, Modulus);
      N := Exp;

      while N > 0 loop
         if N rem 2 = 1 then
            Y := Mod_Mul (Y, X, Modulus);
         end if;
         N := N / 2;
         if N > 0 then
            X := Mod_Mul (X, X, Modulus);
         end if;
      end loop;
      return Y;
   end Pow_Mod;

   ------------------------------------------------------------------
   -- Float (negative Exp → reciprocal power)
   ------------------------------------------------------------------

   function Power_Float
     (Base : Float;
      Exp  : Integer) return Float
   is
      function Pow_Nonneg (B : Float; E : Natural) return Float is
         X : Float   := B;
         N : Natural := E;
         Y : Float   := 1.0;
      begin
         if N = 0 then
            return 1.0;
         end if;
         loop
            if N rem 2 = 1 then
               Y := Mul_F (Y, X);
            end if;
            N := N / 2;
            exit when N = 0;
            X := Mul_F (X, X);
         end loop;
         return Y;
      end Pow_Nonneg;
   begin
      if Exp >= 0 then
         if Base = 0.0 and then Exp = 0 then
            return 1.0;  --  convention matching integer 0^0 := 1
         end if;
         return Pow_Nonneg (Base, Natural (Exp));
      else
         if Base = 0.0 then
            raise Invalid_Argument;
         end if;
         return Pow_Nonneg (1.0 / Base, Natural (-Exp));
      end if;
   end Power_Float;

   ------------------------------------------------------------------
   -- 2×2 matrix sketch
   ------------------------------------------------------------------

   function Identity_2x2 return Matrix_2x2 is
   begin
      return (A11 => 1, A12 => 0, A21 => 0, A22 => 1);
   end Identity_2x2;

   function Multiply_2x2 (Left, Right : Matrix_2x2) return Matrix_2x2 is
   begin
      Note_Mul;
      Note_Mul;
      Note_Mul;
      Note_Mul;
      --  Four scalar products in the usual formula (educational count).
      return
        (A11 => Left.A11 * Right.A11 + Left.A12 * Right.A21,
         A12 => Left.A11 * Right.A12 + Left.A12 * Right.A22,
         A21 => Left.A21 * Right.A11 + Left.A22 * Right.A21,
         A22 => Left.A21 * Right.A12 + Left.A22 * Right.A22);
   end Multiply_2x2;

   function Power_Matrix_2x2
     (M   : Matrix_2x2;
      Exp : Natural) return Matrix_2x2
   is
      X : Matrix_2x2 := M;
      N : Natural    := Exp;
      Y : Matrix_2x2 := Identity_2x2;
   begin
      if N = 0 then
         return Identity_2x2;
      end if;
      loop
         if N rem 2 = 1 then
            Y := Multiply_2x2 (Y, X);
         end if;
         N := N / 2;
         exit when N = 0;
         X := Multiply_2x2 (X, X);
      end loop;
      return Y;
   end Power_Matrix_2x2;

end Exponentiating_By_Squaring;
