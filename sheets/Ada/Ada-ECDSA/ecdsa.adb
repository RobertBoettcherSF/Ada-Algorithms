package body ECDSA is

   function Mod_Add (X, Y, M : Field_Element) return Field_Element is
   begin
      return (X + Y) mod M;
   end Mod_Add;

   function Mod_Sub (X, Y, M : Field_Element) return Field_Element is
      Res : Value_Type := (X - Y) mod M;
   begin
      if Res < 0 then
         Res := Res + M;
      end if;
      return Res;
   end Mod_Sub;

   function Mod_Mul (X, Y, M : Field_Element) return Field_Element is
   begin
      return (X * Y) mod M;
   end Mod_Mul;

   --  Calculates the modular inverse using the Extended Euclidean Algorithm
   function Mod_Inv (A, M : Field_Element) return Field_Element is
      T, New_T, Temp_T : Value_Type;
      R, New_R, Temp_R : Value_Type;
      Quotient         : Value_Type;
   begin
      T := 0; 
      New_T := 1;
      R := M; 
      New_R := A mod M;

      while New_R /= 0 loop
         Quotient := R / New_R;

         Temp_T := T - Quotient * New_T;
         T := New_T;
         New_T := Temp_T;

         Temp_R := R - Quotient * New_R;
         R := New_R;
         New_R := Temp_R;
      end loop;

      if R > 1 then
         raise Math_Error with "Value is not invertible";
      end if;

      if T < 0 then
         T := T + M;
      end if;

      return T;
   end Mod_Inv;

   function Point_Double (P1 : Point; Params : Domain_Parameters) return Point is
      M_Slope, X3, Y3 : Field_Element;
      Numerator, Denominator : Field_Element;
   begin
      if P1.Is_Infinity then
         return (Is_Infinity => True);
      end if;
      
      if P1.Y = 0 then
         return (Is_Infinity => True);
      end if;

      --  M = (3 * X1^2 + A) / (2 * Y1) mod P
      Numerator := Mod_Add (Mod_Mul (3, Mod_Mul (P1.X, P1.X, Params.P), Params.P), Params.A, Params.P);
      Denominator := Mod_Inv (Mod_Mul (2, P1.Y, Params.P), Params.P);
      M_Slope := Mod_Mul (Numerator, Denominator, Params.P);

      --  X3 = M^2 - 2*X1 mod P
      X3 := Mod_Sub (Mod_Mul (M_Slope, M_Slope, Params.P), Mod_Mul (2, P1.X, Params.P), Params.P);
      
      --  Y3 = M*(X1 - X3) - Y1 mod P
      Y3 := Mod_Sub (Mod_Mul (M_Slope, Mod_Sub (P1.X, X3, Params.P), Params.P), P1.Y, Params.P);

      return (Is_Infinity => False, X => X3, Y => Y3);
   end Point_Double;

   function Point_Add (P1, P2 : Point; Params : Domain_Parameters) return Point is
      M_Slope, X3, Y3 : Field_Element;
      Numerator, Denominator : Field_Element;
   begin
      if P1.Is_Infinity then
         return P2;
      end if;
      
      if P2.Is_Infinity then
         return P1;
      end if;

      if P1.X = P2.X then
         if P1.Y = P2.Y then
            return Point_Double (P1, Params);
         else
            return (Is_Infinity => True);
         end if;
      end if;

      --  M = (Y2 - Y1) / (X2 - X1) mod P
      Numerator := Mod_Sub (P2.Y, P1.Y, Params.P);
      Denominator := Mod_Inv (Mod_Sub (P2.X, P1.X, Params.P), Params.P);
      M_Slope := Mod_Mul (Numerator, Denominator, Params.P);

      --  X3 = M^2 - X1 - X2 mod P
      X3 := Mod_Sub (Mod_Sub (Mod_Mul (M_Slope, M_Slope, Params.P), P1.X, Params.P), P2.X, Params.P);
      
      --  Y3 = M*(X1 - X3) - Y1 mod P
      Y3 := Mod_Sub (Mod_Mul (M_Slope, Mod_Sub (P1.X, X3, Params.P), Params.P), P1.Y, Params.P);

      return (Is_Infinity => False, X => X3, Y => Y3);
   end Point_Add;

   --  Double-and-add algorithm for scalar multiplication
   function Scalar_Mult (K : Scalar; P1 : Point; Params : Domain_Parameters) return Point is
      Result : Point := (Is_Infinity => True);
      Base   : Point := P1;
      Temp_K : Scalar := K mod Params.N;
   begin
      if Temp_K = 0 or P1.Is_Infinity then
         return Result;
      end if;

      while Temp_K > 0 loop
         if (Temp_K mod 2) = 1 then
            Result := Point_Add (Result, Base, Params);
         end if;
         Base := Point_Double (Base, Params);
         Temp_K := Temp_K / 2;
      end loop;

      return Result;
   end Scalar_Mult;

   function Generate_Key (Params : Domain_Parameters; Private_D : Scalar) return Point is
   begin
      return Scalar_Mult (Private_D, Params.G, Params);
   end Generate_Key;

   function Sign
     (Params       : Domain_Parameters;
      Message_Hash : Scalar;
      Private_D    : Scalar;
      Nonce_K      : Scalar) return Signature
   is
      P1   : Point;
      R, S : Scalar;
      K_Inv : Scalar;
   begin
      --  1. Calculate curve point (X1, Y1) = K * G
      P1 := Scalar_Mult (Nonce_K, Params.G, Params);
      
      if P1.Is_Infinity then
         raise Retry_K_Error with "Point is at infinity, retry K";
      end if;

      --  2. Calculate R = X1 mod N
      R := P1.X mod Params.N;
      if R = 0 then
         raise Retry_K_Error with "R is zero, retry K";
      end if;

      --  3. Calculate S = K^-1 * (Hash + R * D) mod N
      K_Inv := Mod_Inv (Nonce_K, Params.N);
      S := Mod_Mul (K_Inv, Mod_Add (Message_Hash, Mod_Mul (R, Private_D, Params.N), Params.N), Params.N);
      
      if S = 0 then
         raise Retry_K_Error with "S is zero, retry K";
      end if;

      return (R => R, S => S);
   end Sign;

   function Verify
     (Params       : Domain_Parameters;
      Message_Hash : Scalar;
      Sig          : Signature;
      Public_Q     : Point) return Boolean
   is
      W, U1, U2 : Scalar;
      P1, P2, P3 : Point;
   begin
      --  1. Check R and S boundaries
      if Sig.R < 1 or Sig.R >= Params.N or Sig.S < 1 or Sig.S >= Params.N then
         return False;
      end if;

      --  2. Check Public Key validity broadly
      if Public_Q.Is_Infinity then
         return False;
      end if;

      --  3. Calculate W = S^-1 mod N
      begin
         W := Mod_Inv (Sig.S, Params.N);
      exception
         when Math_Error =>
            return False;
      end;

      --  4. Calculate U1 = (Hash * W) mod N and U2 = (R * W) mod N
      U1 := Mod_Mul (Message_Hash, W, Params.N);
      U2 := Mod_Mul (Sig.R, W, Params.N);

      --  5. Calculate P1 = U1 * G and P2 = U2 * Q
      P1 := Scalar_Mult (U1, Params.G, Params);
      P2 := Scalar_Mult (U2, Public_Q, Params);

      --  6. P3 = P1 + P2
      P3 := Point_Add (P1, P2, Params);

      if P3.Is_Infinity then
         return False;
      end if;

      --  7. The signature is valid if P3.X mod N = R
      return (P3.X mod Params.N) = Sig.R;
   end Verify;

end ECDSA;
