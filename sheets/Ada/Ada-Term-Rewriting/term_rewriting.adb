with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Containers;

package body Term_Rewriting is

   use type Ada.Containers.Count_Type;

   -- Local set package for rule variable validation
   package String_Sets is new Ada.Containers.Indefinite_Ordered_Sets (String);

   ---------
   -- "=" --
   ---------
   function "=" (Left, Right : Node_Type) return Boolean is
      use Ada.Strings.Unbounded;
   begin
      return Left.Kind = Right.Kind and then Left.Name = Right.Name;
   end "=";

   function "=" (Left, Right : Term) return Boolean is
      use Term_Trees;
   begin
      return Left.AST = Right.AST;
   end "=";

   ---------------------
   -- Create_Variable --
   ---------------------
   function Create_Variable (Name : String) return Term is
      Result : Term;
      use Ada.Strings.Unbounded;
   begin
      Result.AST.Insert_Child
        (Parent   => Result.AST.Root,
         Before   => Term_Trees.No_Element,
         New_Item => Node_Type'(Variable_Node, To_Unbounded_String (Name)));
      return Result;
   end Create_Variable;

   ---------------------
   -- Create_Function --
   ---------------------
   function Create_Function (Name : String; Args : Term_Array) return Term is
      Result   : Term;
      Root_Cur : Term_Trees.Cursor;
      use Ada.Strings.Unbounded;
      use Term_Trees;
   begin
      Result.AST.Insert_Child
        (Parent   => Result.AST.Root,
         Before   => No_Element,
         New_Item => Node_Type'(Function_Node, To_Unbounded_String (Name)));

      Root_Cur := First_Child (Result.AST.Root);

      for I in Args'Range loop
         Result.AST.Copy_Subtree
           (Parent => Root_Cur,
            Before => No_Element,
            Source => First_Child (Args (I).AST.Root));
      end loop;

      return Result;
   end Create_Function;

   ---------------------
   -- Create_Constant --
   ---------------------
   function Create_Constant (Name : String) return Term is
   begin
      return Create_Function (Name, Term_Array'[]);
   end Create_Constant;

   -----------------------
   -- Collect_Variables --
   -----------------------
   -- Helper to extract all variable names from a subtree.
   procedure Collect_Variables (C : Term_Trees.Cursor; Vars : in out String_Sets.Set) is
      use Term_Trees;
   begin
      if Element (C).Kind = Variable_Node then
         Vars.Include (Ada.Strings.Unbounded.To_String (Element (C).Name));
      else
         declare
            Child : Cursor := First_Child (C);
         begin
            while Has_Element (Child) loop
               Collect_Variables (Child, Vars);
               Child := Next_Sibling (Child);
            end loop;
         end;
      end if;
   end Collect_Variables;

   -----------------
   -- Create_Rule --
   -----------------
   function Create_Rule (Lhs : Term; Rhs : Term) return Rule is
      use Term_Trees;
      Lhs_Root : constant Cursor := First_Child (Lhs.AST.Root);
      Lhs_Vars, Rhs_Vars : String_Sets.Set;
   begin
      if not Has_Element (Lhs_Root) then
         raise Invalid_Term_Error with "LHS is completely empty.";
      end if;
      
      if Element (Lhs_Root).Kind = Variable_Node then
         raise Invalid_Rule_Error with "LHS cannot be a standalone variable.";
      end if;

      Collect_Variables (Lhs_Root, Lhs_Vars);
      Collect_Variables (First_Child (Rhs.AST.Root), Rhs_Vars);

      if not Rhs_Vars.Is_Subset (Lhs_Vars) then
         raise Invalid_Rule_Error with "Variables in RHS must be a subset of LHS.";
      end if;

      return Rule'(Lhs => Lhs, Rhs => Rhs);
   end Create_Rule;

   ----------------------
   -- To_String_Cursor --
   ----------------------
   function To_String_Cursor (C : Term_Trees.Cursor) return String is
      use Term_Trees;
      use Ada.Strings.Unbounded;
      Elem : constant Node_Type := Element (C);
      Res  : Unbounded_String := Elem.Name;
   begin
      if Elem.Kind = Function_Node and then Child_Count (C) > 0 then
         Append (Res, "(");
         declare
            Child : Cursor := First_Child (C);
         begin
            while Has_Element (Child) loop
               Append (Res, To_String_Cursor (Child));
               Child := Next_Sibling (Child);
               if Has_Element (Child) then
                  Append (Res, ", ");
               end if;
            end loop;
         end;
         Append (Res, ")");
      end if;
      return To_String (Res);
   end To_String_Cursor;

   ---------------
   -- To_String --
   ---------------
   function To_String (T : Term) return String is
      use Term_Trees;
   begin
      return To_String_Cursor (First_Child (T.AST.Root));
   end To_String;

   ------------------------
   -- Match_Tree_Cursors --
   ------------------------
   -- Recursively matches a target against a pattern, building up a substitution map.
   procedure Match_Tree_Cursors
     (Pat_Cur    : Term_Trees.Cursor;
      Target_Cur : Term_Trees.Cursor;
      Sub        : in out Substitution_Map;
      Success    : out Boolean)
   is
      use Term_Trees;
      use Ada.Strings.Unbounded;
      Pat_Elem : constant Node_Type := Element (Pat_Cur);
      Tar_Elem : constant Node_Type := Element (Target_Cur);
   begin
      if Pat_Elem.Kind = Variable_Node then
         declare
            Var_Name : constant String := To_String (Pat_Elem.Name);
            Sub_Term : Term;
         begin
            Sub_Term.AST.Copy_Subtree (Parent => Sub_Term.AST.Root,
                                       Before => No_Element,
                                       Source => Target_Cur);
            if Sub.Contains (Var_Name) then
               Success := Sub.Element (Var_Name) = Sub_Term;
            else
               Sub.Insert (Var_Name, Sub_Term);
               Success := True;
            end if;
         end;
      else
         if Tar_Elem.Kind = Variable_Node or else Pat_Elem.Name /= Tar_Elem.Name then
            Success := False;
            return;
         end if;
         
         if Child_Count (Pat_Cur) /= Child_Count (Target_Cur) then
            Success := False;
            return;
         end if;

         declare
            P_Child : Cursor := First_Child (Pat_Cur);
            T_Child : Cursor := First_Child (Target_Cur);
         begin
            while Has_Element (P_Child) loop
               Match_Tree_Cursors (P_Child, T_Child, Sub, Success);
               if not Success then
                  return;
               end if;
               P_Child := Next_Sibling (P_Child);
               T_Child := Next_Sibling (T_Child);
            end loop;
         end;
         Success := True;
      end if;
   end Match_Tree_Cursors;

   ------------------------
   -- Apply_Substitution --
   ------------------------
   -- Replaces variables in a tree in-place according to the substitution map.
   procedure Apply_Substitution
     (Container : in out Term_Trees.Tree;
      C         : Term_Trees.Cursor;
      Sub       : Substitution_Map)
   is
      use Term_Trees;
      use Ada.Strings.Unbounded;
      Elem : constant Node_Type := Element (C);
   begin
      if Elem.Kind = Variable_Node then
         declare
            Var_Name : constant String := To_String (Elem.Name);
         begin
            if Sub.Contains (Var_Name) then
               declare
                  Parent_Cur : constant Cursor := Parent (C);
                  New_Term   : constant Term := Sub.Element (Var_Name);
                  Temp_C     : Cursor := C;
               begin
                  Container.Copy_Subtree
                    (Parent => Parent_Cur,
                     Before => C,
                     Source => First_Child (New_Term.AST.Root));
                  Container.Delete_Subtree (Temp_C);
               end;
            end if;
         end;
      else
         declare
            Child  : Cursor := First_Child (C);
            Next_C : Cursor;
         begin
            while Has_Element (Child) loop
               Next_C := Next_Sibling (Child);
               Apply_Substitution (Container, Child, Sub);
               Child := Next_C;
            end loop;
         end;
      end if;
   end Apply_Substitution;

   -----------------------
   -- Rewrite_Recursive --
   -----------------------
   procedure Rewrite_Recursive
     (Container : in out Term_Trees.Tree;
      C         : Term_Trees.Cursor;
      Rules     : Rule_Array;
      Strategy  : Strategy_Type;
      Rewritten : out Boolean)
   is
      use Term_Trees;
      Sub     : Substitution_Map;
      Success : Boolean;

      procedure Try_Rewrite is
      begin
         for R of Rules loop
            Sub.Clear;
            Match_Tree_Cursors (First_Child (R.Lhs.AST.Root), C, Sub, Success);
            
            if Success then
               declare
                  Parent_Cur : constant Cursor := Parent (C);
                  New_Term   : Term := R.Rhs;
                  Temp_C     : Cursor := C;
               begin
                  Apply_Substitution (New_Term.AST, First_Child (New_Term.AST.Root), Sub);

                  Container.Copy_Subtree
                    (Parent => Parent_Cur,
                     Before => C,
                     Source => First_Child (New_Term.AST.Root));
                     
                  Container.Delete_Subtree (Temp_C);
                  Rewritten := True;
               end;
               return;
            end if;
         end loop;
      end Try_Rewrite;

      procedure Try_Children is
         Child : Cursor := First_Child (C);
      begin
         while Has_Element (Child) loop
            Rewrite_Recursive (Container, Child, Rules, Strategy, Rewritten);
            if Rewritten then
               return;
            end if;
            Child := Next_Sibling (Child);
         end loop;
      end Try_Children;

   begin
      Rewritten := False;

      if Element (C).Kind = Variable_Node then
         return;
      end if;

      case Strategy is
         when Innermost =>
            Try_Children;
            if not Rewritten then
               Try_Rewrite;
            end if;
         when Outermost =>
            Try_Rewrite;
            if not Rewritten then
               Try_Children;
            end if;
      end case;
   end Rewrite_Recursive;

   ------------------
   -- Rewrite_Step --
   ------------------
   function Rewrite_Step
     (T        : Term;
      Rules    : Rule_Array;
      Strategy : Strategy_Type) return Term
   is
      Result    : Term := T;
      Rewritten : Boolean;
      use Term_Trees;
   begin
      Rewrite_Recursive (Result.AST, First_Child (Result.AST.Root), Rules, Strategy, Rewritten);
      
      -- Read reference to silence assigned-but-unread compiler warning without using pragma
      if Rewritten then
         null;
      end if;
      
      return Result;
   end Rewrite_Step;

   ---------------
   -- Normalize --
   ---------------
   function Normalize
     (T         : Term;
      Rules     : Rule_Array;
      Strategy  : Strategy_Type;
      Max_Steps : Step_Count) return Term
   is
      Result    : Term := T;
      Rewritten : Boolean := True;
      Steps     : Step_Count := 0;
      use Term_Trees;
   begin
      while Rewritten loop
         if Steps >= Max_Steps then
            raise Limit_Exceeded_Error with "Max steps exceeded during normalization";
         end if;
         
         Rewrite_Recursive (Result.AST, First_Child (Result.AST.Root), Rules, Strategy, Rewritten);
         
         if Rewritten then
            Steps := Steps + 1;
         end if;
      end loop;
      return Result;
   end Normalize;

end Term_Rewriting;
