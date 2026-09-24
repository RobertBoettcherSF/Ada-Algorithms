-- hamming_7_4.adb
-- Implementation of the Hamming(7,4) subprograms using matrix multiplication.

package body Hamming_7_4 is

   ----------------------------------------------------------------------------
   -- Multiply: Vector (1x4) * Matrix G (4x7)
   ----------------------------------------------------------------------------
   function Multiply (Data : Data_Word; G : Matrix_G) return Code_Word is
      Result : Code_Word := (others => 0);
   begin
      for J in Code_Word'Range loop
         for I in Data_Word'Range loop
            Result (J) := Result (J) xor (Data (I) and G (I, J));
         end loop;
      end loop;
      return Result;
   end Multiply;

   ----------------------------------------------------------------------------
   -- Multiply: Vector (1x7) * Matrix H Transpose (implied via indices)
   ----------------------------------------------------------------------------
   function Multiply (Code : Code_Word; H : Matrix_H) return Syndrome is
      Result : Syndrome := (others => 0);
   begin
      for I in Syndrome'Range loop
         for J in Code_Word'Range loop
            Result (I) := Result (I) xor (Code (J) and H (I, J));
         end loop;
      end loop;
      return Result;
   end Multiply;

   ----------------------------------------------------------------------------
   -- Syndrome_To_Int: Translates a 3-bit syndrome into a bit error position (1..7)
   ----------------------------------------------------------------------------
   function Syndrome_To_Int (S : Syndrome; Variant : Code_Variant) return Natural is
   begin
      if S = (0, 0, 0) then
         return 0; -- No error
      end if;

      if Variant = Interleaved then
         -- Interleaved syndrome translates directly to binary position
         return Natural(S(1)) * 1 + Natural(S(2)) * 2 + Natural(S(3)) * 4;
      else
         -- Systematic requires finding the matching column in H_Systematic
         for Col in Code_Word'Range loop
            if S(1) = H_Systematic(1, Col) and then
               S(2) = H_Systematic(2, Col) and then
               S(3) = H_Systematic(3, Col) 
            then
               return Col;
            end if;
         end loop;
         return 0; -- Failsafe, should not happen for single bit errors
      end if;
   end Syndrome_To_Int;

   ----------------------------------------------------------------------------
   -- Encode: Generates parity bits for the provided data bits
   ----------------------------------------------------------------------------
   function Encode (Data    : Data_Word; 
                    Variant : Code_Variant := Interleaved) return Code_Word is
   begin
      case Variant is
         when Systematic =>
            return Multiply (Data, G_Systematic);
         when Interleaved =>
            return Multiply (Data, G_Interleaved);
      end case;
   end Encode;

   ----------------------------------------------------------------------------
   -- Decode: Validates, corrects (if needed), and extracts original data
   ----------------------------------------------------------------------------
   procedure Decode (Code        : in out Code_Word;
                     Data        : out Data_Word;
                     Error_Found : out Boolean;
                     Error_Pos   : out Natural;
                     Variant     : in Code_Variant := Interleaved) is
      S : Syndrome;
   begin
      -- 1. Calculate Syndrome
      if Variant = Systematic then
         S := Multiply (Code, H_Systematic);
      else
         S := Multiply (Code, H_Interleaved);
      end if;

      -- 2. Identify Error Position
      Error_Pos := Syndrome_To_Int (S, Variant);

      -- 3. Correct Error (if any)
      if Error_Pos > 0 and Error_Pos <= 7 then
         Error_Found := True;
         Code (Error_Pos) := Code (Error_Pos) xor 1; -- Flip the corrupted bit
      else
         Error_Found := False;
      end if;

      -- 4. Extract Data Bits
      if Variant = Systematic then
         Data (1) := Code (1);
         Data (2) := Code (2);
         Data (3) := Code (3);
         Data (4) := Code (4);
      else
         Data (1) := Code (3);
         Data (2) := Code (5);
         Data (3) := Code (6);
         Data (4) := Code (7);
      end if;
   end Decode;

end Hamming_7_4;
