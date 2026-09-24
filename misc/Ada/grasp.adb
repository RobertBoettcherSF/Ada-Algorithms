--  Grasp body — RCL construction, knapsack GRASP, optional TSP 2-opt.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Grasp
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- LCG: Numerical Recipes style (a=1664525, c=1013904223)
   ---------------------------------------------------------------------------

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      State := RNG_State (Seed);
      State := State * 1_664_525 + 1_013_904_223;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
   begin
      State := State * 1_664_525 + 1_013_904_223;
      return Unit_Interval (Real (State) / Real (RNG_State'Last));
   end Next_Unit;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      Span : constant Natural := Hi - Lo + 1;
   begin
      State := State * 1_664_525 + 1_013_904_223;
      return Lo + Natural (State rem RNG_State (Span));
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Parameters
     (Alpha          : Unit_Interval := 0.3;
      Max_Iterations : Positive      := 50;
      Seed           : Natural       := 1) return Parameters
   is
   begin
      return
        (Alpha => Alpha, Max_Iterations => Max_Iterations, Seed => Seed);
   end Default_Parameters;

   function Greedy_Score (Value, Weight : Natural) return Real is
   begin
      if Weight = 0 then
         return Real (Value);
      else
         return Real (Value) / Real (Weight);
      end if;
   end Greedy_Score;

   function Total_Weight
     (Weights : Weight_Array; Sel : Selection) return Natural
   is
      Sum : Natural := 0;
   begin
      for I in Weights'Range loop
         if Sel (I) then
            Sum := Sum + Weights (I);
         end if;
      end loop;
      return Sum;
   end Total_Weight;

   function Total_Value
     (Values : Value_Array; Sel : Selection) return Natural
   is
      Sum : Natural := 0;
   begin
      for I in Values'Range loop
         if Sel (I) then
            Sum := Sum + Values (I);
         end if;
      end loop;
      return Sum;
   end Total_Value;

   function Is_Feasible
     (Weights  : Weight_Array;
      Sel      : Selection;
      Capacity : Natural) return Boolean
   is
   begin
      return Total_Weight (Weights, Sel) <= Capacity;
   end Is_Feasible;

   function Euclidean
     (X1, Y1, X2, Y2 : Real) return Non_Negative
   is
      DX : constant Real := X2 - X1;
      DY : constant Real := Y2 - Y1;
   begin
      return Non_Negative (EF.Sqrt (Long_Float (DX * DX + DY * DY)));
   end Euclidean;

   ---------------------------------------------------------------------------
   -- RCL cores
   ---------------------------------------------------------------------------

   procedure Build_RCL
     (Items  : RCL_Buffer;
      Scores : Score_Array;
      Count  : Natural;
      Alpha  : Unit_Interval;
      List   : out RCL)
   is
      G_Max, G_Min, Threshold : Real;
   begin
      List.Count := 0;
      List.Items := [others => 0];
      if Count = 0 then
         return;
      end if;

      G_Max := Scores (Scores'First);
      G_Min := Scores (Scores'First);
      for K in 1 .. Count loop
         declare
            S : constant Real := Scores (Scores'First + K - 1);
         begin
            if S > G_Max then
               G_Max := S;
            end if;
            if S < G_Min then
               G_Min := S;
            end if;
         end;
      end loop;

      Threshold := G_Max - Alpha * (G_Max - G_Min);

      for K in 1 .. Count loop
         declare
            S : constant Real := Scores (Scores'First + K - 1);
         begin
            if S >= Threshold - Epsilon_Tol then
               List.Count := List.Count + 1;
               List.Items (List.Count) := Items (Items'First + K - 1);
            end if;
         end;
      end loop;
   end Build_RCL;

   procedure Build_RCL_Min
     (Items  : RCL_Buffer;
      Scores : Score_Array;
      Count  : Natural;
      Alpha  : Unit_Interval;
      List   : out RCL)
   is
      D_Max, D_Min, Threshold : Real;
   begin
      List.Count := 0;
      List.Items := [others => 0];
      if Count = 0 then
         return;
      end if;

      D_Max := Scores (Scores'First);
      D_Min := Scores (Scores'First);
      for K in 1 .. Count loop
         declare
            S : constant Real := Scores (Scores'First + K - 1);
         begin
            if S > D_Max then
               D_Max := S;
            end if;
            if S < D_Min then
               D_Min := S;
            end if;
         end;
      end loop;

      Threshold := D_Min + Alpha * (D_Max - D_Min);

      for K in 1 .. Count loop
         declare
            S : constant Real := Scores (Scores'First + K - 1);
         begin
            if S <= Threshold + Epsilon_Tol then
               List.Count := List.Count + 1;
               List.Items (List.Count) := Items (Items'First + K - 1);
            end if;
         end;
      end loop;
   end Build_RCL_Min;

   function Pick_From_RCL
     (List  : RCL;
      State : in out RNG_State) return Natural
   is
      Slot : constant Natural := Next_Natural (State, 1, List.Count);
   begin
      return List.Items (Slot);
   end Pick_From_RCL;

   ---------------------------------------------------------------------------
   -- Knapsack RCL / construct / local search / GRASP
   ---------------------------------------------------------------------------

   procedure Build_RCL_Knapsack
     (Weights   : Weight_Array;
      Values    : Value_Array;
      Sel       : Selection;
      Remaining : Natural;
      Alpha     : Unit_Interval;
      List      : out RCL)
   is
      Cand_Items  : RCL_Buffer (1 .. Max_Items) := [others => 0];
      Cand_Scores : Score_Array (1 .. Max_Items) := [others => 0.0];
      N_Cand      : Natural := 0;
   begin
      for I in Weights'Range loop
         if not Sel (I) and then Weights (I) <= Remaining then
            N_Cand := N_Cand + 1;
            Cand_Items (N_Cand) := I;
            Cand_Scores (N_Cand) :=
              Greedy_Score (Values (I), Weights (I));
         end if;
      end loop;
      Build_RCL (Cand_Items, Cand_Scores, N_Cand, Alpha, List);
   end Build_RCL_Knapsack;

   procedure Construct_Solution_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Alpha    : Unit_Interval;
      State    : in out RNG_State;
      Sel      : out Selection)
   is
      N         : constant Positive := Weights'Length;
      Remaining : Natural := Capacity;
      List      : RCL;
      Pick      : Natural;
      Work      : Selection (1 .. N) := [others => False];
   begin
      loop
         Build_RCL_Knapsack
           (Weights, Values, Work, Remaining, Alpha, List);
         exit when List.Count = 0;
         Pick := Pick_From_RCL (List, State);
         Work (Pick) := True;
         Remaining := Remaining - Weights (Pick);
      end loop;
      Sel := Work;
   end Construct_Solution_Knapsack;

   procedure Local_Search_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Sel      : in out Selection;
      Improves : out Natural)
   is
      Improved : Boolean;
      Cur_W    : Natural := Total_Weight (Weights, Sel);
      Cur_V    : Natural := Total_Value (Values, Sel);
   begin
      Improves := 0;
      loop
         Improved := False;

         --  Add moves: insert any unused item that fits.
         for I in Weights'Range loop
            if not Sel (I)
              and then Cur_W + Weights (I) <= Capacity
              and then Values (I) > 0
            then
               Sel (I) := True;
               Cur_W := Cur_W + Weights (I);
               Cur_V := Cur_V + Values (I);
               Improves := Improves + 1;
               Improved := True;
               exit;  -- first-improvement: restart scan
            end if;
         end loop;

         if not Improved then
            --  1-1 swaps: drop I, add J if feasible and value rises.
            Outer :
            for I in Weights'Range loop
               if Sel (I) then
                  for J in Weights'Range loop
                     if not Sel (J)
                       and then Cur_W - Weights (I) + Weights (J)
                                  <= Capacity
                       and then Cur_V - Values (I) + Values (J) > Cur_V
                     then
                        Sel (I) := False;
                        Sel (J) := True;
                        Cur_W := Cur_W - Weights (I) + Weights (J);
                        Cur_V := Cur_V - Values (I) + Values (J);
                        Improves := Improves + 1;
                        Improved := True;
                        exit Outer;
                     end if;
                  end loop;
               end if;
            end loop Outer;
         end if;

         exit when not Improved;
      end loop;
   end Local_Search_Knapsack;

   function Grasp_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Params   : Parameters) return Knapsack_Result
   is
      N      : constant Positive := Weights'Length;
      State  : RNG_State;
      Sel    : Selection (1 .. N);
      Improves : Natural;
      Const_V  : Natural;
      Const_W  : Natural;
      R        : Knapsack_Result;
   begin
      Seed_RNG (State, Params.Seed);
      R.N_Items := N;
      R.Best_Value := 0;
      R.Best_Weight := Natural'Last;
      R.Best_Construction := 0;
      R.Local_Improves := 0;
      R.Iterations_Run := 0;
      R.Selected := [others => False];

      for Iter in 1 .. Params.Max_Iterations loop
         Construct_Solution_Knapsack
           (Weights, Values, Capacity, Params.Alpha, State, Sel);
         Const_V := Total_Value (Values, Sel);
         if Const_V > R.Best_Construction then
            R.Best_Construction := Const_V;
         end if;

         Local_Search_Knapsack
           (Weights, Values, Capacity, Sel, Improves);
         R.Local_Improves := R.Local_Improves + Improves;
         R.Iterations_Run := Iter;

         Const_V := Total_Value (Values, Sel);
         Const_W := Total_Weight (Weights, Sel);
         if Const_V > R.Best_Value
           or else (Const_V = R.Best_Value and then Const_W < R.Best_Weight)
         then
            R.Best_Value := Const_V;
            R.Best_Weight := Const_W;
            R.Selected := [others => False];
            for I in 1 .. N loop
               R.Selected (I) := Sel (I);
            end loop;
         end if;
      end loop;

      if R.Best_Weight = Natural'Last then
         R.Best_Weight := 0;
      end if;
      return R;
   end Grasp_Knapsack;

   ---------------------------------------------------------------------------
   -- TSP helpers / GRASP
   ---------------------------------------------------------------------------

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative is
      Sum : Non_Negative := 0.0;
      N   : constant City_Index := T'Last;
   begin
      for K in T'First .. City_Index'Pred (N) loop
         Sum := Sum + D (T (K), T (City_Index'Succ (K)));
      end loop;
      Sum := Sum + D (T (N), T (T'First));
      return Sum;
   end Tour_Length;

   function Apply_2Opt (T : Tour; I, J : City_Index) return Tour is
      R     : Tour := T;
      Left  : City_Index := City_Index'Succ (I);
      Right : City_Index := J;
      Tmp   : City_Index;
   begin
      while Left < Right loop
         Tmp := R (Left);
         R (Left) := R (Right);
         R (Right) := Tmp;
         exit when City_Index'Succ (Left) >= Right;
         Left := City_Index'Succ (Left);
         Right := City_Index'Pred (Right);
      end loop;
      return R;
   end Apply_2Opt;

   procedure Construct_Tour_NN_RCL
     (D     : Dist_Matrix;
      Alpha : Unit_Interval;
      State : in out RNG_State;
      T     : out Tour)
   is
      N        : constant City_Index := D'Last (1);
      Used     : array (City_Index range 1 .. N) of Boolean :=
                   [others => False];
      Cand_I   : RCL_Buffer (1 .. Max_Cities) := [others => 0];
      Cand_S   : Score_Array (1 .. Max_Cities) := [others => 0.0];
      N_Cand   : Natural;
      List     : RCL;
      Current  : City_Index := 1;
      Pick     : Natural;
      Pos      : City_Index;
   begin
      T := [others => 1];
      T (1) := 1;
      Used (1) := True;
      Pos := 1;

      while Pos < N loop
         N_Cand := 0;
         for C in 1 .. N loop
            if not Used (C) then
               N_Cand := N_Cand + 1;
               Cand_I (N_Cand) := Natural (C);
               Cand_S (N_Cand) := Real (D (Current, C));
            end if;
         end loop;
         Build_RCL_Min (Cand_I, Cand_S, N_Cand, Alpha, List);
         Pick := Pick_From_RCL (List, State);
         Pos := City_Index'Succ (Pos);
         T (Pos) := City_Index (Pick);
         Used (City_Index (Pick)) := True;
         Current := City_Index (Pick);
      end loop;
   end Construct_Tour_NN_RCL;

   procedure Local_Search_2Opt
     (D        : Dist_Matrix;
      T        : in out Tour;
      Improves : out Natural)
   is
      N          : constant City_Index := T'Last;
      Best_Len   : Non_Negative := Tour_Length (T, D);
      Candidate  : Tour (T'Range);
      Cand_Len   : Non_Negative;
      Improved   : Boolean;
      Best_I     : City_Index;
      Best_J     : City_Index;
      Best_Gain : Non_Negative;
   begin
      Improves := 0;
      loop
         Improved := False;
         Best_Gain := 0.0;
         Best_I := T'First;
         Best_J := T'First;

         for I in T'First .. City_Index'Pred (N) loop
            for J in City_Index'Succ (I) .. N loop
               --  Skip adjacent-trivial / full-tour reverse edge cases
               if City_Index'Succ (I) /= J
                 and then not (I = T'First and then J = N)
               then
                  Candidate := Apply_2Opt (T, I, J);
                  Cand_Len := Tour_Length (Candidate, D);
                  if Cand_Len + Epsilon_Tol < Best_Len then
                     declare
                        Gain : constant Non_Negative :=
                          Best_Len - Cand_Len;
                     begin
                        if not Improved or else Gain > Best_Gain then
                           Improved := True;
                           Best_Gain := Gain;
                           Best_I := I;
                           Best_J := J;
                        end if;
                     end;
                  end if;
               end if;
            end loop;
         end loop;

         exit when not Improved;
         T := Apply_2Opt (T, Best_I, Best_J);
         Best_Len := Tour_Length (T, D);
         Improves := Improves + 1;
      end loop;
   end Local_Search_2Opt;

   function Grasp_TSP
     (D      : Dist_Matrix;
      Params : Parameters) return TSP_Result
   is
      N        : constant City_Index := D'Last (1);
      State    : RNG_State;
      T        : Tour (1 .. N);
      Improves : Natural;
      Len      : Non_Negative;
      R        : TSP_Result;
   begin
      Seed_RNG (State, Params.Seed);
      R.N := N;
      R.Best_Length := Non_Negative'Last;
      R.Iterations_Run := 0;
      R.Local_Improves := 0;
      R.Best_Tour := [others => 1];

      for Iter in 1 .. Params.Max_Iterations loop
         Construct_Tour_NN_RCL (D, Params.Alpha, State, T);
         Local_Search_2Opt (D, T, Improves);
         R.Local_Improves := R.Local_Improves + Improves;
         R.Iterations_Run := Iter;
         Len := Tour_Length (T, D);
         if Len < R.Best_Length then
            R.Best_Length := Len;
            R.Best_Tour := [others => 1];
            for K in 1 .. N loop
               R.Best_Tour (K) := T (K);
            end loop;
         end if;
      end loop;

      return R;
   end Grasp_TSP;

end Grasp;
