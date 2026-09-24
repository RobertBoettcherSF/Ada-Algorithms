--  Matching_Wildcards body — Krauss star-bookmark + DP boolean table.

pragma Ada_2022;

package body Matching_Wildcards
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Taxonomy helpers
   -------------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Krauss => return "Krauss";
         when DP     => return "DP";
      end case;
   end Method_Name;

   function Method_Count return Positive is
     (Method_Kind'Pos (Method_Kind'Last) - Method_Kind'Pos (Method_Kind'First) + 1);

   function Describe (M : Method_Kind) return String is
   begin
      case M is
         when Krauss =>
            return "Non-recursive star-bookmark walker (Krauss-style)";
         when DP =>
            return "Classic DP boolean table (pattern × text)";
      end case;
   end Describe;

   -------------------------------------------------------------------------
   -- Match_Krauss — non-recursive bookmark walker
   -------------------------------------------------------------------------
   --  Advance Pattern and Text in lockstep; on '*', save bookmarks and try
   --  matching the remainder; on mismatch after a '*', bump the text
   --  bookmark and retry. Linear backtracking, no recursion stack.

   function Match_Krauss (Pattern, Text : String) return Boolean is
      P : Natural := Pattern'First;
      T : Natural := Text'First;

      --  Bookmarks after the most recent '*'. Zero means "no active star".
      Star_P : Natural := 0;
      Star_T : Natural := 0;

      function Pattern_Done return Boolean is
        (Pattern'Length = 0 or else P > Pattern'Last);

      function Text_Done return Boolean is
        (Text'Length = 0 or else T > Text'Last);
   begin
      if Pattern'Length = 0 then
         return Text'Length = 0;
      end if;

      loop
         if Text_Done then
            while not Pattern_Done and then Pattern (P) = '*' loop
               P := P + 1;
            end loop;
            return Pattern_Done;
         end if;

         if not Pattern_Done and then Pattern (P) = '*' then
            Star_P := P;
            Star_T := T;
            P := P + 1;

         elsif not Pattern_Done
           and then (Pattern (P) = '?' or else Pattern (P) = Text (T))
         then
            P := P + 1;
            T := T + 1;

         elsif Star_P /= 0 then
            P := Star_P + 1;
            Star_T := Star_T + 1;
            T := Star_T;

         else
            return False;
         end if;
      end loop;
   end Match_Krauss;

   -------------------------------------------------------------------------
   -- Match_DP — classic boolean DP table
   -------------------------------------------------------------------------
   --  Let DP (I, J) be True iff Pattern (1 .. I) (relative) matches
   --  Text (1 .. J). Empty pattern matches only empty text; a leading
   --  run of '*' can match empty text. Recurrence (1-based lengths):
   --    DP (0, 0) = True
   --    DP (0, J) = False  for J > 0
   --    DP (I, 0) = (Pattern_I = '*') and DP (I-1, 0)
   --    DP (I, J) =
   --      DP (I, J-1) or DP (I-1, J)           if Pattern_I = '*'
   --      DP (I-1, J-1)                        if Pattern_I = '?' or =
   --      False                                otherwise

   function Match_DP (Pattern, Text : String) return Boolean is
      NP : constant Natural := Pattern'Length;
      NT : constant Natural := Text'Length;
   begin
      if NP = 0 then
         return NT = 0;
      end if;

      declare
         --  Row-major table indexed by pattern length and text length.
         Table : array (0 .. NP, 0 .. NT) of Boolean :=
           [others => [others => False]];

         function Pat (I : Positive) return Character is
           (Pattern (Pattern'First + I - 1));

         function Txt (J : Positive) return Character is
           (Text (Text'First + J - 1));
      begin
         Table (0, 0) := True;

         for I in 1 .. NP loop
            if Pat (I) = '*' then
               Table (I, 0) := Table (I - 1, 0);
            else
               Table (I, 0) := False;
            end if;
         end loop;

         for I in 1 .. NP loop
            for J in 1 .. NT loop
               if Pat (I) = '*' then
                  Table (I, J) := Table (I, J - 1) or else Table (I - 1, J);
               elsif Pat (I) = '?' or else Pat (I) = Txt (J) then
                  Table (I, J) := Table (I - 1, J - 1);
               else
                  Table (I, J) := False;
               end if;
            end loop;
         end loop;

         return Table (NP, NT);
      end;
   end Match_DP;

   -------------------------------------------------------------------------
   -- Dispatcher / alias
   -------------------------------------------------------------------------

   function Match
     (Pattern : String;
      Text    : String;
      Method  : Method_Kind := Krauss) return Boolean is
   begin
      case Method is
         when Krauss => return Match_Krauss (Pattern, Text);
         when DP     => return Match_DP (Pattern, Text);
      end case;
   end Match;

   function Is_Match (Pattern, Text : String) return Boolean is
     (Match (Pattern, Text, Krauss));

end Matching_Wildcards;
