--  Standalone test suite for Transitive_Closure (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Transitive_Closure; use Transitive_Closure;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Nat (X : Natural) return Natural is (X);
   function Vid (X : Integer) return Vertex_Id is (Vertex_Id (X));

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; From, To : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, From, To);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Has_Raises
     (G : Graph; From, To : Vertex_Id) return Boolean
   is
      B : Boolean;
   begin
      B := Has_Edge (G, From, To);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Has_Raises;

   function Warshall_Raises
     (G : Graph; Last : Positive; Reflexive : Boolean) return Boolean
   is
      C : Bool_Matrix (1 .. Vertex_Id (Last), 1 .. Vertex_Id (Last));
   begin
      Warshall (G, C, Reflexive);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Warshall_Raises;

   function DFS_Raises (G : Graph; Last : Positive) return Boolean is
      C : Bool_Matrix (1 .. Vertex_Id (Last), 1 .. Vertex_Id (Last));
   begin
      Reachability_DFS (G, C, False);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end DFS_Raises;

   function BFS_Raises (G : Graph; Last : Positive) return Boolean is
      C : Bool_Matrix (1 .. Vertex_Id (Last), 1 .. Vertex_Id (Last));
   begin
      Reachability_BFS (G, C, False);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end BFS_Raises;

   function Reaches_Raises
     (G : Graph; From, To : Vertex_Id) return Boolean
   is
      B : Boolean;
   begin
      B := Reaches (G, From, To);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reaches_Raises;

   function Rel_Raises (G : Graph; Last : Positive) return Boolean is
      M : Bool_Matrix (1 .. Vertex_Id (Last), 1 .. Vertex_Id (Last));
   begin
      Relation_Matrix (G, M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Rel_Raises;

   function Matrices_Equal
     (A, B : Bool_Matrix; N : Positive) return Boolean
   is
   begin
      for I in 1 .. Vertex_Id (N) loop
         for J in 1 .. Vertex_Id (N) loop
            if A (I, J) /= B (I, J) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Matrices_Equal;

   function IT_Raises_Zero return Boolean is
      M : constant Bool_Matrix (Vertex_Id, Vertex_Id) :=
        [others => [others => False]];
      B : Boolean;
   begin
      B := Is_Transitive (M, 0);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end IT_Raises_Zero;

   function IT_Raises_Bounds return Boolean is
      M : constant Bool_Matrix (2 .. 4, 2 .. 4) :=
        [others => [others => False]];
      B : Boolean;
   begin
      B := Is_Transitive (M, 3);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end IT_Raises_Bounds;

   function WOM_Raises_Bounds return Boolean is
      R : constant Bool_Matrix (2 .. 3, 2 .. 3) :=
        [others => [others => False]];
      C : Bool_Matrix (2 .. 3, 2 .. 3);
   begin
      Warshall_On_Matrix (R, C, False);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end WOM_Raises_Bounds;

   function WOM_Mismatch return Boolean is
      R : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [others => [others => False]];
      C : Bool_Matrix (1 .. 3, 1 .. 3);
   begin
      Warshall_On_Matrix (R, C, False);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end WOM_Mismatch;

   G             : Graph;
   Cw, Cd, Cb, M : Bool_Matrix (Vertex_Id, Vertex_Id);
   R3, C3        : Bool_Matrix (1 .. 3, 1 .. 3);
   N             : Positive;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / capacity / guards");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear > Max raises");
   Check (Clear_Raises (Nat (Max_Vertices + 50)), "Clear far over raises");
   Check (Warshall_Raises (G, Max_Vertices, False), "empty Warshall raises");
   Check (DFS_Raises (G, Max_Vertices), "empty DFS raises");
   Check (BFS_Raises (G, Max_Vertices), "empty BFS raises");
   Check (Reaches_Raises (G, 1, 1), "empty Reaches raises");
   Check (Has_Raises (G, 1, 1), "empty Has_Edge raises");
   Check (Rel_Raises (G, Max_Vertices), "empty Relation_Matrix raises");
   Check (IT_Raises_Zero, "Is_Transitive N=0 raises");

   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear at Max_Vertices ok");
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "re-clear to empty");

   ------------------------------------------------------------------
   Section ("2. Single vertex");
   ------------------------------------------------------------------
   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   Check (not Has_Edge (G, 1, 1), "single no self-loop");
   Check (not Reaches (G, 1, 1), "single R+ not reflexive");
   Check (Reaches (G, 1, 1, True), "single R* reflexive");

   Warshall (G, Cw, False);
   Check (not Cw (1, 1), "Warshall R+ single False");
   Warshall (G, Cw, True);
   Check (Cw (1, 1), "Warshall R* single True");
   Reachability_DFS (G, Cd, False);
   Check (not Cd (1, 1), "DFS R+ single False");
   Reachability_BFS (G, Cb, True);
   Check (Cb (1, 1), "BFS R* single True");
   Check (Is_Transitive (Cw, 1), "R* single transitive");

   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Check (Has_Edge (G, 1, 1), "self-loop present");
   Check (Reaches (G, 1, 1), "self-loop R+ reaches self");
   Warshall (G, Cw, False);
   Check (Cw (1, 1), "Warshall self-loop R+");
   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "idempotent Add_Edge");

   ------------------------------------------------------------------
   Section ("3. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   Check (not Reaches (G, 1, 2), "2 isolated no path");
   Check (not Reaches (G, 2, 1), "2 isolated reverse");
   Warshall (G, Cw, False);
   Check (not Cw (1, 2) and not Cw (2, 1), "2 isolated Warshall");
   Check (Is_Transitive (Cw, 2), "empty relation transitive");

   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 1, "2-vert one edge");
   Check (Has_Edge (G, 1, 2), "has 1→2");
   Check (not Has_Edge (G, 2, 1), "no 2→1");
   Check (Reaches (G, 1, 2), "reaches 1→2");
   Check (not Reaches (G, 2, 1), "no reverse reach");
   Check (not Reaches (G, 1, 1), "no cycle yet");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cd, 2), "Warshall≡DFS two-vert");
   Check (Matrices_Equal (Cw, Cb, 2), "Warshall≡BFS two-vert");
   Check (Cw (1, 2) and not Cw (2, 1), "closure 1→2 only");
   Relation_Matrix (G, M);
   Check (Is_Transitive (M, 2), "single arc is transitive");

   Add_Edge (G, 2, 1);
   Check (Reaches (G, 1, 1), "mutual cycle 1→1");
   Check (Reaches (G, 2, 2), "mutual cycle 2→2");
   Warshall (G, Cw, False);
   Check (Cw (1, 1) and Cw (2, 2) and Cw (1, 2) and Cw (2, 1),
          "2-cycle full R+");

   ------------------------------------------------------------------
   Section ("4. Directed chain");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Check (Edge_Count (G) = 4, "chain edge count");
   Check (Reaches (G, 1, 5), "chain 1 reaches 5");
   Check (Reaches (G, 2, 5), "chain 2 reaches 5");
   Check (not Reaches (G, 5, 1), "chain no reverse");
   Check (not Reaches (G, 3, 1), "chain 3 no 1");
   Check (Reaches (G, 1, 3), "chain 1 reaches 3");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Reachability_BFS (G, Cb, False);
   Check (Matrices_equal (Cw, Cd, 5), "chain Warshall≡DFS");
   Check (Matrices_Equal (Cw, Cb, 5), "chain Warshall≡BFS");
   Check (Cw (1, 5) and Cw (1, 4) and Cw (1, 2), "chain row 1");
   Check (not Cw (5, 4), "chain no back");
   Check (not Cw (1, 1), "chain irreflexive R+");
   Warshall (G, Cw, True);
   Check (Cw (1, 1) and Cw (5, 5), "chain R* diagonal");
   Check (Is_Transitive (Cw, 5), "chain R* transitive");
   Relation_Matrix (G, M);
   Check (not Is_Transitive (M, 5), "raw chain not transitive");

   ------------------------------------------------------------------
   Section ("5. DAG diamond");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Check (Reaches (G, 1, 4), "diamond 1→4");
   Check (not Reaches (G, 2, 3), "diamond 2 not→3");
   Check (not Reaches (G, 4, 1), "diamond no reverse");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cd, 4), "diamond Warshall≡DFS");
   Check (Cw (1, 2) and Cw (1, 3) and Cw (1, 4), "diamond from 1");
   Check (Cw (2, 4) and Cw (3, 4), "diamond mids to 4");
   Closure_Matrix (G, Cb, False);
   Check (Matrices_Equal (Cw, Cb, 4), "Closure_Matrix = Warshall");

   ------------------------------------------------------------------
   Section ("6. Cycles");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cd, 3), "3-cycle Warshall≡DFS");
   Check (Matrices_Equal (Cw, Cb, 3), "3-cycle Warshall≡BFS");
   Check (Cw (1, 1) and Cw (2, 2) and Cw (3, 3), "3-cycle diagonals R+");
   Check (Cw (1, 2) and Cw (1, 3) and Cw (2, 1), "3-cycle complete");
   Check (Reaches (G, 2, 2), "cycle Reaches self");
   Check (Is_Transitive (Cw, 3), "3-cycle R+ transitive");
   Relation_Matrix (G, M);
   Check (not Is_Transitive (M, 3), "raw 3-cycle not transitive");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Check (Reaches (G, 1, 4), "pendant from cycle");
   Check (Reaches (G, 1, 1), "cycle self via 2");
   Check (not Reaches (G, 4, 1), "pendant no return");
   Warshall (G, Cw, False);
   Check (Cw (1, 4) and Cw (2, 4) and not Cw (4, 3), "pendant closure");

   ------------------------------------------------------------------
   Section ("7. Complete digraph");
   ------------------------------------------------------------------
   Clear (G, 4);
   for I in 1 .. Vid (4) loop
      for J in 1 .. Vid (4) loop
         if I /= J then
            Add_Edge (G, I, J);
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "K4 directed no loops edges");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Check (Matrices_equal (Cw, Cd, 4), "complete Warshall≡DFS");
   Check (Cw (1, 1) and Cw (2, 3) and Cw (4, 1), "complete sample cells");
   Check (Cw (1, 2) and Cw (1, 3) and Cw (1, 4), "complete from 1");
   Check (Cw (2, 1) and Cw (3, 1) and Cw (4, 2), "complete cross");
   Check (Cw (3, 4) and Cw (4, 3) and Cw (2, 4), "complete more");
   Check (Cw (3, 2) and Cw (4, 4) and Cw (2, 2), "complete diagonals via paths");

   ------------------------------------------------------------------
   Section ("8. Reflexive vs irreflexive");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Warshall (G, Cw, False);
   Warshall (G, Cd, True);
   Check (not Cw (1, 1) and not Cw (2, 2) and not Cw (3, 3),
          "R+ no forced diagonal");
   Check (Cd (1, 1) and Cd (2, 2) and Cd (3, 3), "R* forced diagonal");
   Check (Cw (1, 3) and Cd (1, 3), "both reach 1→3");
   Check (Reaches (G, 2, 2, True), "Reaches reflexive shortcut");
   Check (not Reaches (G, 2, 2, False), "Reaches irreflexive no loop");
   Reachability_BFS (G, Cb, True);
   Check (Matrices_Equal (Cd, Cb, 3), "R* Warshall≡BFS");
   Reachability_DFS (G, Cb, True);
   Check (Matrices_Equal (Cd, Cb, 3), "R* Warshall≡DFS");

   ------------------------------------------------------------------
   Section ("9. Warshall_On_Matrix / Is_Transitive");
   ------------------------------------------------------------------
   for I in 1 .. Vid (3) loop
      for J in 1 .. Vid (3) loop
         R3 (I, J) := False;
      end loop;
   end loop;
   R3 (1, 2) := True;
   R3 (2, 3) := True;
   Check (not Is_Transitive (R3, 3), "missing hop not transitive");
   Warshall_On_Matrix (R3, C3, False);
   Check (C3 (1, 3), "matrix Warshall fills 1→3");
   Check (C3 (1, 2) and C3 (2, 3), "matrix Warshall keeps arcs");
   Check (Is_Transitive (C3, 3), "closed matrix is transitive");
   Warshall_On_Matrix (R3, C3, True);
   Check (C3 (1, 1) and C3 (2, 2) and C3 (3, 3), "matrix Warshall R* diag");

   for I in 1 .. Vid (3) loop
      for J in 1 .. Vid (3) loop
         R3 (I, J) := (I = J);
      end loop;
   end loop;
   Check (Is_Transitive (R3, 3), "identity transitive");

   for I in 1 .. Vid (3) loop
      for J in 1 .. Vid (3) loop
         R3 (I, J) := True;
      end loop;
   end loop;
   Check (Is_Transitive (R3, 3), "full relation transitive");

   ------------------------------------------------------------------
   Section ("10. Disconnected components");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Check (Reaches (G, 1, 3), "comp A reach");
   Check (Reaches (G, 4, 5), "comp B reach");
   Check (not Reaches (G, 1, 5), "no cross A→B");
   Check (not Reaches (G, 4, 3), "no cross B→A");
   Check (not Reaches (G, 6, 1), "isolated 6");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cd, 6), "disconnected Warshall≡DFS");
   Check (not Cw (3, 1) and not Cw (5, 4), "no reverse comps");
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cb, 6), "disconnected Warshall≡BFS");

   ------------------------------------------------------------------
   Section ("11. Star / in-star");
   ------------------------------------------------------------------
   Clear (G, 5);
   for J in 2 .. Vid (5) loop
      Add_Edge (G, 1, J);
   end loop;
   Check (Edge_Count (G) = 4, "out-star edges");
   Warshall (G, Cw, False);
   Check (Cw (1, 2) and Cw (1, 3) and Cw (1, 4) and Cw (1, 5),
          "out-star hub reaches leaves");
   Check (not Cw (2, 1) and not Cw (5, 1), "out-star leaf no hub");
   Check (not Cw (2, 3), "out-star no leaf-leaf");

   Clear (G, 5);
   for I in 2 .. Vid (5) loop
      Add_Edge (G, I, 1);
   end loop;
   Check (Reaches (G, 3, 1), "in-star leaf→hub");
   Check (not Reaches (G, 1, 3), "in-star hub no leaf");
   Warshall (G, Cw, False);
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cb, 5), "in-star Warshall≡BFS");
   Check (Cw (2, 1) and Cw (5, 1) and not Cw (1, 1), "in-star cells");

   ------------------------------------------------------------------
   Section ("12. Self-loops mixed");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 2, 3);
   Check (Reaches (G, 2, 2), "explicit self-loop");
   Check (not Reaches (G, 1, 1), "1 no cycle");
   Check (Reaches (G, 1, 3), "through self-loop vertex");
   Warshall (G, Cw, False);
   Check (Cw (2, 2) and not Cw (1, 1) and not Cw (3, 3), "only mid diagonal");
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cd, 3), "self-loop Warshall≡DFS");

   ------------------------------------------------------------------
   Section ("13. Larger chain / grid");
   ------------------------------------------------------------------
   N := 12;
   Clear (G, N);
   for I in 1 .. Vid (N - 1) loop
      Add_Edge (G, I, Vertex_Id (Natural (I) + 1));
   end loop;
   Check (Reaches (G, 1, Vid (N)), "long chain end");
   Check (not Reaches (G, Vid (N), 1), "long chain no back");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cd, N), "long Warshall≡DFS");
   Check (Matrices_Equal (Cw, Cb, N), "long Warshall≡BFS");
   Check (Cw (1, Vid (N)) and Cw (6, 10), "long mid reaches");
   Check (not Cw (10, 6), "long no back mid");

   Clear (G, 9);
   for R in 0 .. 2 loop
      for C in 0 .. 2 loop
         declare
            V : constant Vertex_Id := Vertex_Id (R * 3 + C + 1);
         begin
            if C < 2 then
               Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
            end if;
            if R < 2 then
               Add_Edge (G, V, Vertex_Id (Natural (V) + 3));
            end if;
         end;
      end loop;
   end loop;
   Check (Reaches (G, 1, 9), "grid 1→9");
   Check (Reaches (G, 1, 5), "grid 1→5");
   Check (not Reaches (G, 9, 1), "grid no reverse");
   Check (not Reaches (G, 3, 7), "grid 3 not→7");
   Check (Reaches (G, 1, 3) and Reaches (G, 1, 7), "grid row/col");
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cd, 9), "grid Warshall≡DFS");
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cb, 9), "grid Warshall≡BFS");

   ------------------------------------------------------------------
   Section ("14. Invalid_Argument exhaustive");
   ------------------------------------------------------------------
   Clear (G, 3);
   Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");
   Check (Add_Raises (G, 1, 4), "Add_Edge To out of range");
   Check (Add_Raises (G, Vid (Max_Vertices), 1), "Add_Edge From Max on N=3");
   Check (Has_Raises (G, 4, 1), "Has_Edge bad From");
   Check (Has_Raises (G, 1, 4), "Has_Edge bad To");
   Check (Reaches_Raises (G, 4, 1), "Reaches bad From");
   Check (Reaches_Raises (G, 1, 4), "Reaches bad To");
   Check (Warshall_Raises (G, 2, False), "Warshall Last < N");
   Check (DFS_Raises (G, 2), "DFS Last < N");
   Check (BFS_Raises (G, 1), "BFS Last < N");
   Check (Rel_Raises (G, 2), "Relation_Matrix Last < N");
   Check (WOM_Raises_Bounds, "Warshall_On_Matrix First/=1 raises");
   Check (IT_Raises_Bounds, "Is_Transitive First/=1 raises");
   Check (WOM_Mismatch, "Warshall_On_Matrix size mismatch");

   Clear (G, 0);
   Check (Add_Raises (G, 1, 1), "Add_Edge on empty raises");

   ------------------------------------------------------------------
   Section ("15. Clear / rebuild / Relation_Matrix");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Relation_Matrix (G, M);
   Check (M (1, 2) and M (2, 3) and not M (1, 3), "Relation_Matrix raw");
   Check (Edge_Count (G) = 2, "before clear edges");
   Clear (G, 4);
   Check (Edge_Count (G) = 0, "after clear edges 0");
   Check (not Has_Edge (G, 1, 2), "cleared edge gone");
   Add_Edge (G, 4, 1);
   Check (Has_Edge (G, 4, 1), "rebuild edge");
   Check (Vertex_Count (G) = 4, "rebuild N");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Clear (G, 5);
   Check (Vertex_Count (G) = 5, "resize Clear");
   Check (Edge_Count (G) = 0, "resize clears edges");
   Check (not Has_Edge (G, 1, 2), "resize drops old edge");

   ------------------------------------------------------------------
   Section ("16. SCC-style mutual reachability");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Warshall (G, Cw, False);
   Check (Cw (1, 2) and Cw (2, 1) and Cw (1, 3), "SCC mutual");
   Check (Cw (1, 5) and Cw (2, 5), "SCC to sink");
   Check (not Cw (5, 1), "sink not back to SCC");
   Check (Cw (1, 1), "SCC member self via cycle");
   Check (Cw (3, 4) and Cw (3, 5) and not Cw (4, 3), "SCC exit");
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cd, 5), "SCC Warshall≡DFS");
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cb, 5), "SCC Warshall≡BFS");

   ------------------------------------------------------------------
   Section ("17. Empty relation / handcrafted");
   ------------------------------------------------------------------
   Clear (G, 8);
   Warshall (G, Cw, False);
   Check (not Cw (1, 1) and not Cw (4, 7) and not Cw (8, 8),
          "empty 8x8 sample False");
   Check (not Cw (2, 3) and not Cw (5, 1), "empty 8x8 more False");
   Warshall (G, Cw, True);
   Check (Cw (1, 1) and Cw (4, 4) and Cw (8, 8), "empty R* identity");
   Check (not Cw (1, 2) and not Cw (3, 5), "empty R* off-diag");
   Check (Is_Transitive (Cw, 8), "identity R* transitive");

   Clear (G, 7);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 5, 2);
   Add_Edge (G, 2, 7);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 6);
   Add_Edge (G, 6, 7);
   Add_Edge (G, 7, 7);
   Check (Reaches (G, 1, 7), "handcraft 1→7");
   Check (Reaches (G, 7, 7), "handcraft loop");
   Check (not Reaches (G, 7, 1), "handcraft no back");
   Check (Reaches (G, 1, 2) and Reaches (G, 1, 6), "handcraft branches");
   Warshall (G, Cw, False);
   Reachability_BFS (G, Cb, False);
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cb, 7), "handcraft Warshall≡BFS");
   Check (Matrices_Equal (Cw, Cd, 7), "handcraft Warshall≡DFS");
   Check (Is_Transitive (Cw, 7), "handcraft closed");

   ------------------------------------------------------------------
   Section ("18. Larger mixed graph");
   ------------------------------------------------------------------
   Clear (G, 16);
   for I in 1 .. Vid (15) loop
      Add_Edge (G, I, Vertex_Id (Natural (I) + 1));
      if Natural (I) mod 3 = 0 then
         Add_Edge (G, I, 1);
      end if;
   end loop;
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Check (Matrices_Equal (Cw, Cd, 16), "16-vert Warshall≡DFS");
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cb, 16), "16-vert Warshall≡BFS");
   Check (Reaches (G, 1, 16), "16-vert reaches end");
   Check (Reaches (G, 3, 1), "16-vert back-edge reach");
   Closure_Matrix (G, Cb, True);
   Check (Cb (8, 8) and Cb (16, 16), "16-vert R* diag");

   ------------------------------------------------------------------
   Section ("19. Extra equivalence and edge cases");
   ------------------------------------------------------------------
   Clear (G, 1);
   Closure_Matrix (G, Cw, False);
   Check (not Cw (1, 1), "closure single R+");
   Closure_Matrix (G, Cw, True);
   Check (Cw (1, 1), "closure single R*");

   Clear (G, 2);
   Add_Edge (G, 1, 1);
   Check (Reaches (G, 1, 1), "only-loop reaches");
   Check (not Reaches (G, 1, 2), "loop no to other");
   Check (not Reaches (G, 2, 1), "isolated no to loop");
   Warshall (G, Cw, False);
   Check (Cw (1, 1) and not Cw (1, 2) and not Cw (2, 2), "only-loop matrix");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 2);
   Add_Edge (G, 3, 4);
   Check (Reaches (G, 1, 4), "cycle-mid to 4");
   Check (Reaches (G, 2, 2), "mid cycle self");
   Check (Reaches (G, 3, 3), "mid cycle 3 self");
   Check (not Reaches (G, 4, 2), "4 no back");
   Warshall (G, Cw, True);
   Reachability_DFS (G, Cd, True);
   Reachability_BFS (G, Cb, True);
   Check (Matrices_Equal (Cw, Cd, 4), "R* cycle Warshall≡DFS");
   Check (Matrices_Equal (Cw, Cb, 4), "R* cycle Warshall≡BFS");

   Clear (G, 5);
   for I in 1 .. Vid (5) loop
      for J in Vertex_Id'Max (1, Vertex_Id (Natural (I) + 1)) .. Vid (5) loop
         if Natural (J) > Natural (I) then
            Add_Edge (G, I, J);
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 10, "transitive tournament edges");
   Relation_Matrix (G, M);
   Check (Is_Transitive (M, 5), "tournament already transitive");
   Warshall (G, Cw, False);
   Check (Matrices_Equal (Cw, M, 5), "tournament R+ = R");

   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 3);
   Relation_Matrix (G, M);
   Check (Is_Transitive (M, 3), "already-closed chain transitive");
   Warshall (G, Cw, False);
   Check (Matrices_Equal (Cw, M, 3), "closed chain R+ = R");

   --  Two disjoint edges: not transitive? 1→2 and 3→4 — IS transitive
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Relation_Matrix (G, M);
   Check (Is_Transitive (M, 4), "two disjoint arcs transitive");
   Check (not Reaches (G, 1, 4), "disjoint no cross");
   Warshall (G, Cw, False);
   Check (Cw (1, 2) and Cw (3, 4) and not Cw (1, 4), "disjoint closure");

   ------------------------------------------------------------------
   Section ("20. More method agreement");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 3);
   Warshall (G, Cw, False);
   Reachability_DFS (G, Cd, False);
   Reachability_BFS (G, Cb, False);
   Check (Matrices_Equal (Cw, Cd, 6), "tail-cycle Warshall≡DFS");
   Check (Matrices_equal (Cw, Cb, 6), "tail-cycle Warshall≡BFS");
   Check (Cw (1, 6) and Cw (3, 3) and Cw (6, 4), "tail-cycle cells");
   Check (not Cw (6, 1) and not Cw (4, 1), "tail-cycle no to head");
   Check (Is_Transitive (Cw, 6), "tail-cycle closed transitive");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 3);
   Warshall (G, Cw, True);
   Closure_Matrix (G, Cd, True);
   Check (Matrices_Equal (Cw, Cd, 4), "Closure_Matrix R* alias");
   Check (Cw (1, 1) and Cw (1, 4) and Cw (2, 3), "fan R* cells");
   Check (not Cw (3, 2) and not Cw (4, 1), "fan no reverse");

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
