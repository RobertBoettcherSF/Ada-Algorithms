--  Heaps_Algorithm body — SPARK Level 4 classic recursive Heap permutation
--  generation into a static store. No access Visit callback, no exceptions,
--  no Intentional Annotate. Heap_Generate proves Last advances by K! via
--  Subprogram_Variant (Decreases => K); Generate posts Last = Factorial(N)
--  and that every stored row is a permutation of 1 .. N.

package body Heaps_Algorithm
  with SPARK_Mode => On
is

   -------------------------------------------------------------------------
   -- Count
   -------------------------------------------------------------------------

   function Count (N : Positive) return Natural is
   begin
      return Factorial (N);
   end Count;

   -------------------------------------------------------------------------
   -- Differs_By_Single_Swap
   -------------------------------------------------------------------------

   function Differs_By_Single_Swap
     (A, B : Permutation) return Boolean
   is
      N          : constant Natural := A'Length;
      Diff_Count : Natural := 0;
      First_Off  : Natural := 0;
      Second_Off : Natural := 0;
   begin
      if N /= B'Length or else N < 2 then
         return False;
      end if;

      if A'Length = 0 or else B'Length = 0 then
         return False;
      end if;

      for K in 0 .. N - 1 loop
         pragma Loop_Invariant (Diff_Count <= 2);
         pragma Loop_Invariant (Diff_Count <= K);
         pragma Loop_Invariant (if Diff_Count = 0 then First_Off = 0);
         pragma Loop_Invariant
           (if Diff_Count >= 1 then First_Off in 1 .. K);
         pragma Loop_Invariant
           (if Diff_Count >= 2 then Second_Off in First_Off + 1 .. K);
         pragma Loop_Invariant
           (if Diff_Count < 2 then Second_Off = 0);

         if A (A'First + K) /= B (B'First + K) then
            Diff_Count := Diff_Count + 1;
            if Diff_Count > 2 then
               return False;
            end if;
            if First_Off = 0 then
               First_Off := K + 1;
            else
               Second_Off := K + 1;
            end if;
         end if;
      end loop;

      if Diff_Count /= 2 then
         return False;
      end if;

      declare
         AI : constant Positive := A'First + (First_Off - 1);
         AJ : constant Positive := A'First + (Second_Off - 1);
         BI : constant Positive := B'First + (First_Off - 1);
         BJ : constant Positive := B'First + (Second_Off - 1);
      begin
         return A (AI) = B (BJ) and then A (AJ) = B (BI);
      end;
   end Differs_By_Single_Swap;

   -------------------------------------------------------------------------
   -- Generate (classic recursive Heap into static store)
   -------------------------------------------------------------------------

   procedure Generate
     (N     : Positive;
      Store : out Perm_Store;
      Last  : out Natural)
   is
      Perm : Permutation (1 .. N) := [for I in 1 .. N => I];

      procedure Swap (I, J : Positive)
        with
          Global => (Proof_In => N, In_Out => Perm),
          Pre    =>
            I in 1 .. N
            and then J in 1 .. N
            and then Is_Permutation (Perm),
          Post   =>
            Is_Permutation (Perm)
            and then Perm (I) = Perm'Old (J)
            and then Perm (J) = Perm'Old (I)
            and then
              (for all K in 1 .. N =>
                 (if K /= I and then K /= J then Perm (K) = Perm'Old (K)))
      is
         Tmp : Positive;
      begin
         if I = J then
            return;
         end if;
         Tmp      := Perm (I);
         Perm (I) := Perm (J);
         Perm (J) := Tmp;
      end Swap;

      procedure Record_Current
        with
          Global => (Input => (Perm, N), In_Out => (Store, Last)),
          Pre    =>
            Last < Max_Count
            and then Is_Permutation (Perm)
            and then
              (for all R in 1 .. Last =>
                 Row_Is_Permutation (Store, R, N)),
          Post   =>
            Last = Last'Old + 1
            and then Last <= Max_Count
            and then
              (for all R in 1 .. Last =>
                 Row_Is_Permutation (Store, R, N))
      is
      begin
         Last := Last + 1;
         for C in 1 .. N loop
            pragma Loop_Invariant (Last = Last'Loop_Entry);
            pragma Loop_Invariant
              (for all K in 1 .. C - 1 => Store (Last, K) = Perm (K));
            Store (Last, C) := Perm (C);
         end loop;
         pragma Assert (for all K in 1 .. N => Store (Last, K) = Perm (K));
         pragma Assert (Row_Is_Permutation (Store, Last, N));
      end Record_Current;

      --  Case-split lemma: K! = K*(K-1)! and monotonicity on 2 .. Max_N.
      procedure Lemma_Fact_Step (K : Positive)
        with
          Ghost              => True,
          Global             => null,
          Pre                => K in 2 .. Max_N,
          Post               =>
            Factorial (K) = K * Factorial (K - 1)
            and then Factorial (K - 1) <= Factorial (K)
            and then Factorial (K - 1) >= 1
      is
      begin
         case K is
            when 2 =>
               pragma Assert (Factorial (1) = 1);
               pragma Assert (Factorial (2) = 2);
            when 3 =>
               pragma Assert (Factorial (2) = 2);
               pragma Assert (Factorial (3) = 6);
            when 4 =>
               pragma Assert (Factorial (3) = 6);
               pragma Assert (Factorial (4) = 24);
            when 5 =>
               pragma Assert (Factorial (4) = 24);
               pragma Assert (Factorial (5) = 120);
            when 6 =>
               pragma Assert (Factorial (5) = 120);
               pragma Assert (Factorial (6) = 720);
            when 7 =>
               pragma Assert (Factorial (6) = 720);
               pragma Assert (Factorial (7) = Max_Count);
            when others =>
               pragma Assert (False);
         end case;
      end Lemma_Fact_Step;

      --  Emit Factorial(K) permutations of the current length-N array by
      --  running classic Heap on the prefix 1 .. K. Advances Last by K!.
      procedure Heap_Generate (K : Natural; Count_Before : Natural)
        with
          Global             =>
            (Input => N, In_Out => (Perm, Store, Last)),
          Always_Terminates  => True,
          Subprogram_Variant => (Decreases => K),
          Pre                =>
            N in 1 .. Max_N
            and then K in 1 .. N
            and then Factorial (K) <= Max_Count
            and then Count_Before <= Max_Count - Factorial (K)
            and then Last = Count_Before
            and then Is_Permutation (Perm)
            and then
              (for all R in 1 .. Last =>
                 Row_Is_Permutation (Store, R, N)),
          Post               =>
            Last = Count_Before + Factorial (K)
            and then Is_Permutation (Perm)
            and then
              (for all R in 1 .. Last =>
                 Row_Is_Permutation (Store, R, N))
      is
      begin
         if K = 1 then
            pragma Assert (Factorial (1) = 1);
            Record_Current;
            return;
         end if;

         pragma Assert (K >= 2);
         pragma Assert (K <= Max_N);
         Lemma_Fact_Step (K);
         pragma Assert (Factorial (K) = K * Factorial (K - 1));
         pragma Assert (Factorial (K - 1) <= Factorial (K));
         pragma Assert
           (Count_Before <= Max_Count - Factorial (K));
         --  Since Fact(K-1) <= Fact(K), capacity for K implies capacity for K-1.
         pragma Assert
           (Max_Count - Factorial (K) <= Max_Count - Factorial (K - 1));
         pragma Assert
           (Count_Before <= Max_Count - Factorial (K - 1));

         Heap_Generate (K - 1, Count_Before);

         pragma Assert (Last = Count_Before + Factorial (K - 1));
         pragma Assert
           (Last <= Max_Count - (K - 1) * Factorial (K - 1));
         pragma Assert
           (Last <= Max_Count - Factorial (K - 1));

         for I in 1 .. K - 1 loop
            pragma Loop_Invariant (Is_Permutation (Perm));
            pragma Loop_Invariant
              (Last = Count_Before + I * Factorial (K - 1));
            pragma Loop_Invariant
              (Last <= Max_Count - Factorial (K - 1));
            pragma Loop_Invariant
              (Count_Before <= Max_Count - Factorial (K));
            pragma Loop_Invariant
              (for all R in 1 .. Last =>
                 Row_Is_Permutation (Store, R, N));
            pragma Loop_Invariant (K in 2 .. N);
            pragma Loop_Invariant (K <= Max_N);

            if K rem 2 = 0 then
               Swap (I, K);
            else
               Swap (1, K);
            end if;

            pragma Assert (Last <= Max_Count - Factorial (K - 1));
            Heap_Generate (K - 1, Last);
         end loop;

         pragma Assert
           (Last = Count_Before + K * Factorial (K - 1));
         Lemma_Fact_Step (K);
         pragma Assert
           (Last = Count_Before + Factorial (K));
      end Heap_Generate;

   begin
      --  Definite assignment for out Store: pad with 1s.
      Store := [others => [others => 1]];

      pragma Assert (Is_Permutation (Perm));

      Last := 0;
      pragma Assert (Factorial (N) <= Max_Count);
      Heap_Generate (N, 0);
      pragma Assert (Last = Factorial (N));
      pragma Assert (Is_Permutation (Perm));
   end Generate;

end Heaps_Algorithm;
