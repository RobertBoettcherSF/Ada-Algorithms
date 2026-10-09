pragma Ada_2022;

package body Search_Insert_Position with SPARK_Mode => On is

   --  In a sorted array A <= B gives Data (A) <= Data (B).
   procedure Lemma_Chain (Data : Sorted_Array; A, B : Index)
   with
     Ghost,
     Pre  => A <= B,
     Post => Data (A) <= Data (B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Data (K) <= Data (K + 1));
         pragma Loop_Invariant (Data (A) <= Data (K + 1));
      end loop;
   end Lemma_Chain;

   --  The two neighbours of P decide every element.
   procedure Lemma_Split (Data : Sorted_Array; Target : Value; P : Insertion_Index)
   with
     Ghost,
     Pre  => (P = 1 or else Data (P - 1) < Target)
             and then (P = Length + 1 or else Data (P) >= Target),
     Post => (for all I in Index =>
                (if I < P then Data (I) < Target else Data (I) >= Target))
   is
   begin
      for I in Index loop
         if I < P then
            Lemma_Chain (Data, I, P - 1);
         else
            Lemma_Chain (Data, P, I);
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I =>
              (if J < P then Data (J) < Target else Data (J) >= Target));
      end loop;
   end Lemma_Split;

   --  Largest Hi - Lo after K reads: 32 / 2 ** K, and 0 after 6.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 32, when 1 => 16, when 2 => 8, when 3 => 4,
        when 4 => 2, when 5 => 1, when 6 => 0)
   with Ghost;

   function Position (Data : Sorted_Array; Target : Value) return Search_Result is
      Lo     : Insertion_Index := 1;            --  candidates are Lo .. Hi
      Hi     : Insertion_Index := Length + 1;
      Mid    : Index;
      Probes : Probe_Count := 0;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Lo = 1 or else Data (Lo - 1) < Target);
         pragma Loop_Invariant (Hi = Length + 1 or else Data (Hi) >= Target);
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Data (Mid) < Target then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;
      Lemma_Split (Data, Target, Lo);
      return (Position => Lo, Probes => Probes);
   end Position;
end Search_Insert_Position;
