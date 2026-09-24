--  Chain_Matrix_Multiplication body — classic O(n^3) matrix-chain DP.

pragma Ada_2022;

package body Chain_Matrix_Multiplication
  with SPARK_Mode => Off
is

   function Trim_Image (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      if S'Length > 0 and then S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      end if;
      return S;
   end Trim_Image;

   function Matrix_Count_Of (Dims : Dimensions) return Matrix_Count is
   begin
      return Dims'Length - 1;
   end Matrix_Count_Of;

   function Dim_At (Dims : Dimensions; Zero_Based : Natural) return Positive is
   --  p_{Zero_Based} via relative indexing from Dims'First.
   begin
      return Dims (Dims'First + Zero_Based);
   end Dim_At;

   ---------------------------------------------------------------------------
   -- Core DP
   ---------------------------------------------------------------------------

   function Optimal_Order (Dims : Dimensions) return DP_Result is
      P : constant Matrix_Count := Dims'Length - 1;
      R : DP_Result;
      Q : Natural;
   begin
      R.N := P;

      if P = 0 then
         R.Success := True;
         return R;
      end if;

      if P = 1 then
         R.Min_Cost := 0;
         R.Cost (1, 1) := 0;
         R.Success := True;
         return R;
      end if;

      --  Length-1 chains already 0 on the diagonal.
      for I in 1 .. P loop
         R.Cost (I, I) := 0;
      end loop;

      for Len in 2 .. P loop
         for I in 1 .. P - Len + 1 loop
            declare
               J : constant Matrix_Index := I + Len - 1;
               First : Boolean := True;
            begin
               for K in I .. J - 1 loop
                  Q := R.Cost (I, K) + R.Cost (K + 1, J)
                    + Dim_At (Dims, I - 1)
                    * Dim_At (Dims, K)
                    * Dim_At (Dims, J);
                  if First or else Q < R.Cost (I, J) then
                     R.Cost (I, J) := Q;
                     R.Split (I, J) := K;
                     First := False;
                  end if;
               end loop;
            end;
         end loop;
      end loop;

      R.Min_Cost := R.Cost (1, P);
      R.Success  := True;
      return R;
   end Optimal_Order;

   function Optimal_Cost (Dims : Dimensions) return Natural is
      R : constant DP_Result := Optimal_Order (Dims);
   begin
      return R.Min_Cost;
   end Optimal_Cost;

   function Compute_DP (Dims : Dimensions) return DP_Result is
   begin
      return Optimal_Order (Dims);
   end Compute_DP;

   ---------------------------------------------------------------------------
   -- Parenthesization
   ---------------------------------------------------------------------------

   function Parenthesize
     (Split : Split_Table;
      N     : Matrix_Count;
      I, J  : Matrix_Index) return String
   is
   begin
      if J > N then
         raise Invalid_Argument;
      end if;
      if I = J then
         return "A" & Trim_Image (I);
      else
         declare
            K     : constant Natural := Split (I, J);
            Left  : constant String :=
              Parenthesize (Split, N, I, Matrix_Index (K));
            Right : constant String :=
              Parenthesize (Split, N, Matrix_Index (K + 1), J);
         begin
            return "(" & Left & "*" & Right & ")";
         end;
      end if;
   end Parenthesize;

   function Format_Order (R : DP_Result) return String is
   begin
      return Parenthesize (R.Split, R.N, 1, Matrix_Index (R.N));
   end Format_Order;

   ---------------------------------------------------------------------------
   -- Verification helpers
   ---------------------------------------------------------------------------

   function Cost_Of_Split
     (Dims  : Dimensions;
      Split : Split_Table;
      I, J  : Matrix_Index) return Natural
   is
   begin
      if I = J then
         return 0;
      else
         declare
            K : constant Natural := Split (I, J);
         begin
            if K < I or else K >= J then
               raise Invalid_Argument;
            end if;
            return Cost_Of_Split (Dims, Split, I, Matrix_Index (K))
              + Cost_Of_Split (Dims, Split, Matrix_Index (K + 1), J)
              + Dim_At (Dims, I - 1)
              * Dim_At (Dims, K)
              * Dim_At (Dims, J);
         end;
      end if;
   end Cost_Of_Split;

   function Cost_Of_Split
     (Dims  : Dimensions;
      Split : Split_Table) return Natural
   is
      N : constant Matrix_Count := Dims'Length - 1;
   begin
      if N = 0 then
         return 0;
      end if;
      return Cost_Of_Split (Dims, Split, 1, Matrix_Index (N));
   end Cost_Of_Split;

   function Left_Associative_Cost (Dims : Dimensions) return Natural is
      N    : constant Matrix_Count := Dims'Length - 1;
      Cost : Natural := 0;
      --  Running product has shape p0 × p_k after multiplying A1..Ak.
      Rows : Positive;
   begin
      if N <= 1 then
         return 0;
      end if;
      Rows := Dim_At (Dims, 0);
      for K in 1 .. N - 1 loop
         --  (...A_k) is Rows × p_k; multiply by A_{k+1} = p_k × p_{k+1}.
         Cost := Cost
           + Rows * Dim_At (Dims, K) * Dim_At (Dims, K + 1);
         --  Result shape: Rows × p_{k+1}; Rows unchanged.
      end loop;
      return Cost;
   end Left_Associative_Cost;

   function Right_Associative_Cost (Dims : Dimensions) return Natural is
      N    : constant Matrix_Count := Dims'Length - 1;
      Cost : Natural := 0;
      --  Running product A_k..A_n has shape p_{k-1} × p_n.
      Cols : Positive;
   begin
      if N <= 1 then
         return 0;
      end if;
      Cols := Dim_At (Dims, N);
      for K in reverse 1 .. N - 1 loop
         --  Multiply A_k = p_{k-1} × p_k by (A_{k+1}..A_n) = p_k × Cols.
         Cost := Cost
           + Dim_At (Dims, K - 1) * Dim_At (Dims, K) * Cols;
         --  Result shape: p_{k-1} × Cols; Cols unchanged.
      end loop;
      return Cost;
   end Right_Associative_Cost;

end Chain_Matrix_Multiplication;
