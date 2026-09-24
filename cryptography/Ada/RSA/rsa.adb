package body RSA is

   function To_RSA (Value : Integer) return RSA_Integer is
   begin
      return To_Big_Integer (Value);
   end To_RSA;

   function To_RSA (Value : String) return RSA_Integer is
   begin
      return From_String (Value);
   end To_RSA;

   function Modular_Exponentiation (Base, Exponent, Modulus : RSA_Integer) return RSA_Integer is
      Result : RSA_Integer := One;
      B      : RSA_Integer := Base mod Modulus;
      Exp    : RSA_Integer := Exponent;
   begin
      -- Standard Right-to-Left Binary Exponentiation
      while Exp > Zero loop
         if Exp mod Two = One then
            Result := (Result * B) mod Modulus;
         end if;
         Exp := Exp / Two;
         B := (B * B) mod Modulus;
      end loop;
      return Result;
   end Modular_Exponentiation;

   function GCD (A, B : RSA_Integer) return RSA_Integer is
      Old_R : RSA_Integer := A;
      R     : RSA_Integer := B;
      Temp  : RSA_Integer;
   begin
      while R /= Zero loop
         Temp := R;
         R := Old_R mod R;
         Old_R := Temp;
      end loop;
      return Old_R;
   end GCD;

   function Extended_GCD (A, B : RSA_Integer; X, Y : out RSA_Integer) return RSA_Integer is
      Old_R : RSA_Integer := A;
      R     : RSA_Integer := B;
      Old_S : RSA_Integer := One;
      S     : RSA_Integer := Zero;
      Old_T : RSA_Integer := Zero;
      T     : RSA_Integer := One;
      Quotient, Temp : RSA_Integer;
   begin
      -- Iterative extended Euclidean computation
      while R /= Zero loop
         Quotient := Old_R / R;

         Temp := R;
         R := Old_R - Quotient * R;
         Old_R := Temp;

         Temp := S;
         S := Old_S - Quotient * S;
         Old_S := Temp;

         Temp := T;
         T := Old_T - Quotient * T;
         Old_T := Temp;
      end loop;

      X := Old_S;
      Y := Old_T;
      return Old_R;
   end Extended_GCD;

   function LCM (A, B : RSA_Integer) return RSA_Integer is
      Divisor : RSA_Integer;
   begin
      Divisor := GCD (A, B);
      if Divisor = Zero then
         return Zero;
      end if;
      return (A / Divisor) * B;
   end LCM;

   function Modular_Inverse (A, M : RSA_Integer) return RSA_Integer is
      X, Y, GCD_Val : RSA_Integer;
   begin
      GCD_Val := Extended_GCD (A, M, X, Y);
      if GCD_Val /= One then
         raise Math_Error with "Modular inverse does not exist; numbers are not coprime.";
      end if;
      -- Ensure positive modular inverse
      return (X mod M + M) mod M;
   end Modular_Inverse;

   function Generate_Key_Pair (P, Q, E : RSA_Integer) return Key_Pair is
      N        : RSA_Integer;
      Lambda_N : RSA_Integer;
      D        : RSA_Integer;
   begin
      N := P * Q;

      -- Carmichael's totient function: lambda(n) = lcm(p-1, q-1)
      Lambda_N := LCM (P - One, Q - One);

      -- Public exponent E must be coprime to Lambda_N
      if GCD (E, Lambda_N) /= One then
         raise Invalid_Key_Error with "E and Lambda(N) are not coprime.";
      end if;

      D := Modular_Inverse (E, Lambda_N);

      return Key_Pair'(
         Pub  => Public_Key'(N => N, E => E),
         Priv => Private_Key'(N => N, D => D)
      );
   end Generate_Key_Pair;

   function Encrypt (Plaintext : RSA_Integer; Key : Public_Key) return RSA_Integer is
   begin
      if Plaintext >= Key.N then
         raise Message_Too_Large_Error with "Plaintext must be strictly less than N.";
      end if;
      return Modular_Exponentiation (Plaintext, Key.E, Key.N);
   end Encrypt;

   function Decrypt (Ciphertext : RSA_Integer; Key : Private_Key) return RSA_Integer is
   begin
      if Ciphertext >= Key.N then
         raise Message_Too_Large_Error with "Ciphertext must be strictly less than N.";
      end if;
      return Modular_Exponentiation (Ciphertext, Key.D, Key.N);
   end Decrypt;

   function Decrypt_Blinded (Ciphertext : RSA_Integer; Key : Private_Key; Pub_E : RSA_Integer; R : RSA_Integer) return RSA_Integer is
      -- Factor r^e mod N
      R_E       : constant RSA_Integer := Modular_Exponentiation (R, Pub_E, Key.N);
      -- Blinded ciphertext: (C * r^e) mod N
      C_Blinded : constant RSA_Integer := (Ciphertext * R_E) mod Key.N;
      -- Perform standard exponentiation on blinded value: (C_Blinded)^d mod N
      M_Blinded : constant RSA_Integer := Modular_Exponentiation (C_Blinded, Key.D, Key.N);
      -- Factor r^-1 mod N
      R_Inv     : constant RSA_Integer := Modular_Inverse (R, Key.N);
      -- Unblind the result
      M         : constant RSA_Integer := (M_Blinded * R_Inv) mod Key.N;
   begin
      return M;
   end Decrypt_Blinded;

   function Sign (Message : RSA_Integer; Key : Private_Key) return RSA_Integer is
   begin
      if Message >= Key.N then
         raise Message_Too_Large_Error with "Message must be strictly less than N.";
      end if;
      -- Signing is mathematically identical to decryption (Message^D mod N)
      return Modular_Exponentiation (Message, Key.D, Key.N);
   end Sign;

   function Verify (Signature : RSA_Integer; Message : RSA_Integer; Key : Public_Key) return Boolean is
      Computed_Msg : RSA_Integer;
   begin
      if Signature >= Key.N or Message >= Key.N then
         return False;
      end if;
      -- Verification is computationally identical to encryption
      Computed_Msg := Modular_Exponentiation (Signature, Key.E, Key.N);
      return Computed_Msg = Message;
   end Verify;

end RSA;
