pragma Ada_2022;

package body Find_K_Closest with SPARK_Mode => On is
   function Closest_Index (Input : Input_Array; Target : Value) return Index is
      Best : Index := Index'First;
      Best_Distance : Natural := abs (Input (Index'First) - Target);
      Distance : Natural;
   begin
      for I in Index loop
         Distance := abs (Input (I) - Target);
         if Distance < Best_Distance then
            Best := I;
            Best_Distance := Distance;
         end if;
      end loop;
      return Best;
   end Closest_Index;
end Find_K_Closest;
