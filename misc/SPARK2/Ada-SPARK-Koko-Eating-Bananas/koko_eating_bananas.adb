pragma Ada_2022;

package body Koko_Eating_Bananas with SPARK_Mode => On is

   --  A faster speed never takes more hours for one pile.
   procedure Lemma_Pile (Pile : Pile_Size; S1, S2 : Speed)
   with
     Ghost,
     Pre  => S1 <= S2,
     Post => Pile_Hours (Pile, S2) <= Pile_Hours (Pile, S1)
   is
      Q1 : constant Natural := (Pile + S1 - 1) / S1;
      R1 : constant Natural := (Pile + S1 - 1) mod S1;
      Q2 : constant Natural := (Pile + S2 - 1) / S2;
      R2 : constant Natural := (Pile + S2 - 1) mod S2;
   begin
      pragma Assert (Pile + S1 - 1 = Q1 * S1 + R1 and R1 < S1);
      pragma Assert (Q1 * S1 >= Pile);            --  Q1 is the ceiling
      pragma Assert (Q1 * S2 >= Q1 * S1);
      pragma Assert (Pile + S2 - 1 = Q2 * S2 + R2);
      pragma Assert (Q2 * S2 <= Pile + S2 - 1);
      pragma Assert (Q2 * S2 < (Q1 + 1) * S2);
      pragma Assert (Q2 <= Q1);
   end Lemma_Pile;

   --  A faster speed never takes more hours in total.
   procedure Lemma_Monotone (Piles : Pile_Array; S1, S2 : Speed)
   with
     Ghost,
     Pre  => S1 <= S2,
     Post => Hours_Needed (Piles, S2) <= Hours_Needed (Piles, S1)
   is
   begin
      for K in Index loop
         Lemma_Pile (Piles (K), S1, S2);
         pragma Loop_Invariant
           (Partial_Hours (Piles, S2, K) <= Partial_Hours (Piles, S1, K));
      end loop;
   end Lemma_Monotone;

   --  At speed 100 every pile takes one hour.
   procedure Lemma_Fastest (Piles : Pile_Array)
   with
     Ghost,
     Post => Hours_Needed (Piles, Speed'Last) = Length
   is
   begin
      for K in Index loop
         pragma Assert (Pile_Hours (Piles (K), Speed'Last) = 1);
         pragma Loop_Invariant (Partial_Hours (Piles, Speed'Last, K) = K);
      end loop;
   end Lemma_Fastest;

   --  Largest Hi - Lo after K speeds tried: 99 halved K times.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 99, when 1 => 49, when 2 => 24, when 3 => 12,
        when 4 => 6, when 5 => 3, when 6 => 1, when 7 => 0)
   with Ghost;

   function Minimum_Speed
     (Piles : Pile_Array; Hours : Hour_Count) return Speed_Result is
      Lo     : Speed := Speed'First;   --  the answer is in Lo .. Hi
      Hi     : Speed := Speed'Last;
      Mid    : Speed;
      Probes : Probe_Count := 0;
   begin
      Lemma_Fastest (Piles);
      while Lo < Hi loop
         pragma Loop_Invariant (Hours_Needed (Piles, Hi) <= Hours);
         pragma Loop_Invariant (Lo = 1 or else Hours_Needed (Piles, Lo - 1) > Hours);
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Hours_Needed (Piles, Mid) <= Hours then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;
      for S in 1 .. Lo - 1 loop
         Lemma_Monotone (Piles, S, Lo - 1);
         pragma Loop_Invariant (for all T in 1 .. S => Hours_Needed (Piles, T) > Hours);
      end loop;
      return (Minimum => Lo, Probes => Probes);
   end Minimum_Speed;
end Koko_Eating_Bananas;
