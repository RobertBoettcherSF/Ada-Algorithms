package body Key_Exchange is

   use type Interfaces.Integer_64;

   -- Internal type for calculations that double the bit-width to prevent overflow
   type Double_Value is new Interfaces.Unsigned_64;

   --------------------------------------------------------------------------
   -- 1. Core Mathematical Utilities
   --------------------------------------------------------------------------

   function Modular_Add (A, B, Modulus : Key_Value) return Key_Value is
      Sum : constant Double_Value := Double_Value (A) + Double_Value (B);
   begin
      return Key_Value (Sum mod Double_Value (Modulus));
   end Modular_Add;

   function Modular_Multiply (A, B, Modulus : Key_Value) return Key_Value is
      Prod : constant Double_Value := Double_Value (A) * Double_Value (B);
   begin
      return Key_Value (Prod mod Double_Value (Modulus));
   end Modular_Multiply;

   function Modular_Exponentiation (Base, Exponent, Modulus : Key_Value) return Key_Value is
      Result : Double_Value := 1;
      B      : Double_Value := Double_Value (Base) mod Double_Value (Modulus);
      E      : Double_Value := Double_Value (Exponent);
      M      : constant Double_Value := Double_Value (Modulus);
   begin
      if M = 1 then
         return 0;
      end if;

      -- Standard Right-to-Left Binary Exponentiation
      while E > 0 loop
         if (E and 1) = 1 then
            Result := (Result * B) mod M;
         end if;
         B := (B * B) mod M;
         E := E / 2;
      end loop;

      return Key_Value (Result);
   end Modular_Exponentiation;

   function Modular_Inverse (Value, Modulus : Key_Value) return Key_Value is
      -- Uses the Extended Euclidean Algorithm. Needs signed integers for intermediates.
      T, New_T       : Interfaces.Integer_64 := 0;
      R, New_R       : Interfaces.Integer_64 := 0;
      Quotient, Temp : Interfaces.Integer_64 := 0;
   begin
      T := 0; 
      New_T := 1;
      
      R := Interfaces.Integer_64 (Modulus);
      New_R := Interfaces.Integer_64 (Value);

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
         raise Invalid_Parameters_Error with "Value and Modulus are not coprime";
      end if;

      if T < 0 then
         T := T + Interfaces.Integer_64 (Modulus);
      end if;

      return Key_Value (T);
   end Modular_Inverse;

   --------------------------------------------------------------------------
   -- 2. Diffie-Hellman Key Exchange
   --------------------------------------------------------------------------

   function DH_Generate_Public (Generator, Private_Key, Prime : Key_Value) return Key_Value is
   begin
      return Modular_Exponentiation (Generator, Private_Key, Prime);
   end DH_Generate_Public;

   function DH_Compute_Secret (Remote_Public, Local_Private, Prime : Key_Value) return Key_Value is
   begin
      return Modular_Exponentiation (Remote_Public, Local_Private, Prime);
   end DH_Compute_Secret;

   procedure DH_Validate_Public_Key (Public_Key, Prime : Key_Value) is
   begin
      -- Check for invalid public keys that fall into small subgroups,
      -- severely weakening the security of the shared secret.
      if Public_Key <= 1 or else Public_Key >= Prime - 1 then
         raise Invalid_Parameters_Error with "Public key fails validation check (subgroup attack risk)";
      end if;
   end DH_Validate_Public_Key;

   --------------------------------------------------------------------------
   -- 3. Password-Authenticated Diffie-Hellman Key Exchange (SPEKE)
   --------------------------------------------------------------------------

   function PAKA_Generate_Public (Password, Private_Key, Prime : Key_Value) return Key_Value is
   begin
      -- SPEKE utilizes the password directly as the base generator.
      return DH_Generate_Public (Generator   => Password,
                                 Private_Key => Private_Key,
                                 Prime       => Prime);
   end PAKA_Generate_Public;

   function PAKA_Compute_Secret (Remote_Public, Local_Private, Prime, Password : Key_Value) return Key_Value is
      pragma Unreferenced (Password);
   begin
      -- Computing the SPEKE secret is mathematically identical to standard DH.
      return DH_Compute_Secret (Remote_Public => Remote_Public,
                                Local_Private => Local_Private,
                                Prime         => Prime);
   end PAKA_Compute_Secret;

   --------------------------------------------------------------------------
   -- 4. Shamir's Three-Pass Protocol
   --------------------------------------------------------------------------

   procedure Shamir_Generate_Keys (Prime, E_Key : Key_Value; D_Key : out Key_Value) is
      Totient : constant Key_Value := Prime - 1;
   begin
      -- D_Key * E_Key = 1 mod (Prime - 1)
      D_Key := Modular_Inverse (E_Key, Totient);
   end Shamir_Generate_Keys;

   function Shamir_Pass_1 (Message, Local_E, Prime : Key_Value) return Key_Value is
   begin
      return Modular_Exponentiation (Message, Local_E, Prime);
   end Shamir_Pass_1;

   function Shamir_Pass_2 (Cipher_1, Remote_E, Prime : Key_Value) return Key_Value is
   begin
      return Modular_Exponentiation (Cipher_1, Remote_E, Prime);
   end Shamir_Pass_2;

   function Shamir_Pass_3 (Cipher_2, Local_D, Prime : Key_Value) return Key_Value is
   begin
      return Modular_Exponentiation (Cipher_2, Local_D, Prime);
   end Shamir_Pass_3;

   function Shamir_Final_Decrypt (Cipher_3, Remote_D, Prime : Key_Value) return Key_Value is
   begin
      return Modular_Exponentiation (Cipher_3, Remote_D, Prime);
   end Shamir_Final_Decrypt;

end Key_Exchange;
