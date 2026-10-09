pragma Ada_2022;

package body Find_Peak_Element with SPARK_Mode => On is

   --  Largest Hi - Lo after K comparisons: 31 / 2 ** K, and 0 after 5.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 31, when 1 => 15, when 2 => 7, when 3 => 3,
        when 4 => 1, when 5 => 0)
   with Ghost;

   function Find_Peak (Input : Input_Array) return Search_Result is
      Lo     : Index := Index'First;   --  a peak lies in Lo .. Hi
      Hi     : Index := Index'Last;
      Mid    : Index;
      Probes : Probe_Count := 0;
   begin
      while Lo < Hi loop
         --  The array rises into Lo and falls out of Hi (or they are ends).
         pragma Loop_Invariant (Lo = 1 or else Input (Lo - 1) < Input (Lo));
         pragma Loop_Invariant (Hi = Length or else Input (Hi) > Input (Hi + 1));
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
      return (Position => Lo, Probes => Probes);
   end Find_Peak;
end Find_Peak_Element;
