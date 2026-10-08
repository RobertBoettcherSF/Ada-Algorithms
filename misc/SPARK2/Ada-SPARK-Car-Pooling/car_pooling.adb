pragma Ada_2022;
package body Car_Pooling with SPARK_Mode => On is
   function Feasible (T : Trips; Limit : Capacity) return Boolean is
      On_Board : Capacity;
   begin
      for Stop in Index loop
         --  people of every trip with Pickup <= Stop < Dropoff (they leave before new people board)
         On_Board := 0;
         for I in Index loop
            pragma Loop_Invariant (On_Board <= Passengers'Last * (I - Index'First));
            if T (I).Pickup <= Stop and then Stop < T (I).Dropoff then
               On_Board := On_Board + T (I).People;
            end if;
         end loop;
         if On_Board > Limit then
            return False;
         end if;
      end loop;
      return True;
   end Feasible;
end Car_Pooling;
