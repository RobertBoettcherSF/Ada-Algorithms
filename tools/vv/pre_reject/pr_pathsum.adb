--  Pre rejection: misc/SPARK2/Ada-SPARK-Path-Sum (Set_Node). Tree: 30
--  random Set_Node calls from Empty, each applied only when its Pre holds;
--  then Node uniform over Node_Index, Left and Right uniform over Index.
with Pre_Rng; use Pre_Rng;
with Path_Sum; use Path_Sum;
procedure Pr_Pathsum is
   Rej : Natural := 0;
   function Pre_Set (T : Tree; Node : Node_Index; Left, Right : Index) return Boolean is
     ((Left = 0
       or else (not Has_Other_Parent (T, Left, Node)
                and then not Is_Ancestor_Or_Self (T, Left, Node)))
      and then (Right = 0
                or else (not Has_Other_Parent (T, Right, Node)
                         and then not Is_Ancestor_Or_Self (T, Right, Node)))
      and then (Left = 0 or else Left /= Right));
begin
   for K in 1 .. Sample loop
      declare
         T : Tree := Empty;
         N : Node_Index;
         L, R : Index;
      begin
         for Step in 1 .. 30 loop
            N := Draw (1, Node_Index'Last); L := Draw (0, Index'Last); R := Draw (0, Index'Last);
            if Pre_Set (T, N, L, R) then
               Set_Node (T, N, Draw (Value'First, Value'Last), L, R);
            end if;
         end loop;
         N := Draw (1, Node_Index'Last); L := Draw (0, Index'Last); R := Draw (0, Index'Last);
         if not Pre_Set (T, N, L, R) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report ("misc/SPARK2/Ada-SPARK-Path-Sum", "Set_Node",
           "tree from 30 random accepted Set_Node calls, then Node/Left/Right uniform", Rej);
end Pr_Pathsum;
