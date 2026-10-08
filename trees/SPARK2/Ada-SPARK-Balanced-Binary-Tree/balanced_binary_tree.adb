pragma Ada_2022;
pragma SPARK_Mode (On);

package body Balanced_Binary_Tree is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Lefts => [others => 0],
              Rights => [others => 0], Used => [others => False]);
   end Empty;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Node_Value (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Node_Value;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;

   --  Post-order walk: H = height of the tree at N (N at depth D), Ok = it is balanced.
   procedure Walk (T : Tree; N : Node_Index; D : Positive; H : out Natural; Ok : out Boolean)
     with Pre => D <= 31,
          Post => Ok = Spec_Balanced (T, N, D) and then (if Ok then H = Spec_Height (T, N, D)),
          Subprogram_Variant => (Decreases => 32 - D)
   is
      HL, HR : Natural := 0;
      OkL, OkR : Boolean;
   begin
      H := 0;
      if T.Lefts (N) /= 0 then
         if D = 31 then
            Ok := False;   --  a 32nd level: only possible with a cycle
            return;
         end if;
         Walk (T, T.Lefts (N), D + 1, HL, OkL);
         if not OkL then
            Ok := False;
            return;
         end if;
      end if;
      if T.Rights (N) /= 0 then
         if D = 31 then
            Ok := False;
            return;
         end if;
         Walk (T, T.Rights (N), D + 1, HR, OkR);
         if not OkR then
            Ok := False;
            return;
         end if;
      end if;
      Ok := abs (HL - HR) <= 1;
      H := 1 + Natural'Max (HL, HR);
   end Walk;

   function Is_Balanced (T : Tree; Root : Index) return Boolean is
      H : Natural;
      Ok : Boolean;
   begin
      if Root = 0 or else not T.Used (Root) then
         return True;
      end if;
      Walk (T, Root, 1, H, Ok);
      pragma Assert (if Ok then H >= 1);   --  a non-empty balanced tree has height >= 1
      return Ok;
   end Is_Balanced;
end Balanced_Binary_Tree;
