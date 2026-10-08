-- ziggurat.adb
-- Ziggurat Algorithm Package Body
-- Includes precomputed tables generation and Marsaglia's tail evaluations.

with Ada.Numerics.Generic_Elementary_Functions;
with Interfaces;

package body Ziggurat is
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;
   use Interfaces;

   -- Ziggurat configuration constants based on 256 rectangles (Standard Marsaglia parameters)
   R_Norm : constant Real := 3.6541528853610088;
   V_Norm : constant Real := 0.00492867323399;

   R_Exp  : constant Real := 7.69711747013104972;
   V_Exp  : constant Real := 0.0039496598225815571993;

   -- Precomputed tables for rectangle widths (X)
   X_Norm : array (0 .. 256) of Real;
   X_Exp  : array (0 .. 256) of Real;

   -- 64-bit XorShift Pseudo-Random Number Generator state
   -- Used instead of standard Ada.Numerics to guarantee bit-level determinism 
   -- across platforms and allow ultra-fast generation.
   PRNG_State : Unsigned_64 := 88172645463325252;

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------
   
   -- Fast uniform unsigned 64-bit integer generator
   function Next_U64 return Unsigned_64 is
      X : Unsigned_64 := PRNG_State;
   begin
      X := X xor Shift_Left(X, 13);
      X := X xor Shift_Right(X, 7);
      X := X xor Shift_Left(X, 17);
      PRNG_State := X;
      return X;
   end Next_U64;

   -- Generates a float in the range [0.0, 1.0)
   function Random_Float_0_To_1 return Real is
   begin
      return Real(Next_U64) / 18446744073709551616.0;
   end Random_Float_0_To_1;

   -- Generates a float in the range (-1.0, 1.0)
   function Random_Float_Minus1_To_1 return Real is
   begin
      return (Real(Next_U64) / 18446744073709551616.0) * 2.0 - 1.0;
   end Random_Float_Minus1_To_1;

   -- Generates an integer in the range [0, 255]
   function Random_Int_0_To_255 return Integer is
   begin
      return Integer (Next_U64 and 255);
   end Random_Int_0_To_255;

   -----------------------------------------------------------------------------
   -- Table Initialization
   -----------------------------------------------------------------------------
   
   procedure Initialize (Seed : Integer := 1) is
   begin
      -- Seed the PRNG safely, avoiding zero state
      PRNG_State := Unsigned_64(Seed) * 6364136223846793005 + 1442695040888963407;
      if PRNG_State = 0 then
         PRNG_State := 1;
      end if;
      
      -- Mix the state a bit
      for I in 1 .. 10 loop
         PRNG_State := Next_U64;
      end loop;

      -- Initialize Normal Tables (256 rectangles)
      X_Norm(256) := 0.0;
      X_Norm(1) := R_Norm;
      X_Norm(0) := V_Norm / Exp(-0.5 * R_Norm * R_Norm);
      for I in 2 .. 255 loop
         X_Norm(I) := Sqrt(-2.0 * Log(V_Norm / X_Norm(I-1) + Exp(-0.5 * X_Norm(I-1) * X_Norm(I-1))));
      end loop;

      -- Initialize Exponential Tables (256 rectangles)
      X_Exp(256) := 0.0;
      X_Exp(1) := R_Exp;
      X_Exp(0) := V_Exp / Exp(-R_Exp);
      for I in 2 .. 255 loop
         X_Exp(I) := -Log(V_Exp / X_Exp(I-1) + Exp(-X_Exp(I-1)));
      end loop;
   end Initialize;

   -----------------------------------------------------------------------------
   -- Core Algorithms
   -----------------------------------------------------------------------------
   
   function Random_Normal return Real is
      I : Integer;
      U, Val, U1, Y : Real;
      X_Tail, Y_Tail : Real;
   begin
      loop
         I := Random_Int_0_To_255;
         U := Random_Float_Minus1_To_1;
         Val := U * X_Norm(I);

         -- 1. Fast acceptance inside the rectangular boundary
         if abs Val < X_Norm(I+1) then
            return Val;
         end if;

         -- 2. Base layer: Generate from the tail
         if I = 0 then
            loop
               U1 := Random_Float_0_To_1;
               Y  := Random_Float_0_To_1;
               -- Edge Case Protection: Avoid Log(0.0)
               if U1 > 0.0 and Y > 0.0 then
                  X_Tail := -Log(U1) / R_Norm;
                  Y_Tail := -Log(Y);
                  if 2.0 * Y_Tail > X_Tail * X_Tail then
                     if U > 0.0 then
                        return R_Norm + X_Tail;
                     else
                        return -(R_Norm + X_Tail);
                     end if;
                  end if;
               end if;
            end loop;
         else
            -- 3. Wedge rejection sampling (Check if inside the distribution curve)
            U1 := Random_Float_0_To_1;
            Y := Exp(-0.5 * X_Norm(I) * X_Norm(I)) + 
                 U1 * (Exp(-0.5 * X_Norm(I+1) * X_Norm(I+1)) - Exp(-0.5 * X_Norm(I) * X_Norm(I)));
            if Y < Exp(-0.5 * Val * Val) then
               return Val;
            end if;
         end if;
      end loop;
   end Random_Normal;

   function Random_Exponential return Real is
      I : Integer;
      U, Val, U1, Y : Real;
      U_Tail : Real;
   begin
      loop
         I := Random_Int_0_To_255;
         U := Random_Float_0_To_1;
         Val := U * X_Exp(I);

         -- 1. Fast acceptance
         if Val < X_Exp(I+1) then
            return Val;
         end if;

         -- 2. Base layer: Evaluate tail
         if I = 0 then
            loop
               U_Tail := Random_Float_0_To_1;
               -- Edge Case Protection: Avoid Log(0.0)
               if U_Tail > 0.0 then
                  return R_Exp - Log(U_Tail);
               end if;
            end loop;
         else
            -- 3. Wedge rejection sampling
            U1 := Random_Float_0_To_1;
            Y := Exp(-X_Exp(I)) + U1 * (Exp(-X_Exp(I+1)) - Exp(-X_Exp(I)));
            if Y < Exp(-Val) then
               return Val;
            end if;
         end if;
      end loop;
   end Random_Exponential;

begin
   -- Auto-initialize tables during elaboration
   Initialize (123456789);
end Ziggurat;
