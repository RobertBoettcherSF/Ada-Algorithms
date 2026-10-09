pragma Ada_2022;

package body Binary_Search_Upper_Bound with SPARK_Mode => On is

   --  In a sorted array A <= B gives Input (A) <= Input (B).
   procedure Lemma_Chain (Input : Input_Array; A, B : Index)
   with
     Ghost,
     Pre  => A <= B,
     Post => Input (A) <= Input (B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Input (K) <= Input (K + 1));
         pragma Loop_Invariant (Input (A) <= Input (K + 1));
      end loop;
   end Lemma_Chain;

   --  The two neighbours of P decide every element.
   procedure Lemma_Split (Input : Input_Array; Target : Target_Value; P : Result_Index)
   with
     Ghost,
     Pre  => (P = 1 or else Input (P - 1) <= Target)
             and then (P = Length + 1 or else Input (P) > Target),
     Post => (for all I in Index =>
                (if I < P then Input (I) <= Target else Input (I) > Target))
   is
   begin
      for I in Index loop
         if I < P then
            Lemma_Chain (Input, I, P - 1);
         else
            Lemma_Chain (Input, P, I);
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I =>
              (if J < P then Input (J) <= Target else Input (J) > Target));
      end loop;
   end Lemma_Split;

   --  Largest Hi - Lo after K reads: 32 / 2 ** K, and 0 after 6.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 32, when 1 => 16, when 2 => 8, when 3 => 4,
        when 4 => 2, when 5 => 1, when 6 => 0)
   with Ghost;

   function Find (Input : Input_Array; Target : Target_Value) return Search_Result is
      Lo     : Result_Index := 1;            --  candidates are Lo .. Hi
      Hi     : Result_Index := Length + 1;
      Mid    : Index;
      Probes : Probe_Count := 0;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Lo = 1 or else Input (Lo - 1) <= Target);
         pragma Loop_Invariant (Hi = Length + 1 or else Input (Hi) > Target);
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Input (Mid) <= Target then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;
      Lemma_Split (Input, Target, Lo);
      return (Position => Lo, Probes => Probes);
   end Find;
end Binary_Search_Upper_Bound;
