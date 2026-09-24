package body DSA is

   -- Use a local 64-bit type to prevent overflow during intermediate multiplications
   type U64 is new Interfaces.Unsigned_64;

   function Mod_Exp (Base, Exponent, Modulus : DSA_Value) return DSA_Value is
      Result : U64 := 1;
      B      : U64;
      E      : U64 := U64 (Exponent);
      M      : constant U64 := U64 (Modulus);
   begin
      if Modulus = 0 then
         raise Invalid_Parameter_Error with "Modulus cannot be zero";
      end if;

      B := U64 (Base) mod M;

      -- Binary exponentiation algorithm
      while E > 0 loop
         if (E and 1) = 1 then
            Result := (Result * B) mod M;
         end if;
         E := E / 2;
         B := (B * B) mod M;
      end loop;
      
      return DSA_Value (Result);
   end Mod_Exp;

   function Mod_Inverse (Value, Modulus : DSA_Value) return DSA_Value is
      -- Signed 64-bit integer needed to handle negative coefficients in the
      -- Extended Euclidean Algorithm steps.
      type Signed_64 is new Interfaces.Integer_64;
      T     : Signed_64 := 0;
      New_T : Signed_64 := 1;
      R     : Signed_64;
      New_R : Signed_64;
      Quotient, Temp : Signed_64;
   begin
      if Modulus = 0 or Value = 0 then
         raise Invalid_Parameter_Error with "Value and Modulus must be positive";
      end if;

      R     := Signed_64 (Modulus);
      New_R := Signed_64 (Value mod Modulus);

      while New_R /= 0 loop
         Quotient := R / New_R;

         Temp := T - Quotient * New_T;
         T := New_T;
         New_T := Temp;

         Temp := R - Quotient * New_R;
         R := New_R;
         New_R := Temp;
      end loop;

      if R > 1 then
         raise Invalid_Parameter_Error with "Value is not invertible";
      end if;

      if T < 0 then
         T := T + Signed_64 (Modulus);
      end if;

      return DSA_Value (T);
   end Mod_Inverse;

   function Generate_Key_Pair (Params : DSA_Parameters; X : DSA_Value) return Key_Pair is
   begin
      -- Enforce invariants dynamically to assist test coverage regardless of -gnata
      if Params.P = 0 or Params.Q = 0 or Params.G = 0 then
         raise Invalid_Parameter_Error with "Invalid domain parameters";
      end if;
      if X = 0 or X >= Params.Q then
         raise Invalid_Parameter_Error with "Private key out of bounds";
      end if;

      -- Public key Y = G^X mod P
      return (Params => Params,
              X      => X,
              Y      => Mod_Exp (Params.G, X, Params.P));
   end Generate_Key_Pair;

   function Sign_Standard
     (Params : DSA_Parameters;
      X      : DSA_Value;
      K      : DSA_Value;
      Hash   : DSA_Value) return Signature
   is
      R, S, K_Inv : DSA_Value;
      Temp_S : U64;
   begin
      if Params.P = 0 or Params.Q = 0 then
         raise Invalid_Parameter_Error with "Invalid domain parameters";
      end if;
      if X = 0 or X >= Params.Q then
         raise Invalid_Parameter_Error with "Private key out of bounds";
      end if;
      if K = 0 or K >= Params.Q then
         raise Invalid_Parameter_Error with "K value out of bounds";
      end if;

      -- Step 1: r = (g^k mod p) mod q
      R := Mod_Exp (Params.G, K, Params.P) mod Params.Q;
      if R = 0 then
         raise Generation_Error with "R is zero; must select a new K";
      end if;

      -- Step 2: Calculate modular inverse of K
      K_Inv := Mod_Inverse (K, Params.Q);

      -- Step 3: s = (k^-1 * (H(m) + x * r)) mod q
      Temp_S := (U64 (X) * U64 (R)) mod U64 (Params.Q);
      Temp_S := (U64 (Hash) + Temp_S) mod U64 (Params.Q);
      Temp_S := (U64 (K_Inv) * Temp_S) mod U64 (Params.Q);

      S := DSA_Value (Temp_S);
      if S = 0 then
         raise Generation_Error with "S is zero; must select a new K";
      end if;

      return (R => R, S => S);
   end Sign_Standard;

   function Sign_Deterministic
     (Params : DSA_Parameters;
      X      : DSA_Value;
      Hash   : DSA_Value) return Signature
   is
      K : DSA_Value;
   begin
      if Params.P = 0 or Params.Q = 0 or X = 0 or X >= Params.Q then
         raise Invalid_Parameter_Error with "Invalid input for deterministic signature";
      end if;

      -- Simulate RFC 6979 by generating a deterministic K from Private Key and Hash.
      -- Using XOR here because we lack a full SHA-256 HMAC implementation in this standalone block.
      K := (X xor Hash) mod Params.Q;
      if K = 0 then
         K := 1;
      end if;

      -- Try to sign. In the rare case of R=0 or S=0, loop deterministically.
      loop
         begin
            return Sign_Standard (Params, X, K, Hash);
         exception
            when Generation_Error =>
               K := (K + 1) mod Params.Q;
               if K = 0 then
                  K := 1;
               end if;
         end;
      end loop;
   end Sign_Deterministic;

   function Verify
     (Params : DSA_Parameters;
      Y      : DSA_Value;
      Hash   : DSA_Value;
      Sig    : Signature) return Boolean
   is
      W, U1, U2, V : DSA_Value;
      V_Temp1, V_Temp2, V_Total : U64;
   begin
      if Params.P = 0 or Params.Q = 0 or Y = 0 then
         return False;
      end if;

      -- Signatures must be within bounds 0 < R < Q and 0 < S < Q
      if Sig.R = 0 or Sig.R >= Params.Q or Sig.S = 0 or Sig.S >= Params.Q then
         return False;
      end if;

      begin
         -- w = s^-1 mod q
         W := Mod_Inverse (Sig.S, Params.Q);
      exception
         when Invalid_Parameter_Error =>
            return False; -- S was not invertible
      end;

      -- u1 = (H(m) * w) mod q
      U1 := DSA_Value ((U64 (Hash) * U64 (W)) mod U64 (Params.Q));
      
      -- u2 = (r * w) mod q
      U2 := DSA_Value ((U64 (Sig.R) * U64 (W)) mod U64 (Params.Q));

      -- v = ((g^u1 * y^u2) mod p) mod q
      V_Temp1 := U64 (Mod_Exp (Params.G, U1, Params.P));
      V_Temp2 := U64 (Mod_Exp (Y, U2, Params.P));
      V_Total := (V_Temp1 * V_Temp2) mod U64 (Params.P);

      V := DSA_Value (V_Total mod U64 (Params.Q));

      -- The signature is valid if v matches r
      return V = Sig.R;
   end Verify;

end DSA;
