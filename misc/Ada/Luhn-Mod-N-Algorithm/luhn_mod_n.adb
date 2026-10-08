-- luhn_mod_n.adb
-- Implementation of the Luhn Mod N Algorithm

package body Luhn_Mod_N is

   -------------------------------------------------------------------------
   -- Create_Codec
   -- Initializes the codec, ensuring the alphabet is valid (length >= 2, no duplicates)
   -------------------------------------------------------------------------
   function Create_Codec (Mapping : String) return Codec is
      Result : Codec;
      Len    : Natural := Mapping'Length;
   begin
      if Len < 2 or Len > 256 then
         raise Invalid_Alphabet;
      end if;

      Result.Alphabet_Length := Len;
      
      for I in Mapping'Range loop
         declare
            C   : Character := Mapping(I);
            Idx : Natural   := I - Mapping'First;
         begin
            -- Disprove assumption: Algorithm blindly accepts duplicate mappings
            if Result.Map(C) /= -1 then
               raise Invalid_Alphabet;
            end if;
            
            Result.Map(C) := Idx;
            Result.Alphabet(Idx + 1) := C;
         end;
      end loop;
      
      return Result;
   end Create_Codec;

   -------------------------------------------------------------------------
   -- Generate_Check_Character
   -- Calculates the required check character to make a string valid.
   -------------------------------------------------------------------------
   function Generate_Check_Character (C : Codec; Input : String) return Character is
      Factor     : Natural := 2;
      Sum        : Natural := 0;
      N          : Natural := C.Alphabet_Length;
      Addend     : Natural;
      Code       : Integer;
      Remainder  : Natural;
      Check_Code : Natural;
   begin
      if Input'Length = 0 then
         raise Empty_Input;
      end if;

      -- Traverse right to left
      for I in reverse Input'Range loop
         Code := C.Map(Input(I));
         
         if Code = -1 then
            raise Invalid_Character;
         end if;

         Addend := Factor * Code;
         
         -- Toggle factor between 1 and 2
         if Factor = 2 then
            Factor := 1;
         else
            Factor := 2;
         end if;

         Addend := (Addend / N) + (Addend mod N);
         Sum    := Sum + Addend;
      end loop;

      Remainder  := Sum mod N;
      Check_Code := (N - Remainder) mod N;
      
      return C.Alphabet(Check_Code + 1);
   end Generate_Check_Character;

   -------------------------------------------------------------------------
   -- Validate
   -- Verifies if an input string (including its check character) is valid.
   -------------------------------------------------------------------------
   function Validate (C : Codec; Input : String) return Boolean is
      Factor : Natural := 1; -- Starts at 1 for validation (includes check char)
      Sum    : Natural := 0;
      N      : Natural := C.Alphabet_Length;
      Addend : Natural;
      Code   : Integer;
   begin
      if Input'Length = 0 then
         raise Empty_Input;
      end if;

      for I in reverse Input'Range loop
         Code := C.Map(Input(I));
         
         if Code = -1 then
            raise Invalid_Character;
         end if;

         Addend := Factor * Code;
         
         if Factor = 2 then
            Factor := 1;
         else
            Factor := 2;
         end if;

         Addend := (Addend / N) + (Addend mod N);
         Sum    := Sum + Addend;
      end loop;

      return (Sum mod N) = 0;
   end Validate;

   -------------------------------------------------------------------------
   -- Append_Check_Character
   -------------------------------------------------------------------------
   function Append_Check_Character (C : Codec; Input : String) return String is
   begin
      return Input & Generate_Check_Character(C, Input);
   end Append_Check_Character;

end Luhn_Mod_N;
