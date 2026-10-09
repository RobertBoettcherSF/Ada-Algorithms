pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with LCS;
procedure Tests is

   --  First-relative test helpers: copy S to storage starting at O, or to
   --  storage ending at Positive'Last.
   function At_Origin (S : LCS.Char_Array; O : Positive) return LCS.Char_Array is
      R : LCS.Char_Array (O .. O + (S'Length - 1));
   begin
      for K in 0 .. S'Length - 1 loop
         R (O + K) := S (S'First + K);
      end loop;
      return R;
   end At_Origin;
   function At_Top (S : LCS.Char_Array) return LCS.Char_Array is
     (At_Origin (S, Positive'Last - (S'Length - 1)));
   A : constant LCS.Char_Array := ('A', 'G', 'G', 'T', 'A', 'B');
   B : constant LCS.Char_Array := ('G', 'X', 'T', 'X', 'A', 'Y', 'B');
begin
   Assert (LCS.Length (A, B) = 4);
   Assert (LCS.Length (A, A) = A'Length);
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   Assert (LCS.Length (At_Origin (A, 7), At_Origin (B, 20)) = 4);
   Assert (LCS.Length (At_Top (A), B) = 4);
   Assert (LCS.Length (A, At_Top (B)) = 4);
   Assert (LCS.Length (At_Origin (A, 3), At_Origin (A, 3)) = A'Length);
   Put_Line ("PASS LCS.Length");
   Put_Line ("All LCS SPARK topic tests passed.");
end Tests;
