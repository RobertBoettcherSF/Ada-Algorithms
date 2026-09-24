package body Tiny_Encryption_Algorithm is
   use Interfaces;

   --  The magic constant used in the key scheduling (derived from the golden ratio).
   TEA_Delta : constant Word := 16#9E3779B9#;

   -----------------------------------------------------------------------------
   --  XXTEA Core Mixing Function (MX)
   -----------------------------------------------------------------------------

   --  This function encapsulates the complex shift, XOR, and add operations
   --  used internally during the XXTEA passes.
   function MX (Z, Y, Sum : Word; P : Natural; E : Word; Key : Key_128) return Word
     with Inline;

   function MX (Z, Y, Sum : Word; P : Natural; E : Word; Key : Key_128) return Word is
      Term1   : constant Word := Shift_Right (Z, 5) xor Shift_Left (Y, 2);
      Term2   : constant Word := Shift_Right (Y, 3) xor Shift_Left (Z, 4);
      Term3   : constant Word := Sum xor Y;
      Key_Idx : constant Natural := Natural ((Word (P) and 3) xor E);
      Term4   : constant Word := Key (Key_Idx) xor Z;
   begin
      --  Parentheses ensure the precise order of operations, mitigating Ada's
      --  distinct operator precedence rules (compared to C) and avoiding warnings.
      return (Term1 + Term2) xor (Term3 + Term4);
   end MX;

   -----------------------------------------------------------------------------
   --  TEA Implementation
   -----------------------------------------------------------------------------

   procedure TEA_Encrypt (Data : in out Block_64; Key : Key_128) is
      V0  : Word := Data (0);
      V1  : Word := Data (1);
      Sum : Word := 0;
   begin
      for I in 1 .. 32 loop
         pragma Unreferenced (I);
         Sum := Sum + TEA_Delta;
         V0  := V0 + (((Shift_Left (V1, 4) + Key (0)) xor (V1 + Sum)) xor (Shift_Right (V1, 5) + Key (1)));
         V1  := V1 + (((Shift_Left (V0, 4) + Key (2)) xor (V0 + Sum)) xor (Shift_Right (V0, 5) + Key (3)));
      end loop;
      Data (0) := V0;
      Data (1) := V1;
   end TEA_Encrypt;

   procedure TEA_Decrypt (Data : in out Block_64; Key : Key_128) is
      V0  : Word := Data (0);
      V1  : Word := Data (1);
      Sum : Word := TEA_Delta * 32;
   begin
      for I in 1 .. 32 loop
         pragma Unreferenced (I);
         V1  := V1 - (((Shift_Left (V0, 4) + Key (2)) xor (V0 + Sum)) xor (Shift_Right (V0, 5) + Key (3)));
         V0  := V0 - (((Shift_Left (V1, 4) + Key (0)) xor (V1 + Sum)) xor (Shift_Right (V1, 5) + Key (1)));
         Sum := Sum - TEA_Delta;
      end loop;
      Data (0) := V0;
      Data (1) := V1;
   end TEA_Decrypt;

   -----------------------------------------------------------------------------
   --  XTEA Implementation
   -----------------------------------------------------------------------------

   procedure XTEA_Encrypt (Data : in out Block_64; Key : Key_128; Num_Rounds : Positive := 32) is
      V0  : Word := Data (0);
      V1  : Word := Data (1);
      Sum : Word := 0;
   begin
      for I in 1 .. Num_Rounds loop
         pragma Unreferenced (I);
         V0  := V0 + ((((Shift_Left (V1, 4) xor Shift_Right (V1, 5)) + V1) xor (Sum + Key (Natural (Sum and 3)))));
         Sum := Sum + TEA_Delta;
         V1  := V1 + ((((Shift_Left (V0, 4) xor Shift_Right (V0, 5)) + V0) xor (Sum + Key (Natural (Shift_Right (Sum, 11) and 3)))));
      end loop;
      Data (0) := V0;
      Data (1) := V1;
   end XTEA_Encrypt;

   procedure XTEA_Decrypt (Data : in out Block_64; Key : Key_128; Num_Rounds : Positive := 32) is
      V0  : Word := Data (0);
      V1  : Word := Data (1);
      Sum : Word := TEA_Delta * Word (Num_Rounds);
   begin
      for I in 1 .. Num_Rounds loop
         pragma Unreferenced (I);
         V1  := V1 - ((((Shift_Left (V0, 4) xor Shift_Right (V0, 5)) + V0) xor (Sum + Key (Natural (Shift_Right (Sum, 11) and 3)))));
         Sum := Sum - TEA_Delta;
         V0  := V0 - ((((Shift_Left (V1, 4) xor Shift_Right (V1, 5)) + V1) xor (Sum + Key (Natural (Sum and 3)))));
      end loop;
      Data (0) := V0;
      Data (1) := V1;
   end XTEA_Decrypt;

   -----------------------------------------------------------------------------
   --  XXTEA Implementation
   -----------------------------------------------------------------------------

   procedure XXTEA_Encrypt (Data : in out Word_Array; Key : Key_128) is
      N : constant Natural := Data'Length;
   begin
      --  Enforce bounds contract explicitly
      if N < 2 then
         raise Invalid_Block_Size;
      end if;

      declare
         --  Map to a strict 0-indexed local buffer to match C references
         V      : array (0 .. N - 1) of Word;
         Y, Z   : Word;
         Sum, E : Word;
         Rounds : Natural;
      begin
         --  Isolate index offset mapping entirely here
         for I in 0 .. N - 1 loop
            V (I) := Data (Data'First + I);
         end loop;

         Rounds := 6 + 52 / N;
         Sum    := 0;
         Z      := V (N - 1);

         while Rounds > 0 loop
            Sum := Sum + TEA_Delta;
            E   := Shift_Right (Sum, 2) and 3;

            for P in 0 .. N - 2 loop
               Y     := V (P + 1);
               V (P) := V (P) + MX (Z, Y, Sum, P, E, Key);
               Z     := V (P);
            end loop;

            Y         := V (0);
            V (N - 1) := V (N - 1) + MX (Z, Y, Sum, N - 1, E, Key);
            Z         := V (N - 1);
            
            Rounds := Rounds - 1;
         end loop;

         --  Map back out, preserving the original array slice's arbitrary bounds
         for I in 0 .. N - 1 loop
            Data (Data'First + I) := V (I);
         end loop;
      end;
   end XXTEA_Encrypt;

   procedure XXTEA_Decrypt (Data : in out Word_Array; Key : Key_128) is
      N : constant Natural := Data'Length;
   begin
      if N < 2 then
         raise Invalid_Block_Size;
      end if;

      declare
         V      : array (0 .. N - 1) of Word;
         Y, Z   : Word;
         Sum, E : Word;
         Rounds : Natural;
      begin
         for I in 0 .. N - 1 loop
            V (I) := Data (Data'First + I);
         end loop;

         Rounds := 6 + 52 / N;
         Sum    := Word (Rounds) * TEA_Delta;
         Y      := V (0);

         while Rounds > 0 loop
            E := Shift_Right (Sum, 2) and 3;

            for P in reverse 1 .. N - 1 loop
               Z     := V (P - 1);
               V (P) := V (P) - MX (Z, Y, Sum, P, E, Key);
               Y     := V (P);
            end loop;

            Z     := V (N - 1);
            V (0) := V (0) - MX (Z, Y, Sum, 0, E, Key);
            Y     := V (0);
            
            Sum    := Sum - TEA_Delta;
            Rounds := Rounds - 1;
         end loop;

         for I in 0 .. N - 1 loop
            Data (Data'First + I) := V (I);
         end loop;
      end;
   end XXTEA_Decrypt;

end Tiny_Encryption_Algorithm;
