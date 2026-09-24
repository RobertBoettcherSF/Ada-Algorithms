with Ada.Numerics.Discrete_Random;

package body Deutsch_Jozsa is

   -------------------
   -- Solve_Deutsch --
   -------------------

   function Solve_Deutsch (F : not null access function (X : Bit) return Bit) return Algorithm_Result is
      Y0 : constant Bit := F (0);
      Y1 : constant Bit := F (1);
   begin
      if Y0 = 0 and Y1 = 0 then
         return Constant_Zero;
      elsif Y0 = 1 and Y1 = 1 then
         return Constant_One;
      elsif Y0 /= Y1 then
         return Balanced;
      else
         raise Invalid_Function_Error;
      end if;
   end Solve_Deutsch;

   -------------------------
   -- Solve_Deutsch_Jozsa --
   -------------------------

   function Solve_Deutsch_Jozsa (N : Positive; Truth_Table : Bit_Vector) return Algorithm_Result is
      Total      : constant Natural := Truth_Table'Length;
      Count_Ones : Natural := 0;
   begin
      if Total /= 2 ** N then
         raise Invalid_Dimension_Error;
      end if;

      for B of Truth_Table loop
         if B = 1 then
            Count_Ones := Count_Ones + 1;
         end if;
      end loop;

      if Count_Ones = 0 then
         return Constant_Zero;
      elsif Count_Ones = Total then
         return Constant_One;
      elsif Count_Ones = Total / 2 then
         return Balanced;
      else
         return Invalid_Function;
      end if;
   end Solve_Deutsch_Jozsa;

   ------------------------------
   -- Solve_Deutsch_Jozsa_Fn --
   ------------------------------

   function Solve_Deutsch_Jozsa_Fn (N : Positive; F : not null access function (Input : Bit_Vector) return Bit) return Algorithm_Result is
      Total : constant Natural := 2 ** N;
      TT    : Bit_Vector (1 .. Total);
   begin
      for I in 0 .. Total - 1 loop
         declare
            Temp : Natural := I;
            Vec  : Bit_Vector (1 .. N);
         begin
            for J in reverse 1 .. N loop
               Vec (J) := Bit (Temp mod 2);
               Temp := Temp / 2;
            end loop;
            TT (I + 1) := F (Vec);
         end;
      end loop;
      return Solve_Deutsch_Jozsa (N, TT);
   end Solve_Deutsch_Jozsa_Fn;

   -----------------------------------
   -- Solve_Classical_Deterministic --
   -----------------------------------

   function Solve_Classical_Deterministic (N : Positive; Truth_Table : Bit_Vector) return Algorithm_Result is
      Total     : constant Natural := Truth_Table'Length;
      First_Val : constant Bit := Truth_Table (Truth_Table'First);
      Seen_Diff : Boolean := False;
   begin
      if Total /= 2 ** N then
         raise Invalid_Dimension_Error;
      end if;

      for B of Truth_Table loop
         if B /= First_Val then
            Seen_Diff := True;
            exit;
         end if;
      end loop;

      if Seen_Diff then
         return Balanced;
      else
         if First_Val = 0 then
            return Constant_Zero;
         else
            return Constant_One;
         end if;
      end if;
   end Solve_Classical_Deterministic;

   ---------------------------------
   -- Solve_Classical_Randomized --
   ---------------------------------

   function Solve_Classical_Randomized (N : Positive; Truth_Table : Bit_Vector; Trials : Positive) return Algorithm_Result is
      Total      : constant Natural := Truth_Table'Length;
      First_Val  : Bit;
      Found_Diff : Boolean := False;
      subtype Index_Range is Positive range Truth_Table'First .. Truth_Table'Last;
      package Rand_Idx is new Ada.Numerics.Discrete_Random (Index_Range);
      Gen        : Rand_Idx.Generator;
   begin
      if Total /= 2 ** N then
         raise Invalid_Dimension_Error;
      end if;

      Rand_Idx.Reset (Gen);
      First_Val := Truth_Table (Rand_Idx.Random (Gen));

      for I in 1 .. Trials loop
         declare
            Idx : constant Positive := Rand_Idx.Random (Gen);
         begin
            if Truth_Table (Idx) /= First_Val then
               Found_Diff := True;
               exit;
            end if;
         end;
      end loop;

      if Found_Diff then
         return Balanced;
      else
         if First_Val = 0 then
            return Constant_Zero;
         else
            return Constant_One;
         end if;
      end if;
   end Solve_Classical_Randomized;

end Deutsch_Jozsa;
