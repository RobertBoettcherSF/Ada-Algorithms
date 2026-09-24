package body Diffie_Hellman is

   --  Helper: Safe Modular Multiplication using Russian Peasant algorithm.
   --  This ensures that multiplying two 64-bit unsigned integers does not overflow 
   --  the Unsigned_64 bounds during intermediate modulus calculations.
   function Mod_Mul_Safe (A, B, M : Unsigned_64) return Unsigned_64 is
      Result : Unsigned_64 := 0;
      X      : Unsigned_64 := A mod M;
      Y      : Unsigned_64 := B mod M;
   begin
      while Y > 0 loop
         if (Y and 1) = 1 then
            -- Safe addition: Result := (Result + X) mod M
            if Result >= M - X then
               Result := Result - (M - X);
            else
               Result := Result + X;
            end if;
         end if;

         -- Safe doubling: X := (X * 2) mod M
         if X >= M - X then
            X := X - (M - X);
         else
            X := X + X;
         end if;

         Y := Shift_Right (Y, 1);
      end loop;
      return Result;
   end Mod_Mul_Safe;

   --  Helper: Safe Modular Exponentiation using Right-to-Left Binary Method.
   function Mod_Exp (Base, Exp, Modulus : Unsigned_64) return Unsigned_64 is
      Result : Unsigned_64 := 1;
      B      : Unsigned_64 := Base mod Modulus;
      E      : Unsigned_64 := Exp;
   begin
      if Modulus = 1 then
         return 0;
      end if;
      
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mod_Mul_Safe (Result, B, Modulus);
         end if;
         B := Mod_Mul_Safe (B, B, Modulus);
         E := Shift_Right (E, 1);
      end loop;
      
      return Result;
   end Mod_Exp;

   -----------------------------------------------------------------------------
   -- Internal Validation Helpers to enforce constraints at runtime
   -----------------------------------------------------------------------------
   procedure Check_Parameters (P : Modulus_Type; G : Base_Type; Priv : Private_Key_Type) is
   begin
      if not Is_Valid_Modulus (P) then
         raise Invalid_Parameter with "Modulus must be > 2";
      end if;
      if not Is_Valid_Base (G, P) then
         raise Invalid_Parameter with "Base must be > 1 and < P-1";
      end if;
      if not Is_Valid_Private_Key (Priv, P) then
         raise Invalid_Parameter with "Private key must be > 0 and < P-1";
      end if;
   end Check_Parameters;

   procedure Check_Key_Exchange_Params (P : Modulus_Type; Pub : Public_Key_Type; Priv : Private_Key_Type) is
   begin
      if not Is_Valid_Modulus (P) then
         raise Invalid_Parameter with "Modulus must be > 2";
      end if;
      if not Is_Valid_Private_Key (Priv, P) then
         raise Invalid_Parameter with "Private key must be > 0 and < P-1";
      end if;
      -- Protections against Small Subgroup Attacks (NIST SP 800-56A compliant bounds)
      if not Is_Valid_Public_Key (Pub, P) then
         raise Invalid_Public_Key with "Public key must be > 1 and < P-1";
      end if;
   end Check_Key_Exchange_Params;

   -----------------------------------------------------------------------------
   -- Public API
   -----------------------------------------------------------------------------
   function Generate_Public_Key
     (P    : Modulus_Type;
      G    : Base_Type;
      Priv : Private_Key_Type) return Public_Key_Type
   is
   begin
      Check_Parameters (P, G, Priv);
      return Public_Key_Type (Mod_Exp (Unsigned_64 (G), Unsigned_64 (Priv), Unsigned_64 (P)));
   end Generate_Public_Key;

   function Compute_Shared_Secret
     (P          : Modulus_Type;
      Remote_Pub : Public_Key_Type;
      Priv       : Private_Key_Type) return Shared_Secret_Type
   is
   begin
      Check_Key_Exchange_Params (P, Remote_Pub, Priv);
      return Shared_Secret_Type (Mod_Exp (Unsigned_64 (Remote_Pub), Unsigned_64 (Priv), Unsigned_64 (P)));
   end Compute_Shared_Secret;

   function Compute_Multi_Party_Intermediate
     (P          : Modulus_Type;
      Remote_Pub : Public_Key_Type;
      Priv       : Private_Key_Type) return Public_Key_Type
   is
   begin
      Check_Key_Exchange_Params (P, Remote_Pub, Priv);
      return Public_Key_Type (Mod_Exp (Unsigned_64 (Remote_Pub), Unsigned_64 (Priv), Unsigned_64 (P)));
   end Compute_Multi_Party_Intermediate;

end Diffie_Hellman;
