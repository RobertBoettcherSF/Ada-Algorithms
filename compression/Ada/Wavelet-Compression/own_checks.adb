--  Own checks for Haar compression.
--  Float step and the integer S-transform are written here. See tests/SOURCES.txt.
--  Seed 20261008, printed, overridable with AA_SEED.

with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Wavelet_Compression;

procedure Own_Checks (Fail_Count : out Natural) is
   use Wavelet_Compression;
   package Txt renames Ada.Text_IO;

   Checks : Natural := 0;
   Fails  : Natural := 0;

   type U32 is mod 2**32;
   Seed : U32 := 20261008;

   procedure Note (OK : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Fails := Fails + 1;
         Txt.Put_Line ("  FAIL -- " & Label);
      end if;
   end Note;

   function Next_U return U32 is
   begin
      Seed := Seed * 1664525 + 1013904223;
      return Seed;
   end Next_U;

   function Floor_Div_2 (N : Long_Integer) return Long_Integer is
   begin
      --  Even values, including Long_Integer'First, divide evenly.
      --  An odd negative truncates toward zero, so floor is one less.
      if N >= 0 or else N mod 2 = 0 then
         return N / 2;
      else
         return N / 2 - 1;
      end if;
   end Floor_Div_2;

   function Own_Float (Input : Signal_1D) return Signal_1D is
      Half   : constant Natural := Input'Length / 2;
      Result : Signal_1D (Input'Range);
   begin
      if Input'Length = 1 then
         return Input;
      end if;
      for I in 0 .. Half - 1 loop
         declare
            X : constant Float := Input (Input'First + 2 * I);
            Y : constant Float := Input (Input'First + 2 * I + 1);
         begin
            Result (Result'First + I) := (X + Y) / 2.0;
            Result (Result'First + Half + I) := (X - Y) / 2.0;
         end;
      end loop;
      return Result;
   end Own_Float;

   function Own_S (Input : Signal_1D_Int) return Signal_1D_Int is
      Half   : constant Natural := Input'Length / 2;
      Result : Signal_1D_Int (Input'Range);
   begin
      if Input'Length = 1 then
         return Input;
      end if;
      for I in 0 .. Half - 1 loop
         declare
            X : constant Long_Integer := Input (Input'First + 2 * I);
            Y : constant Long_Integer := Input (Input'First + 2 * I + 1);
            D : constant Long_Integer := Y - X;
            S : constant Long_Integer := X + Floor_Div_2 (D);
         begin
            Result (Result'First + I) := S;
            Result (Result'First + Half + I) := D;
         end;
      end loop;
      return Result;
   end Own_S;

   function Own_S_Inverse (Input : Signal_1D_Int) return Signal_1D_Int is
      Half   : constant Natural := Input'Length / 2;
      Result : Signal_1D_Int (Input'Range);
   begin
      if Input'Length = 1 then
         return Input;
      end if;
      for I in 0 .. Half - 1 loop
         declare
            S    : constant Long_Integer := Input (Input'First + I);
            D    : constant Long_Integer := Input (Input'First + Half + I);
            Even : constant Long_Integer := S - Floor_Div_2 (D);
         begin
            Result (Result'First + 2 * I) := Even;
            Result (Result'First + 2 * I + 1) := Even + D;
         end;
      end loop;
      return Result;
   end Own_S_Inverse;

   function Same_Int (A, B : Signal_1D_Int) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in 0 .. A'Length - 1 loop
         if A (A'First + I) /= B (B'First + I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Int;

   function Near (A, B : Signal_1D) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in 0 .. A'Length - 1 loop
         if abs (A (A'First + I) - B (B'First + I)) > 1.0e-5 then
            return False;
         end if;
      end loop;
      return True;
   end Near;

   procedure Read_Seed is
   begin
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         declare
            Raw : constant String := Ada.Environment_Variables.Value ("AA_SEED");
            Acc : U32 := 0;
         begin
            for Ch of Raw loop
               if Ch in '0' .. '9' then
                  Acc := Acc * 10 + U32 (Character'Pos (Ch) - Character'Pos ('0'));
               end if;
            end loop;
            if Raw'Length > 0 then
               Seed := Acc;
            end if;
         end;
      end if;
      Txt.Put_Line ("own checks seed:" & U32'Image (Seed)
        & " (default 20261008; set AA_SEED to override)");
   end Read_Seed;

begin
   Fail_Count := 0;
   Read_Seed;

   --  Published float pair and a hand 2D level.
   declare
      Sig : constant Signal_1D := [1.0, 3.0, 5.0, 7.0];
      Got : constant Signal_1D := Forward_Haar_1D (Sig);
      Two : constant Signal_2D := [[1.0, 2.0], [3.0, 4.0]];
      G2  : constant Signal_2D := Forward_Haar_2D (Two);
   begin
      Note (Near (Got, Own_Float (Sig)), "float Haar matches (x+y)/2 and (x-y)/2");
      Note (Near (Inverse_Haar_1D (Got), Sig), "float inverse restores the signal");
      Note (abs (G2 (G2'First (1), G2'First (2)) - 2.5) < 1.0e-5
        and then abs (G2 (G2'First (1), G2'First (2) + 1) - (-0.5)) < 1.0e-5
        and then abs (G2 (G2'First (1) + 1, G2'First (2)) - (-1.0)) < 1.0e-5
        and then abs (G2 (G2'First (1) + 1, G2'First (2) + 1)) < 1.0e-5,
        "2D Haar is rows then columns");
      Note (abs (Inverse_Haar_2D (G2) (Two'First (1), Two'First (2)) - 1.0) < 1.0e-5,
        "2D inverse restores the corner");
   end;

   --  Floor is toward -infinity. Ada "/" on (-5+2) is -1; floor is -2.
   --  Hand values, not (A+B)/2. A sum that does not fit in Integer must
   --  still transform: the lifting step never forms A+B.
   declare
      procedure Check_Pair (A, B, Expect_S, Expect_D : Long_Integer; Label : String) is
         Sig : constant Signal_1D_Int := [A, B];
         Got : Signal_1D_Int (Sig'Range);
         Back : Signal_1D_Int (Sig'Range);
      begin
         Got := Forward_Haar_1D_Lossless (Sig);
         Note (Got (Got'First) = Expect_S and then Got (Got'First + 1) = Expect_D, Label);
         Back := Inverse_Haar_1D_Lossless (Got);
         Note (Back (Back'First) = A and then Back (Back'First + 1) = B,
           Label & " round trip");
      exception
         when Constraint_Error =>
            Note (False, Label & " raised Constraint_Error");
      end Check_Pair;
   begin
      --  (-5+2)/2 truncates to -1; floor is -2. Detail is 2-(-5) = 7.
      Check_Pair (-5, 2, -2, 7, "mixed signs (-5, 2)");
      --  Both negative, odd sum: floor((-8-3)/2) = -6, detail -3-(-8) = 5.
      Check_Pair (-8, -3, -6, 5, "both negative (-8, -3)");
      --  (Last, Last): Last+Last does not fit. Lifting detail is 0.
      Check_Pair (Long_Integer (Integer'Last), Long_Integer (Integer'Last),
        Long_Integer (Integer'Last), 0, "(Last, Last)");
      --  Detail is Long_Integer'First. (N - 1) would overflow.
      Check_Pair (0, Long_Integer'First, Long_Integer'First / 2, Long_Integer'First,
        "(0, First)");
      --  2**31 is not an Integer. Detail of (-2**30, 2**30) is exactly that.
      Check_Pair (-(2**30), 2**30, 0, 2**31, "detail 2**31 needs headroom");
   end;

   --  A one-sample signal has no pair. Levels 0 and 1 both return it.
   --  A length that is not divisible by 2**Levels is Invalid_Dimensions
   --  (length 6, two levels: the second prefix has width 3).
   declare
      One : constant Signal_1D_Int (4 .. 4) := [42];
      Six : constant Signal_1D_Int := [1, 2, 3, 4, 5, 6];
      Raised_F, Raised_I : Boolean := False;
   begin
      Note (Same_Int (Forward_Haar_Levels (One, 0), One), "levels 0 copies one sample");
      Note (Same_Int (Forward_Haar_Levels (One, 1), One), "one sample forward is unchanged");
      Note (Same_Int (Inverse_Haar_Levels (One, 1), One), "one sample inverse is unchanged");
      begin
         declare
            Dummy : constant Signal_1D_Int := Forward_Haar_Levels (Six, 2);
         begin
            Note (False, "length 6 with 2 levels was accepted");
         end;
      exception
         when Invalid_Dimensions =>
            Raised_F := True;
      end;
      begin
         declare
            Dummy : constant Signal_1D_Int := Inverse_Haar_Levels (Six, 2);
         begin
            Note (False, "inverse length 6 with 2 levels was accepted");
         end;
      exception
         when Invalid_Dimensions =>
            Raised_I := True;
      end;
      Note (Raised_F, "length 6 with 2 levels raises Invalid_Dimensions");
      Note (Raised_I, "inverse length 6 with 2 levels raises Invalid_Dimensions");
   end;

   --  Two levels on values whose first detail is 2**31. The low-pass of
   --  the second level is the average of those averages.
   declare
      Sig : constant Signal_1D_Int := [-(2**30), 2**30, -(2**30), 2**30];
      Got : Signal_1D_Int (Sig'Range);
      Back : Signal_1D_Int (Sig'Range);
   begin
      Got := Forward_Haar_Levels (Sig, 2);
      Note (Got (1) = 0 and then Got (2) = 0
        and then Got (3) = 2**31 and then Got (4) = 2**31,
        "two levels keep a 2**31 detail");
      Back := Inverse_Haar_Levels (Got, 2);
      Note (Same_Int (Back, Sig), "two levels restore the signal");
   exception
      when Constraint_Error =>
         Note (False, "two levels raised Constraint_Error");
   end;

   --  S-transform on a pair whose sum is odd, and on negatives.
   --  floor((5+2)/2) = 3 and d = 2-5 = -3. Truncating (even-odd)/2 is not that.
   declare
      Odd_Sum : constant Signal_1D_Int := [5, 2, -5, 2];
      Got     : constant Signal_1D_Int := Forward_Haar_1D_Lossless (Odd_Sum);
      Expect  : constant Signal_1D_Int := Own_S (Odd_Sum);
      Back    : constant Signal_1D_Int := Inverse_Haar_1D_Lossless (Got);
   begin
      Note (Same_Int (Got, Expect), "integer Haar is the S-transform");
      Note (Same_Int (Back, Odd_Sum), "S-transform inverse restores the pair");
      Note (Same_Int (Own_S_Inverse (Expect), Odd_Sum),
        "own inverse of the S-transform restores the pair");
   end;

   --  Index origin other than 1, length 1, and a coefficient equal to the threshold.
   declare
      Shifted : constant Signal_1D (5 .. 8) := [2.0, 4.0, 6.0, 8.0];
      Got     : constant Signal_1D := Forward_Haar_1D (Shifted);
      One     : constant Signal_1D (4 .. 4) := [7.5];
      Q       : constant Signal_1D := Quantize ([1.0, -1.0, 0.5], 1.0);
   begin
      Note (Near (Got, Own_Float (Shifted)), "float Haar follows an index origin other than 1");
      Note (Got'First = 5 and then Got'Last = 8, "float Haar keeps the index range");
      Note (Forward_Haar_1D (One) (4) = 7.5, "length 1 is unchanged");
      Note (Q (Q'First) = 1.0 and then Q (Q'First + 1) = -1.0 and then Q (Q'Last) = 0.0,
        "quantization keeps a coefficient equal to the threshold");
   end;

   for Trial in 1 .. 12 loop
      declare
         N    : constant Positive := 2 + Positive (Next_U mod 4) * 2;
         Sig  : Signal_1D_Int (1 .. N);
         Flt  : Signal_1D (1 .. N);
         Got  : Signal_1D_Int (1 .. N);
         Back : Signal_1D_Int (1 .. N);
      begin
         for I in Sig'Range loop
            Sig (I) := Long_Integer (Integer (Next_U mod 41) - 20);
            Flt (I) := Float (Sig (I)) / 5.0;
         end loop;
         Got := Forward_Haar_1D_Lossless (Sig);
         Back := Inverse_Haar_1D_Lossless (Got);
         Note (Same_Int (Got, Own_S (Sig)), "random integer signal matches the S-transform");
         Note (Same_Int (Back, Sig), "random integer signal is restored");
         Note (Near (Forward_Haar_1D (Flt), Own_Float (Flt)), "random float signal matches Haar");
         Note (Near (Inverse_Haar_1D (Forward_Haar_1D (Flt)), Flt),
           "random float signal is restored");
      end;
   end loop;

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
   if Fails /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
