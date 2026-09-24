package body Berlekamp_Massey is

   -- Epsilon for floating point comparisons
   Epsilon : constant Real := 1.0e-9;

   -----------------------------------------------------------------------------
   -- Compute_LFSR_GF2
   -----------------------------------------------------------------------------
   procedure Compute_LFSR_GF2
     (Sequence    : in  Bit_Array;
      Polynomial  : out Bit_Array;
      LFSR_Length : out Natural)
   is
      N : constant Natural := Sequence'Length;
   begin
      if N = 0 then
         raise Size_Error with "Input sequence must not be empty.";
      end if;

      if Polynomial'Length <= N then
         raise Size_Error with "Polynomial array must be strictly larger than Sequence length.";
      end if;

      declare
         -- We use internal arrays normalized to 0 .. N bounds.
         -- C is the current connection polynomial C(x)
         C : Bit_Array (0 .. N) := (0 => 1, others => 0);
         -- B is a copy of the last connection polynomial that caused a length increase
         B : Bit_Array (0 .. N) := (0 => 1, others => 0);
         -- T is a temporary array for updates
         T : Bit_Array (0 .. N) := (others => 0);
         L : Natural := 0;
         M : Natural := 1;
         D : Bit;
      begin
         for I in 0 .. N - 1 loop
            -- Calculate discrepancy D
            D := Sequence (Sequence'First + I);
            for J in 1 .. L loop
               D := D xor (C (J) and Sequence (Sequence'First + I - J));
            end loop;

            if D = 0 then
               M := M + 1;
            else
               -- Update polynomial: T(x) = C(x) - d * x^m * B(x)
               -- In GF2, subtraction is XOR and d is always 1.
               T := C;
               for J in 0 .. N - M loop
                  T (J + M) := T (J + M) xor B (J);
               end loop;

               -- Check if LFSR length needs updating
               if 2 * L <= I then
                  L := I + 1 - L;
                  B := C;
                  M := 1;
               else
                  M := M + 1;
               end if;
               C := T;
            end if;
         end loop;

         -- Output the result to the caller's polynomial array
         for I in Polynomial'Range loop
            Polynomial (I) := 0;
         end loop;

         for I in 0 .. L loop
            Polynomial (Polynomial'First + I) := C (I);
         end loop;

         LFSR_Length := L;
      end;
   end Compute_LFSR_GF2;

   -----------------------------------------------------------------------------
   -- Is_Valid_LFSR_GF2
   -----------------------------------------------------------------------------
   function Is_Valid_LFSR_GF2
     (Sequence    : in Bit_Array;
      Polynomial  : in Bit_Array;
      LFSR_Length : in Natural) return Boolean
   is
      Sum : Bit;
   begin
      if Sequence'Length = 0 then
         return True;
      end if;

      if LFSR_Length = 0 then
         -- If L=0, the sequence must be all zeros
         for I in Sequence'Range loop
            if Sequence (I) /= 0 then
               return False;
            end if;
         end loop;
         return True;
      end if;

      for I in Sequence'First + LFSR_Length .. Sequence'Last loop
         Sum := 0;
         for J in 1 .. LFSR_Length loop
            Sum := Sum xor (Polynomial (Polynomial'First + J) and Sequence (I - J));
         end loop;
         
         if Sequence (I) /= Sum then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_LFSR_GF2;

   -----------------------------------------------------------------------------
   -- Compute_LFSR_Real
   -----------------------------------------------------------------------------
   procedure Compute_LFSR_Real
     (Sequence    : in  Real_Array;
      Polynomial  : out Real_Array;
      LFSR_Length : out Natural)
   is
      N : constant Natural := Sequence'Length;
   begin
      if N = 0 then
         raise Size_Error with "Input sequence must not be empty.";
      end if;

      if Polynomial'Length <= N then
         raise Size_Error with "Polynomial array must be strictly larger than Sequence length.";
      end if;

      declare
         C      : Real_Array (0 .. N) := (0 => 1.0, others => 0.0);
         B      : Real_Array (0 .. N) := (0 => 1.0, others => 0.0);
         T      : Real_Array (0 .. N) := (others => 0.0);
         L      : Natural := 0;
         M      : Natural := 1;
         D      : Real;
         Prev_D : Real := 1.0;
         Coef   : Real;
      begin
         for I in 0 .. N - 1 loop
            D := Sequence (Sequence'First + I);
            for J in 1 .. L loop
               D := D + C (J) * Sequence (Sequence'First + I - J);
            end loop;

            if abs (D) < Epsilon then
               M := M + 1;
            else
               T := C;
               Coef := D / Prev_D;
               for J in 0 .. N - M loop
                  T (J + M) := T (J + M) - Coef * B (J);
               end loop;

               if 2 * L <= I then
                  L := I + 1 - L;
                  B := C;
                  Prev_D := D;
                  M := 1;
               else
                  M := M + 1;
               end if;
               C := T;
            end if;
         end loop;

         for I in Polynomial'Range loop
            Polynomial (I) := 0.0;
         end loop;

         for I in 0 .. L loop
            Polynomial (Polynomial'First + I) := C (I);
         end loop;

         LFSR_Length := L;
      end;
   end Compute_LFSR_Real;

   -----------------------------------------------------------------------------
   -- Is_Valid_LFSR_Real
   -----------------------------------------------------------------------------
   function Is_Valid_LFSR_Real
     (Sequence    : in Real_Array;
      Polynomial  : in Real_Array;
      LFSR_Length : in Natural) return Boolean
   is
      Sum : Real;
   begin
      if Sequence'Length = 0 then
         return True;
      end if;

      if LFSR_Length = 0 then
         for I in Sequence'Range loop
            if abs (Sequence (I)) > Epsilon then
               return False;
            end if;
         end loop;
         return True;
      end if;

      for I in Sequence'First + LFSR_Length .. Sequence'Last loop
         Sum := 0.0;
         for J in 1 .. LFSR_Length loop
            Sum := Sum + Polynomial (Polynomial'First + J) * Sequence (I - J);
         end loop;
         
         -- Expected condition: S_i + Sum(C_j * S_{i-j}) = 0
         if abs (Sequence (I) + Sum) > Epsilon then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_LFSR_Real;

end Berlekamp_Massey;
