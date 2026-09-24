pragma SPARK_Mode (On);

package body Special_Array_With_X_Elements is
   function Match (V, X : Value) return Natural is
     (if V = X then 1 else 0);

   function Match_Count (A : Array_Of_Values; X : Value) return Natural is
   begin
      return Match (A (1), X) + Match (A (2), X)
        + Match (A (3), X) + Match (A (4), X)
        + Match (A (5), X) + Match (A (6), X)
        + Match (A (7), X) + Match (A (8), X);
   end Match_Count;

   function Is_Special (A : Array_Of_Values; X : Value) return Boolean is
   begin
      return Match_Count (A, X) = X;
   end Is_Special;
end Special_Array_With_X_Elements;
