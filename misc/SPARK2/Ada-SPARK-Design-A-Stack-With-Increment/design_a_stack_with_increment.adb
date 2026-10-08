pragma Ada_2022;
package body Design_A_Stack_With_Increment with SPARK_Mode => On is
   function Empty return Stack is
   begin return (Data => (others => 0), Count_Stored => 0); end Empty;
   function Size (S : Stack) return Count is
   begin return S.Count_Stored; end Size;
   procedure Push (S : in out Stack; V : Value) is
   begin
      case S.Count_Stored is
         when 0 => S.Data (1) := V; when 1 => S.Data (2) := V;
         when 2 => S.Data (3) := V; when 3 => S.Data (4) := V;
         when 4 => S.Data (5) := V; when 5 => S.Data (6) := V;
         when 6 => S.Data (7) := V; when 7 => S.Data (8) := V; when 8 => null;
      end case;
      if S.Count_Stored < Capacity then S.Count_Stored := S.Count_Stored + 1; end if;
   end Push;
   procedure Pop (S : in out Stack; V : out Value) is
   begin
      case S.Count_Stored is
         when 1 => V := S.Data (1); when 2 => V := S.Data (2);
         when 3 => V := S.Data (3); when 4 => V := S.Data (4);
         when 5 => V := S.Data (5); when 6 => V := S.Data (6);
         when 7 => V := S.Data (7); when 8 => V := S.Data (8); when 0 => V := 0;
      end case;
      if S.Count_Stored > 0 then S.Count_Stored := S.Count_Stored - 1; end if;
   end Pop;
   procedure Increment_Bottom (S : in out Stack; K : Count; D : Change) is
   begin
      if K >= 1 and then S.Count_Stored >= 1 and then S.Data (1) < Value'Last then S.Data (1) := S.Data (1) + D; end if;
      if K >= 2 and then S.Count_Stored >= 2 and then S.Data (2) < Value'Last then S.Data (2) := S.Data (2) + D; end if;
      if K >= 3 and then S.Count_Stored >= 3 and then S.Data (3) < Value'Last then S.Data (3) := S.Data (3) + D; end if;
      if K >= 4 and then S.Count_Stored >= 4 and then S.Data (4) < Value'Last then S.Data (4) := S.Data (4) + D; end if;
      if K >= 5 and then S.Count_Stored >= 5 and then S.Data (5) < Value'Last then S.Data (5) := S.Data (5) + D; end if;
      if K >= 6 and then S.Count_Stored >= 6 and then S.Data (6) < Value'Last then S.Data (6) := S.Data (6) + D; end if;
      if K >= 7 and then S.Count_Stored >= 7 and then S.Data (7) < Value'Last then S.Data (7) := S.Data (7) + D; end if;
      if K >= 8 and then S.Count_Stored >= 8 and then S.Data (8) < Value'Last then S.Data (8) := S.Data (8) + D; end if;
   end Increment_Bottom;
end Design_A_Stack_With_Increment;
