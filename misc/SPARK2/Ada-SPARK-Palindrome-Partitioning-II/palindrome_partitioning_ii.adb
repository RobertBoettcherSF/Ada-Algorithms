pragma Ada_2022;

package body Palindrome_Partitioning_II with SPARK_Mode => On is
   type Grid is array (Length, Length) of Boolean;
   type Cut_Array is array (Length) of Length;

   function Increment (Value : Length) return Length is
   begin
      if Value < Length'Last then
         return Value + 1;
      else
         return Length'Last;
      end if;
   end Increment;

   function Min_Cuts (Input : Text; N : Length) return Length is
      Pal : Grid := (others => (others => False));
      Cuts : Cut_Array := (others => Length'Last);
      Candidate : Length;
   begin
      Cuts (0) := 0;
      for I in reverse 1 .. N loop
         for J in I .. N loop
            if Input (I) = Input (J) then
               if J - I <= 1 then
                  Pal (I, J) := True;
               elsif Pal (I + 1, J - 1) then
                  Pal (I, J) := True;
               end if;
            end if;
         end loop;
      end loop;
      for J in 1 .. N loop
         for I in 1 .. J loop
            if Pal (I, J) then
               Candidate := Increment (Cuts (I - 1));
               if Candidate < Cuts (J) then
                  Cuts (J) := Candidate;
               end if;
            end if;
         end loop;
      end loop;
      if Cuts (N) > 0 then
         return Cuts (N) - 1;
      else
         return 0;
      end if;
   end Min_Cuts;
end Palindrome_Partitioning_II;
