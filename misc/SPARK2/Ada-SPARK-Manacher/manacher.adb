pragma Ada_2022;
package body Manacher with SPARK_Mode => On is
   function Is_Palindrome
     (Text : Text_Array; First : Index; Last : Index) return Boolean is
      Left : Index := First;
      Right : Index := Last;
   begin
      while Left < Right loop
         pragma Loop_Variant (Decreases => Right - Left);
         if Text (Left) /= Text (Right) then
            return False;
         end if;
         Left := Left + 1;
         Right := Right - 1;
      end loop;
      return True;
   end Is_Palindrome;

   function Longest_Palindrome_Length (Text : Text_Array) return Length is
      Best : Length := 0;
      Current : Natural;
   begin
      for First in Index loop
         for Last in Index loop
            if Last >= First and then Is_Palindrome (Text, First, Last) then
               Current := Last - First + 1;
               if Current > Best then
                  Best := Length (Current);
               end if;
            end if;
         end loop;
      end loop;
      return Best;
   end Longest_Palindrome_Length;
end Manacher;
