pragma Ada_2022;

package body Split_Array_Largest_Sum with SPARK_Mode => On is

   --  S2 is ahead of S1: fewer parts, or as many and a lighter last part.
   function Ahead (S2, S1 : Progress) return Boolean is
     (S2.Parts < S1.Parts or else (S2.Parts = S1.Parts and then S2.Load <= S1.Load))
   with Ghost;

   --  One element: with the larger limit the scan stays ahead.
   procedure Lemma_Step (S1, S2 : Progress; X : Element; L1, L2 : Limit)
   with
     Ghost,
     Pre  => L1 <= L2 and then Ahead (S2, S1)
             and then S1.Parts <= Length and then S1.Load + X <= Sum'Last
             and then S2.Parts <= Length and then S2.Load + X <= Sum'Last,
     Post => Ahead (Step (S2, X, L2), Step (S1, X, L1))
   is
   begin
      if S2.Parts < S1.Parts then
         pragma Assert (Step (S2, X, L2).Parts <= S2.Parts + 1);
         pragma Assert (Step (S1, X, L1).Parts >= S1.Parts);
      elsif S1.Load + X > L1 then
         pragma Assert (Step (S1, X, L1) = (Parts => S1.Parts + 1, Load => X));
      else
         pragma Assert (S2.Load + X <= L2);
      end if;
   end Lemma_Step;

   --  A larger limit never needs more parts.
   procedure Lemma_Monotone (Input : Input_Array; L1, L2 : Limit)
   with
     Ghost,
     Pre  => L1 <= L2,
     Post => Greedy_Parts (Input, L2) <= Greedy_Parts (Input, L1)
   is
      P1, P2 : Progress := (Parts => 1, Load => 0);
   begin
      for K in Index loop
         pragma Assert (P1 = Scan (Input, L1, K - 1));
         pragma Assert (P2 = Scan (Input, L2, K - 1));
         Lemma_Step (P1, P2, Input (K), L1, L2);
         P1 := Step (P1, Input (K), L1);
         P2 := Step (P2, Input (K), L2);
         pragma Loop_Invariant (P1 = Scan (Input, L1, K));
         pragma Loop_Invariant (P2 = Scan (Input, L2, K));
         pragma Loop_Invariant (Ahead (P2, P1));
      end loop;
   end Lemma_Monotone;

   --  With the whole sum as the limit nothing is ever cut.
   procedure Lemma_Whole (Input : Input_Array)
   with
     Ghost,
     Post => Greedy_Parts (Input, Total (Input)) = 1
   is
   begin
      for K in Index loop
         pragma Assert (Prefix_Sum (Input, K) <= Prefix_Sum (Input, Length));
         pragma Loop_Invariant
           (for all J in K .. Length => Prefix_Sum (Input, K) <= Prefix_Sum (Input, J));
         pragma Loop_Invariant (Scan (Input, Total (Input), K) = (Parts => 1, Load => Prefix_Sum (Input, K)));
      end loop;
   end Lemma_Whole;

   --  Largest Hi - Lo after K limits tried: 799 halved K times.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 799, when 1 => 399, when 2 => 199, when 3 => 99,
        when 4 => 49, when 5 => 24, when 6 => 12, when 7 => 6,
        when 8 => 3, when 9 => 1, when 10 => 0)
   with Ghost;

   function Largest_Sum
     (Input : Input_Array; Parts : Part_Count) return Sum_Result is
      Lo     : Limit := Max_Element (Input);   --  the answer is in Lo .. Hi
      Hi     : Limit := Total (Input);
      Mid    : Limit;
      Probes : Probe_Count := 0;
   begin
      Lemma_Whole (Input);
      while Lo < Hi loop
         pragma Loop_Invariant (Lo in Max_Element (Input) .. Hi and Hi <= Total (Input));
         pragma Loop_Invariant (Greedy_Parts (Input, Hi) <= Parts);
         pragma Loop_Invariant (Lo = Max_Element (Input) or else Greedy_Parts (Input, Lo - 1) > Parts);
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Greedy_Parts (Input, Mid) <= Parts then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;
      for L in Max_Element (Input) .. Lo - 1 loop
         Lemma_Monotone (Input, L, Lo - 1);
         pragma Loop_Invariant
           (for all T in Max_Element (Input) .. L => Greedy_Parts (Input, T) > Parts);
      end loop;
      return (Largest => Lo, Probes => Probes);
   end Largest_Sum;
end Split_Array_Largest_Sum;
