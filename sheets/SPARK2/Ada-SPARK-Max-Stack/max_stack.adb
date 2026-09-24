pragma Ada_2022;
package body Max_Stack with SPARK_Mode => On is
   function Empty return Stack is
   begin return (Data => [others => 0], Count => 0, Current_Max => Value'First); end Empty;
   procedure Push (S : in out Stack; V : Value) is
   begin S.Count := S.Count + 1; S.Data (S.Count) := V; if S.Count = 1 or else V > S.Current_Max then S.Current_Max := V; end if; end Push;
   procedure Pop (S : in out Stack; V : out Value) is
   begin
      V := S.Data (S.Count); S.Count := S.Count - 1;
      if S.Count = 0 then S.Current_Max := Value'First;
      elsif V = S.Current_Max then
         S.Current_Max := S.Data (1);
         for I in 2 .. S.Count loop if S.Data (I) > S.Current_Max then S.Current_Max := S.Data (I); end if; end loop;
      end if;
   end Pop;
   function Maximum (S : Stack) return Value is (S.Current_Max);
   function Size (S : Stack) return Natural is (S.Count);
end Max_Stack;
