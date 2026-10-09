package body Red_Black_Tree.Test_Support is

   procedure Build
     (T       : in out Tree;
      Present : Present_Array;
      Keys    : Key_Array;
      Red     : Red_Array)
   is
      Nodes : array (Position) of Node_Access := [others => null];
      N     : Natural := 0;
   begin
      Clear (T);
      for P in Position loop
         if Present (P) then
            Nodes (P) := new Node'(Key    => Keys (P),
                                   Value  => 0.0,
                                   Color  => (if Red (P) then Red_Black_Tree.Red
                                              else Black),
                                   Left   => null,
                                   Right  => null,
                                   Parent => (if P = 1 then null
                                              else Nodes (P / 2)));
            if P > 1 then
               if P mod 2 = 0 then
                  Nodes (P / 2).Left := Nodes (P);
               else
                  Nodes (P / 2).Right := Nodes (P);
               end if;
            end if;
            N := N + 1;
         end if;
      end loop;
      T.Root  := Nodes (1);
      T.Count := N;
   end Build;

   procedure Break_Parent_Link (T : in out Tree) is
   begin
      if T.Root /= null then
         if T.Root.Left /= null then
            T.Root.Left.Parent := null;
         elsif T.Root.Right /= null then
            T.Root.Right.Parent := null;
         end if;
      end if;
   end Break_Parent_Link;

   procedure Set_Count (T : in out Tree; Count : Natural) is
   begin
      T.Count := Count;
   end Set_Count;

   function Reference_Valid (T : Tree) return Boolean is
      Max_Nodes : constant := 64;
      In_Order  : array (1 .. Max_Nodes) of Node_Key := [others => 0];
      Last      : Natural := 0;
      Leaf_Blacks : Integer := -1;   --  black count of the first path seen
      OK        : Boolean := True;

      procedure Walk (N : Node_Access; Up : Node_Access; Blacks : Natural) is
      begin
         if N = null then
            if Leaf_Blacks < 0 then
               Leaf_Blacks := Blacks;
            elsif Leaf_Blacks /= Blacks then
               OK := False;
            end if;
            return;
         end if;
         if N.Parent /= Up then
            OK := False;
         end if;
         if N.Color = Red
           and then ((N.Left /= null and then N.Left.Color = Red)
                     or else (N.Right /= null and then N.Right.Color = Red))
         then
            OK := False;
         end if;
         declare
            B : constant Natural :=
              Blacks + (if N.Color = Black then 1 else 0);
         begin
            Walk (N.Left, N, B);
            if Last = Max_Nodes then
               OK := False;
               return;
            end if;
            Last := Last + 1;
            In_Order (Last) := N.Key;
            Walk (N.Right, N, B);
         end;
      end Walk;
   begin
      if T.Root /= null and then T.Root.Color = Red then
         return False;
      end if;
      Walk (T.Root, null, 0);
      for I in 2 .. Last loop
         if In_Order (I - 1) >= In_Order (I) then
            OK := False;
         end if;
      end loop;
      return OK and then Last = T.Count;
   end Reference_Valid;

end Red_Black_Tree.Test_Support;
