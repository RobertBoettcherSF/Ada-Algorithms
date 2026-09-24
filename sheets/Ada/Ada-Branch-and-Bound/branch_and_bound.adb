--  Branch_And_Bound body — 0-1 knapsack BnB with Dantzig fractional bound.

pragma Ada_2022;

package body Branch_And_Bound
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Utilities
   ---------------------------------------------------------------------------

   function Total_Weight
     (Weights : Weight_Array; Chosen : Selection) return Natural
   is
      S : Natural := 0;
   begin
      for I in Weights'Range loop
         if Chosen (Chosen'First + (I - Weights'First)) then
            S := S + Weights (I);
         end if;
      end loop;
      return S;
   end Total_Weight;

   function Total_Value
     (Values : Value_Array; Chosen : Selection) return Natural
   is
      S : Natural := 0;
   begin
      for I in Values'Range loop
         if Chosen (Chosen'First + (I - Values'First)) then
            S := S + Values (I);
         end if;
      end loop;
      return S;
   end Total_Value;

   function Is_Feasible
     (Weights  : Weight_Array;
      Chosen   : Selection;
      Capacity : Natural) return Boolean
   is
   begin
      return Total_Weight (Weights, Chosen) <= Capacity;
   end Is_Feasible;

   function Density (Value, Weight : Natural) return Real is
   begin
      if Weight = 0 then
         if Value = 0 then
            return 0.0;
         else
            return Real'Last / 4.0;
         end if;
      else
         return Real (Value) / Real (Weight);
      end if;
   end Density;

   function Density_Order
     (Weights : Weight_Array;
      Values  : Value_Array) return Index_Array
   is
      N   : constant Item_Count := Weights'Length;
      Ord : Index_Array (1 .. N);
   begin
      for I in 1 .. N loop
         Ord (I) := I;
      end loop;
      --  Insertion sort by decreasing density (stable enough for n ≤ 32).
      for I in 2 .. N loop
         declare
            Key : constant Positive := Ord (I);
            J   : Natural := I - 1;
         begin
            while J >= 1
              and then Density (Values (Ord (J)), Weights (Ord (J)))
                         < Density (Values (Key), Weights (Key))
            loop
               Ord (J + 1) := Ord (J);
               J := J - 1;
            end loop;
            Ord (J + 1) := Key;
         end;
      end loop;
      return Ord;
   end Density_Order;

   function Same_Selection
     (A, B : Selection; N : Item_Count) return Boolean
   is
   begin
      for I in 1 .. N loop
         if A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Selection;

   ---------------------------------------------------------------------------
   -- Dantzig fractional bound
   ---------------------------------------------------------------------------

   function Fractional_Bound
     (Weights   : Weight_Array;
      Values    : Value_Array;
      Order     : Index_Array;
      First_Pos : Positive;
      Remaining : Natural) return Real
   is
      Cap   : Natural := Remaining;
      Bound : Real := 0.0;
      Idx   : Positive;
      W, V  : Natural;
   begin
      if First_Pos > Order'Last then
         return 0.0;
      end if;

      for Pos in First_Pos .. Order'Last loop
         Idx := Order (Pos);
         W   := Weights (Idx);
         V   := Values (Idx);
         if W = 0 then
            Bound := Bound + Real (V);
         elsif W <= Cap then
            Bound := Bound + Real (V);
            Cap   := Cap - W;
         else
            --  Take fractional piece of this item, then stop.
            if Cap > 0 then
               Bound := Bound + Real (V) * (Real (Cap) / Real (W));
            end if;
            return Bound;
         end if;
      end loop;
      return Bound;
   end Fractional_Bound;

   function Fractional_Bound
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Real
   is
      Ord : constant Index_Array := Density_Order (Weights, Values);
   begin
      return Fractional_Bound
        (Weights, Values, Ord, Ord'First, Capacity);
   end Fractional_Bound;

   ---------------------------------------------------------------------------
   -- Exhaustive baseline
   ---------------------------------------------------------------------------

   function Knapsack_Exhaustive
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Result
   is
      N : constant Item_Count := Weights'Length;
      R : Result;
      --  Mask enumeration: bit k (0-based) => item k+1.
      Max_Mask : constant Natural :=
        (if N = 0 then 0 else (2 ** N) - 1);
   begin
      if Capacity > Max_Capacity then
         raise Invalid_Argument;
      end if;

      R.N_Items := N;
      R.Exact   := True;
      R.Success := True;
      R.Nodes   := Max_Mask + 1;

      for Mask in 0 .. Max_Mask loop
         declare
            Wsum : Natural := 0;
            Vsum : Natural := 0;
            Ok   : Boolean := True;
         begin
            for I in 1 .. N loop
               if (Mask / (2 ** (I - 1))) mod 2 = 1 then
                  Wsum := Wsum + Weights (I);
                  if Wsum > Capacity then
                     Ok := False;
                     exit;
                  end if;
                  Vsum := Vsum + Values (I);
               end if;
            end loop;
            if Ok and then Vsum > R.Best_Value then
               R.Best_Value  := Vsum;
               R.Best_Weight := Wsum;
               for I in 1 .. N loop
                  R.Selected (I) :=
                    ((Mask / (2 ** (I - 1))) mod 2 = 1);
               end loop;
               for I in N + 1 .. Max_Items loop
                  R.Selected (I) := False;
               end loop;
            end if;
         end;
      end loop;

      return R;
   end Knapsack_Exhaustive;

   ---------------------------------------------------------------------------
   -- Branch-and-bound search
   ---------------------------------------------------------------------------

   function Solve_Knapsack_BnB
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Params   : Parameters := Default_Parameters) return Result
   is
      N : constant Item_Count := Weights'Length;
      R : Result;

      Order : Index_Array (1 .. N);

      Cur_Sel : Selection (1 .. Max_Items) := [others => False];

      --  Dantzig bound over undecided items Order(Pos..N), always
      --  re-sorted by density so branching order need not be sorted.
      function Bound_From (Pos : Positive; Rem_Cap : Natural) return Real is
         Count : Natural := 0;
         Rest  : Index_Array (1 .. N);
         Key   : Positive;
         J     : Natural;
      begin
         if Pos > N then
            return 0.0;
         end if;
         for P in Pos .. N loop
            Count := Count + 1;
            Rest (Count) := Order (P);
         end loop;
         --  Sort Rest(1 .. Count) by decreasing density.
         for I in 2 .. Count loop
            Key := Rest (I);
            J := I - 1;
            while J >= 1
              and then Density (Values (Rest (J)), Weights (Rest (J)))
                         < Density (Values (Key), Weights (Key))
            loop
               Rest (J + 1) := Rest (J);
               J := J - 1;
            end loop;
            Rest (J + 1) := Key;
         end loop;
         return Fractional_Bound
           (Weights, Values, Rest (1 .. Count), 1, Rem_Cap);
      end Bound_From;

      procedure Visit
        (Pos        : Positive;
         Cur_Value  : Natural;
         Cur_Weight : Natural;
         Rem_Cap    : Natural)
      is
         Bound_Add  : Real;
         Optimistic : Real;
         Idx        : Positive;
      begin
         R.Nodes := R.Nodes + 1;

         --  Completed assignment of all ordered positions.
         if N = 0 or else Pos > N then
            if Cur_Value > R.Best_Value then
               R.Best_Value  := Cur_Value;
               R.Best_Weight := Cur_Weight;
               R.Selected    := Cur_Sel;
            end if;
            return;
         end if;

         Bound_Add  := Bound_From (Pos, Rem_Cap);
         Optimistic := Real (Cur_Value) + Bound_Add;

         --  Maximization: prune when bound cannot beat incumbent.
         if Optimistic <= Real (R.Best_Value) then
            R.Pruned := R.Pruned + 1;
            return;
         end if;

         Idx := Order (Pos);

         --  Branch 1: include item Idx (if it fits).
         if Weights (Idx) <= Rem_Cap then
            Cur_Sel (Idx) := True;
            Visit
              (Pos + 1,
               Cur_Value + Values (Idx),
               Cur_Weight + Weights (Idx),
               Rem_Cap - Weights (Idx));
            Cur_Sel (Idx) := False;
         end if;

         --  Branch 2: exclude item Idx.
         --  Re-check bound after the include branch may have raised incumbent.
         Bound_Add  := Bound_From (Pos + 1, Rem_Cap);
         Optimistic := Real (Cur_Value) + Bound_Add;
         if Optimistic <= Real (R.Best_Value) then
            R.Pruned := R.Pruned + 1;
         else
            Visit (Pos + 1, Cur_Value, Cur_Weight, Rem_Cap);
         end if;
      end Visit;

   begin
      if Capacity > Max_Capacity then
         raise Invalid_Argument;
      end if;

      R.N_Items := N;
      R.Exact   := True;
      R.Success := True;

      if Params.Sort_By_Density then
         Order := Density_Order (Weights, Values);
      else
         for I in 1 .. N loop
            Order (I) := I;
         end loop;
      end if;

      --  Optional quick incumbent from greedy integral fill (helps pruning).
      declare
         Cap_Left : Natural := Capacity;
         Greedy_V : Natural := 0;
         Greedy_W : Natural := 0;
         Greedy_S : Selection (1 .. Max_Items) := [others => False];
         Idx      : Positive;
      begin
         for Pos in 1 .. N loop
            Idx := Order (Pos);
            if Weights (Idx) <= Cap_Left then
               Cap_Left := Cap_Left - Weights (Idx);
               Greedy_V := Greedy_V + Values (Idx);
               Greedy_W := Greedy_W + Weights (Idx);
               Greedy_S (Idx) := True;
            end if;
         end loop;
         R.Best_Value  := Greedy_V;
         R.Best_Weight := Greedy_W;
         R.Selected    := Greedy_S;
      end;

      Visit (1, 0, 0, Capacity);
      return R;
   end Solve_Knapsack_BnB;

   function Branch_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Params   : Parameters := Default_Parameters) return Result
   is
   begin
      return Solve_Knapsack_BnB (Weights, Values, Capacity, Params);
   end Branch_Knapsack;

end Branch_And_Bound;
