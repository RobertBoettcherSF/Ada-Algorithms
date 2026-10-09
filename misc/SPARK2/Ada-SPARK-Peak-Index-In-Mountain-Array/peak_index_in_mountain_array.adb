pragma Ada_2022;

package body Peak_Index_In_Mountain_Array with SPARK_Mode => On is

   --  Rising into P means rising all the way from the start.
   procedure Lemma_Rise (Input : Mountain_Array; P : Peak_Range)
   with
     Ghost,
     Pre  => Input (P - 1) < Input (P),
     Post => (for all J in 1 .. P - 1 => Input (J) < Input (J + 1))
   is
   begin
      for K in reverse 1 .. P - 2 loop
         pragma Assert (Input (K + 1) < Input (K + 2));
         pragma Assert (not (Input (K) > Input (K + 1) and Input (K + 1) < Input (K + 2)));
         pragma Assert (Input (K) /= Input (K + 1));
         pragma Loop_Invariant (for all J in K .. P - 1 => Input (J) < Input (J + 1));
      end loop;
   end Lemma_Rise;

   --  Falling after P means falling all the way to the end.
   procedure Lemma_Fall (Input : Mountain_Array; P : Peak_Range)
   with
     Ghost,
     Pre  => Input (P) > Input (P + 1),
     Post => (for all J in P .. Length - 1 => Input (J) > Input (J + 1))
   is
   begin
      for K in P + 1 .. Length - 1 loop
         pragma Assert (Input (K - 1) > Input (K));
         pragma Assert (not (Input (K - 1) > Input (K) and Input (K) < Input (K + 1)));
         pragma Assert (Input (K) /= Input (K + 1));
         pragma Loop_Invariant (for all J in P .. K => Input (J) > Input (J + 1));
      end loop;
   end Lemma_Fall;

   --  Largest Hi - Lo after K comparisons: 31 / 2 ** K, and 0 after 5.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 31, when 1 => 15, when 2 => 7, when 3 => 3,
        when 4 => 1, when 5 => 0)
   with Ghost;

   function Peak_Index (Input : Mountain_Array) return Search_Result is
      Lo     : Peak_Range := Peak_Range'First;   --  candidates are Lo .. Hi
      Hi     : Peak_Range := Peak_Range'Last;
      Mid    : Peak_Range;
      Probes : Probe_Count := 0;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Input (Lo - 1) < Input (Lo));
         pragma Loop_Invariant (Input (Hi) > Input (Hi + 1));
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Input (Mid) < Input (Mid + 1) then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;
      Lemma_Rise (Input, Lo);
      Lemma_Fall (Input, Lo);
      return (Position => Lo, Probes => Probes);
   end Peak_Index;
end Peak_Index_In_Mountain_Array;
