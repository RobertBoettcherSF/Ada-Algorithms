pragma Ada_2022;
package body Design_A_Stack_With_Increment_Operation with SPARK_Mode => On is
   function Empty return Stack is
   begin return (Data => [others => 0], Count => 0); end Empty;
   procedure Push (S : in out Stack; V : Value) is
   begin S.Count := S.Count + 1; S.Data (S.Count) := V; end Push;
   procedure Increment (S : in out Stack; Bottom : Index; By : Amount) is
      Limit : constant Index := Integer'Min (Bottom, S.Count);
   begin
      for I in 1 .. Limit loop
         pragma Loop_Invariant
           (for all J in I .. Limit => S.Data (J) = S.Data'Loop_Entry (J));
         S.Data (I) := S.Data (I) + By;
      end loop;
   end Increment;
   procedure Pop (S : in out Stack; V : out Value) is
   begin V := S.Data (S.Count); S.Count := S.Count - 1; end Pop;
   function Size (S : Stack) return Natural is (S.Count);
end Design_A_Stack_With_Increment_Operation;
