--  Knuth_Morris_Pratt body — LPS (π) preprocess + linear search.
--  Text cursor i only moves forward; pattern cursor j falls back via LPS.

pragma Ada_2022;

package body Knuth_Morris_Pratt is

   procedure Check_Bounds (Pattern, Text : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
      if Text'Length > Max_Text_Length then
         raise Invalid_Argument with "text too long";
      end if;
   end Check_Bounds;

   procedure Check_Pattern (Pattern : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
   end Check_Pattern;

   ---------------------------------------------------------------------------
   -- LPS / π table
   ---------------------------------------------------------------------------

   function Build_LPS (Pattern : String) return LPS_Array is
   begin
      Check_Pattern (Pattern);

      declare
         M   : constant Positive := Pattern'Length;
         PF  : constant Positive := Pattern'First;
         LPS : LPS_Array (1 .. M);
         Len : Natural := 0;
         I   : Positive := 2;
      begin
         LPS (1) := 0;

         while I <= M loop
            if Pattern (PF + I - 1) = Pattern (PF + Len) then
               Len := Len + 1;
               LPS (I) := Len;
               I := I + 1;
            elsif Len /= 0 then
               Len := LPS (Len);
            else
               LPS (I) := 0;
               I := I + 1;
            end if;
         end loop;

         return LPS;
      end;
   end Build_LPS;

   ---------------------------------------------------------------------------
   -- Naive oracle
   ---------------------------------------------------------------------------

   function Naive_Search (Pattern, Text : String) return Match_Index_Array is
      M : constant Natural := Pattern'Length;
      N : constant Natural := Text'Length;
   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         PF       : constant Positive := Pattern'First;
         TF       : constant Positive := Text'First;
         Ok       : Boolean;
      begin
         for Start in 0 .. N - M loop
            Ok := True;
            for K in 0 .. M - 1 loop
               if Pattern (PF + K) /= Text (TF + Start + K) then
                  Ok := False;
                  exit;
               end if;
            end loop;
            if Ok then
               Count := Count + 1;
               Buf (Count) := Start + 1;
            end if;
         end loop;
         return Buf (1 .. Count);
      end;
   end Naive_Search;

   ---------------------------------------------------------------------------
   -- KMP search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array is
      M  : constant Natural := Pattern'Length;
      N  : constant Natural := Text'Length;
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         LPS      : constant LPS_Array := Build_LPS (Pattern);
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         --  0-based offsets into Pattern / Text as length views
         I : Natural := 0;  -- text index (advances only)
         J : Natural := 0;  -- pattern index (LPS jumps on mismatch)
      begin
         while I < N loop
            if Pattern (PF + J) = Text (TF + I) then
               I := I + 1;
               J := J + 1;
               if J = M then
                  Count := Count + 1;
                  Buf (Count) := I - M + 1;
                  J := LPS (J);
               end if;
            elsif J /= 0 then
               J := LPS (J);
            else
               I := I + 1;
            end if;
         end loop;

         return Buf (1 .. Count);
      end;
   end Search;

end Knuth_Morris_Pratt;
