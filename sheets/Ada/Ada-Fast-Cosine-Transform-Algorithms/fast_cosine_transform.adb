-- fast_cosine_transform.adb
-- Implementation of the FCT and its variants.

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Generic_Complex_Types;
with Ada.Numerics.Generic_Complex_Elementary_Functions;

package body Fast_Cosine_Transform is

   -- Instantiate Math for our custom Real type to resolve "Cos"
   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Math;

   -- Instantiate Complex Types and Math
   package Real_Complex is new Ada.Numerics.Generic_Complex_Types (Real);
   use Real_Complex;

   package Real_Complex_Math is new Ada.Numerics.Generic_Complex_Elementary_Functions (Real_Complex);
   use Real_Complex_Math;

   -- Define the missing Complex_Array type
   type Complex_Array is array (Integer range <>) of Complex;

   Pi : constant Real := Ada.Numerics.Pi;

   -----------------------
   -- Helper Functions --
   -----------------------

   function Is_Power_Of_Two (N : Natural) return Boolean is
      Temp : Natural := N;
   begin
      if Temp = 0 then
         return False;
      end if;
      -- Modulo division replaces the bitwise 'and' to stay strictly within standard Integer/Natural math
      while Temp mod 2 = 0 loop
         Temp := Temp / 2;
      end loop;
      return Temp = 1;
   end Is_Power_Of_Two;

   function Bit_Reverse (V : Natural; Bits : Natural) return Natural is
      Result : Natural := 0;
      Temp_V : Natural := V;
   begin
      for I in 1 .. Bits loop
         Result := Result * 2 + (Temp_V mod 2);
         Temp_V := Temp_V / 2;
      end loop;
      return Result;
   end Bit_Reverse;

   -- Standard Cooley-Tukey Radix-2 FFT (Decimation in Time)
   procedure In_Place_FFT (A : in out Complex_Array) is
      N : constant Integer := A'Length;
      Bits : Natural := 0;
      Temp : Integer := N;
   begin
      while Temp > 1 loop
         Bits := Bits + 1;
         Temp := Temp / 2;
      end loop;

      -- Bit-reversal permutation
      for I in 0 .. N - 1 loop
         declare
            Rev_I : constant Natural := Bit_Reverse (I, Bits);
         begin
            if I < Rev_I then
               declare
                  T : constant Complex := A(A'First + I);
               begin
                  A(A'First + I) := A(A'First + Rev_I);
                  A(A'First + Rev_I) := T;
               end;
            end if;
         end;
      end loop;

      -- Butterfly operations
      declare
         Step, Half_Step : Integer;
         W_M, W, T, U    : Complex;
      begin
         Step := 2;
         while Step <= N loop
            Half_Step := Step / 2;
            W_M := Compose_From_Polar (1.0, -2.0 * Pi / Real(Step));
            for K in 0 .. (N / Step) - 1 loop
               W := Compose_From_Polar (1.0, 0.0);
               for J in 0 .. Half_Step - 1 loop
                  declare
                     Idx1 : constant Integer := A'First + K * Step + J;
                     Idx2 : constant Integer := Idx1 + Half_Step;
                  begin
                     T := W * A(Idx2);
                     U := A(Idx1);
                     A(Idx1) := U + T;
                     A(Idx2) := U - T;
                  end;
                  W := W * W_M;
               end loop;
            end loop;
            Step := Step * 2;
         end loop;
      end;
   end In_Place_FFT;

   -----------------------------
   -- Fast O(N log N) DCT-II --
   -----------------------------
   -- Makhoul's Algorithm
   procedure Fast_DCT_II_Power_Of_2 (Input : in out Real_Array) is
      N : constant Integer := Input'Length;
      V : Complex_Array (0 .. N - 1);
   begin
      -- Reorder input sequence
      for I in 0 .. (N / 2) - 1 loop
         V(I)         := (Re => Input(Input'First + 2 * I), Im => 0.0);
         V(N - 1 - I) := (Re => Input(Input'First + 2 * I + 1), Im => 0.0);
      end loop;

      In_Place_FFT (V);

      -- Apply phase shift
      for K in 0 .. N - 1 loop
         declare
            Phase      : constant Real := -Pi * Real(K) / Real(2 * N);
            Multiplier : constant Complex := Compose_From_Polar (1.0, Phase);
            Res        : constant Complex := V(K) * Multiplier;
         begin
            Input(Input'First + K) := Res.Re;
         end;
      end loop;
   end Fast_DCT_II_Power_Of_2;

   ---------------------------------------
   -- Naive O(N^2) Fallback Procedures --
   ---------------------------------------
   
   procedure Transform_DCT_I (Input : in out Real_Array) is
      N : constant Integer := Input'Length;
      Result : Real_Array (Input'Range);
      Sum : Real;
   begin
      if N < 2 then
         raise Invalid_Argument_Error with "DCT-I requires array size >= 2";
      end if;
      for K in 0 .. N - 1 loop
         Sum := 0.5 * (Input(Input'First) + (if K mod 2 = 1 then -1.0 else 1.0) * Input(Input'Last));
         for N_Idx in 1 .. N - 2 loop
            Sum := Sum + Input(Input'First + N_Idx) * 
                   Cos(Pi * Real(N_Idx) * Real(K) / Real(N - 1));
         end loop;
         Result(Input'First + K) := Sum;
      end loop;
      Input := Result;
   end Transform_DCT_I;

   procedure Transform_DCT_II (Input : in out Real_Array) is
      N : constant Integer := Input'Length;
   begin
      if N = 0 then
         raise Invalid_Argument_Error with "Array cannot be empty";
      elsif N = 1 then
         return;
      end if;

      if Is_Power_Of_Two (N) then
         Fast_DCT_II_Power_Of_2 (Input);
      else
         declare
            Result : Real_Array (Input'Range);
            Sum : Real;
         begin
            for K in 0 .. N - 1 loop
               Sum := 0.0;
               for N_Idx in 0 .. N - 1 loop
                  Sum := Sum + Input(Input'First + N_Idx) * 
                         Cos(Pi * Real(K) * (Real(N_Idx) + 0.5) / Real(N));
               end loop;
               Result(Input'First + K) := Sum;
            end loop;
            Input := Result;
         end;
      end if;
   end Transform_DCT_II;

   procedure Transform_DCT_III (Input : in out Real_Array) is
      N : constant Integer := Input'Length;
      Result : Real_Array (Input'Range);
      Sum : Real;
   begin
      if N = 0 then raise Invalid_Argument_Error; end if;
      if N = 1 then return; end if;

      for K in 0 .. N - 1 loop
         Sum := 0.5 * Input(Input'First);
         for N_Idx in 1 .. N - 1 loop
            Sum := Sum + Input(Input'First + N_Idx) * 
                   Cos(Pi * Real(N_Idx) * (Real(K) + 0.5) / Real(N));
         end loop;
         Result(Input'First + K) := Sum;
      end loop;
      Input := Result;
   end Transform_DCT_III;

   procedure Transform_DCT_IV (Input : in out Real_Array) is
      N : constant Integer := Input'Length;
      Result : Real_Array (Input'Range);
      Sum : Real;
   begin
      if N = 0 then raise Invalid_Argument_Error; end if;
      if N = 1 then return; end if;

      for K in 0 .. N - 1 loop
         Sum := 0.0;
         for N_Idx in 0 .. N - 1 loop
            Sum := Sum + Input(Input'First + N_Idx) * 
                   Cos(Pi * (Real(N_Idx) + 0.5) * (Real(K) + 0.5) / Real(N));
         end loop;
         Result(Input'First + K) := Sum;
      end loop;
      Input := Result;
   end Transform_DCT_IV;

   -- Dispatcher
   procedure Transform (Input : in out Real_Array; Variant : Transform_Variant := DCT_II) is
   begin
      case Variant is
         when DCT_I   => Transform_DCT_I (Input);
         when DCT_II  => Transform_DCT_II (Input);
         when DCT_III => Transform_DCT_III (Input);
         when DCT_IV  => Transform_DCT_IV (Input);
      end case;
   end Transform;

end Fast_Cosine_Transform;
