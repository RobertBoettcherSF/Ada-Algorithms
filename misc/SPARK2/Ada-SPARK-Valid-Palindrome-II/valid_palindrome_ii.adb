pragma Ada_2022;
package body Valid_Palindrome_II with SPARK_Mode => On is
   function Is_Palindrome (Input : Text; Skip : Index) return Boolean is
      Left : Index := Index'First;
      Right : Index := Index'Last;
   begin
      while Left < Right loop
         pragma Loop_Invariant (Left <= Right);
         pragma Loop_Variant (Decreases => Right - Left);
         if Left = Skip then
            Left := Left + 1;
         elsif Right = Skip then
            Right := Right - 1;
         elsif Input (Left) /= Input (Right) then
            return False;
         else
            Left := Left + 1;
            Right := Right - 1;
         end if;
      end loop;
      return True;
   end Is_Palindrome;
   function Is_Valid (Input : Text) return Boolean is
      Left : Index := Index'First;
      Right : Index := Index'Last;
   begin
      while Left < Right loop
         pragma Loop_Invariant (Left <= Right);
         pragma Loop_Variant (Decreases => Right - Left);
         if Input (Left) /= Input (Right) then
            return Is_Palindrome (Input, Left) or else Is_Palindrome (Input, Right);
         end if;
         Left := Left + 1;
         Right := Right - 1;
      end loop;
      return True;
   end Is_Valid;
end Valid_Palindrome_II;
