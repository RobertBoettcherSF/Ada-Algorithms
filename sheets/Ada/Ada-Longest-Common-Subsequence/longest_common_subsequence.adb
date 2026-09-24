--  Longest_Common_Subsequence body — classic DP + backtrack reconstruction.

pragma Ada_2022;

package body Longest_Common_Subsequence is

   subtype Index is Natural range 0 .. Max_Length;
   type DP_Table is array (Index, Index) of Natural;
   type DP_Row is array (Index) of Natural;

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

   function Nat_Max (X, Y : Natural) return Natural is
     (if X >= Y then X else Y);

   --  Fill the classic LCS length table L(0..M, 0..N).
   procedure Fill_DP (A, B : String; L : out DP_Table) is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
   begin
      L := [others => [others => 0]];

      for I in 1 .. M loop
         for J in 1 .. N loop
            if At_A (A, I) = At_B (B, J) then
               L (I, J) := L (I - 1, J - 1) + 1;
            else
               L (I, J) := Nat_Max (L (I - 1, J), L (I, J - 1));
            end if;
         end loop;
      end loop;
   end Fill_DP;

   function Length (A, B : String) return Natural is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
      L : DP_Table;
   begin
      Check_Bounds (A, B);

      if M = 0 or else N = 0 then
         return 0;
      end if;

      Fill_DP (A, B, L);
      return L (M, N);
   end Length;

   function Find (A, B : String) return String is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
      L : DP_Table;
   begin
      Check_Bounds (A, B);

      if M = 0 or else N = 0 then
         return "";
      end if;

      Fill_DP (A, B, L);

      declare
         Len    : constant Natural := L (M, N);
         Result : String (1 .. Len);
         Pos    : Natural := Len;
         I      : Natural := M;
         J      : Natural := N;
      begin
         if Len = 0 then
            return "";
         end if;

         --  Iterative Wikipedia-style backtrack.
         --  Tie-break: move left only when L(I, J-1) > L(I-1, J);
         --  otherwise move up (prefer discarding from A).
         while I > 0 and then J > 0 loop
            if At_A (A, I) = At_B (B, J) then
               Result (Pos) := At_A (A, I);
               Pos := Pos - 1;
               I   := I - 1;
               J   := J - 1;
            elsif L (I, J - 1) > L (I - 1, J) then
               J := J - 1;
            else
               I := I - 1;
            end if;
         end loop;

         return Result;
      end;
   end Find;

   function Length_Space_Optimized (A, B : String) return Natural is
   begin
      Check_Bounds (A, B);

      --  Put the shorter string on the inner axis so the rolling row is
      --  as short as possible.
      if A'Length <= B'Length then
         declare
            M    : constant Natural := A'Length;
            N    : constant Natural := B'Length;
            Prev : DP_Row := [others => 0];
            Curr : DP_Row := [others => 0];
         begin
            if M = 0 or else N = 0 then
               return 0;
            end if;

            for I in 1 .. M loop
               Curr := [others => 0];
               for J in 1 .. N loop
                  if At_A (A, I) = At_B (B, J) then
                     Curr (J) := Prev (J - 1) + 1;
                  else
                     Curr (J) := Nat_Max (Prev (J), Curr (J - 1));
                  end if;
               end loop;
               Prev := Curr;
            end loop;

            return Prev (N);
         end;
      else
         --  Swap roles: iterate over B as outer, A as inner.
         declare
            M    : constant Natural := B'Length;
            N    : constant Natural := A'Length;
            Prev : DP_Row := [others => 0];
            Curr : DP_Row := [others => 0];
         begin
            if M = 0 or else N = 0 then
               return 0;
            end if;

            for I in 1 .. M loop
               Curr := [others => 0];
               for J in 1 .. N loop
                  if At_B (B, I) = At_A (A, J) then
                     Curr (J) := Prev (J - 1) + 1;
                  else
                     Curr (J) := Nat_Max (Prev (J), Curr (J - 1));
                  end if;
               end loop;
               Prev := Curr;
            end loop;

            return Prev (N);
         end;
      end if;
   end Length_Space_Optimized;

end Longest_Common_Subsequence;
