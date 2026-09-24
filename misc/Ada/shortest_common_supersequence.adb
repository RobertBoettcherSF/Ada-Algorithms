-- shortest_common_supersequence.adb

package body Shortest_Common_Supersequence is

   -----------------------------------------------------------------------------
   -- SCS_Length
   -- Uses Dynamic Programming to find the length of the SCS.
   -- DP(i, j) stores the length of SCS for X(1..i) and Y(1..j)
   -----------------------------------------------------------------------------
   function SCS_Length (X, Y : String) return Natural is
      subtype X_Range is Natural range 0 .. X'Length;
      subtype Y_Range is Natural range 0 .. Y'Length;
      
      -- Initialize DP table with zeros
      DP : array (X_Range, Y_Range) of Natural := (others => (others => 0));
   begin
      for I in 0 .. X'Length loop
         for J in 0 .. Y'Length loop
            if I = 0 then
               -- If first string is empty, SCS length is length of second string
               DP (I, J) := J;
            elsif J = 0 then
               -- If second string is empty, SCS length is length of first string
               DP (I, J) := I;
            elsif X (X'First + I - 1) = Y (Y'First + J - 1) then
               -- If characters match, add 1 to the diagonal DP value
               DP (I, J) := 1 + DP (I - 1, J - 1);
            else
               -- If characters differ, take 1 + minimum of left or top DP cell
               DP (I, J) := 1 + Natural'Min (DP (I - 1, J), DP (I, J - 1));
            end if;
         end loop;
      end loop;
      
      return DP (X'Length, Y'Length);
   end SCS_Length;

   -----------------------------------------------------------------------------
   -- SCS_String
   -- Builds the DP table exactly like SCS_Length, then backtracks to build
   -- the actual supersequence string.
   -----------------------------------------------------------------------------
   function SCS_String (X, Y : String) return String is
      subtype X_Range is Natural range 0 .. X'Length;
      subtype Y_Range is Natural range 0 .. Y'Length;
      
      DP : array (X_Range, Y_Range) of Natural := (others => (others => 0));
   begin
      -- 1. Build the DP table
      for I in 0 .. X'Length loop
         for J in 0 .. Y'Length loop
            if I = 0 then
               DP (I, J) := J;
            elsif J = 0 then
               DP (I, J) := I;
            elsif X (X'First + I - 1) = Y (Y'First + J - 1) then
               DP (I, J) := 1 + DP (I - 1, J - 1);
            else
               DP (I, J) := 1 + Natural'Min (DP (I - 1, J), DP (I, J - 1));
            end if;
         end loop;
      end loop;

      -- 2. Backtrack to construct string
      declare
         I          : Natural := X'Length;
         J          : Natural := Y'Length;
         Result_Len : constant Natural := DP (I, J);
         Res        : String (1 .. Result_Len);
         Pos        : Natural := Result_Len;
      begin
         while I > 0 and J > 0 loop
            if X (X'First + I - 1) = Y (Y'First + J - 1) then
               Res (Pos) := X (X'First + I - 1);
               I := I - 1;
               J := J - 1;
            elsif DP (I - 1, J) < DP (I, J - 1) then
               Res (Pos) := X (X'First + I - 1);
               I := I - 1;
            else
               Res (Pos) := Y (Y'First + J - 1);
               J := J - 1;
            end if;
            Pos := Pos - 1;
         end loop;
         
         -- Append remaining characters of X (if any)
         while I > 0 loop
            Res (Pos) := X (X'First + I - 1);
            I := I - 1;
            Pos := Pos - 1;
         end loop;
         
         -- Append remaining characters of Y (if any)
         while J > 0 loop
            Res (Pos) := Y (Y'First + J - 1);
            J := J - 1;
            Pos := Pos - 1;
         end loop;
         
         return Res;
      end;
   end SCS_String;

   -----------------------------------------------------------------------------
   -- SCS_Multiple
   -- Iterative approximation for an NP-hard problem. Merges strings one by one.
   -----------------------------------------------------------------------------
   function SCS_Multiple (Strings : Unbounded_String_Array) return String is
      Res : Unbounded_String;
   begin
      -- Edge Case: Empty Input Array
      if Strings'Length = 0 then
         raise Empty_Array_Error with "Cannot compute SCS for an empty array of sequences.";
      end if;
      
      Res := Strings (Strings'First);
      
      for I in Strings'First + 1 .. Strings'Last loop
         Res := To_Unbounded_String (SCS_String (To_String (Res), To_String (Strings (I))));
      end loop;
      
      return To_String (Res);
   end SCS_Multiple;

end Shortest_Common_Supersequence;
