with Interfaces; use Interfaces;

package body ElGamal_Encryption is

   function Mod_Exp (Base, Exp : Plaintext_T) return Plaintext_T is
      Res  : Plaintext_T := 1;
      B    : Plaintext_T := Base;
      E    : Plaintext_T := Exp;
      M    : constant Unsigned_64 := Unsigned_64 (Modulus_Value);
      Prod : Unsigned_64;
   begin
      while E > 0 loop
         if E mod 2 = 1 then
            Prod := Unsigned_64 (Res) * Unsigned_64 (B);
            Res := Plaintext_T (Prod mod M);
         end if;
         Prod := Unsigned_64 (B) * Unsigned_64 (B);
         B := Plaintext_T (Prod mod M);
         E := E / 2;
      end loop;
      return Res;
   end Mod_Exp;

   function GCD (A, B : Plaintext_T) return Plaintext_T is
      X    : Plaintext_T := A;
      Y    : Plaintext_T := B;
      Temp : Plaintext_T;
   begin
      while Y /= 0 loop
         Temp := Y;
         Y := X mod Y;
         X := Temp;
      end loop;
      return X;
   end GCD;

   function Mod_Inverse (A : Plaintext_T) return Plaintext_T is
      T        : Integer := 0;
      New_T    : Integer := 1;
      R        : Integer := Modulus_Value;
      New_R    : Integer := Integer (A);
      Quotient : Integer;
      Temp     : Integer;
   begin
      while New_R /= 0 loop
         Quotient := R / New_R;

         Temp := New_T;
         New_T := T - Quotient * New_T;
         T := Temp;

         Temp := New_R;
         New_R := R - Quotient * New_R;
         R := Temp;
      end loop;

      if R > 1 then
         raise Invalid_Key_Error;
      end if;

      if T < 0 then
         T := T + Modulus_Value;
      end if;

      return Plaintext_T (T);
   end Mod_Inverse;

   procedure Generate_Keys (Generator   : in     Plaintext_T;
                            Private_Key : in     Plaintext_T;
                            Keys        :    out Key_Pair_T) is
   begin
      Keys.Generator := Generator;
      Keys.Private_Key := Private_Key;
      Keys.Public_Key := Mod_Exp (Generator, Private_Key);
   end Generate_Keys;

   function Encrypt (Message      : Plaintext_T;
                     Public_Key   : Plaintext_T;
                     Generator    : Plaintext_T;
                     Ephemeral_K  : Plaintext_T) return Ciphertext_T is
      C1    : Plaintext_T;
      C2    : Plaintext_T;
      S_Key : Plaintext_T;
   begin
      C1 := Mod_Exp (Generator, Ephemeral_K);
      S_Key := Mod_Exp (Public_Key, Ephemeral_K);
      C2 := Plaintext_T ((Unsigned_64 (Message) * Unsigned_64 (S_Key)) mod Unsigned_64 (Modulus_Value));
      return (C1 => C1, C2 => C2);
   end Encrypt;

   function Decrypt (Cipher      : Ciphertext_T;
                     Private_Key : Plaintext_T) return Plaintext_T is
      S_Key : Plaintext_T;
      S_Inv : Plaintext_T;
   begin
      if Cipher.C1 = 0 then
         raise Invalid_Ciphertext_Error;
      end if;
      S_Key := Mod_Exp (Cipher.C1, Private_Key);
      S_Inv := Mod_Inverse (S_Key);
      return Plaintext_T ((Unsigned_64 (Cipher.C2) * Unsigned_64 (S_Inv)) mod Unsigned_64 (Modulus_Value));
   end Decrypt;

   function Multiply_Ciphertexts (C1, C2 : Ciphertext_T) return Ciphertext_T is
      New_C1 : Plaintext_T;
      New_C2 : Plaintext_T;
      M      : constant Unsigned_64 := Unsigned_64 (Modulus_Value);
   begin
      New_C1 := Plaintext_T ((Unsigned_64 (C1.C1) * Unsigned_64 (C2.C1)) mod M);
      New_C2 := Plaintext_T ((Unsigned_64 (C1.C2) * Unsigned_64 (C2.C2)) mod M);
      return (C1 => New_C1, C2 => New_C2);
   end Multiply_Ciphertexts;

   function Sign (Message      : Plaintext_T;
                  Private_Key  : Plaintext_T;
                  Generator    : Plaintext_T;
                  Ephemeral_K  : Plaintext_T) return Signature_T is
      R      : Plaintext_T;
      S      : Plaintext_T;
      Mod_P1 : constant Plaintext_T := Plaintext_T (Modulus_Value - 1);

      function Mod_Inv_Sub (A_Val, Mod_Val : Plaintext_T) return Plaintext_T is
         T_Sub     : Integer := 0;
         New_T_Sub : Integer := 1;
         R_Sub     : Integer := Integer (Mod_Val);
         New_R_Sub : Integer := Integer (A_Val);
         Q_Sub     : Integer;
         Tmp_Sub   : Integer;
      begin
         while New_R_Sub /= 0 loop
            Q_Sub := R_Sub / New_R_Sub;
            Tmp_Sub := New_T_Sub;
            New_T_Sub := T_Sub - Q_Sub * New_T_Sub;
            T_Sub := Tmp_Sub;
            Tmp_Sub := New_R_Sub;
            New_R_Sub := R_Sub - Q_Sub * New_R_Sub;
            R_Sub := Tmp_Sub;
         end loop;
         if R_Sub > 1 then
            raise Invalid_Key_Error;
         end if;
         if T_Sub < 0 then
            T_Sub := T_Sub + Integer (Mod_Val);
         end if;
         return Plaintext_T (T_Sub);
      end Mod_Inv_Sub;

      Inv_K   : Plaintext_T;
      U_M     : Unsigned_64;
      U_R     : Unsigned_64;
      U_X     : Unsigned_64;
      U_S     : Unsigned_64;
      Prod_XR : Unsigned_64;
      Diff    : Unsigned_64;
   begin
      R := Mod_Exp (Generator, Ephemeral_K);
      Inv_K := Mod_Inv_Sub (Ephemeral_K, Mod_P1);
      U_M := Unsigned_64 (Message);
      U_X := Unsigned_64 (Private_Key);
      U_R := Unsigned_64 (R);
      
      Prod_XR := (U_X * U_R) mod Unsigned_64 (Mod_P1);
      if U_M >= Prod_XR then
         Diff := U_M - Prod_XR;
      else
         Diff := Unsigned_64 (Mod_P1) - ((Prod_XR - U_M) mod Unsigned_64 (Mod_P1));
      end if;
      U_S := (Diff * Unsigned_64 (Inv_K)) mod Unsigned_64 (Mod_P1);
      S := Plaintext_T (U_S);
      
      return (R => R, S => S);
   end Sign;

   function Verify (Message    : Plaintext_T;
                    Sig        : Signature_T;
                    Public_Key : Plaintext_T;
                    Generator  : Plaintext_T) return Boolean is
      V1        : Plaintext_T;
      V2_1      : Plaintext_T;
      V2_2      : Plaintext_T;
      V2_3      : Plaintext_T;
      M         : constant Unsigned_64 := Unsigned_64 (Modulus_Value);
   begin
      if Sig.R = 0 then
         return False;
      end if;
      
      V1 := Mod_Exp (Generator, Message);
      V2_1 := Mod_Exp (Public_Key, Sig.R);
      V2_2 := Mod_Exp (Sig.R, Sig.S);
      V2_3 := Plaintext_T ((Unsigned_64 (V2_1) * Unsigned_64 (V2_2)) mod M);
      
      return V1 = V2_3;
   end Verify;

end ElGamal_Encryption;
