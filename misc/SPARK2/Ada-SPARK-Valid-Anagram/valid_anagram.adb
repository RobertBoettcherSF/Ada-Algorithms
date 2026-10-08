pragma Ada_2022;

package body Valid_Anagram with SPARK_Mode => On is
   function Count (Text : Text_Array; Target : Letter) return Natural is
      Total : Natural range 0 .. Length := 0;
   begin
      for I in Index loop
         if Text (I) = Target then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count;

   function Is_Anagram (Left : Text_Array; Right : Text_Array) return Boolean is
   begin
      return Count (Left, 'a') = Count (Right, 'a')
        and then Count (Left, 'b') = Count (Right, 'b')
        and then Count (Left, 'c') = Count (Right, 'c')
        and then Count (Left, 'd') = Count (Right, 'd')
        and then Count (Left, 'e') = Count (Right, 'e')
        and then Count (Left, 'f') = Count (Right, 'f');
   end Is_Anagram;
end Valid_Anagram;
