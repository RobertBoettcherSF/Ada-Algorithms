--  Longest_Common_Substring body — DP table for contiguous LCSS.

pragma Ada_2022;

package body Longest_Common_Substring is

   subtype Index is Natural range 0 .. Max_Length;
   type DP_Table is array (Index, Index) of Natural;

   procedure Check_Bounds (A, B : String) is
   begin
      if A'Length > Max_Length or else B'Length > Max_Length then
         raise Invalid_Argument;
      end if;
   end Check_Bounds;

   --  Character of A / B at 1-based logical position I / J.
   function At_A (A : String; I : Positive) return Character is
     (A (A'First + (I - 1)));

   function At_B (B : String; J : Positive) return Character is
     (B (B'First + (J - 1)));

   --  Shared DP scan: fill L, track Max_Len and the ending 1-based index
   --  End_I in A of the chosen longest match (tie-break: first strict
   --  improvement in row-major order ⇒ smallest End_I, then smallest End_J).
   procedure Run_DP
     (A, B     : String;
      Max_Len  : out Natural;
      End_I    : out Natural)
   is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
      L : DP_Table := [others => [others => 0]];
   begin
      Max_Len := 0;
      End_I   := 0;

      if M = 0 or else N = 0 then
         return;
      end if;

      for I in 1 .. M loop
         for J in 1 .. N loop
            if At_A (A, I) = At_B (B, J) then
               if I = 1 or else J = 1 then
                  L (I, J) := 1;
               else
                  L (I, J) := L (I - 1, J - 1) + 1;
               end if;

               if L (I, J) > Max_Len then
                  Max_Len := L (I, J);
                  End_I   := I;
               end if;
            else
               L (I, J) := 0;
            end if;
         end loop;
      end loop;
   end Run_DP;

   function Length (A, B : String) return Natural is
      Max_Len : Natural;
      End_I   : Natural;
   begin
      Check_Bounds (A, B);
      Run_DP (A, B, Max_Len, End_I);
      return Max_Len;
   end Length;

   function Find (A, B : String) return String is
      Max_Len : Natural;
      End_I   : Natural;
   begin
      Check_Bounds (A, B);
      Run_DP (A, B, Max_Len, End_I);

      if Max_Len = 0 then
         return "";
      end if;

      declare
         Start : constant Positive := A'First + (End_I - Max_Len);
         Stop  : constant Positive := A'First + (End_I - 1);
      begin
         return A (Start .. Stop);
      end;
   end Find;

   --  True iff Needle occurs as a contiguous substring of Haystack.
   function Occurs_In (Needle, Haystack : String) return Boolean is
   begin
      if Needle'Length = 0 then
         return True;
      end if;
      if Needle'Length > Haystack'Length then
         return False;
      end if;

      declare
         Last_Start : constant Natural :=
           Haystack'Length - Needle'Length;
      begin
         for Offset in 0 .. Last_Start loop
            declare
               Match : Boolean := True;
            begin
               for K in 0 .. Needle'Length - 1 loop
                  if Haystack (Haystack'First + Offset + K)
                    /= Needle (Needle'First + K)
                  then
                     Match := False;
                     exit;
                  end if;
               end loop;
               if Match then
                  return True;
               end if;
            end;
         end loop;
      end;
      return False;
   end Occurs_In;

   function Brute_Force_Length (A, B : String) return Natural is
   begin
      Check_Bounds (A, B);

      if A'Length = 0 or else B'Length = 0 then
         return 0;
      end if;

      --  Prefer scanning the shorter string's substrings.
      if A'Length <= B'Length then
         for Len in reverse 1 .. A'Length loop
            for Offset in 0 .. A'Length - Len loop
               declare
                  Sub : constant String :=
                    A (A'First + Offset .. A'First + Offset + Len - 1);
               begin
                  if Occurs_In (Sub, B) then
                     return Len;
                  end if;
               end;
            end loop;
         end loop;
      else
         for Len in reverse 1 .. B'Length loop
            for Offset in 0 .. B'Length - Len loop
               declare
                  Sub : constant String :=
                    B (B'First + Offset .. B'First + Offset + Len - 1);
               begin
                  if Occurs_In (Sub, A) then
                     return Len;
                  end if;
               end;
            end loop;
         end loop;
      end if;

      return 0;
   end Brute_Force_Length;

end Longest_Common_Substring;
