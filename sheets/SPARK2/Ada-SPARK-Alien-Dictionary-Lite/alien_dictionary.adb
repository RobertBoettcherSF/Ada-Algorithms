pragma SPARK_Mode (On);

package body Alien_Dictionary with SPARK_Mode => On is
   function Is_Ordered
     (First, Second : Word; First_Length, Second_Length : Length;
      Order : Alphabet_Order) return Boolean is
      Limit : Length := First_Length;
   begin
      if Second_Length < Limit then
         Limit := Second_Length;
      end if;
      for I in 1 .. Limit loop
         if First (I) < Second (I) then
            return True;
         elsif First (I) > Second (I) then
            return False;
         elsif Order (First (I)) < Order (Second (I)) then
            return True;
         elsif Order (First (I)) > Order (Second (I)) then
            return False;
         end if;
      end loop;
      return First_Length <= Second_Length;
   end Is_Ordered;
end Alien_Dictionary;
