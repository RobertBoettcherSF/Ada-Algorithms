--  Wang_Landau package body — flat-histogram density-of-states sampling.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Wang_Landau is

   package EF renames Ada.Numerics.Elementary_Functions;
   package FR renames Ada.Numerics.Float_Random;

   type Bool_Mask is array (Bin_Index range <>) of Boolean;

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Exp_R (X : Real) return Real is
   begin
      if X > 700.0 then
         return Real'Last / 4.0;
      elsif X < -700.0 then
         return 0.0;
      else
         return Real (EF.Exp (Float (X)));
      end if;
   end Exp_R;

   --  Flatness: among allowed bins, require every bin visited and
   --  min H >= Flatness * mean H; also require enough total entries.
   function Histogram_Is_Flat
     (H           : Visit_Array;
      Mask        : Bool_Mask;
      Flatness    : Unit_Fraction;
      Min_Entries : Positive) return Boolean
   is
      Count : Natural := 0;
      Sum   : Natural := 0;
      Min_H : Natural := Natural'Last;
      Mean  : Real;
   begin
      if H'Length /= Mask'Length
        or else H'First /= Mask'First
        or else H'Last /= Mask'Last
      then
         return False;
      end if;

      for K in H'Range loop
         if Mask (K) then
            Count := Count + 1;
            Sum := Sum + H (K);
            if H (K) < Min_H then
               Min_H := H (K);
            end if;
         end if;
      end loop;

      if Count = 0 or else Sum < Min_Entries then
         return False;
      end if;
      if Min_H = 0 then
         return False;
      end if;

      Mean := Real (Sum) / Real (Count);
      return Real (Min_H) >= Flatness * Mean;
   end Histogram_Is_Flat;

   procedure Shift_Ln_G_To_Zero_Max (Ln_G : in out Ln_G_Array) is
      M : Real := Ln_G (Ln_G'First);
   begin
      for K in Ln_G'Range loop
         if Ln_G (K) > M then
            M := Ln_G (K);
         end if;
      end loop;
      for K in Ln_G'Range loop
         Ln_G (K) := Ln_G (K) - M;
      end loop;
   end Shift_Ln_G_To_Zero_Max;

   function Uniform_Index
     (Gen : in out FR.Generator;
      N   : Positive) return Natural
   is
      U   : constant Float := FR.Random (Gen);
      Idx : Natural := Natural (Float'Floor (U * Float (N)));
   begin
      if Idx >= N then
         Idx := N - 1;
      end if;
      return Idx;
   end Uniform_Index;

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function N_Bins (R : Result) return Bin_Count is
   begin
      return R.Last_Bin + 1;
   end N_Bins;

   function Normalize_Density
     (Ln_G  : Ln_G_Array;
      Total : Non_Negative := 1.0) return Density_Array
   is
      Out_D : Density_Array (Ln_G'Range);
      M     : Real := Ln_G (Ln_G'First);
      Sum   : Real := 0.0;
   begin
      for K in Ln_G'Range loop
         if Ln_G (K) > M then
            M := Ln_G (K);
         end if;
      end loop;
      for K in Ln_G'Range loop
         Out_D (K) := Exp_R (Ln_G (K) - M);
         Sum := Sum + Out_D (K);
      end loop;
      if Sum <= 0.0 then
         return Out_D;
      end if;
      for K in Out_D'Range loop
         Out_D (K) := Out_D (K) * (Total / Sum);
      end loop;
      return Out_D;
   end Normalize_Density;

   function Exact_Binomial_Density (L : Positive) return Density_Array is
      Out_D : Density_Array (0 .. L);
      C     : Real := 1.0;
   begin
      Out_D (0) := 1.0;
      for K in 1 .. L loop
         C := C * Real (L - K + 1) / Real (K);
         Out_D (K) := C;
      end loop;
      return Out_D;
   end Exact_Binomial_Density;

   function Relative_L1
     (Estimate : Density_Array;
      Exact    : Density_Array) return Non_Negative
   is
      Sum_Abs : Real := 0.0;
      Sum_Ex  : Real := 0.0;
   begin
      for K in Estimate'Range loop
         Sum_Abs := Sum_Abs + abs (Estimate (K) - Exact (K));
         Sum_Ex  := Sum_Ex + Exact (K);
      end loop;
      if Sum_Ex <= 0.0 then
         return 0.0;
      end if;
      return Sum_Abs / Sum_Ex;
   end Relative_L1;

   function Canonical_Mean_Energy
     (Ln_G     : Ln_G_Array;
      Energies : Energy_Array;
      T        : Positive_Real) return Real
   is
      Max_W : Real := 0.0;
      W     : Real;
      Z     : Real := 0.0;
      Acc   : Real := 0.0;
      First : Boolean := True;
   begin
      for K in Ln_G'Range loop
         W := Ln_G (K) - Energies (K) / T;
         if First or else W > Max_W then
            Max_W := W;
            First := False;
         end if;
      end loop;
      for K in Ln_G'Range loop
         W := Exp_R (Ln_G (K) - Energies (K) / T - Max_W);
         Z := Z + W;
         Acc := Acc + Energies (K) * W;
      end loop;
      if Z <= 0.0 then
         return 0.0;
      end if;
      return Acc / Z;
   end Canonical_Mean_Energy;

   function Ising_Energy_To_Bin (E : Integer; N : Positive) return Bin_Index is
   begin
      return Bin_Index ((E + Integer (N)) / 2);
   end Ising_Energy_To_Bin;

   function Ising_Bin_To_Energy (K : Bin_Index; N : Positive) return Integer is
   begin
      return -Integer (N) + 2 * Integer (K);
   end Ising_Bin_To_Energy;

   function Exact_Ising_1D_Density (N : Positive) return Density_Array is
      Out_D : Density_Array (0 .. N) := [others => 0.0];
      Limit : constant Natural := 2 ** N;
   begin
      for Mask_Val in 0 .. Limit - 1 loop
         declare
            E     : Integer := 0;
            S_I   : Integer;
            S_Ip1 : Integer;
         begin
            for I in 0 .. N - 1 loop
               if (Mask_Val / (2 ** I)) mod 2 = 0 then
                  S_I := -1;
               else
                  S_I := 1;
               end if;
               if (Mask_Val / (2 ** ((I + 1) mod N))) mod 2 = 0 then
                  S_Ip1 := -1;
               else
                  S_Ip1 := 1;
               end if;
               E := E - S_I * S_Ip1;
            end loop;
            declare
               K : constant Bin_Index := Ising_Energy_To_Bin (E, N);
            begin
               Out_D (K) := Out_D (K) + 1.0;
            end;
         end;
      end loop;
      return Out_D;
   end Exact_Ising_1D_Density;

   -------------------------------------------------------------------------
   -- Two-level toy
   -------------------------------------------------------------------------

   function Estimate_Two_Level
     (G0  : Positive;
      G1  : Positive;
      Cfg : Config := (others => <>)) return Result
   is
      Res    : Result (Last_Bin => 1);
      Gen    : FR.Generator;
      Ln_G   : Ln_G_Array (0 .. 1) := [others => 0.0];
      H      : Visit_Array (0 .. 1) := [others => 0];
      Mask   : constant Bool_Mask (0 .. 1) := [True, True];
      Ln_F   : Real := Cfg.Ln_F_Initial;
      State  : Natural;
      E_Cur  : Bin_Index;
      Total  : constant Positive := G0 + G1;
      Stage  : Natural := 0;
      Steps  : Natural := 0;
      F_Stop : constant Real :=
        (if Cfg.F_Final < 1.0E-30 then 1.0E-30 else Cfg.F_Final);

      function Energy_Of (S : Natural) return Bin_Index is
      begin
         if S < G0 then
            return 0;
         else
            return 1;
         end if;
      end Energy_Of;

      procedure One_Step is
         S_New : constant Natural := Uniform_Index (Gen, Total);
         E_New : constant Bin_Index := Energy_Of (S_New);
         Diff  : constant Real := Ln_G (E_Cur) - Ln_G (E_New);
         Acc   : Boolean;
      begin
         if Diff >= 0.0 then
            Acc := True;
         else
            Acc := Real (FR.Random (Gen)) < Exp_R (Diff);
         end if;
         if Acc then
            State := S_New;
            E_Cur := E_New;
         end if;
         Ln_G (E_Cur) := Ln_G (E_Cur) + Ln_F;
         H (E_Cur) := H (E_Cur) + 1;
         Steps := Steps + 1;
      end One_Step;

   begin
      if Cfg.Ln_F_Initial <= 0.0 or else Cfg.F_Final <= 0.0 then
         raise Invalid_Argument with "Ln_F_Initial and F_Final must be > 0";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      State := Uniform_Index (Gen, Total);
      E_Cur := Energy_Of (State);

      while Stage < Cfg.Max_Stages and then Exp_R (Ln_F) - 1.0 >= F_Stop loop
         H := [others => 0];
         declare
            Guard      : Natural := 0;
            Max_Guards : constant Natural :=
              Natural'Max
                (Cfg.Max_Stages * Cfg.Steps_Per_Check * 200, 100_000);
         begin
            loop
               for I in 1 .. Cfg.Steps_Per_Check loop
                  One_Step;
               end loop;
               Guard := Guard + Cfg.Steps_Per_Check;
               exit when Histogram_Is_Flat
                 (H, Mask, Cfg.Flatness, Cfg.Min_Entries);
               exit when Guard >= Max_Guards;
            end loop;
         end;
         Stage := Stage + 1;
         Ln_F := Ln_F * 0.5;
      end loop;

      Shift_Ln_G_To_Zero_Max (Ln_G);
      Res.Ln_G := Ln_G;
      Res.Visits := H;
      Res.Stages := Stage;
      Res.Total_Steps := Steps;
      Res.Final_Ln_F := Ln_F;
      Res.Converged := Exp_R (Ln_F) - 1.0 < F_Stop;
      return Res;
   end Estimate_Two_Level;

   -------------------------------------------------------------------------
   -- Binomial bit model
   -------------------------------------------------------------------------

   function Estimate_Binomial
     (L   : Positive;
      Cfg : Config := (others => <>)) return Result
   is
      Res    : Result (Last_Bin => L);
      Gen    : FR.Generator;
      Ln_G   : Ln_G_Array (0 .. L) := [others => 0.0];
      H      : Visit_Array (0 .. L) := [others => 0];
      Mask   : constant Bool_Mask (0 .. L) := [others => True];
      Ln_F   : Real := Cfg.Ln_F_Initial;
      Bits   : array (0 .. L - 1) of Boolean := [others => False];
      E_Cur  : Natural := 0;
      Stage  : Natural := 0;
      Steps  : Natural := 0;
      F_Stop : constant Real :=
        (if Cfg.F_Final < 1.0E-30 then 1.0E-30 else Cfg.F_Final);

      procedure One_Step is
         I     : constant Natural := Uniform_Index (Gen, L);
         E_New : Natural;
         Diff  : Real;
         Acc   : Boolean;
      begin
         if Bits (I) then
            E_New := E_Cur - 1;
         else
            E_New := E_Cur + 1;
         end if;
         Diff := Ln_G (E_Cur) - Ln_G (E_New);
         if Diff >= 0.0 then
            Acc := True;
         else
            Acc := Real (FR.Random (Gen)) < Exp_R (Diff);
         end if;
         if Acc then
            Bits (I) := not Bits (I);
            E_Cur := E_New;
         end if;
         Ln_G (E_Cur) := Ln_G (E_Cur) + Ln_F;
         H (E_Cur) := H (E_Cur) + 1;
         Steps := Steps + 1;
      end One_Step;

   begin
      if L >= Max_Bins then
         raise Invalid_Argument with "L must be < Max_Bins";
      end if;
      if Cfg.Ln_F_Initial <= 0.0 or else Cfg.F_Final <= 0.0 then
         raise Invalid_Argument with "Ln_F_Initial and F_Final must be > 0";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      E_Cur := 0;
      for I in Bits'Range loop
         Bits (I) := FR.Random (Gen) < 0.5;
         if Bits (I) then
            E_Cur := E_Cur + 1;
         end if;
      end loop;

      while Stage < Cfg.Max_Stages and then Exp_R (Ln_F) - 1.0 >= F_Stop loop
         H := [others => 0];
         declare
            Guard      : Natural := 0;
            Max_Guards : constant Natural :=
              Natural'Max
                (Cfg.Max_Stages * Cfg.Steps_Per_Check * 500, 500_000);
         begin
            loop
               for J in 1 .. Cfg.Steps_Per_Check loop
                  One_Step;
               end loop;
               Guard := Guard + Cfg.Steps_Per_Check;
               exit when Histogram_Is_Flat
                 (H, Mask, Cfg.Flatness, Cfg.Min_Entries);
               exit when Guard >= Max_Guards;
            end loop;
         end;
         Stage := Stage + 1;
         Ln_F := Ln_F * 0.5;
      end loop;

      Shift_Ln_G_To_Zero_Max (Ln_G);
      Res.Ln_G := Ln_G;
      Res.Visits := H;
      Res.Stages := Stage;
      Res.Total_Steps := Steps;
      Res.Final_Ln_F := Ln_F;
      Res.Converged := Exp_R (Ln_F) - 1.0 < F_Stop;
      return Res;
   end Estimate_Binomial;

   -------------------------------------------------------------------------
   -- 1D Ising
   -------------------------------------------------------------------------

   function Estimate_Ising_1D
     (N   : Positive;
      Cfg : Config := (others => <>)) return Result
   is
      Res    : Result (Last_Bin => N);
      Gen    : FR.Generator;
      Ln_G   : Ln_G_Array (0 .. N) := [others => 0.0];
      H      : Visit_Array (0 .. N) := [others => 0];
      Mask   : Bool_Mask (0 .. N);
      Ln_F   : Real := Cfg.Ln_F_Initial;
      Spins  : array (0 .. N - 1) of Integer := [others => 1];
      E_Int  : Integer;
      E_Cur  : Bin_Index;
      Stage  : Natural := 0;
      Steps  : Natural := 0;
      F_Stop : constant Real :=
        (if Cfg.F_Final < 1.0E-30 then 1.0E-30 else Cfg.F_Final);

      function Compute_Energy return Integer is
         E : Integer := 0;
      begin
         for I in 0 .. N - 1 loop
            E := E - Spins (I) * Spins ((I + 1) mod N);
         end loop;
         return E;
      end Compute_Energy;

      procedure One_Step is
         I         : constant Natural := Uniform_Index (Gen, N);
         S_Prev    : constant Integer := Spins ((I + N - 1) mod N);
         S_Next    : constant Integer := Spins ((I + 1) mod N);
         D_E       : constant Integer := 2 * Spins (I) * (S_Prev + S_Next);
         E_New_Int : constant Integer := E_Int + D_E;
         E_New     : constant Bin_Index := Ising_Energy_To_Bin (E_New_Int, N);
         Diff      : constant Real := Ln_G (E_Cur) - Ln_G (E_New);
         Acc       : Boolean;
      begin
         if Diff >= 0.0 then
            Acc := True;
         else
            Acc := Real (FR.Random (Gen)) < Exp_R (Diff);
         end if;
         if Acc then
            Spins (I) := -Spins (I);
            E_Int := E_New_Int;
            E_Cur := E_New;
         end if;
         Ln_G (E_Cur) := Ln_G (E_Cur) + Ln_F;
         H (E_Cur) := H (E_Cur) + 1;
         Steps := Steps + 1;
      end One_Step;

   begin
      if N < 2 or else N > Max_Ising_N then
         raise Invalid_Argument with "Ising N must be in 2 .. Max_Ising_N";
      end if;
      if Cfg.Ln_F_Initial <= 0.0 or else Cfg.F_Final <= 0.0 then
         raise Invalid_Argument with "Ln_F_Initial and F_Final must be > 0";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      for I in Spins'Range loop
         if FR.Random (Gen) < 0.5 then
            Spins (I) := -1;
         else
            Spins (I) := 1;
         end if;
      end loop;
      E_Int := Compute_Energy;
      E_Cur := Ising_Energy_To_Bin (E_Int, N);

      --  Mask unreachable energies (exact g = 0) so flatness ignores them.
      declare
         Exact : constant Density_Array := Exact_Ising_1D_Density (N);
      begin
         for K in Mask'Range loop
            Mask (K) := Exact (K) > 0.0;
         end loop;
      end;

      while Stage < Cfg.Max_Stages and then Exp_R (Ln_F) - 1.0 >= F_Stop loop
         H := [others => 0];
         declare
            Guard      : Natural := 0;
            Max_Guards : constant Natural :=
              Natural'Max
                (Cfg.Max_Stages * Cfg.Steps_Per_Check * 800, 1_000_000);
         begin
            loop
               for J in 1 .. Cfg.Steps_Per_Check loop
                  One_Step;
               end loop;
               Guard := Guard + Cfg.Steps_Per_Check;
               exit when Histogram_Is_Flat
                 (H, Mask, Cfg.Flatness, Cfg.Min_Entries);
               exit when Guard >= Max_Guards;
            end loop;
         end;
         Stage := Stage + 1;
         Ln_F := Ln_F * 0.5;
      end loop;

      Shift_Ln_G_To_Zero_Max (Ln_G);
      Res.Ln_G := Ln_G;
      Res.Visits := H;
      Res.Stages := Stage;
      Res.Total_Steps := Steps;
      Res.Final_Ln_F := Ln_F;
      Res.Converged := Exp_R (Ln_F) - 1.0 < F_Stop;
      return Res;
   end Estimate_Ising_1D;

end Wang_Landau;
