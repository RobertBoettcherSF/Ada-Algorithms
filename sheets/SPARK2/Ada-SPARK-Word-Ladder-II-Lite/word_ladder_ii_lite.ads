pragma SPARK_Mode (On);

package Word_Ladder_II_Lite with SPARK_Mode => On is
   Word_Length : constant := 8;
   subtype Path_Count is Natural range 0 .. Word_Length + 1;
   type Letter_Word is array (Positive range 1 .. Word_Length) of Character;

   function Shortest_Path (Start, Goal : Letter_Word) return Path_Count
     with Global => null;
end Word_Ladder_II_Lite;
