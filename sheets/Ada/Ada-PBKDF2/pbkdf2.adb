with Interfaces; use Interfaces;

package body PBKDF2 is

   ----------------------------------------------------------------------------
   -- Helper Subprograms
   ----------------------------------------------------------------------------

   function "xor" (Left, Right : Byte_Array) return Byte_Array is
      Result : Byte_Array (Left'Range);
      R_Idx  : Natural := Right'First;
   begin
      -- Standard loop ensures safety against arbitrary array bounds
      for L_Idx in Left'Range loop
         Result (L_Idx) := Left (L_Idx) xor Right (R_Idx);
         R_Idx := R_Idx + 1;
      end loop;
      return Result;
   end "xor";

   function To_Big_Endian (Value : Positive) return Byte_Array is
      V : constant Unsigned_32 := Unsigned_32 (Value);
   begin
      -- Utilizing Ada 2022 array aggregates
      return [
        Byte (Shift_Right (V, 24) and 16#FF#),
        Byte (Shift_Right (V, 16) and 16#FF#),
        Byte (Shift_Right (V, 8)  and 16#FF#),
        Byte (V and 16#FF#)
      ];
   end To_Big_Endian;

   ----------------------------------------------------------------------------
   -- PBKDF1 Implementation
   ----------------------------------------------------------------------------

   package body PBKDF1_Algorithm is
      function Derive
        (Password   : Byte_Array;
         Salt       : Byte_Array;
         Iterations : Iteration_Count;
         Length     : Key_Length) return Byte_Array
      is
      begin
         -- PBKDF1 fundamentally cannot generate keys longer than its Hash
         if Length > Hash_Length then
            raise Derived_Key_Too_Long with "PBKDF1 length exceeds hash length";
         end if;

         declare
            Current : Byte_Array := Hash (Password & Salt);
         begin
            for I in 2 .. Iterations loop
               Current := Hash (Current);
            end loop;

            -- Extract up to the requested Length
            return Current (Current'First .. Current'First + Length - 1);
         end;
      end Derive;
   end PBKDF1_Algorithm;

   ----------------------------------------------------------------------------
   -- PBKDF2 Implementation
   ----------------------------------------------------------------------------

   package body PBKDF2_Algorithm is
      function Derive
        (Password   : Byte_Array;
         Salt       : Byte_Array;
         Iterations : Iteration_Count;
         Length     : Key_Length) return Byte_Array
      is
         -- Ceiling division determines total required blocks
         Num_Blocks : constant Natural := (Length + Hash_Length - 1) / Hash_Length;
         Result     : Byte_Array (1 .. Length);
         Res_Idx    : Natural := 1;
      begin
         for I in 1 .. Num_Blocks loop
            declare
               -- U_1 = PRF (Password, Salt || INT_32_BE(i))
               U_Prev : Byte_Array := PRF (Password, Salt & To_Big_Endian (I));
               U_Xor  : Byte_Array := U_Prev;
            begin
               -- Compute successive U_c blocks and accumulate XOR
               for J in 2 .. Iterations loop
                  U_Prev := PRF (Password, U_Prev);
                  U_Xor  := U_Xor xor U_Prev;
               end loop;

               -- Append the resulting block (T_i) into the derived key
               for K in U_Xor'Range loop
                  if Res_Idx <= Length then
                     Result (Res_Idx) := U_Xor (K);
                     Res_Idx := Res_Idx + 1;
                  end if;
               end loop;
            end;
         end loop;

         return Result;
      end Derive;
   end PBKDF2_Algorithm;

end PBKDF2;
