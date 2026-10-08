pragma Ada_2022;
pragma SPARK_Mode (On);
package Jump_Game is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Steps is array (Index) of Natural;   --  A (I) = longest jump allowed from index I

   --  Index K is reachable from index 1 exactly when every K2 in 2 .. K is jumped to or over from some
   --  earlier index J (J + A (J) >= K2): the reachable indices always form a prefix 1 .. R.
   function Covered (A : Steps; K : Index) return Boolean is
     (for some J in 1 .. K - 1 => Long_Long_Integer (J) + Long_Long_Integer (A (J)) >= Long_Long_Integer (K));

   --  Can index N be reached from index 1?
   function Can_Jump (A : Steps; N : Index) return Boolean
     with Post => Can_Jump'Result = (for all K in 2 .. N => Covered (A, K));
end Jump_Game;
