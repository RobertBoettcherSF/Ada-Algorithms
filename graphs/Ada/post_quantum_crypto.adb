with Ada.Numerics.Discrete_Random;

package body Post_Quantum_Crypto is

   --  Internal PRNG isolated to this package body to ensure subprograms
   --  can maintain `Global => null` side-effect purity externally.
   package Element_RNG is new Ada.Numerics.Discrete_Random (Element);

   --  Helper: Samples a small noise factor (-1, 0, 1) mapping to Mod 256.
   function Sample_Error (Gen : in out Element_RNG.Generator) return Element is
      Val : constant Element := Element_RNG.Random (Gen);
   begin
      case Val mod 3 is
         when 0 => return 0;
         when 1 => return 1;
         when 2 => return 255; -- Represents -1 in modulo 256
         when others => return 0;
      end case;
   end Sample_Error;

   --  Helper: Samples uniformly distributed binary coefficients.
   function Sample_Bit (Gen : in out Element_RNG.Generator) return Element is
      Val : constant Element := Element_RNG.Random (Gen);
   begin
      return Val mod 2;
   end Sample_Bit;

   -----------------------------
   -- Generate_Keypair_Static --
   -----------------------------
   procedure Generate_Keypair_Static
     (A_Matrix : in Matrix_M_N;
      S_Vector : in Vector_N;
      E_Vector : in Vector_M;
      SK       : out Secret_Key;
      PK       : out Public_Key)
   is
      B_Vec : Vector_M := [others => 0];
   begin
      SK.S := S_Vector;
      PK.A := A_Matrix;
      
      --  Compute b = A*s + e
      for I in Index_M loop
         declare
            Sum : Element := 0;
         begin
            for J in Index_N loop
               Sum := Sum + A_Matrix (I, J) * S_Vector (J);
            end loop;
            B_Vec (I) := Sum + E_Vector (I);
         end;
      end loop;
      PK.B := B_Vec;
   end Generate_Keypair_Static;

   ----------------------
   -- Generate_Keypair --
   ----------------------
   procedure Generate_Keypair
     (Seed : in Integer;
      SK   : out Secret_Key;
      PK   : out Public_Key)
   is
      Gen   : Element_RNG.Generator;
      A_Mat : Matrix_M_N;
      S_Vec : Vector_N;
      E_Vec : Vector_M;
   begin
      Element_RNG.Reset (Gen, Seed);

      for I in Index_M loop
         for J in Index_N loop
            A_Mat (I, J) := Element_RNG.Random (Gen);
         end loop;
      end loop;

      for J in Index_N loop
         S_Vec (J) := Element_RNG.Random (Gen);
      end loop;

      for I in Index_M loop
         E_Vec (I) := Sample_Error (Gen);
      end loop;

      Generate_Keypair_Static (A_Mat, S_Vec, E_Vec, SK, PK);
   end Generate_Keypair;

   -----------------
   -- Encrypt_Bit --
   -----------------
   function Encrypt_Bit
     (Seed : in Integer;
      PK   : in Public_Key;
      Bit  : in Message_Bit) return Ciphertext
   is
      Gen   : Element_RNG.Generator;
      R_Vec : Vector_M;
      U_Vec : Vector_N := [others => 0];
      V_Val : Element := 0;
      CT    : Ciphertext;
   begin
      Element_RNG.Reset (Gen, Seed);

      --  Sample random coefficient vector r
      for I in Index_M loop
         R_Vec (I) := Sample_Bit (Gen);
      end loop;

      --  Compute u = A^T * r
      for J in Index_N loop
         for I in Index_M loop
            U_Vec (J) := U_Vec (J) + PK.A (I, J) * R_Vec (I);
         end loop;
      end loop;

      --  Compute v = b^T * r + m * (q/2)
      for I in Index_M loop
         V_Val := V_Val + PK.B (I) * R_Vec (I);
      end loop;

      if Bit = 1 then
         V_Val := V_Val + 128; -- 128 is q/2 for modulo 256
      end if;

      CT.U := U_Vec;
      CT.V := V_Val;
      return CT;
   end Encrypt_Bit;

   -----------------
   -- Decrypt_Bit --
   -----------------
   function Decrypt_Bit
     (SK : in Secret_Key;
      CT : in Ciphertext) return Message_Bit
   is
      Inner_Prod : Element := 0;
      Diff       : Element;
   begin
      --  Compute u * s
      for J in Index_N loop
         Inner_Prod := Inner_Prod + CT.U (J) * SK.S (J);
      end loop;

      --  Compute phase difference: v - u * s
      Diff := CT.V - Inner_Prod;

      --  Decode: if distance to 128 is smaller than distance to 0/256, it's 1.
      --  [64, 192] threshold handles accumulated errors up to +/- 64 correctly.
      if Diff >= 64 and then Diff <= 192 then
         return 1;
      else
         return 0;
      end if;
   end Decrypt_Bit;

   ---------------------
   -- Encrypt_Message --
   ---------------------
   function Encrypt_Message
     (Seed : in Integer;
      PK   : in Public_Key;
      Msg  : in Bit_Array) return Ciphertext_Array
   is
      Result : Ciphertext_Array (Msg'Range);
   begin
      --  Failsafe for caller bypassing Pre aspect
      if Msg'Length = 0 then
         raise Crypto_Error with "Empty message array";
      end if;

      for I in Msg'Range loop
         --  Mutate seed per bit to guarantee unique randomness (r vector) per bit
         Result (I) := Encrypt_Bit (Seed + Integer (I mod 10_000), PK, Msg (I));
      end loop;
      
      return Result;
   end Encrypt_Message;

   ---------------------
   -- Decrypt_Message --
   ---------------------
   function Decrypt_Message
     (SK  : in Secret_Key;
      CTs : in Ciphertext_Array) return Bit_Array
   is
      Result : Bit_Array (CTs'Range);
   begin
      if CTs'Length = 0 then
         raise Crypto_Error with "Empty ciphertext array";
      end if;

      for I in CTs'Range loop
         Result (I) := Decrypt_Bit (SK, CTs (I));
      end loop;
      
      return Result;
   end Decrypt_Message;

end Post_Quantum_Crypto;
