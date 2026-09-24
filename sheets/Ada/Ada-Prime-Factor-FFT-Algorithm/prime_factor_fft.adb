with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Prime_Factor_FFT is

   use Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------
   -- Extended Euclidean Algorithm
   -------------------------------------------------------
   procedure Extended_GCD(A, B : Integer; G, X, Y : out Integer) is
      Old_R : Integer := A; R : Integer := B;
      Old_S : Integer := 1; S : Integer := 0;
      Old_T : Integer := 0; T : Integer := 1;
      Quotient, Temp : Integer;
   begin
      while R /= 0 loop
         Quotient := Old_R / R;
         
         Temp := R; R := Old_R - Quotient * R; Old_R := Temp;
         Temp := S; S := Old_S - Quotient * S; Old_S := Temp;
         Temp := T; T := Old_T - Quotient * T; Old_T := Temp;
      end loop;
      G := Old_R; X := Old_S; Y := Old_T;
   end Extended_GCD;

   -------------------------------------------------------
   -- Modular Inverse
   -------------------------------------------------------
   function Mod_Inverse(A, M : Integer) return Integer is
      G, X, Y : Integer;
   begin
      Extended_GCD(A, M, G, X, Y);
      if G /= 1 then
         raise Invalid_Factors with "Factors are not coprime (GCD != 1).";
      end if;
      return (X mod M + M) mod M;
   end Mod_Inverse;

   -------------------------------------------------------
   -- Naive DFT (O(N^2))
   -------------------------------------------------------
   function DFT_Naive (Input : Complex_Array; Inverse : Boolean := False) return Complex_Array is
      N : constant Natural := Input'Length;
      Output : Complex_Array(0 .. N - 1) := (others => (0.0, 0.0));
      Sign : constant Float := (if Inverse then 1.0 else -1.0);
      Angle : Float;
      W : Complex;
   begin
      if N = 0 then
         return Output;
      end if;

      for K in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Angle := Sign * 2.0 * Ada.Numerics.Pi * Float(K * J) / Float(N);
            W := (Cos(Angle), Sin(Angle));
            Output(K) := Output(K) + Input(Input'First + J) * W;
         end loop;
         
         if Inverse then
            Output(K) := (Output(K).Re / Float(N), Output(K).Im / Float(N));
         end if;
      end loop;
      
      return Output;
   end DFT_Naive;

   -------------------------------------------------------
   -- Prime-Factor Algorithm - Out-of-place variant
   -------------------------------------------------------
   function PFA_Transform (Input : Complex_Array; N1, N2 : Positive; Inverse : Boolean := False) return Complex_Array is
      N : constant Natural := N1 * N2;
      Output : Complex_Array(0 .. N - 1);
      Temp2D : array (0 .. N1 - 1, 0 .. N2 - 1) of Complex;
      
      N2_Inv_N1, N1_Inv_N2 : Integer;
      n_idx, k_idx : Integer;
      
      Row_In, Row_Out : Complex_Array(0 .. N1 - 1);
      Col_In, Col_Out : Complex_Array(0 .. N2 - 1);
   begin
      if Input'Length /= N then
         raise Invalid_Factors with "Input length must match N1 * N2.";
      end if;
      if N1 <= 1 or N2 <= 1 then
         raise Invalid_Factors with "Factors must be strictly greater than 1.";
      end if;

      -- Will raise Invalid_Factors if GCD(N1, N2) /= 1
      N2_Inv_N1 := Mod_Inverse(N2, N1);
      N1_Inv_N2 := Mod_Inverse(N1, N2); 

      -- 1. Input Mapping: Rader / Good-Thomas Mapping n = (Idx1*N2 + Idx2*N1) mod N
      for Idx1 in 0 .. N1 - 1 loop
         for Idx2 in 0 .. N2 - 1 loop
            n_idx := (Idx1 * N2 + Idx2 * N1) mod N;
            Temp2D(Idx1, Idx2) := Input(Input'First + n_idx);
         end loop;
      end loop;

      -- 2. Inner Transform: Compute DFT along N1 (rows)
      for Idx2 in 0 .. N2 - 1 loop
         for Idx1 in 0 .. N1 - 1 loop
            Row_In(Idx1) := Temp2D(Idx1, Idx2);
         end loop;
         Row_Out := DFT_Naive(Row_In, Inverse);
         for Idx1 in 0 .. N1 - 1 loop
            Temp2D(Idx1, Idx2) := Row_Out(Idx1);
         end loop;
      end loop;

      -- 3. Outer Transform: Compute DFT along N2 (cols)
      for Idx1 in 0 .. N1 - 1 loop
         for Idx2 in 0 .. N2 - 1 loop
            Col_In(Idx2) := Temp2D(Idx1, Idx2);
         end loop;
         Col_Out := DFT_Naive(Col_In, Inverse);
         for Idx2 in 0 .. N2 - 1 loop
            Temp2D(Idx1, Idx2) := Col_Out(Idx2);
         end loop;
      end loop;

      -- 4. Output Mapping: k = (k1*N2*N2_Inv_N1 + k2*N1*N1_Inv_N2) mod N
      for k1 in 0 .. N1 - 1 loop
         for k2 in 0 .. N2 - 1 loop
            k_idx := (k1 * N2 * N2_Inv_N1 + k2 * N1 * N1_Inv_N2) mod N;
            Output(k_idx) := Temp2D(k1, k2);
         end loop;
      end loop;

      return Output;
   end PFA_Transform;

   -------------------------------------------------------
   -- Prime-Factor Algorithm - In-place variant
   -------------------------------------------------------
   procedure PFA_Transform_In_Place (Data : in out Complex_Array; N1, N2 : Positive; Inverse : Boolean := False) is
      -- The pure Good-Thomas algorithm maps elements recursively to avoid auxiliary arrays.
      -- To avoid a highly complex O(N^2) cycle-leader permutation solver here, 
      -- we rely on the standard variant and copy back to strictly fulfill the in-place signature constraints.
      Temp : Complex_Array(0 .. Data'Length - 1);
   begin
      Temp := PFA_Transform(Data, N1, N2, Inverse);
      for I in 0 .. Data'Length - 1 loop
         Data(Data'First + I) := Temp(I);
      end loop;
   end PFA_Transform_In_Place;

end Prime_Factor_FFT;
