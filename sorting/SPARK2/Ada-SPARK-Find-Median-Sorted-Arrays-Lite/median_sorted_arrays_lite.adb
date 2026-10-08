pragma Ada_2022;
package body Median_Sorted_Arrays_Lite with SPARK_Mode => On is
   type Combined is array (Positive range 1 .. 2 * Capacity) of Value;
   function Median (A : Values; NA : Length; B : Values; NB : Length) return Integer is
      C : Combined := (others => 0);
      Total : constant Natural := NA + NB;
      Mid : Positive;
      Temp : Value;
   begin
      for I in Index loop
         if I <= NA then C (I) := A (I); end if;
         if I <= NB then C (NA + I) := B (I); end if;
      end loop;
      for I in Positive range 1 .. 2 * Capacity loop
         exit when I >= Total;
         for J in Positive range I + 1 .. 2 * Capacity loop
            exit when J > Total;
            if C (J) < C (I) then Temp := C (I); C (I) := C (J); C (J) := Temp; end if;
         end loop;
      end loop;
      Mid := Positive ((Total + 1) / 2);
      if Total mod 2 = 1 then return C (Mid); end if;
      return (Integer (C (Mid)) + Integer (C (Mid + 1))) / 2;
   end Median;
end Median_Sorted_Arrays_Lite;
