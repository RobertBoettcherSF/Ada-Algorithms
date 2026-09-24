--  Krauss_Matching_Wildcards body — non-recursive bookmark walker.
--  Implements Kirk J. Krauss’s star-bookmark approach (2008 / refined
--  2014): advance Pattern and Text in lockstep; on '*', save bookmarks
--  and try matching the remainder; on mismatch after a '*', bump the
--  text bookmark and retry. Linear backtracking, no recursion stack.

pragma Ada_2022;

package body Krauss_Matching_Wildcards
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Match
   -------------------------------------------------------------------------

   function Match (Pattern, Text : String) return Boolean is
      --  Current indices (Ada 1-based; Past Last means exhausted).
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
      --  Fast path: both empty.
      if Pattern'Length = 0 then
         return Text'Length = 0;
      end if;

      loop
         if Text_Done then
            --  Text exhausted: remaining Pattern must be only '*'.
            while not Pattern_Done and then Pattern (P) = '*' loop
               P := P + 1;
            end loop;
            return Pattern_Done;
         end if;

         if not Pattern_Done and then Pattern (P) = '*' then
            --  Record star bookmarks; try matching empty sequence first
            --  (advance Pattern past this '*'; leave Text in place).
            --  Consecutive stars simply refresh the same idea.
            Star_P := P;
            Star_T := T;
            P := P + 1;

         elsif not Pattern_Done
           and then (Pattern (P) = '?' or else Pattern (P) = Text (T))
         then
            --  Literal or single-char wildcard match: advance both.
            P := P + 1;
            T := T + 1;

         elsif Star_P /= 0 then
            --  Mismatch after a '*': let '*' consume one more character
            --  from Text and retry from the Pattern bookmark.
            P := Star_P + 1;
            Star_T := Star_T + 1;
            T := Star_T;

         else
            --  No star to fall back on.
            return False;
         end if;
      end loop;
   end Match;

end Krauss_Matching_Wildcards;
