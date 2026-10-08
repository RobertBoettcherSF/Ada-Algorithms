pragma Ada_2022;
package body Trigram_Search
  with SPARK_Mode => On
is
   function Contains (Text : Char_Array; A, B, C : Character) return Boolean is
   begin
      if Text'Length < 3 then return False; end if;
      for I in 1 .. Text'Length - 2 loop
         if Text (I) = A and then Text (I + 1) = B
           and then Text (I + 2) = C
         then
            return True;
         end if;
      end loop;
      return False;
   end Contains;
end Trigram_Search;
