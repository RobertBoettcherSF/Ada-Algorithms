--  Pre rejection: searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree
--  (Insert). Tree: K uniform 0 .. 16 valid Inserts (random free slots,
--  values uniform) from Empty; then Node uniform over Node_Index.
with Pre_Rng; use Pre_Rng;
with Insert_Into_A_Binary_Search_Tree; use Insert_Into_A_Binary_Search_Tree;
procedure Pr_Bst is
   Rej : Natural := 0;
   function Pre_Insert (T : Tree; Root : Index; Node : Node_Index) return Boolean is
     (Well_Formed (T, Root) and then not Is_Used (T, Node));
begin
   for K in 1 .. Sample loop
      declare
         T    : Tree := Empty;
         Root : Index := 0;
         Want : constant Natural := Draw (0, Node_Index'Last);
         Done : Natural := 0;
         Nd   : Node_Index;
      begin
         while Done < Want loop
            Nd := Draw (1, Node_Index'Last);
            if not Is_Used (T, Nd) then
               Insert (T, Root, Nd, Draw (Value'First, Value'Last));
               Done := Done + 1;
            end if;
         end loop;
         if not Pre_Insert (T, Root, Draw (1, Node_Index'Last)) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report ("searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree", "Insert",
           "tree of K uniform 0..16 valid inserts, Node uniform over Node_Index", Rej);
end Pr_Bst;
