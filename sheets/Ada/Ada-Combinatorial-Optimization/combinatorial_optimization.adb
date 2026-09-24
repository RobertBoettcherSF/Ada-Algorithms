--  Body of Combinatorial_Optimization survey package.

pragma Ada_2022;

package body Combinatorial_Optimization
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Pad16 (S : String) return String is
      R : String (1 .. 16) := [others => ' '];
   begin
      if S'Length >= 16 then
         R := S (S'First .. S'First + 15);
      else
         R (1 .. S'Length) := S;
      end if;
      return R;
   end Pad16;

   function Classify_Problem (Kind : Problem_Kind) return Problem_Info is
      Info : Problem_Info;
   begin
      Info.Kind := Kind;
      case Kind is
         when Knapsack =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Family := Pad16 ("packing");
         when Assignment =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Family := Pad16 ("matching");
         when TSP =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Family := Pad16 ("routing");
         when MST =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Family := Pad16 ("graphs");
         when Set_Cover =>
            --  Sibling Ada-Exact-Cover / greedy sketches elsewhere
            Info.Implemented := False;
            Info.Forthcoming := True;
            Info.Family := Pad16 ("covering");
         when ILP =>
            --  Sibling Ada-Integer-Linear-Programming
            Info.Implemented := False;
            Info.Forthcoming := True;
            Info.Family := Pad16 ("polyhedral");
      end case;
      return Info;
   end Classify_Problem;

   function Classify_Method (Kind : Method_Kind) return Method_Info is
      Info : Method_Info;
   begin
      Info.Kind := Kind;
      case Kind is
         when Exhaustive =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Exactness := Pad16 ("exact");
         when Dynamic_Programming =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Exactness := Pad16 ("exact");
         when Branch_and_Bound =>
            Info.Implemented := False;
            Info.Forthcoming := True;
            Info.Exactness := Pad16 ("exact");
         when Greedy =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Exactness := Pad16 ("approx");
         when Local_Search =>
            Info.Implemented := True;
            Info.Forthcoming := False;
            Info.Exactness := Pad16 ("approx");
         when GRASP =>
            --  Sibling Ada-GRASP
            Info.Implemented := False;
            Info.Forthcoming := True;
            Info.Exactness := Pad16 ("metaheuristic");
         when Hungarian =>
            --  Sibling Ada-Hungarian-Method (poly-time exact assignment)
            Info.Implemented := False;
            Info.Forthcoming := True;
            Info.Exactness := Pad16 ("exact");
         when Metaheuristic =>
            --  Sibling Ada-Genetic-Algorithms / GRASP family
            Info.Implemented := False;
            Info.Forthcoming := True;
            Info.Exactness := Pad16 ("metaheuristic");
      end case;
      return Info;
   end Classify_Method;

   function Problem_Name (Kind : Problem_Kind) return String is
   begin
      case Kind is
         when Knapsack   => return "Knapsack";
         when Assignment => return "Assignment";
         when TSP        => return "TSP";
         when MST        => return "MST";
         when Set_Cover  => return "Set_Cover";
         when ILP        => return "ILP";
      end case;
   end Problem_Name;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Exhaustive           => return "Exhaustive";
         when Dynamic_Programming  => return "Dynamic_Programming";
         when Branch_and_Bound      => return "Branch_and_Bound";
         when Greedy               => return "Greedy";
         when Local_Search         => return "Local_Search";
         when GRASP                => return "GRASP";
         when Hungarian            => return "Hungarian";
         when Metaheuristic        => return "Metaheuristic";
      end case;
   end Method_Name;

   function Implemented (Kind : Problem_Kind) return Boolean is
   begin
      return Classify_Problem (Kind).Implemented;
   end Implemented;

   function Implemented (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Implemented;
   end Implemented;

   function Forthcoming (Kind : Problem_Kind) return Boolean is
   begin
      return Classify_Problem (Kind).Forthcoming;
   end Forthcoming;

   function Forthcoming (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Forthcoming;
   end Forthcoming;

   ---------------------------------------------------------------------------
   -- Knapsack utilities
   ---------------------------------------------------------------------------

   function Total_Weight
     (Weights : Weight_Array; Sel : Selection) return Natural
   is
      S : Natural := 0;
   begin
      for I in Weights'Range loop
         if Sel (I) then
            S := S + Weights (I);
         end if;
      end loop;
      return S;
   end Total_Weight;

   function Total_Value
     (Values : Value_Array; Sel : Selection) return Natural
   is
      S : Natural := 0;
   begin
      for I in Values'Range loop
         if Sel (I) then
            S := S + Values (I);
         end if;
      end loop;
      return S;
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
      else
         return Long_Float (Value) / Long_Float (Weight);
      end if;
   end Density;

   function Knapsack_DP
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Capacity_Range) return Knapsack_Result
   is
      N : constant Item_Count := Weights'Length;
      --  DP (i, c) = best value using items Weights'First .. Weights'First+i-1
      --  Compact 1-based item view.
      type DP_Table is
        array (0 .. Max_Items, 0 .. Max_Capacity) of Natural;
      DP : DP_Table := [others => [others => 0]];
      W  : array (1 .. Max_Items) of Natural := [others => 0];
      V  : array (1 .. Max_Items) of Natural := [others => 0];
      R  : Knapsack_Result;
      Cap_Left : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      for K in 1 .. N loop
         W (K) := Weights (Weights'First + K - 1);
         V (K) := Values (Values'First + K - 1);
      end loop;

      for I in 1 .. N loop
         for C in 0 .. Capacity loop
            DP (I, C) := DP (I - 1, C);
            if W (I) <= C then
               declare
                  Cand : constant Natural := DP (I - 1, C - W (I)) + V (I);
               begin
                  if Cand > DP (I, C) then
                     DP (I, C) := Cand;
                  end if;
               end;
            end if;
         end loop;
      end loop;

      R.Best_Value := DP (N, Capacity);
      R.N_Items := N;
      R.Exact := True;
      Cap_Left := Capacity;
      for I in reverse 1 .. N loop
         if I = 1 then
            if DP (1, Cap_Left) > 0
              and then W (1) <= Cap_Left
              and then DP (1, Cap_Left) = V (1)
            then
               R.Selected (I) := True;
               Cap_Left := Cap_Left - W (1);
            end if;
         elsif DP (I, Cap_Left) /= DP (I - 1, Cap_Left) then
            R.Selected (I) := True;
            Cap_Left := Cap_Left - W (I);
         end if;
      end loop;
      R.Best_Weight := Capacity - Cap_Left;
      return R;
   end Knapsack_DP;

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
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      --  Enumerate masks 0 .. 2^N - 1
      declare
         Max_Mask : constant Natural := (2 ** N) - 1;
      begin
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
      end;
      R.Best_Value := Best_Val;
      R.Best_Weight := Best_W;
      R.Selected := Best_Sel;
      R.N_Items := N;
      R.Exact := True;
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
      --  Simple insertion sort by density descending (stable educational)
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

   ---------------------------------------------------------------------------
   -- MST Kruskal + Union-Find
   ---------------------------------------------------------------------------

   function MST_Kruskal
     (Costs : Cost_Matrix; N : Vertex_Count) return MST_Result
   is
      type Parent_Arr is array (1 .. Max_Vertices) of Natural;
      Parent : Parent_Arr := [others => 0];
      Rank   : array (1 .. Max_Vertices) of Natural := [others => 0];

      function Find (X : Positive) return Positive is
         R : Positive := X;
      begin
         while Parent (R) /= R loop
            Parent (R) := Parent (Parent (R));  -- path halving
            R := Parent (R);
         end loop;
         return R;
      end Find;

      procedure Union (A, B : Positive) is
         RA : constant Positive := Find (A);
         RB : constant Positive := Find (B);
      begin
         if RA = RB then
            return;
         end if;
         if Rank (RA) < Rank (RB) then
            Parent (RA) := RB;
         elsif Rank (RA) > Rank (RB) then
            Parent (RB) := RA;
         else
            Parent (RB) := RA;
            Rank (RA) := Rank (RA) + 1;
         end if;
      end Union;

      type Edge_Rec is record
         U, V : Positive := 1;
         W    : Cost := 0;
      end record;
      Edges : array (1 .. Max_Vertices * Max_Vertices) of Edge_Rec;
      E_Count : Natural := 0;
      R : MST_Result;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         Parent (I) := I;
      end loop;

      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if Costs (I, J) /= No_Edge then
               E_Count := E_Count + 1;
               Edges (E_Count) := (U => I, V => J, W => Costs (I, J));
            elsif Costs (J, I) /= No_Edge then
               --  Accept either triangle orientation
               E_Count := E_Count + 1;
               Edges (E_Count) := (U => I, V => J, W => Costs (J, I));
            end if;
         end loop;
      end loop;

      --  Insertion sort edges by weight ascending
      for I in 2 .. E_Count loop
         declare
            Key : constant Edge_Rec := Edges (I);
            J   : Natural := I - 1;
         begin
            while J >= 1 and then Edges (J).W > Key.W loop
               Edges (J + 1) := Edges (J);
               J := J - 1;
            end loop;
            Edges (J + 1) := Key;
         end;
      end loop;

      R.Total_Weight := 0;
      R.Edge_Count := 0;
      for K in 1 .. E_Count loop
         exit when R.Edge_Count = N - 1;
         declare
            U : constant Positive := Edges (K).U;
            V : constant Positive := Edges (K).V;
         begin
            if Find (U) /= Find (V) then
               Union (U, V);
               R.Edge_Count := R.Edge_Count + 1;
               R.Edges (R.Edge_Count) :=
                 (U => U, V => V, W => Edges (K).W);
               R.Total_Weight := R.Total_Weight + Edges (K).W;
            end if;
         end;
      end loop;

      R.Success := (N = 1) or else (R.Edge_Count = N - 1);
      return R;
   end MST_Kruskal;

   ---------------------------------------------------------------------------
   -- Assignment
   ---------------------------------------------------------------------------

   function Is_Permutation
     (Perm : Permutation; N : Assign_Count) return Boolean
   is
      Seen : array (1 .. Max_Assign) of Boolean := [others => False];
   begin
      for I in 1 .. N loop
         if Perm (I) > N then
            return False;
         end if;
         if Seen (Perm (I)) then
            return False;
         end if;
         Seen (Perm (I)) := True;
      end loop;
      return True;
   end Is_Permutation;

   function Assignment_Cost
     (Costs : Cost_Matrix;
      Perm : Permutation;
      N    : Assign_Count) return Cost
   is
      S : Cost := 0;
   begin
      if not Is_Permutation (Perm, N) then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         S := S + Costs (I, Perm (I));
      end loop;
      return S;
   end Assignment_Cost;

   function Assignment_Brute_Force
     (Costs : Cost_Matrix; N : Assign_Count) return Assignment_Result
   is
      Perm : Permutation (1 .. Max_Assign) := [others => 1];
      Best : Assignment_Result;
      First : Boolean := True;

      procedure Evaluate is
         C : constant Cost := Assignment_Cost (Costs, Perm, N);
      begin
         if First or else C < Best.Total then
            Best.Total := C;
            Best.Mapping := Perm;
            Best.N := N;
            Best.Exact := True;
            First := False;
         end if;
      end Evaluate;

      procedure Heap_Permute (K : Natural) is
      begin
         if K = 1 then
            Evaluate;
            return;
         end if;
         Heap_Permute (K - 1);
         for I in 1 .. K - 1 loop
            if K rem 2 = 0 then
               declare
                  Tmp : constant Positive := Perm (I);
               begin
                  Perm (I) := Perm (K);
                  Perm (K) := Tmp;
               end;
            else
               declare
                  Tmp : constant Positive := Perm (1);
               begin
                  Perm (1) := Perm (K);
                  Perm (K) := Tmp;
               end;
            end if;
            Heap_Permute (K - 1);
         end loop;
      end Heap_Permute;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         Perm (I) := I;
      end loop;
      Best.Total := 0;
      Best.N := N;
      Best.Exact := True;
      Heap_Permute (N);
      return Best;
   end Assignment_Brute_Force;

   ---------------------------------------------------------------------------
   -- TSP
   ---------------------------------------------------------------------------

   function Tour_Length
     (Dist : Cost_Matrix; T : Tour; N : City_Count) return Cost
   is
      S : Cost := 0;
   begin
      for I in 1 .. N - 1 loop
         S := S + Dist (T (I), T (I + 1));
      end loop;
      S := S + Dist (T (N), T (1));
      return S;
   end Tour_Length;

   function TSP_Brute_Force
     (Dist : Cost_Matrix; N : City_Count) return TSP_Result
   is
      --  Fix city 1 at position 1; permute cities 2 .. N
      Cities : array (1 .. Max_Cities) of Positive := [others => 1];
      Best   : TSP_Result;
      First  : Boolean := True;

      procedure Evaluate is
         T : Tour (1 .. Max_Cities) := [others => 1];
         L : Cost;
      begin
         T (1) := 1;
         for I in 2 .. N loop
            T (I) := Cities (I);
         end loop;
         L := Tour_Length (Dist, T, N);
         if First or else L < Best.Best_Length then
            Best.Best_Tour := T;
            Best.Best_Length := L;
            Best.N := N;
            Best.Exact := True;
            First := False;
         end if;
      end Evaluate;

      procedure Heap_Permute (K : Natural) is
         --  Permute Cities (2 .. K) with Heap on suffix length
         Lo : constant Positive := 2;
      begin
         if K <= Lo then
            Evaluate;
            return;
         end if;
         Heap_Permute (K - 1);
         for I in Lo .. K - 1 loop
            if (K - Lo + 1) rem 2 = 0 then
               declare
                  Tmp : constant Positive := Cities (I);
               begin
                  Cities (I) := Cities (K);
                  Cities (K) := Tmp;
               end;
            else
               declare
                  Tmp : constant Positive := Cities (Lo);
               begin
                  Cities (Lo) := Cities (K);
                  Cities (K) := Tmp;
               end;
            end if;
            Heap_Permute (K - 1);
         end loop;
      end Heap_Permute;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      Cities (1) := 1;
      for I in 2 .. N loop
         Cities (I) := I;
      end loop;
      Best.N := N;
      Best.Exact := True;
      Best.Best_Length := 0;
      if N = 2 then
         Evaluate;
      else
         Heap_Permute (N);
      end if;
      return Best;
   end TSP_Brute_Force;

   function Two_Opt_Improve
     (Dist : Cost_Matrix;
      T    : in out Tour;
      N    : City_Count) return Boolean
   is
      Best_Diff : Cost := 0;
      Best_I     : Natural := 0;
      Best_J     : Natural := 0;
      Improved   : Boolean := False;
   begin
      --  Edges (i, i+1) and (j, j+1); reverse segment i+1 .. j
      for I in 1 .. N - 2 loop
         for J in I + 2 .. N loop
            if I = 1 and then J = N then
               null;  -- would remove both edges of city 1 wrap — skip
            else
               declare
                  A : constant Positive := T (I);
                  B : constant Positive := T (I + 1);
                  C : constant Positive := T (J);
                  D : constant Positive :=
                    (if J = N then T (1) else T (J + 1));
                  Diff : constant Cost :=
                    Dist (A, C) + Dist (B, D)
                    - Dist (A, B) - Dist (C, D);
               begin
                  if Diff < Best_Diff then
                     Best_Diff := Diff;
                     Best_I := I;
                     Best_J := J;
                     Improved := True;
                  end if;
               end;
            end if;
         end loop;
      end loop;

      if Improved then
         --  Reverse T (Best_I+1 .. Best_J)
         declare
            L : Natural := Best_I + 1;
            R : Natural := Best_J;
         begin
            while L < R loop
               declare
                  Tmp : constant Positive := T (L);
               begin
                  T (L) := T (R);
                  T (R) := Tmp;
               end;
               L := L + 1;
               R := R - 1;
            end loop;
         end;
      end if;
      return Improved;
   end Two_Opt_Improve;

   function TSP_Two_Opt
     (Dist  : Cost_Matrix;
      Start : Tour;
      N     : City_Count) return TSP_Result
   is
      T : Tour (1 .. Max_Cities) := [others => 1];
      R : TSP_Result;
      Guard : Natural := 0;
   begin
      for I in 1 .. N loop
         T (I) := Start (I);
      end loop;
      while Two_Opt_Improve (Dist, T, N) and then Guard < 10_000 loop
         Guard := Guard + 1;
      end loop;
      R.Best_Tour := T;
      R.N := N;
      R.Best_Length := Tour_Length (Dist, T, N);
      R.Exact := False;
      return R;
   end TSP_Two_Opt;

end Combinatorial_Optimization;
