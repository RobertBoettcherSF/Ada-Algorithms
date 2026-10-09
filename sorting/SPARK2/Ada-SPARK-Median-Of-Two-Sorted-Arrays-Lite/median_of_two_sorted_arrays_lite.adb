pragma Ada_2022;

package body Median_Of_Two_Sorted_Arrays_Lite with SPARK_Mode => On is

   procedure Lemma_Chain (A : Sorted_Array; P, Q : Index)
   with
     Ghost,
     Pre  => P <= Q,
     Post => A (P) <= A (Q)
   is
   begin
      for K in P .. Q - 1 loop
         pragma Loop_Invariant (A (P) <= A (K + 1));
      end loop;
   end Lemma_Chain;

   --  Everything after position I is >= X: at most I elements are < X.
   procedure Lemma_Lt_At_Most (A : Sorted_Array; X : Integer; I : Cut)
   with
     Ghost,
     Pre  => I = Length or else A (I + 1) >= X,
     Post => Count_Lt (A, X, Length) <= I
   is
   begin
      for K in Index loop
         if K > I then
            Lemma_Chain (A, I + 1, K);
         end if;
         pragma Loop_Invariant (Count_Lt (A, X, K) <= (if K <= I then K else I));
      end loop;
   end Lemma_Lt_At_Most;

   --  A (I) <= X: at least I elements are <= X.
   procedure Lemma_Le_At_Least (A : Sorted_Array; X : Integer; I : Cut)
   with
     Ghost,
     Pre  => I = 0 or else A (I) <= X,
     Post => Count_Le (A, X, Length) >= I
   is
   begin
      for K in Index loop
         if K <= I then
            Lemma_Chain (A, K, I);
         end if;
         pragma Loop_Invariant (Count_Le (A, X, K) >= (if K <= I then K else I));
      end loop;
   end Lemma_Le_At_Least;

   --  Largest Hi - Lo after K comparisons: 16 halved K times.
   function Width (K : Natural) return Natural is
     (case K is
        when 0 => 16, when 1 => 8, when 2 => 4, when 3 => 2, when 4 => 1,
        when others => 0)
   with Ghost;

   function Median (Left : Sorted_Array; Right : Sorted_Array) return Median_Result is
      --  Find the smallest I (elements taken from Left into the lower
      --  half; J = Length - I from Right) with I = Length or
      --  Right (J) <= Left (I + 1).
      Lo     : Cut := 0;        --  Lo = 0 or the cut Lo - 1 fails
      Hi     : Cut := Length;   --  the cut Hi holds
      Mid    : Cut;
      Probes : Probe_Count := 0;
      I, J   : Cut;
      Lower  : Value;
      Upper  : Value;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Hi = Length or else Right (Length - Hi) <= Left (Hi + 1));
         pragma Loop_Invariant (Lo = 0 or else Left (Lo) < Right (Length - Lo + 1));
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Right (Length - Mid) <= Left (Mid + 1) then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;
      I := Lo;
      J := Length - I;

      --  Lower: the larger of Left (I) and Right (J).
      if J = 0 or else (I > 0 and then Left (I) >= Right (J)) then
         if I > 0 and then J > 0 then
            Probes := Probes + 1;
         end if;
         Lower := Left (I);
         Lemma_Lt_At_Most (Left, Lower, I - 1);
         Lemma_Lt_At_Most (Right, Lower, J);
         Lemma_Le_At_Least (Left, Lower, I);
         Lemma_Le_At_Least (Right, Lower, J);
      else
         if I > 0 then
            Probes := Probes + 1;
         end if;
         Lower := Right (J);
         Lemma_Lt_At_Most (Right, Lower, J - 1);
         Lemma_Lt_At_Most (Left, Lower, I);
         Lemma_Le_At_Least (Right, Lower, J);
         Lemma_Le_At_Least (Left, Lower, I);
      end if;

      --  Upper: the smaller of Left (I + 1) and Right (J + 1).
      if J = Length or else (I < Length and then Left (I + 1) <= Right (J + 1)) then
         if I < Length and then J < Length then
            Probes := Probes + 1;
         end if;
         Upper := Left (I + 1);
         Lemma_Lt_At_Most (Left, Upper, I);
         Lemma_Lt_At_Most (Right, Upper, J);
         Lemma_Le_At_Least (Left, Upper, I + 1);
         Lemma_Le_At_Least (Right, Upper, J);
      else
         if I < Length then
            Probes := Probes + 1;
         end if;
         Upper := Right (J + 1);
         Lemma_Lt_At_Most (Right, Upper, J);
         Lemma_Lt_At_Most (Left, Upper, I);
         Lemma_Le_At_Least (Right, Upper, J + 1);
         Lemma_Le_At_Least (Left, Upper, I);
      end if;
      return (Lower => Lower, Upper => Upper, Median => (Lower + Upper) / 2, Probes => Probes);
   end Median;
end Median_Of_Two_Sorted_Arrays_Lite;
