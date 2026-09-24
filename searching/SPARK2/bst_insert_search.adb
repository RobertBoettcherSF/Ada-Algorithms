pragma SPARK_Mode (On);

package body BST_Insert_Search is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Insert (T : in out Tree; V : Value) is
      Current : Index := 1;
   begin
      for Step in 1 .. 31 loop
         pragma Loop_Invariant (Current in Index);
         if not T.Used (Current) then
            T.Values (Current) := V; T.Lefts (Current) := 0; T.Rights (Current) := 0; T.Used (Current) := True;
            exit;
         elsif V < T.Values (Current) then
            if T.Lefts (Current) = 0 then
               T.Lefts (Current) := Index'Min (Index'Last, Current * 2);
               Current := T.Lefts (Current);
            else
               Current := T.Lefts (Current);
            end if;
         elsif V > T.Values (Current) then
            if T.Rights (Current) = 0 then
               T.Rights (Current) := Index'Min (Index'Last, Current * 2 + 1);
               Current := T.Rights (Current);
            else
               Current := T.Rights (Current);
            end if;
         else
            exit;
         end if;
      end loop;
   end Insert;

   function Contains (T : Tree; V : Value) return Boolean is
      Current : Index := 1;
      Found : Boolean := False;
   begin
      for Step in 1 .. 31 loop
         pragma Loop_Invariant (Current in Index);
         if not T.Used (Current) then
            exit;
         elsif V = T.Values (Current) then
            Found := True; exit;
         elsif V < T.Values (Current) then
            if T.Lefts (Current) = 0 then exit; else Current := T.Lefts (Current); end if;
         else
            if T.Rights (Current) = 0 then exit; else Current := T.Rights (Current); end if;
         end if;
      end loop;
      return Found;
   end Contains;
end BST_Insert_Search;
