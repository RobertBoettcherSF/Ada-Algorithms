pragma SPARK_Mode (On);

package body Merge_Two_Binary_Trees is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Value_At (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Value_At;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;


   function Merge (A, B : Tree) return Tree is
      Result : Tree := Empty;
      Combined : Integer;
   begin
      for N in Node_Index loop
         if A.Used (N) or else B.Used (N) then
            Combined := 0;
            if A.Used (N) then Combined := A.Values (N); end if;
            if B.Used (N) then
               if Combined <= Value'Last - B.Values (N)
                 and then Combined >= Value'First - B.Values (N)
               then
                  Combined := Combined + B.Values (N);
               end if;
            end if;
            Result.Values (N) := Combined; Result.Lefts (N) := 0; Result.Rights (N) := 0;
            if A.Used (N) then Result.Lefts (N) := A.Lefts (N); Result.Rights (N) := A.Rights (N); end if;
            if B.Used (N) then
               if Result.Lefts (N) = 0 then Result.Lefts (N) := B.Lefts (N); end if;
               if Result.Rights (N) = 0 then Result.Rights (N) := B.Rights (N); end if;
            end if;
            Result.Used (N) := True;
         end if;
      end loop;
      return Result;
   end Merge;
end Merge_Two_Binary_Trees;
