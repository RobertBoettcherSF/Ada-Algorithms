with Ada.Unchecked_Deallocation;

package body Red_Black_Tree is

   procedure Free_Node is new Ada.Unchecked_Deallocation
     (Object => Node, Name => Node_Access);

   -- 
   -- Helper Functions
   -- 

   function Color_Of (N : Node_Access) return Color_Type is
     (if N = null then Black else N.Color);

   function Left_Color (N : Node_Access) return Color_Type is
     (if N = null or else N.Left = null then Black else N.Left.Color);

   function Right_Color (N : Node_Access) return Color_Type is
     (if N = null or else N.Right = null then Black else N.Right.Color);

   function Find_Node (T : Tree; Key : Node_Key) return Node_Access is
      N : Node_Access := T.Root;
   begin
      while N /= null loop
         if Key < N.Key then
            N := N.Left;
         elsif Key > N.Key then
            N := N.Right;
         else
            return N;
         end if;
      end loop;
      return null;
   end Find_Node;

   -- 
   -- Structural Rotations
   -- 

   procedure Left_Rotate (T : in out Tree; X : Node_Access) is
      Y : Node_Access := X.Right;
   begin
      X.Right := Y.Left;
      if Y.Left /= null then
         Y.Left.Parent := X;
      end if;
      Y.Parent := X.Parent;
      if X.Parent = null then
         T.Root := Y;
      elsif X = X.Parent.Left then
         X.Parent.Left := Y;
      else
         X.Parent.Right := Y;
      end if;
      Y.Left := X;
      X.Parent := Y;
   end Left_Rotate;

   procedure Right_Rotate (T : in out Tree; X : Node_Access) is
      Y : Node_Access := X.Left;
   begin
      X.Left := Y.Right;
      if Y.Right /= null then
         Y.Right.Parent := X;
      end if;
      Y.Parent := X.Parent;
      if X.Parent = null then
         T.Root := Y;
      elsif X = X.Parent.Right then
         X.Parent.Right := Y;
      else
         X.Parent.Left := Y;
      end if;
      Y.Right := X;
      X.Parent := Y;
   end Right_Rotate;

   procedure Transplant (T : in out Tree; U, V : Node_Access) is
   begin
      if U.Parent = null then
         T.Root := V;
      elsif U = U.Parent.Left then
         U.Parent.Left := V;
      else
         U.Parent.Right := V;
      end if;
      if V /= null then
         V.Parent := U.Parent;
      end if;
   end Transplant;

   -- 
   -- Insertion Fixup
   -- 

   procedure Insert_Fixup (T : in out Tree; Z_In : Node_Access) is
      Z : Node_Access := Z_In;
      Y : Node_Access;
   begin
      while Z.Parent /= null and then Z.Parent.Color = Red loop
         if Z.Parent = Z.Parent.Parent.Left then
            Y := Z.Parent.Parent.Right;
            if Color_Of (Y) = Red then
               Z.Parent.Color := Black;
               Y.Color := Black;
               Z.Parent.Parent.Color := Red;
               Z := Z.Parent.Parent;
            else
               if Z = Z.Parent.Right then
                  Z := Z.Parent;
                  Left_Rotate (T, Z);
               end if;
               Z.Parent.Color := Black;
               Z.Parent.Parent.Color := Red;
               Right_Rotate (T, Z.Parent.Parent);
            end if;
         else
            Y := Z.Parent.Parent.Left;
            if Color_Of (Y) = Red then
               Z.Parent.Color := Black;
               Y.Color := Black;
               Z.Parent.Parent.Color := Red;
               Z := Z.Parent.Parent;
            else
               if Z = Z.Parent.Left then
                  Z := Z.Parent;
                  Right_Rotate (T, Z);
               end if;
               Z.Parent.Color := Black;
               Z.Parent.Parent.Color := Red;
               Left_Rotate (T, Z.Parent.Parent);
            end if;
         end if;
      end loop;
      T.Root.Color := Black;
   end Insert_Fixup;

   -- 
   -- Deletion Fixup
   -- 

   procedure Delete_Fixup (T : in out Tree; X_In, X_Parent_In : Node_Access) is
      X : Node_Access := X_In;
      X_Parent : Node_Access := X_Parent_In;
      W : Node_Access;
   begin
      while X /= T.Root and then Color_Of (X) = Black loop
         if X = X_Parent.Left then
            W := X_Parent.Right;
            if Color_Of (W) = Red then
               W.Color := Black;
               X_Parent.Color := Red;
               Left_Rotate (T, X_Parent);
               W := X_Parent.Right;
            end if;
            if Left_Color (W) = Black and Right_Color (W) = Black then
               if W /= null then
                  W.Color := Red;
               end if;
               X := X_Parent;
               X_Parent := X.Parent;
            else
               if Right_Color (W) = Black then
                  if W /= null and then W.Left /= null then
                     W.Left.Color := Black;
                  end if;
                  if W /= null then
                     W.Color := Red;
                     Right_Rotate (T, W);
                  end if;
                  W := X_Parent.Right;
               end if;
               if W /= null then
                  W.Color := X_Parent.Color;
               end if;
               X_Parent.Color := Black;
               if W /= null and then W.Right /= null then
                  W.Right.Color := Black;
               end if;
               Left_Rotate (T, X_Parent);
               X := T.Root;
               X_Parent := null;
            end if;
         else
            W := X_Parent.Left;
            if Color_Of (W) = Red then
               W.Color := Black;
               X_Parent.Color := Red;
               Right_Rotate (T, X_Parent);
               W := X_Parent.Left;
            end if;
            if Right_Color (W) = Black and Left_Color (W) = Black then
               if W /= null then
                  W.Color := Red;
               end if;
               X := X_Parent;
               X_Parent := X.Parent;
            else
               if Left_Color (W) = Black then
                  if W /= null and then W.Right /= null then
                     W.Right.Color := Black;
                  end if;
                  if W /= null then
                     W.Color := Red;
                     Left_Rotate (T, W);
                  end if;
                  W := X_Parent.Left;
               end if;
               if W /= null then
                  W.Color := X_Parent.Color;
               end if;
               X_Parent.Color := Black;
               if W /= null and then W.Left /= null then
                  W.Left.Color := Black;
               end if;
               Right_Rotate (T, X_Parent);
               X := T.Root;
               X_Parent := null;
            end if;
         end if;
      end loop;
      if X /= null then
         X.Color := Black;
      end if;
   end Delete_Fixup;

   -- 
   -- Core Operations
   -- 

   procedure Insert (T : in out Tree; Key : Node_Key; Value : Node_Value) is
      Z : Node_Access := new Node'(Key, Value, Red, null, null, null);
      Y : Node_Access := null;
      X : Node_Access := T.Root;
   begin
      while X /= null loop
         Y := X;
         if Z.Key < X.Key then
            X := X.Left;
         elsif Z.Key > X.Key then
            X := X.Right;
         else
            Free_Node (Z);
            raise Duplicate_Key_Error;
         end if;
      end loop;
      
      Z.Parent := Y;
      if Y = null then
         T.Root := Z;
      elsif Z.Key < Y.Key then
         Y.Left := Z;
      else
         Y.Right := Z;
      end if;
      
      T.Count := T.Count + 1;
      Insert_Fixup (T, Z);
   end Insert;

   procedure Delete (T : in out Tree; Key : Node_Key) is
      Z : Node_Access := Find_Node (T, Key);
      Y : Node_Access;
      X : Node_Access;
      X_Parent : Node_Access := null;
      Y_Original_Color : Color_Type;
   begin
      if Z = null then
         raise Key_Not_Found_Error;
      end if;

      Y := Z;
      Y_Original_Color := Y.Color;

      if Z.Left = null then
         X := Z.Right;
         X_Parent := Z.Parent;
         Transplant (T, Z, Z.Right);
      elsif Z.Right = null then
         X := Z.Left;
         X_Parent := Z.Parent;
         Transplant (T, Z, Z.Left);
      else
         Y := Z.Right;
         while Y.Left /= null loop
            Y := Y.Left;
         end loop;
         Y_Original_Color := Y.Color;
         X := Y.Right;

         if Y.Parent = Z then
            X_Parent := Y;
         else
            X_Parent := Y.Parent;
            Transplant (T, Y, Y.Right);
            Y.Right := Z.Right;
            Y.Right.Parent := Y;
         end if;
         Transplant (T, Z, Y);
         Y.Left := Z.Left;
         Y.Left.Parent := Y;
         Y.Color := Z.Color;
      end if;

      Free_Node (Z);
      T.Count := T.Count - 1;

      if Y_Original_Color = Black then
         Delete_Fixup (T, X, X_Parent);
      end if;
   end Delete;

   function Search (T : Tree; Key : Node_Key) return Node_Value is
      N : Node_Access := Find_Node (T, Key);
   begin
      if N = null then
         raise Key_Not_Found_Error;
      end if;
      return N.Value;
   end Search;

   function Contains (T : Tree; Key : Node_Key) return Boolean is
   begin
      return Find_Node (T, Key) /= null;
   end Contains;

   function Minimum (T : Tree) return Node_Key is
      N : Node_Access := T.Root;
   begin
      if N = null then
         raise Empty_Tree_Error;
      end if;
      while N.Left /= null loop
         N := N.Left;
      end loop;
      return N.Key;
   end Minimum;

   function Maximum (T : Tree) return Node_Key is
      N : Node_Access := T.Root;
   begin
      if N = null then
         raise Empty_Tree_Error;
      end if;
      while N.Right /= null loop
         N := N.Right;
      end loop;
      return N.Key;
   end Maximum;

   function Successor (T : Tree; Key : Node_Key) return Node_Key is
      N : Node_Access := Find_Node (T, Key);
      Y : Node_Access;
   begin
      if N = null then
         raise Key_Not_Found_Error;
      end if;
      if N.Right /= null then
         Y := N.Right;
         while Y.Left /= null loop
            Y := Y.Left;
         end loop;
         return Y.Key;
      end if;
      Y := N.Parent;
      while Y /= null and then N = Y.Right loop
         N := Y;
         Y := Y.Parent;
      end loop;
      if Y = null then
         raise Key_Not_Found_Error;
      end if;
      return Y.Key;
   end Successor;

   function Predecessor (T : Tree; Key : Node_Key) return Node_Key is
      N : Node_Access := Find_Node (T, Key);
      Y : Node_Access;
   begin
      if N = null then
         raise Key_Not_Found_Error;
      end if;
      if N.Left /= null then
         Y := N.Left;
         while Y.Right /= null loop
            Y := Y.Right;
         end loop;
         return Y.Key;
      end if;
      Y := N.Parent;
      while Y /= null and then N = Y.Left loop
         N := Y;
         Y := Y.Parent;
      end loop;
      if Y = null then
         raise Key_Not_Found_Error;
      end if;
      return Y.Key;
   end Predecessor;

   function Size (T : Tree) return Natural is
   begin
      return T.Count;
   end Size;

   function Is_Empty (T : Tree) return Boolean is
   begin
      return T.Count = 0;
   end Is_Empty;

   procedure Clear (T : in out Tree) is
      procedure Clear_Tree (N : in out Node_Access) is
      begin
         if N /= null then
            Clear_Tree (N.Left);
            Clear_Tree (N.Right);
            Free_Node (N);
         end if;
      end Clear_Tree;
   begin
      Clear_Tree (T.Root);
      T.Count := 0;
   end Clear;

   -- 
   -- Validation
   -- 

   function Is_Valid_Red_Black_Tree (T : Tree) return Boolean is
      function Verify_Subtree (N : Node_Access; Black_Height : out Integer) return Boolean is
         Left_BH, Right_BH : Integer := 0;
      begin
         Black_Height := 0; -- Ensures 'out' parameter is initialized on early return paths
         if N = null then
            Black_Height := 1;
            return True;
         end if;
         if N.Color = Red then
            if Color_Of (N.Left) = Red or else Color_Of (N.Right) = Red then
               return False;
            end if;
         end if;
         if N.Left /= null and then N.Left.Key >= N.Key then
            return False;
         end if;
         if N.Right /= null and then N.Right.Key <= N.Key then
            return False;
         end if;
         if not Verify_Subtree (N.Left, Left_BH) then return False; end if;
         if not Verify_Subtree (N.Right, Right_BH) then return False; end if;
         if Left_BH /= Right_BH then
            return False;
         end if;
         Black_Height := Left_BH + (if N.Color = Black then 1 else 0);
         return True;
      end Verify_Subtree;

      BH : Integer;
   begin
      if T.Root /= null and then T.Root.Color = Red then
         return False;
      end if;
      return Verify_Subtree (T.Root, BH);
   end Is_Valid_Red_Black_Tree;

end Red_Black_Tree;
