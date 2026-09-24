pragma Ada_2022;
package body Top_K_Frequent_Words with SPARK_Mode => On is
   type Count_Array is array (Word_Id) of Natural range 0 .. Capacity;
   function Kth_Frequency (Words : Word_Array; N : Size; K : Size) return Frequency is
      C : Count_Array := (others => 0);
      Sorted : Count_Array;
      Pos : Word_Id;
      Temp : Natural;
   begin
      for I in Size loop
         pragma Loop_Invariant (for all W in Word_Id => C (W) <= I - 1);
         exit when I > N;
         Pos := Words (I);
         C (Pos) := C (Pos) + 1;
      end loop;
      Sorted := C;
      for I in Word_Id loop
         for J in Word_Id loop
            if Sorted (J) < Sorted (I) then
               Temp := Sorted (I); Sorted (I) := Sorted (J); Sorted (J) := Temp;
            end if;
         end loop;
      end loop;
      return Sorted (K);
   end Kth_Frequency;
end Top_K_Frequent_Words;
