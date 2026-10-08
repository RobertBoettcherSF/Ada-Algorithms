package body Rete is

   -- =========================================================================
   -- Private Types and State Data Structures
   -- =========================================================================

   type Token_Array is array (1 .. Max_Nodes) of Token;
   type Token_List is record
      Count : Natural := 0;
      Items : Token_Array;
   end record;

   type WME_Array_Type is array (1 .. Max_Nodes) of WME;
   type WME_List is record
      Count : Natural := 0;
      Items : WME_Array_Type;
   end record;

   type Alpha_Node is record
      Attribute : Symbol;
      Value     : Symbol;
      Memory    : WME_List;
   end record;

   type Beta_Node is record
      Parent_Beta  : Beta_Node_ID;
      Parent_Alpha : Alpha_Node_ID;
      Condition    : Join_Condition;
      Memory       : Token_List;
   end record;

   type Rule_Rec is record
      ID      : Rule_ID;
      Name    : Symbol;
      Beta_ID : Beta_Node_ID;
   end record;

   -- Network Stores
   Alpha_Nodes : array (Alpha_Node_ID range 1 .. Max_Nodes) of Alpha_Node;
   Alpha_Count : Natural := 0;

   Beta_Nodes : array (Beta_Node_ID range 1 .. Max_Nodes) of Beta_Node;
   Beta_Count : Natural := 0;

   Rules : array (1 .. Max_Nodes) of Rule_Rec;
   Rule_Count : Natural := 0;

   Global_WM : WME_List;

   -- =========================================================================
   -- Internal Forward Declarations
   -- =========================================================================

   procedure Left_Activate (B : Beta_Node_ID; T : Token);
   procedure Right_Activate (B : Beta_Node_ID; F : WME);
   procedure Add_To_Beta_Memory (B : Beta_Node_ID; T : Token);
   function Evaluate_Condition (Cond : Join_Condition; T : Token; F : WME) return Boolean;

   -- =========================================================================
   -- Symbol Conversions
   -- =========================================================================

   function To_Symbol (S : String) return Symbol is
   begin
      return (Value => To_Unbounded_String (S));
   end To_Symbol;

   function To_String (S : Symbol) return String is
   begin
      return To_String (S.Value);
   end To_String;

   function "=" (Left, Right : Symbol) return Boolean is
   begin
      return Left.Value = Right.Value;
   end "=";

   function Empty_Symbol return Symbol is
   begin
      return (Value => Null_Unbounded_String);
   end Empty_Symbol;

   -- =========================================================================
   -- Token Inspection
   -- =========================================================================

   function Get_Token_Size (T : Token) return Natural is
   begin
      return T.Size;
   end Get_Token_Size;

   function Get_Token_Element (T : Token; Index : Positive) return WME is
   begin
      return T.Elements (Index);
   end Get_Token_Element;

   -- =========================================================================
   -- Configuration & Initialization
   -- =========================================================================

   procedure Initialize_Network is
   begin
      Alpha_Count := 0;
      Beta_Count := 0;
      Rule_Count := 0;
      Global_WM.Count := 0;

      for A in 1 .. Max_Nodes loop
         Alpha_Nodes (Alpha_Node_ID (A)).Memory.Count := 0;
      end loop;

      for B in 1 .. Max_Nodes loop
         Beta_Nodes (Beta_Node_ID (B)).Memory.Count := 0;
      end loop;
   end Initialize_Network;

   function Add_Alpha_Node (Attribute : Symbol; Value : Symbol) return Alpha_Node_ID is
   begin
      if Alpha_Count >= Max_Nodes then
         raise Network_Full;
      end if;
      Alpha_Count := Alpha_Count + 1;
      Alpha_Nodes (Alpha_Node_ID (Alpha_Count)) := 
        (Attribute => Attribute, Value => Value, Memory => (Count => 0, Items => [others => <>]));
      return Alpha_Node_ID (Alpha_Count);
   end Add_Alpha_Node;

   function Add_Beta_Node (
      Parent_Beta  : Beta_Node_ID;
      Parent_Alpha : Alpha_Node_ID;
      Condition    : Join_Condition
   ) return Beta_Node_ID is
   begin
      if Beta_Count >= Max_Nodes then
         raise Network_Full;
      end if;
      Beta_Count := Beta_Count + 1;
      Beta_Nodes (Beta_Node_ID (Beta_Count)) :=
        (Parent_Beta  => Parent_Beta,
         Parent_Alpha => Parent_Alpha,
         Condition    => Condition,
         Memory       => (Count => 0, Items => [others => <>]));
      return Beta_Node_ID (Beta_Count);
   end Add_Beta_Node;

   procedure Add_Rule (ID : Rule_ID; Name : Symbol; Beta : Beta_Node_ID) is
   begin
      if Rule_Count >= Max_Nodes then
         raise Network_Full;
      end if;
      Rule_Count := Rule_Count + 1;
      Rules (Rule_Count) := (ID => ID, Name => Name, Beta_ID => Beta);
   end Add_Rule;

   -- =========================================================================
   -- Rete Propagation Engine
   -- =========================================================================

   function Evaluate_Condition (Cond : Join_Condition; T : Token; F : WME) return Boolean is
      L_Str, R_Str : Symbol;
      Target_WME   : WME;
   begin
      -- Zero indicates a cross join (no specific attribute binding needed)
      if Cond.Left_Token_Index = 0 then
         return True;
      end if;

      if Cond.Left_Token_Index > T.Size then
         return False;
      end if;

      Target_WME := T.Elements (Cond.Left_Token_Index);

      case Cond.Left_Field is
         when Select_Entity    => L_Str := Target_WME.Entity;
         when Select_Attribute => L_Str := Target_WME.Attribute;
         when Select_Value     => L_Str := Target_WME.Value;
      end case;

      case Cond.Right_Field is
         when Select_Entity    => R_Str := F.Entity;
         when Select_Attribute => R_Str := F.Attribute;
         when Select_Value     => R_Str := F.Value;
      end case;

      return L_Str = R_Str;
   end Evaluate_Condition;

   procedure Add_To_Beta_Memory (B : Beta_Node_ID; T : Token) is
   begin
      if Beta_Nodes (B).Memory.Count >= Max_Nodes then
         raise Network_Full;
      end if;
      Beta_Nodes (B).Memory.Count := Beta_Nodes (B).Memory.Count + 1;
      Beta_Nodes (B).Memory.Items (Beta_Nodes (B).Memory.Count) := T;
   end Add_To_Beta_Memory;

   procedure Left_Activate (B : Beta_Node_ID; T : Token) is
      Alpha_Mem : WME_List renames Alpha_Nodes (Beta_Nodes (B).Parent_Alpha).Memory;
   begin
      -- Join new Token T with all WMEs in matching Alpha Node's Memory
      for I in 1 .. Alpha_Mem.Count loop
         declare
            F : constant WME := Alpha_Mem.Items (I);
         begin
            if Evaluate_Condition (Beta_Nodes (B).Condition, T, F) then
               declare
                  New_T : Token := T;
               begin
                  if New_T.Size >= Max_WMEs_Per_Token then
                     raise Network_Full;
                  end if;
                  New_T.Size := New_T.Size + 1;
                  New_T.Elements (New_T.Size) := F;
                  
                  Add_To_Beta_Memory (B, New_T);
                  
                  -- Propagate activation downwards
                  for Child in 1 .. Beta_Node_ID (Beta_Count) loop
                     if Beta_Nodes (Child).Parent_Beta = B then
                        Left_Activate (Child, New_T);
                     end if;
                  end loop;
               end;
            end if;
         end;
      end loop;
   end Left_Activate;

   procedure Right_Activate (B : Beta_Node_ID; F : WME) is
   begin
      if Beta_Nodes (B).Parent_Beta = 0 then
         -- Implicit join with Root node's empty token
         declare
            Empty_T : constant Token := (Size => 0, Elements => [others => (ID => Null_WME_ID, others => Empty_Symbol)]);
         begin
            if Evaluate_Condition (Beta_Nodes (B).Condition, Empty_T, F) then
               declare
                  New_T : Token := Empty_T;
               begin
                  New_T.Size := 1;
                  New_T.Elements (1) := F;
                  
                  Add_To_Beta_Memory (B, New_T);
                  
                  for Child in 1 .. Beta_Node_ID (Beta_Count) loop
                     if Beta_Nodes (Child).Parent_Beta = B then
                        Left_Activate (Child, New_T);
                     end if;
                  end loop;
               end;
            end if;
         end;
      else
         -- Join new Fact F with all Tokens in Parent Beta Node's Memory
         declare
            Parent_Mem : Token_List renames Beta_Nodes (Beta_Nodes (B).Parent_Beta).Memory;
         begin
            for I in 1 .. Parent_Mem.Count loop
               declare
                  T : constant Token := Parent_Mem.Items (I);
               begin
                  if Evaluate_Condition (Beta_Nodes (B).Condition, T, F) then
                     declare
                        New_T : Token := T;
                     begin
                        if New_T.Size >= Max_WMEs_Per_Token then
                           raise Network_Full;
                        end if;
                        New_T.Size := New_T.Size + 1;
                        New_T.Elements (New_T.Size) := F;
                        
                        Add_To_Beta_Memory (B, New_T);
                        
                        for Child in 1 .. Beta_Node_ID (Beta_Count) loop
                           if Beta_Nodes (Child).Parent_Beta = B then
                              Left_Activate (Child, New_T);
                           end if;
                        end loop;
                     end;
                  end if;
               end;
            end loop;
         end;
      end if;
   end Right_Activate;

   -- =========================================================================
   -- Dynamic Operations
   -- =========================================================================

   procedure Insert_WME (Fact : WME) is
   begin
      -- Consistency check
      for I in 1 .. Global_WM.Count loop
         if Global_WM.Items (I).ID = Fact.ID then
            raise Duplicate_ID;
         end if;
      end loop;

      if Global_WM.Count >= Max_Nodes then
         raise Network_Full;
      end if;

      Global_WM.Count := Global_WM.Count + 1;
      Global_WM.Items (Global_WM.Count) := Fact;

      -- Activate Alpha Nodes based on literal checks
      for A in 1 .. Alpha_Node_ID (Alpha_Count) loop
         if Alpha_Nodes (A).Attribute = Fact.Attribute and then
            Alpha_Nodes (A).Value = Fact.Value then
            
            if Alpha_Nodes (A).Memory.Count >= Max_Nodes then
               raise Network_Full;
            end if;
            
            Alpha_Nodes (A).Memory.Count := Alpha_Nodes (A).Memory.Count + 1;
            Alpha_Nodes (A).Memory.Items (Alpha_Nodes (A).Memory.Count) := Fact;

            -- Propagate Right Activation
            for B in 1 .. Beta_Node_ID (Beta_Count) loop
               if Beta_Nodes (B).Parent_Alpha = A then
                  Right_Activate (B, Fact);
               end if;
            end loop;
         end if;
      end loop;
   end Insert_WME;

   procedure Insert_WME_Batched (Facts : WME_Array) is
   begin
      for I in Facts'Range loop
         Insert_WME (Facts (I));
      end loop;
   end Insert_WME_Batched;

   procedure Remove_WME (ID : WME_ID) is
      Found : Boolean := False;
   begin
      -- 1. Remove from Global Memory
      for I in 1 .. Global_WM.Count loop
         if Global_WM.Items (I).ID = ID then
            Found := True;
            for J in I .. Global_WM.Count - 1 loop
               Global_WM.Items (J) := Global_WM.Items (J + 1);
            end loop;
            Global_WM.Count := Global_WM.Count - 1;
            exit;
         end if;
      end loop;

      if not Found then
         raise Fact_Not_Found;
      end if;

      -- 2. Sweep Alpha Memories
      for A in 1 .. Alpha_Node_ID (Alpha_Count) loop
         declare
            I : Positive := 1;
         begin
            while I <= Alpha_Nodes (A).Memory.Count loop
               if Alpha_Nodes (A).Memory.Items (I).ID = ID then
                  for J in I .. Alpha_Nodes (A).Memory.Count - 1 loop
                     Alpha_Nodes (A).Memory.Items (J) := Alpha_Nodes (A).Memory.Items (J + 1);
                  end loop;
                  Alpha_Nodes (A).Memory.Count := Alpha_Nodes (A).Memory.Count - 1;
                  exit; -- Safe to exit as ID is unique per alpha memory
               else
                  I := I + 1;
               end if;
            end loop;
         end;
      end loop;

      -- 3. Sweep Beta Memories (Remove any Token containing the removed WME)
      for B in 1 .. Beta_Node_ID (Beta_Count) loop
         declare
            I : Positive := 1;
         begin
            while I <= Beta_Nodes (B).Memory.Count loop
               declare
                  T_Has_ID : Boolean := False;
                  T : Token renames Beta_Nodes (B).Memory.Items (I);
               begin
                  for K in 1 .. T.Size loop
                     if T.Elements (K).ID = ID then
                        T_Has_ID := True;
                        exit;
                     end if;
                  end loop;

                  if T_Has_ID then
                     for J in I .. Beta_Nodes (B).Memory.Count - 1 loop
                        Beta_Nodes (B).Memory.Items (J) := Beta_Nodes (B).Memory.Items (J + 1);
                     end loop;
                     Beta_Nodes (B).Memory.Count := Beta_Nodes (B).Memory.Count - 1;
                     -- Do not increment I, check shifted item
                  else
                     I := I + 1;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Remove_WME;

   -- =========================================================================
   -- Accessors
   -- =========================================================================

   function Get_Global_WM_Count return Natural is
   begin
      return Global_WM.Count;
   end Get_Global_WM_Count;

   function Get_Alpha_Match_Count (Alpha : Alpha_Node_ID) return Natural is
   begin
      return Alpha_Nodes (Alpha).Memory.Count;
   end Get_Alpha_Match_Count;

   function Get_Beta_Match_Count (Beta : Beta_Node_ID) return Natural is
   begin
      return Beta_Nodes (Beta).Memory.Count;
   end Get_Beta_Match_Count;

   function Get_Rule_Match_Count (Rule : Rule_ID) return Natural is
   begin
      for I in 1 .. Rule_Count loop
         if Rules (I).ID = Rule then
            return Beta_Nodes (Rules (I).Beta_ID).Memory.Count;
         end if;
      end loop;
      return 0;
   end Get_Rule_Match_Count;

end Rete;
