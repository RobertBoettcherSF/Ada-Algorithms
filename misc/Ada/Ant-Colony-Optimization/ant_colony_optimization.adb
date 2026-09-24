--  Ant_Colony_Optimization body — classical Ant System for TSP:
--  Init_Pheromone, Construct_Tour (τ^α η^β), Update_Pheromone /
--  Colony_Update (evaporate + Q/L deposit), Solve_TSP.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Ant_Colony_Optimization
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Alpha          : Non_Negative  := 1.0;
      Beta           : Non_Negative  := 2.0;
      Rho            : Unit_Interval := 0.5;
      Q              : Non_Negative  := 100.0;
      N_Ants        : Ant_Count     := 10;
      Max_Iterations : Natural       := 100;
      Seed           : Natural       := 1;
      Best_Only      : Boolean       := False;
      Initial_Tau    : Non_Negative  := 1.0) return Config
   is
   begin
      return
        (Alpha          => Alpha,
         Beta           => Beta,
         Rho            => Rho,
         Q              => Q,
         N_Ants        => N_Ants,
         Max_Iterations => Max_Iterations,
         Seed           => Seed,
         Best_Only      => Best_Only,
         Initial_Tau    => Initial_Tau);
   end Default_Config;

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

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + Real (U) * (Hi - Lo);
   end Next_Uniform;

   function Next_Index
     (State : in out RNG_State; Lo, Hi : City_Index) return City_Index
   is
      Span : constant Natural := Natural (Hi - Lo) + 1;
      U    : constant Unit_Interval := Next_Unit (State);
      K    : Natural;
   begin
      K := Natural (Real (U) * Real (Span));
      if K >= Span then
         K := Span - 1;
      end if;
      return City_Index (Natural (Lo) + K);
   end Next_Index;

   ---------------------------------------------------------------------------
   -- Distance / heuristic / tour utilities
   ---------------------------------------------------------------------------

   function Euclidean (A, B : Point2) return Non_Negative is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
   begin
      return Non_Negative (EF.Sqrt (Long_Float (DX * DX + DY * DY)));
   end Euclidean;

   function Euclidean_Matrix (Pts : Point2_Array) return Dist_Matrix is
      N : constant City_Count := City_Count (Pts'Length);
      D : Dist_Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      I0 : constant City_Index := Pts'First;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               D (I, J) := 0.0;
            else
               D (I, J) :=
                 Euclidean
                   (Pts (City_Index (Natural (I0) + Natural (I) - 1)),
                    Pts (City_Index (Natural (I0) + Natural (J) - 1)));
            end if;
         end loop;
      end loop;
      return D;
   end Euclidean_Matrix;

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative is
      Len  : Real := 0.0;
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

   function Is_Valid_Tour (T : Tour) return Boolean is
      Seen : array (City_Index range T'First .. T'Last) of Boolean :=
        [others => False];
      C : City_Index;
   begin
      for I in T'Range loop
         C := T (I);
         if C < T'First or else C > T'Last then
            return False;
         end if;
         if Seen (C) then
            return False;
         end if;
         Seen (C) := True;
      end loop;
      for I in Seen'Range loop
         if not Seen (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Tour;

   function Build_Heuristic (D : Dist_Matrix) return Heuristic_Matrix is
      N   : constant City_Count := City_Count (D'Length (1));
      Eta : Heuristic_Matrix (1 .. N, 1 .. N);
      Dist : Non_Negative;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Dist := D (I, J);
            if Dist <= 0.0 then
               Eta (I, J) := Big_Heuristic;
            else
               Eta (I, J) := Non_Negative (1.0 / Real (Dist));
            end if;
         end loop;
      end loop;
      return Eta;
   end Build_Heuristic;

   function Safe_Pow (Base, Exp : Non_Negative) return Non_Negative is
   begin
      if Exp = 0.0 then
         return 1.0;
      elsif Base = 0.0 then
         return 0.0;
      else
         return Non_Negative
           (EF.Exp (Long_Float (Exp) * EF.Log (Long_Float (Base))));
      end if;
   end Safe_Pow;

   function Edge_Weight
     (Tau_IJ : Non_Negative;
      Eta_IJ : Non_Negative;
      Alpha  : Non_Negative;
      Beta   : Non_Negative) return Non_Negative
   is
   begin
      return Non_Negative
        (Real (Safe_Pow (Tau_IJ, Alpha)) * Real (Safe_Pow (Eta_IJ, Beta)));
   end Edge_Weight;

   function Is_Visited
     (C : City_Index; Visited : Tour; Visit_Count : Natural) return Boolean
   is
      Idx : City_Index;
   begin
      for K in 1 .. Visit_Count loop
         Idx := City_Index (Natural (Visited'First) + K - 1);
         if Visited (Idx) = C then
            return True;
         end if;
      end loop;
      return False;
   end Is_Visited;

   function Transition_Probability
     (From        : City_Index;
      To          : City_Index;
      Tau         : Pheromone_Matrix;
      Eta         : Heuristic_Matrix;
      Visited     : Tour;
      Visit_Count : Natural;
      Alpha       : Non_Negative;
      Beta        : Non_Negative) return Unit_Interval
   is
      Total  : Real := 0.0;
      W_To   : Real := 0.0;
      W      : Real;
      Allowed : Boolean;
   begin
      if Is_Visited (To, Visited, Visit_Count) then
         return 0.0;
      end if;

      for C in Tau'Range (1) loop
         Allowed := not Is_Visited (C, Visited, Visit_Count);
         if Allowed then
            W := Real
              (Edge_Weight (Tau (From, C), Eta (From, C), Alpha, Beta));
            Total := Total + W;
            if C = To then
               W_To := W;
            end if;
         end if;
      end loop;

      if Total <= 0.0 then
         return 0.0;
      end if;
      return Unit_Interval (W_To / Total);
   end Transition_Probability;

   ---------------------------------------------------------------------------
   -- Pheromone core
   ---------------------------------------------------------------------------

   procedure Init_Pheromone
     (Tau : out Pheromone_Matrix; Initial : Non_Negative := 1.0)
   is
   begin
      for I in Tau'Range (1) loop
         for J in Tau'Range (2) loop
            if I = J then
               Tau (I, J) := 0.0;
            else
               Tau (I, J) := Initial;
            end if;
         end loop;
      end loop;
   end Init_Pheromone;

   procedure Evaporate
     (Tau : in out Pheromone_Matrix; Rho : Unit_Interval)
   is
      Keep : constant Real := 1.0 - Real (Rho);
   begin
      for I in Tau'Range (1) loop
         for J in Tau'Range (2) loop
            if I /= J then
               Tau (I, J) := Non_Negative (Real (Tau (I, J)) * Keep);
            else
               Tau (I, J) := 0.0;
            end if;
         end loop;
      end loop;
   end Evaporate;

   procedure Deposit_Tour
     (Tau    : in out Pheromone_Matrix;
      T      : Tour;
      Length : Non_Negative;
      Q      : Non_Negative)
   is
      Deposit_Amt : Non_Negative;
      A, B  : City_Index;
      N     : constant City_Index := T'Last;
   begin
      if Length <= 0.0 then
         return;
      end if;
      Deposit_Amt := Non_Negative (Real (Q) / Real (Length));
      for I in T'First .. T'Last - 1 loop
         A := T (I);
         B := T (I + 1);
         Tau (A, B) := Non_Negative (Real (Tau (A, B)) + Real (Deposit_Amt));
         Tau (B, A) := Non_Negative (Real (Tau (B, A)) + Real (Deposit_Amt));
      end loop;
      A := T (N);
      B := T (T'First);
      Tau (A, B) := Non_Negative (Real (Tau (A, B)) + Real (Deposit_Amt));
      Tau (B, A) := Non_Negative (Real (Tau (B, A)) + Real (Deposit_Amt));
   end Deposit_Tour;

   procedure Construct_Tour
     (T     : out Tour;
      Tau   : Pheromone_Matrix;
      Eta   : Heuristic_Matrix;
      Alpha : Non_Negative;
      Beta  : Non_Negative;
      State : in out RNG_State)
   is
      N           : constant City_Count := City_Count (T'Length);
      First_City  : constant City_Index := T'First;
      Last_City   : constant City_Index := T'Last;
      Visited     : Tour (First_City .. Last_City) := [others => First_City];
      Visit_Count : Natural := 0;
      Current     : City_Index;
      Next_City   : City_Index;
      Total       : Real;
      W           : Real;
      R           : Real;
      Acc         : Real;
      Chosen      : Boolean;
      Rem_Count   : Natural;
      Pick        : Natural;
      K           : Natural;
   begin
      Current := Next_Index (State, First_City, Last_City);
      Visit_Count := 1;
      Visited (First_City) := Current;
      T (First_City) := Current;

      while Visit_Count < Natural (N) loop
         Total := 0.0;
         for C in First_City .. Last_City loop
            if not Is_Visited (C, Visited, Visit_Count) then
               Total := Total
                 + Real
                     (Edge_Weight
                        (Tau (Current, C), Eta (Current, C), Alpha, Beta));
            end if;
         end loop;

         Chosen := False;
         if Total > 0.0 then
            R := Real (Next_Unit (State)) * Total;
            Acc := 0.0;
            for C in First_City .. Last_City loop
               if not Is_Visited (C, Visited, Visit_Count) then
                  W := Real
                    (Edge_Weight
                       (Tau (Current, C), Eta (Current, C), Alpha, Beta));
                  Acc := Acc + W;
                  if R <= Acc then
                     Next_City := C;
                     Chosen := True;
                     exit;
                  end if;
               end if;
            end loop;
         end if;

         if not Chosen then
            --  Uniform among remaining (zero-weight fallback)
            Rem_Count := Natural (N) - Visit_Count;
            Pick := Natural (Real (Next_Unit (State)) * Real (Rem_Count));
            if Pick >= Rem_Count then
               Pick := Rem_Count - 1;
            end if;
            K := 0;
            for C in First_City .. Last_City loop
               if not Is_Visited (C, Visited, Visit_Count) then
                  if K = Pick then
                     Next_City := C;
                     Chosen := True;
                     exit;
                  end if;
                  K := K + 1;
               end if;
            end loop;
         end if;

         if not Chosen then
            raise Invalid_Argument;
         end if;

         Visit_Count := Visit_Count + 1;
         declare
            Slot : constant City_Index :=
              City_Index (Natural (First_City) + Visit_Count - 1);
         begin
            Visited (Slot) := Next_City;
            T (Slot) := Next_City;
         end;
         Current := Next_City;
      end loop;
   end Construct_Tour;

   procedure Update_Pheromone
     (Tau     : in out Pheromone_Matrix;
      T       : Tour;
      Length  : Non_Negative;
      Rho     : Unit_Interval;
      Q       : Non_Negative;
      Deposit : Boolean := True)
   is
   begin
      Evaporate (Tau, Rho);
      if Deposit then
         Deposit_Tour (Tau, T, Length, Q);
      end if;
   end Update_Pheromone;

   procedure Colony_Update
     (Tau       : in out Pheromone_Matrix;
      N         : City_Count;
      Tours     : Tour_Array;
      Lengths   : Length_Array;
      Used      : Ant_Count;
      Rho       : Unit_Interval;
      Q         : Non_Negative;
      Best_Only : Boolean;
      Best_Idx  : Ant_Count)
   is
      Slice : Tour (1 .. N);
   begin
      Evaporate (Tau, Rho);
      if Best_Only then
         for I in 1 .. N loop
            Slice (I) := Tours (Best_Idx) (I);
         end loop;
         Deposit_Tour (Tau, Slice, Lengths (Best_Idx), Q);
      else
         for K in 1 .. Used loop
            for I in 1 .. N loop
               Slice (I) := Tours (K) (I);
            end loop;
            Deposit_Tour (Tau, Slice, Lengths (K), Q);
         end loop;
      end if;
   end Colony_Update;

   function Solve_TSP
     (D   : Dist_Matrix;
      Cfg : Config) return Result
   is
      N     : constant City_Count := City_Count (D'Length (1));
      Tau   : Pheromone_Matrix (1 .. N, 1 .. N);
      Eta   : constant Heuristic_Matrix := Build_Heuristic (D);
      State : RNG_State;
      Tours : Tour_Array (1 .. Cfg.N_Ants);
      Lens  : Length_Array (1 .. Cfg.N_Ants);
      R     : Result;
      Tmp   : Tour (1 .. N);
      Best_Idx : Ant_Count;
      Iters : Natural;
   begin
      Seed_RNG (State, Cfg.Seed);
      Init_Pheromone (Tau, Cfg.Initial_Tau);

      R.N := N;
      R.Best_Length := Non_Negative'Last;
      R.Ants_Used := Natural (Cfg.N_Ants);
      R.Iterations := 0;

      Iters := Cfg.Max_Iterations;
      if Iters = 0 then
         Iters := 1;
      end if;

      for Iter in 1 .. Iters loop
         Best_Idx := 1;
         for K in 1 .. Cfg.N_Ants loop
            Construct_Tour
              (Tmp, Tau, Eta, Cfg.Alpha, Cfg.Beta, State);
            for I in 1 .. N loop
               Tours (K) (I) := Tmp (I);
            end loop;
            for I in N + 1 .. Max_Cities loop
               Tours (K) (I) := 1;
            end loop;
            Lens (K) := Tour_Length (Tmp, D);
            if Lens (K) < Lens (Best_Idx)
              or else K = 1
            then
               Best_Idx := K;
            end if;
            if Lens (K) < R.Best_Length then
               R.Best_Length := Lens (K);
               for I in 1 .. N loop
                  R.Best_Tour (I) := Tmp (I);
               end loop;
               for I in N + 1 .. Max_Cities loop
                  R.Best_Tour (I) := 1;
               end loop;
            end if;
         end loop;

         Colony_Update
           (Tau, N, Tours, Lens, Cfg.N_Ants, Cfg.Rho, Cfg.Q,
            Cfg.Best_Only, Best_Idx);
         R.Iterations := Iter;
      end loop;

      return R;
   end Solve_TSP;

end Ant_Colony_Optimization;
