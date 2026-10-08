pragma SPARK_Mode (On);

package body Range_Module_Stub is
   function Covers
     (Ranges : Interval_Array; Length : Range_Count;
      Query_First : Coordinate; Query_Last : Coordinate) return Boolean is
   begin
      for I in Ranges'Range loop
         pragma Loop_Invariant (I >= Ranges'First);
         if I <= Length
           and then Ranges (I).First <= Query_First
           and then Ranges (I).Last >= Query_Last
         then
            return True;
         end if;
      end loop;
      return False;
   end Covers;
end Range_Module_Stub;
