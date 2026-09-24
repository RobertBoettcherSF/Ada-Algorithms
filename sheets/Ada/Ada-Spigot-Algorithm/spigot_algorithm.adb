--  Spigot_Algorithm body — Sale e-spigot and Rabinowitz–Wagon π spigot.

pragma Ada_2022;

package body Spigot_Algorithm
  with SPARK_Mode => Off
is

   --  Reference prefixes (digits only, no radix point). Long enough for
   --  Max_Digits_E / Max_Digits_Pi.
   Known_E : constant String :=
     "27182818284590452353602874713526624977572470936999"
     & "595749669676277240766303535475945713821785251664274";

   Known_Pi : constant String :=
     "31415926535897932384626433832795028841971693993751";

   procedure Check_E_Count (N : Natural) is
   begin
      if N = 0 or else N > Max_Digits_E then
         raise Invalid_Argument
           with "Digits_Of_E: N must be in 1 .. Max_Digits_E";
      end if;
   end Check_E_Count;

   procedure Check_Pi_Count (N : Natural) is
   begin
      if N = 0 or else N > Max_Digits_Pi then
         raise Invalid_Argument
           with "Digits_Of_Pi: N must be in 1 .. Max_Digits_Pi";
      end if;
   end Check_Pi_Count;

   function Char_Digit (D : Integer) return Character is
   begin
      return Character'Val (Character'Pos ('0') + D);
   end Char_Digit;

   function Parse_Digit (C : Character) return Digit_Value is
   begin
      if C < '0' or else C > '9' then
         raise Invalid_Argument with "expected decimal digit character";
      end if;
      return Character'Pos (C) - Character'Pos ('0');
   end Parse_Digit;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Digit_String
     (S : String; Max : Positive) return Boolean
   is
   begin
      if S'Length = 0 or else S'Length > Natural (Max) then
         return False;
      end if;
      for C of S loop
         if C < '0' or else C > '9' then
            return False;
         end if;
      end loop;
      return True;
   end Is_Digit_String;

   function E_Term_Count (N : Natural) return Natural is
   begin
      if N = 0 then
         return 0;
      end if;
      return N + E_Term_Guard;
   end E_Term_Count;

   function Pi_Term_Count (Total_Digits : Natural) return Natural is
   begin
      if Total_Digits = 0 then
         return 0;
      end if;
      return (10 * Total_Digits) / 3 + 1;
   end Pi_Term_Count;

   ---------------------------------------------------------------------------
   -- e-spigot
   ---------------------------------------------------------------------------

   function Digits_Of_E (N : Natural) return String is
      M : Natural;
   begin
      Check_E_Count (N);

      if N = 1 then
         return "2";
      end if;

      --  Mixed-radix remainders for e = 2 + Σ_{k≥2} 1/k!  in radices
      --  2,3,4,… : initialise every slot to 1, then repeatedly ×10 and
      --  renormalise from the right; the outgoing carry is the next
      --  fractional digit. Array length M = N + E_Term_Guard.
      M := E_Term_Count (N);

      declare
         type Rem_Array is array (Integer range <>) of Integer;
         A      : Rem_Array (2 .. M) := [others => 1];
         Result : String (1 .. N);
         Q      : Integer;
         X      : Integer;
      begin
         Result (1) := '2';

         for Digit_Index in 2 .. N loop
            Q := 0;
            for J in reverse 2 .. M loop
               X    := 10 * A (J) + Q;
               A (J) := X rem J;
               Q    := X / J;
            end loop;
            --  Q is in 0 .. 9 for well-sized M; clamp defensively for
            --  the Character conversion (should never trip in-range N).
            if Q < 0 or else Q > 9 then
               raise Invalid_Argument
                 with "Digits_Of_E: unexpected carry out of 0..9";
            end if;
            Result (Digit_Index) := Char_Digit (Q);
         end loop;

         return Result;
      end;
   end Digits_Of_E;

   function Digits_Of_E_Array (N : Natural) return Digit_Array is
      S : constant String := Digits_Of_E (N);
      A : Digit_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := Parse_Digit (S (S'First + I - 1));
      end loop;
      return A;
   end Digits_Of_E_Array;

   ---------------------------------------------------------------------------
   -- π-spigot (Rabinowitz–Wagon)
   ---------------------------------------------------------------------------

   function Digits_Of_Pi (N : Natural) return String is
      Total : Natural;
      L     : Natural;
   begin
      Check_Pi_Count (N);

      --  Run Pi_Digit_Guard extra steps so a terminal nines-run / carry
      --  settles before we slice the first N digits.
      Total := N + Pi_Digit_Guard;
      L     := Pi_Term_Count (Total);

      declare
         type Rem_Array is array (Natural range <>) of Integer;
         A        : Rem_Array (0 .. L - 1) := [others => 2];
         --  Buffer: classic algorithm emits a leading dummy 0 (initial
         --  predigit), then Total real digits, plus flushed nines.
         Buf      : String (1 .. Total + 16);
         Buf_Last : Natural := 0;
         Nines    : Natural := 0;
         Predigit : Integer := 0;
         Q        : Integer;
         X        : Integer;
         Den      : Integer;

         procedure Append_Digit (D : Integer) is
         begin
            if D < 0 or else D > 9 then
               raise Invalid_Argument
                 with "Digits_Of_Pi: digit out of 0..9";
            end if;
            Buf_Last := Buf_Last + 1;
            Buf (Buf_Last) := Char_Digit (D);
         end Append_Digit;
      begin
         for Step in 1 .. Total loop
            Q := 0;
            for I in reverse 0 .. L - 1 loop
               X     := 10 * A (I) + Q * (I + 1);
               Den   := 2 * I + 1;
               A (I) := X rem Den;
               Q     := X / Den;
            end loop;

            A (0) := Q rem 10;
            Q     := Q / 10;

            if Q = 9 then
               Nines := Nines + 1;
            elsif Q = 10 then
               Append_Digit (Predigit + 1);
               for K in 1 .. Nines loop
                  pragma Unreferenced (K);
                  Append_Digit (0);
               end loop;
               Predigit := 0;
               Nines    := 0;
            else
               Append_Digit (Predigit);
               Predigit := Q;
               for K in 1 .. Nines loop
                  pragma Unreferenced (K);
                  Append_Digit (9);
               end loop;
               Nines := 0;
            end if;
         end loop;

         Append_Digit (Predigit);
         for K in 1 .. Nines loop
            pragma Unreferenced (K);
            Append_Digit (9);
         end loop;

         --  Drop the leading dummy 0; copy next N digits into 1 .. N.
         if Buf_Last < N + 1 then
            raise Invalid_Argument
              with "Digits_Of_Pi: internal buffer shorter than N";
         end if;

         declare
            Result : String (1 .. N);
         begin
            Result := Buf (2 .. N + 1);
            return Result;
         end;
      end;
   end Digits_Of_Pi;

   function Digits_Of_Pi_Array (N : Natural) return Digit_Array is
      S : constant String := Digits_Of_Pi (N);
      A : Digit_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := Parse_Digit (S (S'First + I - 1));
      end loop;
      return A;
   end Digits_Of_Pi_Array;

   ---------------------------------------------------------------------------
   -- Known prefixes
   ---------------------------------------------------------------------------

   function Known_E_Prefix (N : Natural) return String is
   begin
      Check_E_Count (N);
      if N > Known_E'Length then
         raise Invalid_Argument with "Known_E_Prefix: table too short";
      end if;
      return Known_E (1 .. N);
   end Known_E_Prefix;

   function Known_Pi_Prefix (N : Natural) return String is
   begin
      Check_Pi_Count (N);
      if N > Known_Pi'Length then
         raise Invalid_Argument with "Known_Pi_Prefix: table too short";
      end if;
      return Known_Pi (1 .. N);
   end Known_Pi_Prefix;

   function Matches_Known_E (Digit_Str : String) return Boolean is
   begin
      if Digit_Str'Length = 0 or else Digit_Str'Length > Max_Digits_E then
         return False;
      end if;
      if not Is_Digit_String (Digit_Str, Max_Digits_E) then
         return False;
      end if;
      return Digit_Str = Known_E_Prefix (Digit_Str'Length);
   end Matches_Known_E;

   function Matches_Known_Pi (Digit_Str : String) return Boolean is
   begin
      if Digit_Str'Length = 0 or else Digit_Str'Length > Max_Digits_Pi then
         return False;
      end if;
      if not Is_Digit_String (Digit_Str, Max_Digits_Pi) then
         return False;
      end if;
      return Digit_Str = Known_Pi_Prefix (Digit_Str'Length);
   end Matches_Known_Pi;

begin
   --  Table lengths must cover the advertised caps.
   if Known_E'Length < Max_Digits_E then
      raise Program_Error with "Known_E shorter than Max_Digits_E";
   end if;
   if Known_Pi'Length < Max_Digits_Pi then
      raise Program_Error with "Known_Pi shorter than Max_Digits_Pi";
   end if;
end Spigot_Algorithm;
