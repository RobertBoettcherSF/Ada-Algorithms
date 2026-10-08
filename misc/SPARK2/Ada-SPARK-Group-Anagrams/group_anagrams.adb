pragma Ada_2022;

package body Group_Anagrams with SPARK_Mode => On is
   function Same_Anagram (Left, Right : Word) return Boolean is
      Left_Count, Right_Count : Natural range 0 .. Word_Length;
   begin
      for I in Position loop
         Left_Count := 0;
         Right_Count := 0;
         for J in Position loop
            if Left (J) = Left (I) then
               Left_Count := Left_Count + 1;
            end if;
            if Right (J) = Left (I) then
               Right_Count := Right_Count + 1;
            end if;
         end loop;
         if Left_Count /= Right_Count then
            return False;
         end if;
      end loop;
      return True;
   end Same_Anagram;

   function Group (Input : Word_Set) return Labels is
      Result : Labels := (others => 1);
   begin
      if not Same_Anagram (Input (1), Input (2)) then
         Result (2) := 2;
      end if;
      if Same_Anagram (Input (1), Input (3)) then
         Result (3) := 1;
      elsif Same_Anagram (Input (2), Input (3)) then
         Result (3) := Result (2);
      else
         Result (3) := 3;
      end if;
      return Result;
   end Group;
end Group_Anagrams;
