pragma Ada_2022;

package body Hybrid_Algorithms is

   ---------------------------------------------------------------------------
   -- Numeric / config / RNG
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Insertion_Threshold : Positive      := Default_Insertion_Threshold;
      Exact_Threshold     : Positive      := Default_Exact_Threshold;
      Alpha               : Unit_Interval := 0.3;
      Max_Iterations      : Positive      := 20;
      Local_Search_Steps  : Natural       := 50;
      Seed                : Natural       := 1) return Config
   is
   begin
      return
        (Insertion_Threshold => Insertion_Threshold,
         Exact_Threshold     => Exact_Threshold,
         Alpha               => Alpha,
         Max_Iterations      => Max_Iterations,
         Local_Search_Steps  => Local_Search_Steps,
         Seed                => Seed);
   end Default_Config;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      --  Numerical Recipes LCG constants
      A : constant RNG_State := 1664525;
      C : constant RNG_State := 1013904223;
   begin
      State := State * A + C;
      return Unit_Interval (Long_Float (State) / Long_Float (RNG_State'Last));
   end Next_Unit;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      Span : constant Natural := Hi - Lo;
      U    : constant Unit_Interval := Next_Unit (State);
      Offset : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      Offset := Natural
        (Long_Float'Truncation (Long_Float (U) * Long_Float (Span + 1)));
      if Offset > Span then
         return Hi;
      end if;
      return Lo + Offset;
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Pad24 (S : String) return String is
      R : String (1 .. 24) := [others => ' '];
      N : constant Natural := Natural'Min (S'Length, 24);
   begin
      R (1 .. N) := S (S'First .. S'First + N - 1);
      return R;
   end Pad24;

   function Classify (Kind : Hybrid_Kind) return Hybrid_Info is
   begin
      case Kind is
         when Switch_By_Size =>
            return
              (Kind        => Switch_By_Size,
               Implemented => True,
               Forthcoming => False,
               Stochastic  => False,
               Label       => Pad24 ("switch-by-size"));
         when Portfolio_Select =>
            return
              (Kind        => Portfolio_Select,
               Implemented => True,
               Forthcoming => False,
               Stochastic  => True,
               Label       => Pad24 ("portfolio-select"));
         when Memetic_GA_Local =>
            return
              (Kind        => Memetic_GA_Local,
               Implemented => True,
               Forthcoming => False,
               Stochastic  => True,
               Label       => Pad24 ("memetic-ga-local"));
         when Grasp_Construct_LS =>
            return
              (Kind        => Grasp_Construct_LS,
               Implemented => True,
               Forthcoming => False,
               Stochastic  => True,
               Label       => Pad24 ("grasp-construct-ls"));
         when Exact_Then_Heuristic =>
            return
              (Kind        => Exact_Then_Heuristic,
               Implemented => True,
               Forthcoming => False,
               Stochastic  => False,
               Label       => Pad24 ("exact-then-heuristic"));
      end case;
   end Classify;

   function Hybrid_Name (Kind : Hybrid_Kind) return String is
   begin
      case Kind is
         when Switch_By_Size        => return "Switch_By_Size";
         when Portfolio_Select      => return "Portfolio_Select";
         when Memetic_GA_Local      => return "Memetic_GA_Local";
         when Grasp_Construct_LS    => return "Grasp_Construct_LS";
         when Exact_Then_Heuristic  => return "Exact_Then_Heuristic";
      end case;
   end Hybrid_Name;

   function Implemented (Kind : Hybrid_Kind) return Boolean is
   begin
      return Classify (Kind).Implemented;
   end Implemented;

   function Forthcoming (Kind : Hybrid_Kind) return Boolean is
   begin
      return Classify (Kind).Forthcoming;
   end Forthcoming;

   ---------------------------------------------------------------------------
   -- Bit helpers
   ---------------------------------------------------------------------------

   function Zero_Count (Bits : Bit_String) return Natural is
      C : Natural := 0;
   begin
      for B of Bits loop
         if not B then
            C := C + 1;
         end if;
      end loop;
      return C;
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

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Src (Src'First + I - 1);
      end loop;
      return R;
   end Copy_Bits;

   ---------------------------------------------------------------------------
   -- Sorting primitives
   ---------------------------------------------------------------------------

   function Is_Sorted (Data : Int_Array) return Boolean is
   begin
      if Data'Length <= 1 then
         return True;
      end if;
      for I in Data'First .. Data'Last - 1 loop
         if Data (I) > Data (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   procedure Swap (Data : in out Int_Array; I, J : Positive) is
      T : constant Integer := Data (I);
   begin
      Data (I) := Data (J);
      Data (J) := T;
   end Swap;

   procedure Insertion_Sort_Range
     (Data : in out Int_Array; Lo, Hi : Positive)
   is
   begin
      for I in Lo + 1 .. Hi loop
         declare
            Key : constant Integer := Data (I);
            J   : Natural := I - 1;
         begin
            while J >= Lo and then Data (J) > Key loop
               Data (J + 1) := Data (J);
               J := J - 1;
            end loop;
            Data (J + 1) := Key;
         end;
      end loop;
   end Insertion_Sort_Range;

   procedure Sift_Down
     (Data : in out Int_Array; Start, Finish, Base : Positive)
   is
      Root : Positive := Start;
   begin
      loop
         declare
            Child : constant Natural := Base + 2 * (Root - Base) + 1;
         begin
            exit when Child > Finish;
            declare
               Swap_Idx : Positive := Root;
            begin
               if Data (Swap_Idx) < Data (Child) then
                  Swap_Idx := Child;
               end if;
               if Child + 1 <= Finish
                 and then Data (Swap_Idx) < Data (Child + 1)
               then
                  Swap_Idx := Child + 1;
               end if;
               exit when Swap_Idx = Root;
               Swap (Data, Root, Swap_Idx);
               Root := Swap_Idx;
            end;
         end;
      end loop;
   end Sift_Down;

   procedure Heap_Sort_Range
     (Data : in out Int_Array; Lo, Hi : Positive)
   is
      N : constant Natural := Hi - Lo + 1;
   begin
      if N <= 1 then
         return;
      end if;
      --  Build max-heap on Data (Lo .. Hi)
      for Start in reverse Lo .. Lo + (N / 2) - 1 loop
         Sift_Down (Data, Start, Hi, Lo);
      end loop;
      for Finish in reverse Lo + 1 .. Hi loop
         Swap (Data, Lo, Finish);
         Sift_Down (Data, Lo, Finish - 1, Lo);
      end loop;
   end Heap_Sort_Range;

   function Floor_Log2 (N : Natural) return Natural is
      X : Natural := N;
      L : Natural := 0;
   begin
      while X > 1 loop
         X := X / 2;
         L := L + 1;
      end loop;
      return L;
   end Floor_Log2;

   procedure Intro_Recurse
     (Data   : in out Int_Array;
      Lo, Hi : Positive;
      Depth  : Natural;
      Thr    : Positive;
      Stats  : in out Sort_Stats;
      Depth_Now : Natural)
   is
      Len : constant Natural := Hi - Lo + 1;
   begin
      if Depth_Now > Stats.Max_Recursion_Depth then
         Stats.Max_Recursion_Depth := Depth_Now;
      end if;

      if Len <= 1 then
         return;
      elsif Len <= Thr then
         Insertion_Sort_Range (Data, Lo, Hi);
         Stats.Insertion_Segments := Stats.Insertion_Segments + 1;
         return;
      elsif Depth = 0 then
         Heap_Sort_Range (Data, Lo, Hi);
         Stats.Heap_Fallbacks := Stats.Heap_Fallbacks + 1;
         return;
      end if;

      --  Median-of-three pivot into Hi
      declare
         Mid : constant Positive := Lo + (Hi - Lo) / 2;
      begin
         if Data (Mid) < Data (Lo) then
            Swap (Data, Lo, Mid);
         end if;
         if Data (Hi) < Data (Lo) then
            Swap (Data, Lo, Hi);
         end if;
         if Data (Mid) < Data (Hi) then
            Swap (Data, Mid, Hi);
         end if;
      end;

      declare
         Pivot : constant Integer := Data (Hi);
         I     : Natural := Lo;
      begin
         for J in Lo .. Hi - 1 loop
            if Data (J) <= Pivot then
               Swap (Data, I, J);
               I := I + 1;
            end if;
         end loop;
         Swap (Data, I, Hi);
         Stats.Quick_Partitions := Stats.Quick_Partitions + 1;

         if I > Lo then
            Intro_Recurse
              (Data, Lo, I - 1, Depth - 1, Thr, Stats, Depth_Now + 1);
         end if;
         if I < Hi then
            Intro_Recurse
              (Data, I + 1, Hi, Depth - 1, Thr, Stats, Depth_Now + 1);
         end if;
      end;
   end Intro_Recurse;

   procedure Hybrid_Sort
     (Data                : in out Int_Array;
      Stats               : out Sort_Stats;
      Insertion_Threshold : Positive := Default_Insertion_Threshold)
   is
      Limit : Natural;
   begin
      Stats :=
        (Elements            => Data'Length,
         Insertion_Segments  => 0,
         Heap_Fallbacks      => 0,
         Quick_Partitions    => 0,
         Max_Recursion_Depth => 0);

      if Data'Length <= 1 then
         return;
      end if;

      if Data'Length <= Insertion_Threshold then
         Insertion_Sort_Range (Data, Data'First, Data'Last);
         Stats.Insertion_Segments := 1;
         return;
      end if;

      Limit := 2 * Floor_Log2 (Data'Length);
      Intro_Recurse
        (Data, Data'First, Data'Last, Limit,
         Insertion_Threshold, Stats, 0);
   end Hybrid_Sort;

   function Hybrid_Sort_Copy
     (Data                : Int_Array;
      Insertion_Threshold : Positive := Default_Insertion_Threshold)
      return Int_Array
   is
      R : Int_Array := Data;
      S : Sort_Stats;
   begin
      Hybrid_Sort (R, S, Insertion_Threshold);
      return R;
   end Hybrid_Sort_Copy;

   ---------------------------------------------------------------------------
   -- Knapsack utilities
   ---------------------------------------------------------------------------

   function Total_Weight
     (Weights : Weight_Array; Sel : Selection) return Natural
   is
      T : Natural := 0;
   begin
      for I in Weights'Range loop
         if Sel (I) then
            T := T + Weights (I);
         end if;
      end loop;
      return T;
   end Total_Weight;

   function Total_Value
     (Values : Value_Array; Sel : Selection) return Natural
   is
      T : Natural := 0;
   begin
      for I in Values'Range loop
         if Sel (I) then
            T := T + Values (I);
         end if;
      end loop;
      return T;
   end Total_Value;

   function Is_Feasible
     (Weights  : Weight_Array;
      Sel      : Selection;
      Capacity : Natural) return Boolean
   is
   begin
      return Total_Weight (Weights, Sel) <= Capacity;
   end Is_Feasible;

   function Density (Value, Weight : Natural) return Long_Float is
   begin
      if Weight = 0 then
         if Value = 0 then
            return 0.0;
         else
            return Long_Float (Value) * 1.0E9;
         end if;
      end if;
      return Long_Float (Value) / Long_Float (Weight);
   end Density;

   function Empty_KS (N : Item_Count) return Knapsack_Result is
      R : Knapsack_Result;
   begin
      R.N_Items := N;
      return R;
   end Empty_KS;

   function Knapsack_Exhaustive
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Knapsack_Result
   is
      N : constant Item_Count := Weights'Length;
      R : Knapsack_Result;
      Best_Val : Natural := 0;
      Best_Sel : Selection (1 .. Max_Items) := [others => False];
      Best_W   : Natural := 0;
      Max_Mask : constant Natural := (2 ** Natural (N)) - 1;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      for Mask in 0 .. Max_Mask loop
         declare
            Sel : Selection (1 .. Max_Items) := [others => False];
            Tw  : Natural := 0;
            Tv  : Natural := 0;
            Bit : Natural;
         begin
            for K in 1 .. N loop
               Bit := (Mask / (2 ** (K - 1))) rem 2;
               if Bit = 1 then
                  Sel (K) := True;
                  Tw := Tw + Weights (Weights'First + K - 1);
                  Tv := Tv + Values (Values'First + K - 1);
               end if;
            end loop;
            if Tw <= Capacity and then Tv > Best_Val then
               Best_Val := Tv;
               Best_W := Tw;
               Best_Sel := Sel;
            elsif Tw <= Capacity
              and then Tv = Best_Val
              and then Tw < Best_W
            then
               Best_W := Tw;
               Best_Sel := Sel;
            end if;
         end;
      end loop;
      R.Best_Value := Best_Val;
      R.Best_Weight := Best_W;
      R.Selected := Best_Sel;
      R.N_Items := N;
      R.Exact := True;
      R.Used_Greedy := False;
      return R;
   end Knapsack_Exhaustive;

   function Knapsack_Greedy_Density
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Knapsack_Result
   is
      N : constant Item_Count := Weights'Length;
      Order : array (1 .. Max_Items) of Item_Index := [others => 1];
      Dens  : array (1 .. Max_Items) of Long_Float := [others => 0.0];
      R     : Knapsack_Result;
      Cap   : Natural := Capacity;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      for K in 1 .. N loop
         Order (K) := K;
         Dens (K) := Density
           (Values (Values'First + K - 1),
            Weights (Weights'First + K - 1));
      end loop;
      for I in 2 .. N loop
         declare
            Key_O : constant Item_Index := Order (I);
            Key_D : constant Long_Float := Dens (I);
            J     : Natural := I - 1;
         begin
            while J >= 1 and then Dens (J) < Key_D loop
               Order (J + 1) := Order (J);
               Dens (J + 1) := Dens (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key_O;
            Dens (J + 1) := Key_D;
         end;
      end loop;

      R.N_Items := N;
      R.Exact := False;
      R.Used_Greedy := True;
      for K in 1 .. N loop
         declare
            Idx : constant Item_Index := Order (K);
            W   : constant Natural := Weights (Weights'First + Idx - 1);
            V   : constant Natural := Values (Values'First + Idx - 1);
         begin
            if W <= Cap then
               R.Selected (Idx) := True;
               Cap := Cap - W;
               R.Best_Weight := R.Best_Weight + W;
               R.Best_Value := R.Best_Value + V;
            end if;
         end;
      end loop;
      return R;
   end Knapsack_Greedy_Density;

   function Size_Switch_Knapsack
     (Weights         : Weight_Array;
      Values          : Value_Array;
      Capacity        : Natural;
      Exact_Threshold : Positive := Default_Exact_Threshold)
      return Knapsack_Result
   is
      N : constant Item_Count := Weights'Length;
   begin
      if N <= Item_Count (Exact_Threshold)
        and then N <= Max_Exact_N
      then
         return Knapsack_Exhaustive (Weights, Values, Capacity);
      else
         return Knapsack_Greedy_Density (Weights, Values, Capacity);
      end if;
   end Size_Switch_Knapsack;

   ---------------------------------------------------------------------------
   -- Local search / memetic one-step
   ---------------------------------------------------------------------------

   function Hill_Climb_OneMax
     (Start     : Bit_String;
      Max_Steps : Natural := 50) return Bit_Result
   is
      N   : constant Bit_Count := Start'Length;
      Cur : Bit_String (1 .. N) := Copy_Bits (Start, N);
      Cost : Natural := Zero_Count (Cur);
      Improves : Natural := 0;
      R : Bit_Result;
   begin
      for Step in 1 .. Max_Steps loop
         declare
            Best_I    : Natural := 0;
            Best_Cost : Natural := Cost;
         begin
            for K in 1 .. N loop
               declare
                  Cand : constant Bit_String := Flip_Bit (Cur, K);
                  Cc   : constant Natural := Zero_Count (Cand);
               begin
                  if Cc < Best_Cost then
                     Best_Cost := Cc;
                     Best_I := K;
                  end if;
               end;
            end loop;
            exit when Best_I = 0;
            Cur := Flip_Bit (Cur, Best_I);
            Cost := Best_Cost;
            Improves := Improves + 1;
            exit when Cost = 0;
         end;
      end loop;
      R.N := N;
      R.Best_Cost := Real (Cost);
      R.Local_Improves := Improves;
      for I in 1 .. N loop
         R.Best_Bits (I) := Cur (I);
      end loop;
      return R;
   end Hill_Climb_OneMax;

   function Memetic_One_Step_OneMax
     (N   : Bit_Count;
      Cfg : Config := Default_Config) return Bit_Result
   is
      State : RNG_State;
      Start : Bit_String (1 .. N);
   begin
      Seed_RNG (State, Cfg.Seed);
      Start := Random_Bit_String (State, N);
      return Hill_Climb_OneMax (Start, Cfg.Local_Search_Steps);
   end Memetic_One_Step_OneMax;

   function Hill_Climb_Knapsack
     (Weights   : Weight_Array;
      Values    : Value_Array;
      Capacity  : Natural;
      Start     : Selection;
      Max_Steps : Natural := 50) return Knapsack_Result
   is
      N   : constant Item_Count := Weights'Length;
      Cur : Selection (1 .. Max_Items) := [others => False];
      Val : Natural;
      Wgt : Natural;
      Improves : Natural := 0;
      R : Knapsack_Result;
   begin
      for K in 1 .. N loop
         Cur (K) := Start (Start'First + K - 1);
      end loop;
      --  Repair if start infeasible: drop items from the end
      Wgt := 0;
      for K in 1 .. N loop
         if Cur (K) then
            Wgt := Wgt + Weights (Weights'First + K - 1);
         end if;
      end loop;
      if Wgt > Capacity then
         for K in reverse 1 .. N loop
            exit when Wgt <= Capacity;
            if Cur (K) then
               Cur (K) := False;
               Wgt := Wgt - Weights (Weights'First + K - 1);
            end if;
         end loop;
      end if;
      Val := 0;
      Wgt := 0;
      for K in 1 .. N loop
         if Cur (K) then
            Val := Val + Values (Values'First + K - 1);
            Wgt := Wgt + Weights (Weights'First + K - 1);
         end if;
      end loop;

      for Step in 1 .. Max_Steps loop
         declare
            Best_K   : Natural := 0;
            Best_Val : Natural := Val;
            Best_W   : Natural := Wgt;
            Best_On  : Boolean := False;
         begin
            for K in 1 .. N loop
               declare
                  Wk : constant Natural :=
                    Weights (Weights'First + K - 1);
                  Vk : constant Natural :=
                    Values (Values'First + K - 1);
                  Nw : Natural;
                  Nv : Natural;
               begin
                  if Cur (K) then
                     Nw := Wgt - Wk;
                     Nv := Val - Vk;
                     if Nv > Best_Val
                       or else (Nv = Best_Val and then Nw < Best_W)
                     then
                        Best_Val := Nv;
                        Best_W := Nw;
                        Best_K := K;
                        Best_On := False;
                     end if;
                  else
                     if Wgt + Wk <= Capacity then
                        Nw := Wgt + Wk;
                        Nv := Val + Vk;
                        if Nv > Best_Val
                          or else (Nv = Best_Val and then Nw < Best_W)
                        then
                           Best_Val := Nv;
                           Best_W := Nw;
                           Best_K := K;
                           Best_On := True;
                        end if;
                     end if;
                  end if;
               end;
            end loop;
            exit when Best_K = 0 or else Best_Val <= Val;
            Cur (Best_K) := Best_On;
            Val := Best_Val;
            Wgt := Best_W;
            Improves := Improves + 1;
         end;
      end loop;

      R.Best_Value := Val;
      R.Best_Weight := Wgt;
      R.Selected := Cur;
      R.N_Items := N;
      R.Exact := False;
      R.Used_Greedy := False;
      R.Local_Improves := Improves;
      return R;
   end Hill_Climb_Knapsack;

   function Memetic_One_Step_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Cfg      : Config := Default_Config) return Knapsack_Result
   is
      N     : constant Item_Count := Weights'Length;
      State : RNG_State;
      Start : Selection (1 .. N) := [others => False];
      Cap   : Natural := Capacity;
   begin
      Seed_RNG (State, Cfg.Seed);
      --  Random feasible construction
      for K in 1 .. N loop
         if Next_Unit (State) >= 0.5 then
            declare
               W : constant Natural := Weights (Weights'First + K - 1);
            begin
               if W <= Cap then
                  Start (K) := True;
                  Cap := Cap - W;
               end if;
            end;
         end if;
      end loop;
      return Hill_Climb_Knapsack
        (Weights, Values, Capacity, Start, Cfg.Local_Search_Steps);
   end Memetic_One_Step_Knapsack;

   ---------------------------------------------------------------------------
   -- Construct + LS (mini-GRASP style)
   ---------------------------------------------------------------------------

   function RCL_Construct
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Alpha    : Unit_Interval;
      State    : in out RNG_State) return Selection
   is
      N : constant Item_Count := Weights'Length;
      Taken : Selection (1 .. N) := [others => False];
      Remaining : array (1 .. Max_Items) of Boolean := [others => True];
      Cap : Natural := Capacity;
      Left : Natural := N;
   begin
      while Left > 0 loop
         declare
            Min_D, Max_D : Long_Float;
            First : Boolean := True;
            RCL_Count : Natural := 0;
            RCL_Idx : array (1 .. Max_Items) of Item_Index := [others => 1];
         begin
            --  Densities among feasible remaining
            for K in 1 .. N loop
               if Remaining (K)
                 and then Weights (Weights'First + K - 1) <= Cap
               then
                  declare
                     D : constant Long_Float := Density
                       (Values (Values'First + K - 1),
                        Weights (Weights'First + K - 1));
                  begin
                     if First then
                        Min_D := D;
                        Max_D := D;
                        First := False;
                     else
                        if D < Min_D then
                           Min_D := D;
                        end if;
                        if D > Max_D then
                           Max_D := D;
                        end if;
                     end if;
                  end;
               end if;
            end loop;
            exit when First;  -- nothing feasible left

            declare
               Threshold : constant Long_Float :=
                 Max_D - Long_Float (Alpha) * (Max_D - Min_D);
            begin
               for K in 1 .. N loop
                  if Remaining (K)
                    and then Weights (Weights'First + K - 1) <= Cap
                  then
                     declare
                        D : constant Long_Float := Density
                          (Values (Values'First + K - 1),
                           Weights (Weights'First + K - 1));
                     begin
                        if D >= Threshold then
                           RCL_Count := RCL_Count + 1;
                           RCL_Idx (RCL_Count) := K;
                        end if;
                     end;
                  end if;
               end loop;
            end;

            exit when RCL_Count = 0;
            declare
               Pick : constant Item_Index :=
                 RCL_Idx (Next_Natural (State, 1, RCL_Count));
               W : constant Natural :=
                 Weights (Weights'First + Pick - 1);
            begin
               Taken (Pick) := True;
               Remaining (Pick) := False;
               Cap := Cap - W;
               Left := Left - 1;
            end;
         end;
      end loop;
      return Taken;
   end RCL_Construct;

   function Construct_Local_Search_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Cfg      : Config := Default_Config) return Knapsack_Result
   is
      N : constant Item_Count := Weights'Length;
      State : RNG_State;
      Best  : Knapsack_Result := Empty_KS (N);
      Total_Improves : Natural := 0;
   begin
      Seed_RNG (State, Cfg.Seed);
      Best.Exact := False;
      for Iter in 1 .. Cfg.Max_Iterations loop
         declare
            Built : constant Selection :=
              RCL_Construct (Weights, Values, Capacity, Cfg.Alpha, State);
            Improved : constant Knapsack_Result :=
              Hill_Climb_Knapsack
                (Weights, Values, Capacity, Built, Cfg.Local_Search_Steps);
         begin
            Total_Improves := Total_Improves + Improved.Local_Improves;
            if Improved.Best_Value > Best.Best_Value
              or else
                (Improved.Best_Value = Best.Best_Value
                 and then Improved.Best_Weight < Best.Best_Weight)
            then
               Best := Improved;
            end if;
         end;
      end loop;
      Best.Local_Improves := Total_Improves;
      Best.N_Items := N;
      return Best;
   end Construct_Local_Search_Knapsack;

   ---------------------------------------------------------------------------
   -- Portfolio
   ---------------------------------------------------------------------------

   function Portfolio_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Cfg      : Config := Default_Config) return Knapsack_Result
   is
      G : constant Knapsack_Result :=
        Knapsack_Greedy_Density (Weights, Values, Capacity);
      --  Single-iteration construct+LS for diversity
      Cfg1 : Config := Cfg;
      C : Knapsack_Result;
   begin
      Cfg1.Max_Iterations := 1;
      C := Construct_Local_Search_Knapsack (Weights, Values, Capacity, Cfg1);
      if C.Best_Value > G.Best_Value
        or else
          (C.Best_Value = G.Best_Value
           and then C.Best_Weight < G.Best_Weight)
      then
         return C;
      else
         return G;
      end if;
   end Portfolio_Knapsack;

end Hybrid_Algorithms;
