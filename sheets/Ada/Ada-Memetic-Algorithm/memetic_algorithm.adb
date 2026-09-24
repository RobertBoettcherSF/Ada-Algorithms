--  Memetic_Algorithm body — Lamarckian hybrid EA + local search.

pragma Ada_2022;

package body Memetic_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- RNG (Numerical Recipes–style LCG, period 2^32)
   ---------------------------------------------------------------------------

   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      U    : constant Unit_Interval := Next_Unit (State);
      Span : constant Natural := Hi - Lo;
      K    : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      K := Natural (Real (U) * Real (Span + 1));
      if K > Span then
         K := Span;
      end if;
      return Lo + K;
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Pop_Size           : Pop_Size_T    := 20;
      Generations        : Natural       := 50;
      Mutation_Rate      : Unit_Interval := 0.05;
      Local_Search_Steps : Natural       := 10;
      Tournament_Size    : Tourney_K     := 3;
      Seed               : Natural       := 1;
      Use_Steepest       : Boolean       := True;
      Improve_All        : Boolean       := True) return Config
   is
   begin
      return
        (Pop_Size           => Pop_Size,
         Generations        => Generations,
         Mutation_Rate      => Mutation_Rate,
         Local_Search_Steps => Local_Search_Steps,
         Tournament_Size    => Tournament_Size,
         Seed               => Seed,
         Use_Steepest       => Use_Steepest,
         Improve_All        => Improve_All);
   end Default_Config;

   function Config_Is_Valid (Cfg : Config) return Boolean is
   begin
      return Natural (Cfg.Tournament_Size) <= Natural (Cfg.Pop_Size);
   end Config_Is_Valid;

   ---------------------------------------------------------------------------
   -- Bit-string utilities
   ---------------------------------------------------------------------------

   function Hamming_Distance (A, B : Bit_String) return Natural is
      D : Natural := 0;
   begin
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Hamming_Distance;

   function Zero_Count (Bits : Bit_String) return Natural is
      Z : Natural := 0;
   begin
      for B of Bits loop
         if not B then
            Z := Z + 1;
         end if;
      end loop;
      return Z;
   end Zero_Count;

   function Ones_Count (Bits : Bit_String) return Natural is
   begin
      return Bits'Length - Zero_Count (Bits);
   end Ones_Count;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String is
      R : Bit_String := Bits;
   begin
      R (Index) := not R (Index);
      return R;
   end Flip_Bit;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
   is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Next_Unit (State) >= 0.5;
      end loop;
      return R;
   end Random_Bit_String;

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Src (Src'First + I - 1);
      end loop;
      return R;
   end Copy_Bits;

   function All_Ones (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => True];
   begin
      return B;
   end All_Ones;

   function All_Zeros (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => False];
   begin
      return B;
   end All_Zeros;

   ---------------------------------------------------------------------------
   -- Tournament / crossover / mutation (bits)
   ---------------------------------------------------------------------------

   function Tournament_Pick
     (State : in out RNG_State;
      Costs : Cost_Array;
      K     : Tourney_K) return Positive
   is
      Best_I : Positive;
      Cand_I : Positive;
      First  : constant Positive := Costs'First;
      Last   : constant Positive := Costs'Last;
   begin
      if Costs'Length < 2 or else Natural (K) > Costs'Length then
         raise Invalid_Argument;
      end if;

      Best_I := Next_Natural (State, First, Last);
      for T in 2 .. Natural (K) loop
         pragma Unreferenced (T);
         Cand_I := Next_Natural (State, First, Last);
         if Costs (Cand_I) < Costs (Best_I) then
            Best_I := Cand_I;
         end if;
      end loop;
      return Best_I;
   end Tournament_Pick;

   function One_Point_Crossover
     (Parent_A, Parent_B : Bit_String;
      State              : in out RNG_State) return Bit_String
   is
      N   : constant Bit_Count := Parent_A'Length;
      A   : constant Bit_String (1 .. N) := Copy_Bits (Parent_A, N);
      B   : constant Bit_String (1 .. N) := Copy_Bits (Parent_B, N);
      Cut : Natural;
      Child : Bit_String (1 .. N);
   begin
      if Parent_A'Length /= Parent_B'Length
        or else Parent_A'Length < 1
        or else Parent_A'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      --  Cut in 0 .. N: loci 1 .. Cut from A, Cut+1 .. N from B.
      Cut := Next_Natural (State, 0, Natural (N));
      for I in 1 .. N loop
         if Natural (I) <= Cut then
            Child (I) := A (I);
         else
            Child (I) := B (I);
         end if;
      end loop;
      return Child;
   end One_Point_Crossover;

   function Mutate_Bits
     (Bits  : Bit_String;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Bit_String
   is
      N : constant Bit_Count := Bits'Length;
      R : Bit_String (1 .. N) := Copy_Bits (Bits, N);
   begin
      if Bits'Length < 1 or else Bits'Length > Max_Bits then
         raise Invalid_Argument;
      end if;

      if Rate = 0.0 then
         return R;
      end if;

      for I in 1 .. N loop
         if Next_Unit (State) < Rate then
            R (I) := not R (I);
         end if;
      end loop;
      return R;
   end Mutate_Bits;

   function Local_Improve_Bits
     (Start     : Bit_String;
      Target    : Bit_String;
      Max_Steps : Natural;
      Steepest  : Boolean;
      Improves  : out Natural) return Bit_String
   is
      N     : constant Bit_Count := Start'Length;
      Cur   : Bit_String (1 .. N) := Copy_Bits (Start, N);
      Tgt   : constant Bit_String (1 .. N) := Copy_Bits (Target, N);
      Cost  : Real := Real (Hamming_Distance (Cur, Tgt));
      Found : Boolean;
      Best_N : Bit_String (1 .. N);
      Best_C : Real;
      Cand   : Bit_String (1 .. N);
      Cand_C : Real;
   begin
      if Start'Length /= Target'Length
        or else Start'Length < 1
        or else Start'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      Improves := 0;
      if Max_Steps = 0 or else Cost = 0.0 then
         return Cur;
      end if;

      for Step_I in 1 .. Max_Steps loop
         pragma Unreferenced (Step_I);
         Found := False;

         if Steepest then
            Best_C := Cost;
            Best_N := Cur;
            for K in 1 .. N loop
               Cand   := Flip_Bit (Cur, K);
               Cand_C := Real (Hamming_Distance (Cand, Tgt));
               if Cand_C < Best_C then
                  Found  := True;
                  Best_C := Cand_C;
                  Best_N := Cand;
               end if;
            end loop;
            if Found then
               Cur      := Best_N;
               Cost     := Best_C;
               Improves := Improves + 1;
            end if;
         else
            for K in 1 .. N loop
               Cand   := Flip_Bit (Cur, K);
               Cand_C := Real (Hamming_Distance (Cand, Tgt));
               if Cand_C < Cost then
                  Cur      := Cand;
                  Cost     := Cand_C;
                  Improves := Improves + 1;
                  Found    := True;
                  exit;
               end if;
            end loop;
         end if;

         exit when not Found;
         exit when Cost = 0.0;
      end loop;

      return Cur;
   end Local_Improve_Bits;

   function Local_Improve
     (Start     : Bit_String;
      Max_Steps : Natural;
      Steepest  : Boolean;
      Improves  : out Natural) return Bit_String
   is
   begin
      return Local_Improve_Bits
        (Start, All_Ones (Start'Length), Max_Steps, Steepest, Improves);
   end Local_Improve;

   ---------------------------------------------------------------------------
   -- TSP utilities
   ---------------------------------------------------------------------------

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative is
      Len : Real := 0.0;
      A, B : City_Index;
   begin
      for I in T'First .. T'Last - 1 loop
         A := T (I);
         B := T (I + 1);
         Len := Len + Real (D (A, B));
      end loop;
      A := T (T'Last);
      B := T (T'First);
      Len := Len + Real (D (A, B));
      return Non_Negative (Len);
   end Tour_Length;

   function Apply_2Opt (T : Tour; I, J : City_Index) return Tour is
      R   : Tour := T;
      Lo  : City_Index := I + 1;
      Hi  : City_Index := J;
      Tmp : City_Index;
   begin
      while Lo < Hi loop
         Tmp    := R (Lo);
         R (Lo) := R (Hi);
         R (Hi) := Tmp;
         Lo     := Lo + 1;
         Hi     := Hi - 1;
      end loop;
      return R;
   end Apply_2Opt;

   function Identity_Tour (N : City_Count) return Tour is
      T : Tour (1 .. City_Index (N));
   begin
      for I in T'Range loop
         T (I) := I;
      end loop;
      return T;
   end Identity_Tour;

   function Random_Tour
     (State : in out RNG_State; N : City_Count) return Tour
   is
      T    : Tour (1 .. City_Index (N));
      J    : City_Index;
      Tmp  : City_Index;
      Pick : Natural;
   begin
      for I in T'Range loop
         T (I) := I;
      end loop;
      for I in reverse T'First + 1 .. T'Last loop
         Pick := Next_Natural (State, Natural (T'First), Natural (I));
         J    := City_Index (Pick);
         Tmp  := T (I);
         T (I) := T (J);
         T (J) := Tmp;
      end loop;
      return T;
   end Random_Tour;

   function Is_Valid_Tour (T : Tour) return Boolean is
      Seen : array (1 .. Max_Cities) of Boolean := [others => False];
      C    : City_Index;
      N    : constant Natural := T'Length;
   begin
      if N < 2 or else N > Max_Cities then
         return False;
      end if;
      for I in T'Range loop
         C := T (I);
         if Natural (C) > N then
            return False;
         end if;
         if Seen (Positive (C)) then
            return False;
         end if;
         Seen (Positive (C)) := True;
      end loop;
      for K in 1 .. N loop
         if not Seen (K) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Tour;

   function Order_Crossover
     (Parent_A, Parent_B : Tour;
      State              : in out RNG_State) return Tour
   is
      N     : constant City_Count := Parent_A'Length;
      Child : Tour (1 .. City_Index (N)) := [others => 1];
      Taken : array (1 .. Max_Cities) of Boolean := [others => False];
      Lo, Hi, Tmp_I : City_Index;
      Pos   : City_Index;
      City  : City_Index;
      Placed : Natural := 0;
      Need   : Natural;
   begin
      if Parent_A'Length /= Parent_B'Length
        or else Parent_A'Length < 2
        or else Parent_A'Length > Max_Cities
        or else Parent_A'First /= 1
        or else Parent_B'First /= 1
      then
         raise Invalid_Argument;
      end if;

      Lo := City_Index (Next_Natural (State, 1, Natural (N)));
      Hi := City_Index (Next_Natural (State, 1, Natural (N)));
      if Lo > Hi then
         Tmp_I := Lo;
         Lo    := Hi;
         Hi    := Tmp_I;
      end if;

      --  Copy segment [Lo .. Hi] from A.
      for I in Lo .. Hi loop
         Child (I) := Parent_A (I);
         Taken (Positive (Parent_A (I))) := True;
         Placed := Placed + 1;
      end loop;

      Need := Natural (N) - Placed;
      if Need = 0 then
         return Child;
      end if;

      --  Start filling just after Hi; walk B in order (wrap), skip taken.
      if Hi = City_Index (N) then
         Pos := 1;
      else
         Pos := Hi + 1;
      end if;

      declare
         B_Idx : City_Index := Pos;
         Filled : Natural := 0;
      begin
         while Filled < Need loop
            City := Parent_B (B_Idx);
            if not Taken (Positive (City)) then
               --  Advance Pos to next unfilled slot (outside [Lo..Hi]).
               while Pos >= Lo and then Pos <= Hi loop
                  if Pos = City_Index (N) then
                     Pos := 1;
                  else
                     Pos := Pos + 1;
                  end if;
               end loop;
               Child (Pos) := City;
               Taken (Positive (City)) := True;
               Filled := Filled + 1;
               if Pos = City_Index (N) then
                  Pos := 1;
               else
                  Pos := Pos + 1;
               end if;
            end if;
            if B_Idx = City_Index (N) then
               B_Idx := 1;
            else
               B_Idx := B_Idx + 1;
            end if;
         end loop;
      end;

      return Child;
   end Order_Crossover;

   function Mutate_Tour
     (T     : Tour;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Tour
   is
      N   : constant City_Count := T'Length;
      R   : Tour (1 .. City_Index (N));
      I, J : City_Index;
      Tmp : City_Index;
   begin
      if T'Length < 2 or else T'Length > Max_Cities then
         raise Invalid_Argument;
      end if;

      for K in 1 .. City_Index (N) loop
         R (K) := T (T'First + (K - 1));
      end loop;

      if Rate = 0.0 then
         return R;
      end if;

      if Next_Unit (State) < Rate then
         I := City_Index (Next_Natural (State, 1, Natural (N)));
         J := City_Index (Next_Natural (State, 1, Natural (N)));
         if I /= J then
            Tmp  := R (I);
            R (I) := R (J);
            R (J) := Tmp;
         end if;
      end if;
      return R;
   end Mutate_Tour;

   function Local_Improve_TSP
     (Start     : Tour;
      D         : Dist_Matrix;
      Max_Steps : Natural;
      Steepest  : Boolean;
      Improves  : out Natural) return Tour
   is
      N     : constant City_Count := Start'Length;
      Cur   : Tour (1 .. City_Index (N));
      Cost  : Non_Negative;
      Found : Boolean;
      Best_T : Tour (1 .. City_Index (N));
      Best_C : Non_Negative;
      Cand   : Tour (1 .. City_Index (N));
      Cand_C : Non_Negative;
   begin
      if Start'First /= D'First (1)
        or else Start'Last /= D'Last (1)
        or else D'First (1) /= D'First (2)
        or else D'Last (1) /= D'Last (2)
        or else Start'Length < 2
        or else Start'Length > Max_Cities
      then
         raise Invalid_Argument;
      end if;

      for K in Cur'Range loop
         Cur (K) := Start (Start'First + (K - 1));
      end loop;
      Cost     := Tour_Length (Cur, D);
      Improves := 0;

      if Max_Steps = 0 then
         return Cur;
      end if;

      for Step_I in 1 .. Max_Steps loop
         pragma Unreferenced (Step_I);
         Found := False;

         if Steepest then
            Best_C := Cost;
            Best_T := Cur;
            for I in Cur'First .. Cur'Last - 2 loop
               for J in I + 2 .. Cur'Last loop
                  if not (I = Cur'First and then J = Cur'Last) then
                     Cand   := Apply_2Opt (Cur, I, J);
                     Cand_C := Tour_Length (Cand, D);
                     if Cand_C < Best_C then
                        Found  := True;
                        Best_C := Cand_C;
                        Best_T := Cand;
                     end if;
                  end if;
               end loop;
            end loop;
            if Found then
               Cur      := Best_T;
               Cost     := Best_C;
               Improves := Improves + 1;
            end if;
         else
            Outer :
            for I in Cur'First .. Cur'Last - 2 loop
               for J in I + 2 .. Cur'Last loop
                  if not (I = Cur'First and then J = Cur'Last) then
                     Cand   := Apply_2Opt (Cur, I, J);
                     Cand_C := Tour_Length (Cand, D);
                     if Cand_C < Cost then
                        Cur      := Cand;
                        Cost     := Cand_C;
                        Improves := Improves + 1;
                        Found    := True;
                        exit Outer;
                     end if;
                  end if;
               end loop;
            end loop Outer;
         end if;

         exit when not Found;
      end loop;

      return Cur;
   end Local_Improve_TSP;

   ---------------------------------------------------------------------------
   -- Pack helpers
   ---------------------------------------------------------------------------

   function Pack_Bits
     (Cur : Bit_String; N : Bit_Count; Cost : Real;
      Gens, Improves, Evals : Natural) return Bit_Result
   is
      R : Bit_Result;
   begin
      R.N               := N;
      R.Best_Cost       := Cost;
      R.Generations_Run := Gens;
      R.Local_Improves  := Improves;
      R.Evaluations     := Evals;
      for I in 1 .. N loop
         R.Best_Bits (I) := Cur (I);
      end loop;
      return R;
   end Pack_Bits;

   function Pack_Tour
     (Cur : Tour; N : City_Count; Len : Non_Negative;
      Gens, Improves, Evals : Natural) return TSP_Result
   is
      R : TSP_Result;
   begin
      R.N               := N;
      R.Best_Length     := Len;
      R.Generations_Run := Gens;
      R.Local_Improves  := Improves;
      R.Evaluations     := Evals;
      for I in 1 .. City_Index (N) loop
         R.Best_Tour (I) := Cur (I);
      end loop;
      return R;
   end Pack_Tour;

   ---------------------------------------------------------------------------
   -- Drivers (bits)
   ---------------------------------------------------------------------------

   function Run_Bit_MA
     (Target : Bit_String; Cfg : Config) return Bit_Result
   is
      N       : constant Bit_Count := Target'Length;
      P       : constant Pop_Size_T := Cfg.Pop_Size;
      State   : RNG_State;
      Pop     : array (1 .. Max_Pop) of Bit_String (1 .. Max_Bits);
      Costs   : Cost_Array (1 .. Max_Pop);
      Next_P  : array (1 .. Max_Pop) of Bit_String (1 .. Max_Bits);
      Next_C  : Cost_Array (1 .. Max_Pop);
      Best    : Bit_String (1 .. N);
      Best_C  : Real;
      Evals   : Natural := 0;
      Improves_Total : Natural := 0;
      Step_Imp : Natural;
      IA, IB  : Positive;
      Child   : Bit_String (1 .. N);
      Elite_Cut : Positive;
      Cost_Slice : Cost_Array (1 .. Natural (P));
      Tgt     : constant Bit_String (1 .. N) := Copy_Bits (Target, N);
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);

      --  Init population.
      Best_C := Real (N) + 1.0;
      for I in 1 .. Natural (P) loop
         declare
            Ind : constant Bit_String := Random_Bit_String (State, N);
         begin
            for K in 1 .. N loop
               Pop (I) (K) := Ind (K);
            end loop;
            Costs (I) := Real (Hamming_Distance (Ind, Tgt));
            Evals := Evals + 1;
            if Costs (I) < Best_C then
               Best_C := Costs (I);
               Best   := Ind;
            end if;
         end;
      end loop;

      --  Optional init local improve (Lamarckian warm-start on whole pop).
      if Cfg.Local_Search_Steps > 0 then
         for I in 1 .. Natural (P) loop
            declare
               Cur : constant Bit_String (1 .. N) :=
                 Copy_Bits (Pop (I) (1 .. N), N);
               Imp : Bit_String (1 .. N);
            begin
               Imp := Local_Improve_Bits
                 (Cur, Tgt, Cfg.Local_Search_Steps,
                  Cfg.Use_Steepest, Step_Imp);
               Improves_Total := Improves_Total + Step_Imp;
               for K in 1 .. N loop
                  Pop (I) (K) := Imp (K);
               end loop;
               Costs (I) := Real (Hamming_Distance (Imp, Tgt));
               Evals := Evals + 1;
               if Costs (I) < Best_C then
                  Best_C := Costs (I);
                  Best   := Imp;
               end if;
            end;
         end loop;
      end if;

      if Cfg.Generations = 0 then
         return Pack_Bits (Best, N, Best_C, 0, Improves_Total, Evals);
      end if;

      --  P >= 2 ⇒ Natural(P)/2 >= 1.
      Elite_Cut := Positive (Natural (P) / 2);

      declare
         Gens_Done : Natural := 0;
      begin
         for Gen in 1 .. Cfg.Generations loop
            Gens_Done := Gen;
            for I in 1 .. Natural (P) loop
               Cost_Slice (I) := Costs (I);
            end loop;

            for Off in 1 .. Natural (P) loop
               IA := Tournament_Pick (State, Cost_Slice, Cfg.Tournament_Size);
               IB := Tournament_Pick (State, Cost_Slice, Cfg.Tournament_Size);
               Child := One_Point_Crossover
                 (Copy_Bits (Pop (IA) (1 .. N), N),
                  Copy_Bits (Pop (IB) (1 .. N), N),
                  State);
               Child := Mutate_Bits (Child, Cfg.Mutation_Rate, State);

               if Cfg.Improve_All
                 or else Off <= Elite_Cut
               then
                  if Cfg.Local_Search_Steps > 0 then
                     Child := Local_Improve_Bits
                       (Child, Tgt, Cfg.Local_Search_Steps,
                        Cfg.Use_Steepest, Step_Imp);
                     Improves_Total := Improves_Total + Step_Imp;
                  end if;
               end if;

               for K in 1 .. N loop
                  Next_P (Off) (K) := Child (K);
               end loop;
               Next_C (Off) := Real (Hamming_Distance (Child, Tgt));
               Evals := Evals + 1;
               if Next_C (Off) < Best_C then
                  Best_C := Next_C (Off);
                  Best   := Child;
               end if;
            end loop;

            for I in 1 .. Natural (P) loop
               for K in 1 .. N loop
                  Pop (I) (K) := Next_P (I) (K);
               end loop;
               Costs (I) := Next_C (I);
            end loop;

            exit when Best_C = 0.0;
         end loop;

         return Pack_Bits
           (Best, N, Best_C, Gens_Done, Improves_Total, Evals);
      end;
   end Run_Bit_MA;

   function Minimize_OneMax
     (N : Bit_Count; Cfg : Config) return Bit_Result
   is
   begin
      return Run_Bit_MA (All_Ones (N), Cfg);
   end Minimize_OneMax;

   function Minimize_Hamming
     (Target : Bit_String; Cfg : Config) return Bit_Result
   is
      N : constant Bit_Count := Target'Length;
   begin
      return Run_Bit_MA (Copy_Bits (Target, N), Cfg);
   end Minimize_Hamming;

   ---------------------------------------------------------------------------
   -- Driver (TSP)
   ---------------------------------------------------------------------------

   function Minimize_TSP
     (D : Dist_Matrix; Cfg : Config) return TSP_Result
   is
      N       : constant City_Count := D'Length (1);
      P       : constant Pop_Size_T := Cfg.Pop_Size;
      State   : RNG_State;
      Pop     : array (1 .. Max_Pop) of Tour (1 .. Max_Cities);
      Costs   : Cost_Array (1 .. Max_Pop);
      Next_P  : array (1 .. Max_Pop) of Tour (1 .. Max_Cities);
      Next_C  : Cost_Array (1 .. Max_Pop);
      Best    : Tour (1 .. City_Index (N));
      Best_C  : Non_Negative;
      Evals   : Natural := 0;
      Improves_Total : Natural := 0;
      Step_Imp : Natural;
      IA, IB  : Positive;
      Child   : Tour (1 .. City_Index (N));
      Elite_Cut : Positive;
      Cost_Slice : Cost_Array (1 .. Natural (P));
      First_Init : Boolean := True;
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;
      if D'First (1) /= D'First (2)
        or else D'Last (1) /= D'Last (2)
        or else D'Length (1) < 2
        or else D'Length (1) > Max_Cities
      then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);
      Best_C := Non_Negative'Last;

      for I in 1 .. Natural (P) loop
         declare
            Ind : constant Tour := Random_Tour (State, N);
         begin
            for K in 1 .. City_Index (N) loop
               Pop (I) (K) := Ind (K);
            end loop;
            Costs (I) := Real (Tour_Length (Ind, D));
            Evals := Evals + 1;
            if First_Init or else Non_Negative (Costs (I)) < Best_C then
               Best_C := Non_Negative (Costs (I));
               Best   := Ind;
               First_Init := False;
            end if;
         end;
      end loop;

      if Cfg.Local_Search_Steps > 0 then
         for I in 1 .. Natural (P) loop
            declare
               Cur : Tour (1 .. City_Index (N));
               Imp : Tour (1 .. City_Index (N));
            begin
               for K in Cur'Range loop
                  Cur (K) := Pop (I) (K);
               end loop;
               Imp := Local_Improve_TSP
                 (Cur, D, Cfg.Local_Search_Steps,
                  Cfg.Use_Steepest, Step_Imp);
               Improves_Total := Improves_Total + Step_Imp;
               for K in Imp'Range loop
                  Pop (I) (K) := Imp (K);
               end loop;
               Costs (I) := Real (Tour_Length (Imp, D));
               Evals := Evals + 1;
               if Non_Negative (Costs (I)) < Best_C then
                  Best_C := Non_Negative (Costs (I));
                  Best   := Imp;
               end if;
            end;
         end loop;
      end if;

      if Cfg.Generations = 0 then
         return Pack_Tour (Best, N, Best_C, 0, Improves_Total, Evals);
      end if;

      --  P >= 2 ⇒ Natural(P)/2 >= 1.
      Elite_Cut := Positive (Natural (P) / 2);

      declare
         Gens_Done : Natural := 0;
      begin
         for Gen in 1 .. Cfg.Generations loop
            Gens_Done := Gen;
            for I in 1 .. Natural (P) loop
               Cost_Slice (I) := Costs (I);
            end loop;

            for Off in 1 .. Natural (P) loop
               IA := Tournament_Pick (State, Cost_Slice, Cfg.Tournament_Size);
               IB := Tournament_Pick (State, Cost_Slice, Cfg.Tournament_Size);

               declare
                  PA : Tour (1 .. City_Index (N));
                  PB : Tour (1 .. City_Index (N));
               begin
                  for K in PA'Range loop
                     PA (K) := Pop (IA) (K);
                     PB (K) := Pop (IB) (K);
                  end loop;
                  Child := Order_Crossover (PA, PB, State);
               end;
               Child := Mutate_Tour (Child, Cfg.Mutation_Rate, State);

               if Cfg.Improve_All or else Off <= Elite_Cut then
                  if Cfg.Local_Search_Steps > 0 then
                     Child := Local_Improve_TSP
                       (Child, D, Cfg.Local_Search_Steps,
                        Cfg.Use_Steepest, Step_Imp);
                     Improves_Total := Improves_Total + Step_Imp;
                  end if;
               end if;

               for K in Child'Range loop
                  Next_P (Off) (K) := Child (K);
               end loop;
               Next_C (Off) := Real (Tour_Length (Child, D));
               Evals := Evals + 1;
               if Non_Negative (Next_C (Off)) < Best_C then
                  Best_C := Non_Negative (Next_C (Off));
                  Best   := Child;
               end if;
            end loop;

            for I in 1 .. Natural (P) loop
               for K in 1 .. City_Index (N) loop
                  Pop (I) (K) := Next_P (I) (K);
               end loop;
               Costs (I) := Next_C (I);
            end loop;
         end loop;

         return Pack_Tour
           (Best, N, Best_C, Gens_Done, Improves_Total, Evals);
      end;
   end Minimize_TSP;

   ---------------------------------------------------------------------------
   -- To_Result
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result is
   begin
      return
        (Best_Cost       => R.Best_Cost,
         Generations_Run => R.Generations_Run,
         Local_Improves  => R.Local_Improves,
         Evaluations     => R.Evaluations);
   end To_Result;

   function To_Result (R : TSP_Result) return Result is
   begin
      return
        (Best_Cost       => Real (R.Best_Length),
         Generations_Run => R.Generations_Run,
         Local_Improves  => R.Local_Improves,
         Evaluations     => R.Evaluations);
   end To_Result;

end Memetic_Algorithm;
