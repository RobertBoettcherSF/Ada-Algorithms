pragma Ada_2022;

package body Longest_Common_Prefix with SPARK_Mode => On is
   function Prefix_Length (Input : Text_Set) return Index is
   begin
      for I in Text_Index loop
         if Input (1) (I) /= Input (2) (I)
           or else Input (1) (I) /= Input (3) (I)
         then
            return I - 1;
         end if;
      end loop;
      return Length;
   end Prefix_Length;
end Longest_Common_Prefix;
