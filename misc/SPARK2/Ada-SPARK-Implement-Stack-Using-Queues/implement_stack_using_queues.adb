pragma Ada_2022;
package body Implement_Stack_Using_Queues with SPARK_Mode => On is
   function Empty return Stack is
   begin return (Data => [others => 0], Count => 0); end Empty;
   procedure Push (S : in out Stack; V : Value) is
   begin S.Count := S.Count + 1; S.Data (S.Count) := V; end Push;
   procedure Pop (S : in out Stack; V : out Value) is
   begin V := S.Data (S.Count); S.Count := S.Count - 1; end Pop;
   function Size (S : Stack) return Natural is (S.Count);
end Implement_Stack_Using_Queues;
