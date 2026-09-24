--  Dynamic_Programming body — classic educational DP tables.

pragma Ada_2022;

package body Dynamic_Programming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Classify (Kind : Problem_Kind) return Problem_Info is
   begin
      case Kind is
         when Fibonacci_Seq =>
            return
              (Kind                         => Fibonacci_Seq,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 1);
         when Knapsack_01 =>
            return
              (Kind                         => Knapsack_01,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 2);
         when Coin_Change_Min =>
            return
              (Kind                         => Coin_Change_Min,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 1);
         when Coin_Change_Ways =>
            return
              (Kind                         => Coin_Change_Ways,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 1);
         when Longest_Common_Subseq =>
            return
              (Kind                         => Longest_Common_Subseq,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 2);
         when Edit_Distance =>
            return
              (Kind                         => Edit_Distance,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 2);
         when Matrix_Chain =>
            return
              (Kind                         => Matrix_Chain,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 2);
         when Unique_Grid_Paths =>
            return
              (Kind                         => Unique_Grid_Paths,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 2);
         when Rod_Cutting =>
            return
              (Kind                         => Rod_Cutting,
               Uses_Optimal_Substructure    => True,
               Uses_Overlapping_Subproblems => True,
               Default_Strategy             => Tabulation,
               Typical_Table_Dims           => 1);
      end case;
   end Classify;

   function Problem_Name (Kind : Problem_Kind) return String is
   begin
      case Kind is
         when Fibonacci_Seq          => return "Fibonacci";
         when Knapsack_01            => return "0/1 Knapsack";
         when Coin_Change_Min        => return "Coin Change (min coins)";
         when Coin_Change_Ways       => return "Coin Change (combinations)";
         when Longest_Common_Subseq  => return "Longest Common Subsequence";
         when Edit_Distance          => return "Edit Distance (Levenshtein)";
         when Matrix_Chain           => return "Matrix-Chain Order";
         when Unique_Grid_Paths      => return "Unique Grid Paths";
         when Rod_Cutting            => return "Rod Cutting";
      end case;
   end Problem_Name;

   function Strategy_Name (S : Fill_Strategy) return String is
   begin
      case S is
         when Tabulation  => return "Tabulation";
         when Memoization => return "Memoization";
      end case;
   end Strategy_Name;

   function Uses_Optimal_Substructure (Kind : Problem_Kind) return Boolean is
      Info : constant Problem_Info := Classify (Kind);
   begin
      return Info.Uses_Optimal_Substructure;
   end Uses_Optimal_Substructure;

   function Uses_Overlapping_Subproblems
     (Kind : Problem_Kind) return Boolean
   is
      Info : constant Problem_Info := Classify (Kind);
   begin
      return Info.Uses_Overlapping_Subproblems;
   end Uses_Overlapping_Subproblems;

   function Problem_Count return Natural is
   begin
      return Problem_Kind'Pos (Problem_Kind'Last)
           - Problem_Kind'Pos (Problem_Kind'First)
           + 1;
   end Problem_Count;

   ---------------------------------------------------------------------------
   -- Fibonacci
   ---------------------------------------------------------------------------

   function Fibonacci (N : Fib_Index) return Fib_Value is
      A, B, T : Fib_Value;
   begin
      if N = 0 then
         return 0;
      elsif N = 1 then
         return 1;
      end if;
      A := 0;
      B := 1;
      for I in 2 .. N loop
         T := A + B;
         A := B;
         B := T;
      end loop;
      return B;
   end Fibonacci;

   function Fibonacci_Memo (N : Fib_Index) return Fib_Value is
      Memo : array (Fib_Index) of Fib_Value := [others => 0];
      Seen : array (Fib_Index) of Boolean := [others => False];

      function Go (K : Fib_Index) return Fib_Value is
      begin
         if Seen (K) then
            return Memo (K);
         end if;
         if K = 0 then
            Memo (K) := 0;
         elsif K = 1 then
            Memo (K) := 1;
         else
            Memo (K) := Go (K - 1) + Go (K - 2);
         end if;
         Seen (K) := True;
         return Memo (K);
      end Go;
   begin
      return Go (N);
   end Fibonacci_Memo;

   ---------------------------------------------------------------------------
   -- 0/1 Knapsack
   ---------------------------------------------------------------------------

   function Knapsack_01
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Capacity_Range) return Natural
   is
      type DP_Row is array (0 .. Max_Capacity) of Natural;
      DP : DP_Row := [others => 0];
      W_I, V_I : Natural;
   begin
      for I in Weights'Range loop
         W_I := Weights (I);
         V_I := Values (I);
         if W_I > Max_Capacity then
            raise Invalid_Argument
              with "Knapsack_01: item weight exceeds Max_Capacity";
         end if;
         for W in reverse W_I .. Capacity loop
            if DP (W - W_I) + V_I > DP (W) then
               DP (W) := DP (W - W_I) + V_I;
            end if;
         end loop;
      end loop;
      return DP (Capacity);
   end Knapsack_01;

   function Knapsack_01_With_Selection
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Capacity_Range) return Knapsack_Result
   is
      N : constant Item_Count := Weights'Length;
      type DP_Table is
        array (0 .. Max_Items, 0 .. Max_Capacity) of Natural;
      DP : DP_Table := [others => [others => 0]];
      R  : Knapsack_Result;
      W_I, V_I : Natural;
      Remain   : Natural;
      Rel      : Positive;
   begin
      for Idx in 1 .. N loop
         W_I := Weights (Weights'First + Idx - 1);
         V_I := Values (Values'First + Idx - 1);
         if W_I > Max_Capacity then
            raise Invalid_Argument
              with "Knapsack_01_With_Selection: weight too large";
         end if;
         for W in 0 .. Capacity loop
            DP (Idx, W) := DP (Idx - 1, W);
            if W_I <= W
              and then DP (Idx - 1, W - W_I) + V_I > DP (Idx, W)
            then
               DP (Idx, W) := DP (Idx - 1, W - W_I) + V_I;
            end if;
         end loop;
      end loop;

      R.Max_Value := DP (N, Capacity);
      R.Capacity  := Capacity;
      R.N_Items   := N;
      R.Success   := True;

      Remain := Capacity;
      for Idx in reverse 1 .. N loop
         if DP (Idx, Remain) /= DP (Idx - 1, Remain) then
            Rel := Idx;
            R.Selected (Rel) := True;
            Remain := Remain - Weights (Weights'First + Idx - 1);
         end if;
      end loop;
      return R;
   end Knapsack_01_With_Selection;

   ---------------------------------------------------------------------------
   -- Coin change
   ---------------------------------------------------------------------------

   function Min_Coins
     (Coins  : Coin_Array;
      Amount : Amount_Range) return Integer
   is
      Inf : constant Natural := Amount + 1;
      type DP_Row is array (0 .. Max_Amount) of Natural;
      DP : DP_Row := [others => Inf];
   begin
      for C of Coins loop
         if C > Max_Amount then
            raise Invalid_Argument
              with "Min_Coins: coin denomination too large";
         end if;
      end loop;

      DP (0) := 0;
      for A in 1 .. Amount loop
         for C of Coins loop
            if C <= A and then DP (A - C) + 1 < DP (A) then
               DP (A) := DP (A - C) + 1;
            end if;
         end loop;
      end loop;

      if DP (Amount) > Amount then
         return -1;
      else
         return Integer (DP (Amount));
      end if;
   end Min_Coins;

   function Coin_Combinations
     (Coins  : Coin_Array;
      Amount : Amount_Range) return Natural
   is
      type DP_Row is array (0 .. Max_Amount) of Natural;
      DP : DP_Row := [others => 0];
   begin
      for C of Coins loop
         if C > Max_Amount then
            raise Invalid_Argument
              with "Coin_Combinations: coin denomination too large";
         end if;
      end loop;

      DP (0) := 1;
      --  Outer loop over coins → unordered combinations.
      for C of Coins loop
         for A in C .. Amount loop
            DP (A) := DP (A) + DP (A - C);
         end loop;
      end loop;
      return DP (Amount);
   end Coin_Combinations;

   ---------------------------------------------------------------------------
   -- LCS
   ---------------------------------------------------------------------------

   function LCS_Length (A, B : String) return Natural is
      NA : constant Natural := A'Length;
      NB : constant Natural := B'Length;
      type DP_Table is
        array (0 .. Max_String_Len, 0 .. Max_String_Len) of Natural;
      DP : DP_Table := [others => [others => 0]];
   begin
      for I in 1 .. NA loop
         for J in 1 .. NB loop
            if A (A'First + I - 1) = B (B'First + J - 1) then
               DP (I, J) := DP (I - 1, J - 1) + 1;
            else
               DP (I, J) := Natural'Max (DP (I - 1, J), DP (I, J - 1));
            end if;
         end loop;
      end loop;
      return DP (NA, NB);
   end LCS_Length;

   function LCS_String (A, B : String) return String is
      NA : constant Natural := A'Length;
      NB : constant Natural := B'Length;
      type DP_Table is
        array (0 .. Max_String_Len, 0 .. Max_String_Len) of Natural;
      DP : DP_Table := [others => [others => 0]];
      Buf : String (1 .. Max_String_Len);
      Len : Natural := 0;
      I, J : Natural;
   begin
      for II in 1 .. NA loop
         for JJ in 1 .. NB loop
            if A (A'First + II - 1) = B (B'First + JJ - 1) then
               DP (II, JJ) := DP (II - 1, JJ - 1) + 1;
            else
               DP (II, JJ) :=
                 Natural'Max (DP (II - 1, JJ), DP (II, JJ - 1));
            end if;
         end loop;
      end loop;

      I := NA;
      J := NB;
      while I > 0 and then J > 0 loop
         if A (A'First + I - 1) = B (B'First + J - 1) then
            Len := Len + 1;
            Buf (Len) := A (A'First + I - 1);
            I := I - 1;
            J := J - 1;
         elsif DP (I - 1, J) >= DP (I, J - 1) then
            I := I - 1;
         else
            J := J - 1;
         end if;
      end loop;

      declare
         Result : String (1 .. Len);
      begin
         for K in 1 .. Len loop
            Result (K) := Buf (Len - K + 1);
         end loop;
         return Result;
      end;
   end LCS_String;

   ---------------------------------------------------------------------------
   -- Edit distance
   ---------------------------------------------------------------------------

   function Edit_Distance (A, B : String) return Natural is
      NA : constant Natural := A'Length;
      NB : constant Natural := B'Length;
      type DP_Table is
        array (0 .. Max_String_Len, 0 .. Max_String_Len) of Natural;
      DP : DP_Table := [others => [others => 0]];
      Cost : Natural;
   begin
      for I in 0 .. NA loop
         DP (I, 0) := I;
      end loop;
      for J in 0 .. NB loop
         DP (0, J) := J;
      end loop;

      for I in 1 .. NA loop
         for J in 1 .. NB loop
            if A (A'First + I - 1) = B (B'First + J - 1) then
               Cost := 0;
            else
               Cost := 1;
            end if;
            DP (I, J) :=
              Natural'Min
                (DP (I - 1, J) + 1,                          -- delete
                 Natural'Min
                   (DP (I, J - 1) + 1,                       -- insert
                    DP (I - 1, J - 1) + Cost));               -- subst / match
         end loop;
      end loop;
      return DP (NA, NB);
   end Edit_Distance;

   ---------------------------------------------------------------------------
   -- Matrix-chain order
   ---------------------------------------------------------------------------

   function Matrix_Chain_Cost (Dims : Dim_Array) return Natural is
      R : constant Matrix_Chain_Result := Matrix_Chain_Order (Dims);
   begin
      return R.Min_Cost;
   end Matrix_Chain_Cost;

   function Matrix_Chain_Order
     (Dims : Dim_Array) return Matrix_Chain_Result
   is
      P : constant Matrix_Count := Dims'Length - 1;
      --  Cost(i,j) = min cost to multiply Ai..Aj (1-based).
      type Cost_Table is
        array (1 .. Max_Matrices, 1 .. Max_Matrices) of Natural;
      Cost : Cost_Table := [others => [others => 0]];
      R    : Matrix_Chain_Result;
      Q    : Natural;
      Di, Dk, Dj : Natural;
   begin
      R.N := P;
      if P = 0 then
         R.Success := True;
         return R;
      end if;
      if P = 1 then
         R.Min_Cost := 0;
         R.Success  := True;
         return R;
      end if;

      for Len in 2 .. P loop
         for I in 1 .. P - Len + 1 loop
            declare
               J : constant Positive := I + Len - 1;
            begin
               Cost (I, J) := Natural'Last;
               for K in I .. J - 1 loop
                  Di := Dims (Dims'First + I - 1);
                  Dk := Dims (Dims'First + K);
                  Dj := Dims (Dims'First + J);
                  --  Guard against overflow in educational demos: products
                  --  stay within Natural for small dims used in tests.
                  Q := Cost (I, K) + Cost (K + 1, J) + Di * Dk * Dj;
                  if Q < Cost (I, J) then
                     Cost (I, J) := Q;
                     R.Split (I, J) := K;
                  end if;
               end loop;
            end;
         end loop;
      end loop;

      R.Min_Cost := Cost (1, P);
      R.Success  := True;
      return R;
   end Matrix_Chain_Order;

   ---------------------------------------------------------------------------
   -- Unique grid paths / rod cutting
   ---------------------------------------------------------------------------

   function Unique_Paths (M, N : Grid_Size) return Natural is
      type DP_Table is array (1 .. Max_Grid, 1 .. Max_Grid) of Natural;
      DP : DP_Table := [others => [others => 0]];
   begin
      for I in 1 .. M loop
         DP (I, 1) := 1;
      end loop;
      for J in 1 .. N loop
         DP (1, J) := 1;
      end loop;
      for I in 2 .. M loop
         for J in 2 .. N loop
            DP (I, J) := DP (I - 1, J) + DP (I, J - 1);
         end loop;
      end loop;
      return DP (M, N);
   end Unique_Paths;

   function Rod_Cutting
     (Prices : Price_Array;
      Length : Rod_Len) return Natural
   is
      type DP_Row is array (0 .. Max_Rod_Len) of Natural;
      DP : DP_Row := [others => 0];
      Best : Natural;
      Price_I : Natural;
   begin
      if Length = 0 then
         return 0;
      end if;
      for L in 1 .. Length loop
         Best := 0;
         for I in 1 .. L loop
            Price_I := Prices (Prices'First + I - 1);
            if Price_I + DP (L - I) > Best then
               Best := Price_I + DP (L - I);
            end if;
         end loop;
         DP (L) := Best;
      end loop;
      return DP (Length);
   end Rod_Cutting;

end Dynamic_Programming;
