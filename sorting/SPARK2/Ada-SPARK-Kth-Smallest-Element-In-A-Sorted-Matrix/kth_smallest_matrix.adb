pragma Ada_2022;

package body Kth_Smallest_Matrix with SPARK_Mode => On is

   --  Along row I of the block the entries never decrease.
   procedure Lemma_Row (S : Sorted_Square; I, J1, J2 : Dimension)
   with
     Ghost,
     Pre  => I <= S.N and then J1 <= J2 and then J2 <= S.N,
     Post => S.M (I, J1) <= S.M (I, J2)
   is
   begin
      for J in J1 .. J2 - 1 loop
         pragma Assert (Position_Of (I, J) + 1 = Position_Of (I, J + 1));
         pragma Assert (Cell (S.M, Position_Of (I, J)) <= Cell (S.M, Position_Of (I, J) + 1));
         pragma Assert (S.M (I, J) <= S.M (I, J + 1));
         pragma Loop_Invariant (S.M (I, J1) <= S.M (I, J + 1));
      end loop;
   end Lemma_Row;

   --  One step down a column of the block.
   procedure Lemma_Down (S : Sorted_Square; I, J : Dimension)
   with
     Ghost,
     Pre  => I < S.N and then J <= S.N,
     Post => S.M (I, J) <= S.M (I + 1, J)
   is
   begin
      pragma Assert (Position_Of (I, J) + Matrix_Size = Position_Of (I + 1, J));
      pragma Assert (Cell (S.M, Position_Of (I, J)) <= Cell (S.M, Position_Of (I, J) + Matrix_Size));
   end Lemma_Down;

   --  Row I rises: if the entries up to C are <= X and the rest are
   --  > X, exactly C of them are <= X.
   procedure Lemma_Row_Count (S : Sorted_Square; I : Dimension; X : Integer; C : Natural)
   with
     Ghost,
     Pre  => I <= S.N and then C <= S.N
             and then (C = 0 or else S.M (I, C) <= X)
             and then (C = S.N or else S.M (I, C + 1) > X),
     Post => Row_Count (S.M, I, X, S.N) = C
   is
   begin
      for J in 1 .. S.N loop
         if J <= C then
            Lemma_Row (S, I, J, C);
         else
            Lemma_Row (S, I, C + 1, J);
         end if;
         pragma Loop_Invariant (Row_Count (S.M, I, X, J) = (if J <= C then J else C));
      end loop;
   end Lemma_Row_Count;

   --  Every entry is <= Value'Last: the count is I * N.
   procedure Lemma_All (S : Sorted_Square; I : Natural)
   with
     Ghost,
     Pre  => I <= S.N,
     Post => Total (S.M, S.N, Value'Last, I) = I * S.N
   is
   begin
      for R in 1 .. I loop
         for J in 1 .. S.N loop
            pragma Loop_Invariant (Row_Count (S.M, R, Value'Last, J) = J);
         end loop;
         pragma Assert (R * S.N = (R - 1) * S.N + S.N);
         pragma Loop_Invariant (Total (S.M, S.N, Value'Last, R) = R * S.N);
      end loop;
   end Lemma_All;

   --  No entry is < Value'First: the count below it is 0.
   procedure Lemma_None (S : Sorted_Square; I : Natural)
   with
     Ghost,
     Pre  => I <= S.N,
     Post => Total (S.M, S.N, Value'First - 1, I) = 0
   is
   begin
      for R in 1 .. I loop
         for J in 1 .. S.N loop
            pragma Loop_Invariant (Row_Count (S.M, R, Value'First - 1, J) = 0);
         end loop;
         pragma Loop_Invariant (Total (S.M, S.N, Value'First - 1, R) = 0);
      end loop;
   end Lemma_None;

   --  Entries <= X, by a staircase walk: start at the right end of row 1
   --  and move left while the entry is > X; the next row's boundary is
   --  never further right. Cmps counts the comparisons with X.
   procedure Count_Le (S : Sorted_Square; X : Integer; Result : out Natural; Cmps : out Natural)
   with
     Post => Result = Count (S, X) and then Cmps <= 2 * S.N
   is
      C : Natural range 0 .. Matrix_Size := S.N;
   begin
      Result := 0;
      Cmps := 0;
      for I in 1 .. S.N loop
         pragma Loop_Invariant (C <= S.N);
         pragma Loop_Invariant (Result = Total (S.M, S.N, X, I - 1));
         pragma Loop_Invariant (C = S.N or else (I > 1 and then S.M (I - 1, C + 1) > X));
         pragma Loop_Invariant (Cmps <= (S.N - C) + (I - 1));
         if C < S.N then
            pragma Assert (I > 1);
            Lemma_Down (S, I - 1, C + 1);
         end if;
         loop
            pragma Loop_Invariant (C <= S.N);
            pragma Loop_Invariant (C = S.N or else S.M (I, C + 1) > X);
            pragma Loop_Invariant (Cmps <= (S.N - C) + (I - 1));
            pragma Loop_Variant (Decreases => C);
            exit when C = 0;
            Cmps := Cmps + 1;
            exit when S.M (I, C) <= X;
            C := C - 1;
         end loop;
         Lemma_Row_Count (S, I, X, C);
         Result := Result + C;
      end loop;
   end Count_Le;

   --  Largest Hi - Lo after K counts: 1000 halved K times.
   function Width (K : Natural) return Natural is
     (case K is
        when 0 => 1000, when 1 => 500, when 2 => 250, when 3 => 125,
        when 4 => 62, when 5 => 31, when 6 => 15, when 7 => 7,
        when 8 => 3, when 9 => 1, when others => 0)
   with Ghost;

   function Kth (S : Sorted_Square; K : Rank) return Kth_Result is
      Lo     : Value := Value'First;   --  Count (Lo - 1) < K
      Hi     : Value := Value'Last;    --  K <= Count (Hi)
      Mid    : Value;
      Below  : Natural;
      Cmps   : Natural;
      Tries  : Try_Count := 0;
      Probes : Natural := 0;
   begin
      Lemma_None (S, S.N);
      Lemma_All (S, S.N);
      while Lo < Hi loop
         pragma Loop_Invariant (Count (S, Lo - 1) < K and then K <= Count (S, Hi));
         pragma Loop_Invariant (Hi - Lo <= Width (Tries));
         pragma Loop_Invariant (Probes <= 2 * S.N * Tries);
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Count_Le (S, Mid, Below, Cmps);
         pragma Assert (2 * S.N * (Tries + 1) = 2 * S.N * Tries + 2 * S.N);
         Tries := Tries + 1;
         Probes := Probes + Cmps;
         if Below >= K then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;
      pragma Assert (2 * S.N * Tries <= 2 * S.N * 10);
      return (Kth => Lo, Tries => Tries, Probes => Probes);
   end Kth;
end Kth_Smallest_Matrix;
