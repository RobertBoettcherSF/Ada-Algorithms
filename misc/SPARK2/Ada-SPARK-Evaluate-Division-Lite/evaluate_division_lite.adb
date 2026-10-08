pragma SPARK_Mode (On);

package body Evaluate_Division_Lite with SPARK_Mode => On is
   function Evaluate
     (Table : Relations; From, To : Variable) return Ratio is
   begin
      if From = To then
         return 1;
      else
         return Table (From, To);
      end if;
   end Evaluate;
end Evaluate_Division_Lite;
