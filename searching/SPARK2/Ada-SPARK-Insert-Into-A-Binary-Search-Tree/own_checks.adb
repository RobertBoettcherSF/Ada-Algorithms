--  Own tests for Insert_Into_A_Binary_Search_Tree.Insert (written for this
--  repository; see tests/SOURCES.txt). Assumption: Insert links the new
--  node in the wrong place, loses or rewires existing nodes, or breaks
--  the search order. Reference: an independent BST in this file, built
--  from heap nodes by recursive insertion (smaller values left, equal or
--  larger right), that records each value's node id. After every Insert
--  the package tree must have the same root and, for every inserted node,
--  the same value and the same left / right child ids as the reference;
--  an in-order walk must give the inserted values in nondecreasing order
--  with the same occurrence counts, and Well_Formed must hold.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Insert_Into_A_Binary_Search_Tree; use Insert_Into_A_Binary_Search_Tree;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   --  Fixed default seed, printed at start; AA_SEED overrides it.
   subtype Seed_Range is Long_Long_Integer range 1 .. 2_147_483_646;
   Default_Seed : constant Seed_Range := 20_261_008;
   function Initial_Seed return Seed_Range is
     (if Ada.Environment_Variables.Exists ("AA_SEED")
      then Seed_Range'Value (Ada.Environment_Variables.Value ("AA_SEED"))
      else Default_Seed);
   Seed : Long_Long_Integer := Initial_Seed;
   function Next (Lo, Hi : Long_Long_Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Lo + Seed mod (Hi - Lo + 1));
   end Next;

   --  Reference BST on the heap.
   type Ref_Node;
   type Ref_Ptr is access Ref_Node;
   type Ref_Node is record
      Id          : Node_Index;
      V           : Value;
      Left, Right : Ref_Ptr;
   end record;

   procedure Ref_Insert (P : in out Ref_Ptr; Id : Node_Index; V : Value) is
   begin
      if P = null then
         P := new Ref_Node'(Id => Id, V => V, Left => null, Right => null);
      elsif V < P.V then
         Ref_Insert (P.Left, Id, V);
      else
         Ref_Insert (P.Right, Id, V);
      end if;
   end Ref_Insert;

   function Id_Of (P : Ref_Ptr) return Index is (if P = null then 0 else P.Id);

   --  Package tree agrees with the reference below P.
   function Same (T : Tree; P : Ref_Ptr) return Boolean is
     (P = null
      or else (Is_Used (T, P.Id) and then Value_Of (T, P.Id) = P.V
               and then Left_Of (T, P.Id) = Id_Of (P.Left)
               and then Right_Of (T, P.Id) = Id_Of (P.Right)
               and then Same (T, P.Left) and then Same (T, P.Right)));

   type Value_List is array (1 .. 16) of Value;

   procedure Walk (T : Tree; N : Index; Out_V : in out Value_List;
                   Count : in out Natural; Ok : in out Boolean;
                   Depth : Natural) is
   begin
      if N = 0 then
         return;
      end if;
      if Depth > 16 or else Count >= 16 or else not Is_Used (T, N) then
         Ok := False;   --  cycle, too many nodes, or a dangling link
         return;
      end if;
      Walk (T, Left_Of (T, N), Out_V, Count, Ok, Depth + 1);
      if Ok and then Count < 16 then
         Count := Count + 1;
         Out_V (Count) := Value_Of (T, N);
         Walk (T, Right_Of (T, N), Out_V, Count, Ok, Depth + 1);
      else
         Ok := False;
      end if;
   end Walk;

   --  Copy the reference tree below P into T with Set_Node, children
   --  before parents or parents before children (Parents_First).
   procedure Copy (T : in out Tree; P : Ref_Ptr; Parents_First : Boolean) is
   begin
      if P /= null then
         if Parents_First then
            Set_Node (T, P.Id, P.V, Id_Of (P.Left), Id_Of (P.Right));
         end if;
         Copy (T, P.Left, Parents_First);
         Copy (T, P.Right, Parents_First);
         if not Parents_First then
            Set_Node (T, P.Id, P.V, Id_Of (P.Left), Id_Of (P.Right));
         end if;
      end if;
   end Copy;

   --  Insert Vals (I) as node Ids (I), one by one, checking after each.
   --  The first Pre_Built pairs are not inserted: the reference inserts
   --  them and the package tree gets them through Set_Node.
   procedure Run (Ids : Value_List; Vals : Value_List; N : Natural;
                  What : String; Pre_Built : Natural := 0;
                  Parents_First : Boolean := True) is
      T     : Tree := Empty;
      Root  : Index := 0;
      Ref   : Ref_Ptr := null;
      Ok    : Boolean := True;
   begin
      for I in 1 .. Pre_Built loop
         Ref_Insert (Ref, Node_Index (Ids (I)), Vals (I));
      end loop;
      Copy (T, Ref, Parents_First);
      Root := Id_Of (Ref);
      if Pre_Built > 0 then
         --  The copy itself must match, and unused nodes must still be 0.
         for Id in Node_Index loop
            declare
               In_Ref : constant Boolean :=
                 (for some I in 1 .. Pre_Built => Ids (I) = Id);
            begin
               if Is_Used (T, Id) /= In_Ref
                 or else (not In_Ref and then
                          (Value_Of (T, Id) /= 0 or else Left_Of (T, Id) /= 0
                           or else Right_Of (T, Id) /= 0))
               then
                  Ok := False;
               end if;
            end;
         end loop;
         if not Same (T, Ref) or else not Well_Formed (T, Root) then
            Ok := False;
         end if;
      end if;
      for I in Pre_Built + 1 .. N loop
         declare
            Id : constant Node_Index := Node_Index (Ids (I));
         begin
            Insert (T, Root, Id, Vals (I));
            Ref_Insert (Ref, Id, Vals (I));
            declare
               Got   : Value_List := [others => 0];
               Count : Natural := 0;
               W_Ok  : Boolean := True;
            begin
               Walk (T, Root, Got, Count, W_Ok, 0);
               if Root /= Id_Of (Ref) or else not Same (T, Ref)
                 or else not Well_Formed (T, Root)
                 or else not W_Ok or else Count /= I
               then
                  Ok := False;
               else
                  for K in 1 .. Count - 1 loop
                     if Got (K) > Got (K + 1) then
                        Ok := False;
                     end if;
                  end loop;
                  for K in 1 .. I loop
                     declare
                        C_Got, C_In : Natural := 0;
                     begin
                        for J in 1 .. Count loop
                           if Got (J) = Vals (K) then
                              C_Got := C_Got + 1;
                           end if;
                        end loop;
                        for J in 1 .. I loop
                           if Vals (J) = Vals (K) then
                              C_In := C_In + 1;
                           end if;
                        end loop;
                        if C_Got /= C_In then
                           Ok := False;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end;
         exit when not Ok;
      end loop;
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("FAIL Insert (" & What & "): ids/values");
            for I in 1 .. N loop
               Put (Ids (I)'Image & "/" & Vals (I)'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Run;

   Ids, Vals : Value_List;
begin
   Put_Line ("own checks seed:" & Seed'Image & " (default"
             & Default_Seed'Image & "; set AA_SEED to override)");
   --  0. Empty: no node used, every value and link 0.
   declare
      E : constant Tree := Empty;
   begin
      Cases := Cases + 1;
      for Id in Node_Index loop
         if Is_Used (E, Id) or else Value_Of (E, Id) /= 0
           or else Left_Of (E, Id) /= 0 or else Right_Of (E, Id) /= 0
         then
            Failures := Failures + 1;
            Put_Line ("FAIL Empty: node" & Id'Image & " not empty");
         end if;
      end loop;
   end;
   --  1. Every value sequence of length 1 .. 6 over {-1, 0, 1} (1,092;
   --     equal values go right), nodes 1 .. n in order.
   Ids := [for I in 1 .. 16 => I];
   for Len in 1 .. 6 loop
      for Code in 0 .. 3 ** Len - 1 loop
         for I in 1 .. Len loop
            Vals (I) := (Code / 3 ** (I - 1)) mod 3 - 1;
         end loop;
         Run (Ids, Vals, Len, "ternary");
      end loop;
   end loop;
   --  2. Every insertion order of 1 .. 6 (720), node ids in reverse.
   declare
      P : Value_List := [for I in 1 .. 16 => I];
      C : array (1 .. 6) of Natural := [others => 0];
      I : Positive := 2;
      T : Integer;
   begin
      Ids := [for I in 1 .. 16 => 17 - I];
      Run (Ids, P, 6, "permutation");
      while I <= 6 loop
         if C (I) < I - 1 then
            if I mod 2 = 1 then
               T := P (1); P (1) := P (I); P (I) := T;
            else
               T := P (C (I) + 1); P (C (I) + 1) := P (I); P (I) := T;
            end if;
            Run (Ids, P, 6, "permutation");
            C (I) := C (I) + 1;
            I := 2;
         else
            C (I) := 0;
            I := I + 1;
         end if;
      end loop;
   end;
   --  3. 3,000 random runs: up to all 16 nodes in a random id order, values
   --     from a random range (narrow ranges give many equal values).
   for K in 1 .. 3_000 loop
      declare
         N     : constant Integer := Next (1, 16);
         Width : constant Integer := Next (0, 100);
      begin
         Ids := [for I in 1 .. 16 => I];
         for I in reverse 2 .. 16 loop
            declare
               J : constant Integer := Next (1, Long_Long_Integer (I));
               X : constant Integer := Ids (I);
            begin
               Ids (I) := Ids (J);
               Ids (J) := X;
            end;
         end loop;
         for I in 1 .. N loop
            Vals (I) := Next (Long_Long_Integer (-Width), Long_Long_Integer (Width));
         end loop;
         Run (Ids, Vals, N, "random" & K'Image);
      end;
   end loop;
   --  4. 1,000 random runs where the first nodes are copied in with
   --     Set_Node (parents first or children first) and the rest inserted.
   for K in 1 .. 1_000 loop
      declare
         N     : constant Integer := Next (1, 16);
         Pre   : constant Integer := Next (1, Long_Long_Integer (N));
         Width : constant Integer := Next (0, 100);
      begin
         Ids := [for I in 1 .. 16 => I];
         for I in reverse 2 .. 16 loop
            declare
               J : constant Integer := Next (1, Long_Long_Integer (I));
               X : constant Integer := Ids (I);
            begin
               Ids (I) := Ids (J);
               Ids (J) := X;
            end;
         end loop;
         for I in 1 .. N loop
            Vals (I) := Next (Long_Long_Integer (-Width), Long_Long_Integer (Width));
         end loop;
         Run (Ids, Vals, N, "Set_Node + random" & K'Image, Pre, K mod 2 = 0);
      end;
   end loop;
   --  5. Full 16-node shapes: ascending and descending chains (path of
   --     15 links), all equal, extremes -100 / 100 alternating, zig-zag.
   Ids := [for I in 1 .. 16 => I];
   Run (Ids, [for I in 1 .. 16 => I * 6 - 100], 16, "ascending chain");
   Run (Ids, [for I in 1 .. 16 => 100 - I * 6], 16, "descending chain");
   Run (Ids, [others => 7], 16, "all equal");
   Run (Ids, [for I in 1 .. 16 => (if I mod 2 = 0 then 100 else -100)], 16,
        "extremes");
   Run (Ids, [for I in 1 .. 16 => (if I mod 2 = 0 then I else -I)], 16,
        "zig-zag");

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image
             & " insertion runs (reference BST shape + in-order + Well_Formed)");
end Own_Checks;
