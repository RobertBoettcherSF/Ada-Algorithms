package body BCH_Codes is

   -- GF(2^4) addition is bitwise XOR
   function GF_Add (A, B : GF_Element) return GF_Element is
   begin
      return A xor B;
   end GF_Add;

   -- GF(2^4) multiplication modulo x^4 + x + 1 (primitive polynomial, element 2 is alpha)
   function GF_Mul (A, B : GF_Element) return GF_Element is
      Res : GF_Element := 0;
      Temp_A : GF_Element := A;
      Temp_B : GF_Element := B;
   begin
      for I in 0 .. 3 loop
         if (Temp_B and 1) /= 0 then
            Res := Res xor Temp_A;
         end if;
         Temp_B := Temp_B / 2;
         declare
            High_Bit : constant GF_Element := Temp_A and 8;
         begin
            Temp_A := (Temp_A * 2) and 15;
            if High_Bit /= 0 then
               Temp_A := Temp_A xor 3;
            end if;
         end;
      end loop;
      return Res;
   end GF_Mul;

   function GF_Power (A : GF_Element; Power : Natural) return GF_Element is
      Res : GF_Element := 1;
      Base : GF_Element := A;
      P : Natural := Power;
   begin
      while P > 0 loop
         if P mod 2 = 1 then
            Res := GF_Mul (Res, Base);
         end if;
         Base := GF_Mul (Base, Base);
         P := P / 2;
      end loop;
      return Res;
   end GF_Power;

   function Encode (Msg : Message_Type) return Codeword_Type is
      Temp : Codeword_Type := [others => 0];
      CW   : Codeword_Type := [others => 0];
   begin
      for I in 1 .. K loop
         Temp (I) := Msg (I);
      end loop;
      
      for I in 1 .. K loop
         if Temp (I) = 1 then
            Temp (I)     := Temp (I) xor 1;
            Temp (I + 1) := Temp (I + 1) xor 1;
            Temp (I + 2) := Temp (I + 2) xor 1;
            Temp (I + 4) := Temp (I + 4) xor 1;
            Temp (I + 8) := Temp (I + 8) xor 1;
         end if;
      end loop;
      
      for I in 1 .. K loop
         CW (I) := Msg (I);
      end loop;
      for I in K + 1 .. N loop
         CW (I) := Temp (I);
      end loop;
      return CW;
   end Encode;

   function Is_Valid_Codeword (CW : Codeword_Type) return Boolean is
      Syms : constant Syndrome_Array := Compute_Syndromes (CW);
   begin
      for S of Syms loop
         if S /= 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Codeword;

   function Compute_Syndromes (CW : Codeword_Type) return Syndrome_Array is
      Syms : Syndrome_Array := [others => 0];
   begin
      for I in 1 .. 2 * T loop
         declare
            Alpha_I : constant GF_Element := GF_Power (2, I);
            Acc : GF_Element := 0;
         begin
            for J in Codeword_Type'Range loop
               if CW (J) = 1 then
                  Acc := GF_Add (Acc, GF_Power (Alpha_I, N - J));
               end if;
            end loop;
            Syms (I) := Acc;
         end;
      end loop;
      return Syms;
   end Compute_Syndromes;

   function Decode (Received : Codeword_Type) return Codeword_Type is
   begin
      if Is_Valid_Codeword (Received) then
         return Received;
      end if;
      
      -- Attempt single-error correction (brute-force Bounded Distance Decoding)
      for I in Codeword_Type'Range loop
         declare
            Test_CW : Codeword_Type := Received;
         begin
            Test_CW (I) := Test_CW (I) xor 1;
            if Is_Valid_Codeword (Test_CW) then
               return Test_CW;
            end if;
         end;
      end loop;

      -- Attempt double-error correction
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            declare
               Test_CW : Codeword_Type := Received;
            begin
               Test_CW (I) := Test_CW (I) xor 1;
               Test_CW (J) := Test_CW (J) xor 1;
               if Is_Valid_Codeword (Test_CW) then
                  return Test_CW;
               end if;
            end;
         end loop;
      end loop;

      -- No valid codeword found within distance t=2
      raise Decoding_Failed_Error;
   end Decode;

end BCH_Codes;
