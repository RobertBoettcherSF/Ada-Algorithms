-- verhoeff.adb
-- Implementation of the Verhoeff algorithm.

package body Verhoeff is

   -- Strong typing for algorithm-specific data to prevent bounds overflow 
   -- and ensure mathematical domain correctness.
   type Digit_Value is range 0 .. 9;
   type Position_Index is mod 8;
   
   type Table_1D is array (Digit_Value) of Digit_Value;
   type Table_2D is array (Digit_Value, Digit_Value) of Digit_Value;
   type Perm_Table is array (Position_Index, Digit_Value) of Digit_Value;

   -- The multiplication table for the dihedral group D5
   D : constant Table_2D :=
     ((0, 1, 2, 3, 4, 5, 6, 7, 8, 9),
      (1, 2, 3, 4, 0, 6, 7, 8, 9, 5),
      (2, 3, 4, 0, 1, 7, 8, 9, 5, 6),
      (3, 4, 0, 1, 2, 8, 9, 5, 6, 7),
      (4, 0, 1, 2, 3, 9, 5, 6, 7, 8),
      (5, 9, 8, 7, 6, 0, 4, 3, 2, 1),
      (6, 5, 9, 8, 7, 1, 0, 4, 3, 2),
      (7, 6, 5, 9, 8, 2, 1, 0, 4, 3),
      (8, 7, 6, 5, 9, 3, 2, 1, 0, 4),
      (9, 8, 7, 6, 5, 4, 3, 2, 1, 0));

   -- The permutation table based on position
   P : constant Perm_Table :=
     ((0, 1, 2, 3, 4, 5, 6, 7, 8, 9),
      (1, 5, 7, 6, 2, 8, 3, 0, 9, 4),
      (5, 8, 0, 3, 7, 9, 6, 1, 4, 2),
      (8, 9, 1, 6, 0, 4, 3, 5, 2, 7),
      (9, 4, 5, 3, 1, 2, 6, 8, 7, 0),
      (4, 2, 8, 6, 5, 7, 3, 9, 0, 1),
      (2, 7, 9, 3, 8, 0, 6, 4, 1, 5),
      (7, 0, 4, 6, 9, 1, 3, 2, 5, 8));

   -- The inverse table for the group
   Inv : constant Table_1D := (0, 4, 3, 2, 1, 5, 6, 7, 8, 9);

   -- Helper: Converts a character to its strictly-typed numerical representation
   function Char_To_Digit (C : Character) return Digit_Value is
   begin
      if C not in '0' .. '9' then
         raise Invalid_Input;
      end if;
      return Digit_Value (Character'Pos (C) - Character'Pos ('0'));
   end Char_To_Digit;

   -- Helper: Converts a strongly-typed digit back to a character
   function Digit_To_Char (Val : Digit_Value) return Character is
   begin
      return Character'Val (Integer(Val) + Character'Pos ('0'));
   end Digit_To_Char;

   -- Core algorithmic component: computes the D5 group checksum
   -- Initial_Pos offsets the position index (1 for generation, 0 for validation)
   function Compute_Checksum (Number : String; Initial_Pos : Integer) return Digit_Value is
      C   : Digit_Value := 0;
      Pos : Integer := Initial_Pos;
      Dig : Digit_Value;
   begin
      -- Process the string right-to-left
      for I in reverse Number'Range loop
         Dig := Char_To_Digit (Number (I));
         
         -- Apply the permutation for the current position and the dihedral operation
         C := D (C, P (Position_Index (Pos mod 8), Dig));
         Pos := Pos + 1;
      end loop;
      return C;
   end Compute_Checksum;

   ----------------------------------------------------------
   -- Public Subprograms
   ----------------------------------------------------------

   function Generate_Check_Digit (Number : String) return Character is
      C : Digit_Value;
   begin
      if Number'Length = 0 then
         raise Invalid_Input;
      end if;
      
      -- Start calculating as if the missing check digit occupies position 0
      C := Compute_Checksum (Number, 1);
      
      -- Return the inverse character required to zero out the checksum
      return Digit_To_Char (Inv (C));
   end Generate_Check_Digit;

   function Validate (Number : String) return Boolean is
      C : Digit_Value;
   begin
      if Number'Length = 0 then
         raise Invalid_Input;
      end if;
      
      -- Calculate including the check digit at position 0
      C := Compute_Checksum (Number, 0);
      
      -- Valid numbers resolve to the D5 group identity element (0)
      return C = 0;
   end Validate;

end Verhoeff;
