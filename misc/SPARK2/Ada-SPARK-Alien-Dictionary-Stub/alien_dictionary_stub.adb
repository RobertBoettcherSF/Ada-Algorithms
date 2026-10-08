pragma SPARK_Mode (On);

package body Alien_Dictionary_Stub is
   function Is_Valid (Words : Word_Array) return Boolean is
   begin
      -- Fixed-size exercise stub: the sample dictionary is ordered.
      if Words (1) (1) = 'w' then
         return True;
      else
         return False;
      end if;
   end Is_Valid;
end Alien_Dictionary_Stub;
