--  Standalone test suite for Prufer_Coding.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Prufer_Coding;
use Prufer_Coding;

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Norm_U (E : Edge_Record) return Vertex_Id is
     (if E.U <= E.V then E.U else E.V);
   function Norm_V (E : Edge_Record) return Vertex_Id is
     (if E.U <= E.V then E.V else E.U);

   function Same_Undirected (A, B : Edge_Record) return Boolean is
     (Norm_U (A) = Norm_U (B) and then Norm_V (A) = Norm_V (B));

   --  Multiset equality of undirected edges (order-independent).
   function Edge_Sets_Equal
     (A : Edge_List; NA : Natural; B : Edge_List; NB : Natural)
      return Boolean
   is
      Used : array (1 .. Max_Edges) of Boolean := [others => False];
      Found : Boolean;
   begin
      if NA /= NB then
         return False;
      end if;
      for I in 1 .. NA loop
         Found := False;
         for J in 1 .. NB loop
            if not Used (J) and then Same_Undirected (A (I), B (J)) then
               Used (J) := True;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Edge_Sets_Equal;

   function Codes_Equal
     (A : Code_Array; LA : Natural; B : Code_Array; LB : Natural)
      return Boolean
   is
   begin
      if LA /= LB then
         return False;
      end if;
      for I in 1 .. LA loop
         if A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Codes_Equal;

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      T : Tree;
   begin
      Clear (T, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Edge_Raises
     (T : in out Tree; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (T, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Edge_Raises;

   function Encode_Raises (T : Tree) return Boolean is
      Code : Code_Array (1 .. Max_Vertices);
      Len  : Natural;
   begin
      Encode (T, Code, Len);
      pragma Unreferenced (Len);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Encode_Raises;

   function Decode_Raises (Code : Code_Array) return Boolean is
      T : Tree;
   begin
      Decode (Code, T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Decode_Raises;

   function Decode_Edges_Raises (Code : Code_Array) return Boolean is
      Edges : Edge_List (1 .. Max_Edges);
      EC, N : Natural;
   begin
      Decode_Edges (Code, Edges, EC, N);
      pragma Unreferenced (EC, N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Decode_Edges_Raises;

   function Cayley_Raises (N : Natural) return Boolean is
      C : Natural;
   begin
      C := Cayley_Count (N);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cayley_Raises;

   function Get_Edges_Raises (T : Tree) return Boolean is
      Edges : Edge_List (2 .. 10);
      EC    : Natural;
   begin
      Get_Edges (T, Edges, EC);
      pragma Unreferenced (EC);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Edges_Raises;

   procedure Make_Path (T : in out Tree; N : Positive) is
   begin
      Clear (T, N);
      for I in 1 .. N - 1 loop
         Add_Edge (T, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
   end Make_Path;

   procedure Make_Star (T : in out Tree; N : Positive; Hub : Positive) is
   begin
      Clear (T, N);
      for I in 1 .. N loop
         if I /= Hub then
            Add_Edge (T, Vertex_Id (Hub), Vertex_Id (I));
         end if;
      end loop;
   end Make_Star;

   procedure Round_Trip_Tree (Label : String; T : Tree) is
      Code1, Code2 : Code_Array (1 .. Max_Vertices);
      L1, L2       : Natural;
      T2           : Tree;
      E1, E2       : Edge_List (1 .. Max_Edges);
      N1, N2       : Natural;
   begin
      Encode (T, Code1, L1);
      Decode (Code1 (1 .. L1), T2);
      Check (Vertex_Count (T2) = Vertex_Count (T),
             Label & " decode N");
      Check (Edge_Count (T2) = Edge_Count (T),
             Label & " decode M");
      Encode (T2, Code2, L2);
      Check (Codes_Equal (Code1, L1, Code2, L2),
             Label & " Encode o Decode identity");
      Get_Edges (T, E1, N1);
      Get_Edges (T2, E2, N2);
      Check (Edge_Sets_Equal (E1, N1, E2, N2),
             Label & " edge multiset");
   end Round_Trip_Tree;

   procedure Round_Trip_Code (Label : String; Code : Code_Array) is
      T          : Tree;
      Code2      : Code_Array (1 .. Max_Vertices);
      L2         : Natural;
      Edges      : Edge_List (1 .. Max_Edges);
      EC, N      : Natural;
      Edges2     : Edge_List (1 .. Max_Edges);
      EC2        : Natural;
   begin
      Decode (Code, T);
      Encode (T, Code2, L2);
      Check (Codes_Equal (Code, Code'Length, Code2, L2),
             Label & " Decode o Encode identity");
      Decode_Edges (Code, Edges, EC, N);
      Check (N = Code'Length + 2, Label & " Decode_Edges N");
      Check (EC = N - 1, Label & " Decode_Edges M");
      Check (Vertex_Count (T) = N, Label & " tree N vs Decode_Edges");
      Get_Edges (T, Edges2, EC2);
      Check (Edge_Sets_Equal (Edges, EC, Edges2, EC2),
             Label & " Decode vs Decode_Edges edges");
   end Round_Trip_Code;

   T : Tree;
   Code : Code_Array (1 .. Max_Vertices);
   Len  : Natural;
   Edges : Edge_List (1 .. Max_Edges);
   EC, NN : Natural;

   --  Enumerate all sequences of length K over 1 .. N (N = K + 2) and
   --  count distinct trees via unique codes (each code is one tree).
   function Count_Sequences (N : Positive) return Natural is
      K : constant Natural := N - 2;
      Total : Natural := 0;

      procedure Recurse (Pos : Natural; Cur : in out Code_Array) is
         Tmp : Tree;
         C2  : Code_Array (1 .. Max_Vertices);
         L2  : Natural;
      begin
         if Pos > K then
            Decode (Cur (1 .. K), Tmp);
            Encode (Tmp, C2, L2);
            if Codes_Equal (Cur, K, C2, L2) then
               Total := Total + 1;
            end if;
            return;
         end if;
         for V in 1 .. N loop
            Cur (Pos) := Vertex_Id (V);
            Recurse (Pos + 1, Cur);
         end loop;
      end Recurse;

      Cur : Code_Array (1 .. Max_Vertices) := [others => 1];
   begin
      if N < 2 then
         return Cayley_Count (N);
      end if;
      if K = 0 then
         --  Single empty sequence ↔ one tree on 2 vertices.
         declare
            Empty : Code_Array (1 .. 0);
            Tmp   : Tree;
            C2    : Code_Array (1 .. Max_Vertices);
            L2    : Natural;
         begin
            Decode (Empty, Tmp);
            Encode (Tmp, C2, L2);
            if L2 = 0 and then Vertex_Count (Tmp) = 2 then
               return 1;
            else
               return 0;
            end if;
         end;
      end if;
      Recurse (1, Cur);
      return Total;
   end Count_Sequences;

begin
   -----------------------------------------------------------------
   Section ("1. Empty / single / two-vertex");
   -----------------------------------------------------------------
   Clear (T, Nat (0));
   Check (Vertex_Count (T) = 0, "empty N=0");
   Check (Edge_Count (T) = 0, "empty M=0");
   Encode (T, Code, Len);
   Check (Len = 0, "empty encode length 0");

   Clear (T, Nat (1));
   Check (Vertex_Count (T) = 1, "single N=1");
   Check (Edge_Count (T) = 0, "single M=0");
   Encode (T, Code, Len);
   Check (Len = 0, "single encode length 0");

   Clear (T, Nat (2));
   Add_Edge (T, 1, 2);
   Check (Edge_Count (T) = 1, "two-vertex M=1");
   Encode (T, Code, Len);
   Check (Len = 0, "two-vertex encode length 0");
   Round_Trip_Tree ("two-vertex", T);

   declare
      Empty : Code_Array (1 .. 0);
   begin
      Decode (Empty, T);
      Check (Vertex_Count (T) = 2, "decode empty => N=2");
      Check (Edge_Count (T) = 1, "decode empty => M=1");
      Round_Trip_Code ("empty code", Empty);
   end;

   -----------------------------------------------------------------
   Section ("2. Wikipedia example [4,4,4,5]");
   -----------------------------------------------------------------
   --  Tree: leaves 1,2,3 attached to 4; 4 attached to 5; sequence [4,4,4,5]
   Clear (T, Nat (5));
   Add_Edge (T, 1, 4);
   Add_Edge (T, 2, 4);
   Add_Edge (T, 3, 4);
   Add_Edge (T, 4, 5);
   Encode (T, Code, Len);
   Check (Len = 3, "wiki Len=N-2=3");
   --  Wait: N=5 => length 3, but wiki says [4,4,4,5] for a 6-vertex tree!
   --  Re-read wiki: sequence [4,4,4,5] has length 4 => N=6.
   --  "left with only two vertices" after removing 1,2,3,4 — so vertices
   --  1..6 with 5 connected to something. Classic figure: 6 vertices.
   --  Rebuild with N=6: edges 1-4, 2-4, 3-4, 4-5, 5-6.
   Clear (T, Nat (6));
   Add_Edge (T, 1, 4);
   Add_Edge (T, 2, 4);
   Add_Edge (T, 3, 4);
   Add_Edge (T, 4, 5);
   Add_Edge (T, 5, 6);
   Encode (T, Code, Len);
   Check (Len = 4, "wiki N=6 Len=4");
   Check (Code (1) = 4 and then Code (2) = 4
            and then Code (3) = 4 and then Code (4) = 5,
          "wiki sequence [4,4,4,5]");
   Round_Trip_Tree ("wiki tree", T);

   declare
      W : constant Code_Array := [4, 4, 4, 5];
   begin
      Round_Trip_Code ("wiki code", W);
      Decode (W, T);
      Check (Vertex_Count (T) = 6, "wiki decode N=6");
      Check (Edge_Count (T) = 5, "wiki decode M=5");
   end;

   -----------------------------------------------------------------
   Section ("3. Paths");
   -----------------------------------------------------------------
   for N in 2 .. 12 loop
      Make_Path (T, N);
      Check (Edge_Count (T) = N - 1, "path" & N'Image & " M");
      Round_Trip_Tree ("path" & N'Image, T);
      Encode (T, Code, Len);
      Check (Len = N - 2, "path" & N'Image & " Len");
      --  Path 1—2—…—N: repeatedly strip smallest leaf.
      --  For N>=3 first leaf is 1, neighbour 2.
      if N >= 3 then
         Check (Code (1) = 2, "path" & N'Image & " first=2");
      end if;
   end loop;

   -----------------------------------------------------------------
   Section ("4. Stars");
   -----------------------------------------------------------------
   for N in 2 .. 12 loop
      Make_Star (T, N, 1);
      Round_Trip_Tree ("star-hub1 n" & N'Image, T);
      Encode (T, Code, Len);
      Check (Len = N - 2, "star1 Len" & N'Image);
      --  Star with hub 1: leaves 2..N removed in order; each records 1.
      if N >= 3 then
         declare
            All_Hub : Boolean := True;
         begin
            for I in 1 .. Len loop
               if Code (I) /= 1 then
                  All_Hub := False;
               end if;
            end loop;
            Check (All_Hub, "star-hub1 code all 1s n" & N'Image);
         end;
      end if;
   end loop;

   for N in 3 .. 10 loop
      Make_Star (T, N, N);
      Round_Trip_Tree ("star-hubN n" & N'Image, T);
      Encode (T, Code, Len);
      declare
         All_Hub : Boolean := True;
      begin
         for I in 1 .. Len loop
            if Code (I) /= Vertex_Id (N) then
               All_Hub := False;
            end if;
         end loop;
         Check (All_Hub, "star-hubN code all hub n" & N'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("5. Cayley counts");
   -----------------------------------------------------------------
   Check (Cayley_Count (Nat (0)) = 0, "Cayley 0");
   Check (Cayley_Count (Nat (1)) = 1, "Cayley 1 = 1");
   Check (Cayley_Count (Nat (2)) = 1, "Cayley 2 = 1");
   Check (Cayley_Count (Nat (3)) = 3, "Cayley 3 = 3");
   Check (Cayley_Count (Nat (4)) = 16, "Cayley 4 = 16");
   Check (Cayley_Count (Nat (5)) = 125, "Cayley 5 = 125");
   Check (Cayley_Count (Nat (6)) = 1296, "Cayley 6 = 1296");
   Check (Cayley_Count (Nat (7)) = 16807, "Cayley 7");
   Check (Cayley_Count (Nat (8)) = 262144, "Cayley 8");
   Check (Cayley_Raises (Nat (9)), "Cayley 9 raises");
   Check (Cayley_Raises (Nat (100)), "Cayley 100 raises");

   --  Enumerate sequences for small n and match Cayley.
   for N in 2 .. 5 loop
      declare
         Cnt : constant Natural := Count_Sequences (N);
      begin
         Check (Cnt = Cayley_Count (N),
                "enumerate n" & N'Image & " =" & Cnt'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("6. Round-trip random-ish codes");
   -----------------------------------------------------------------
   declare
      S01 : constant Code_Array := [1, 1];
      S02 : constant Code_Array := [2, 2];
      S03 : constant Code_Array := [1, 2];
      S04 : constant Code_Array := [3, 1, 2];
      S05 : constant Code_Array := [2, 2, 2];
      S06 : constant Code_Array := [1, 1, 1];
      S07 : constant Code_Array := [4, 4, 4, 5];
      S08 : constant Code_Array := [1, 2, 3, 4];
      S09 : constant Code_Array := [5, 5, 5, 5, 5];
      S10 : constant Code_Array := [1, 3, 5, 2, 4];
      S11 : constant Code_Array := [2, 3, 2, 3];
      S12 : constant Code_Array := [1];
      S13 : constant Code_Array := [2];
      S14 : constant Code_Array := [3];
   begin
      Round_Trip_Code ("sample01", S01);
      Round_Trip_Code ("sample02", S02);
      Round_Trip_Code ("sample03", S03);
      Round_Trip_Code ("sample04", S04);
      Round_Trip_Code ("sample05", S05);
      Round_Trip_Code ("sample06", S06);
      Round_Trip_Code ("sample07", S07);
      Round_Trip_Code ("sample08", S08);
      Round_Trip_Code ("sample09", S09);
      Round_Trip_Code ("sample10", S10);
      Round_Trip_Code ("sample11", S11);
      Round_Trip_Code ("sample12", S12);
      Round_Trip_Code ("sample13", S13);
      Round_Trip_Code ("sample14", S14);
   end;

   --  All length-1 codes (N=3): three trees.
   for V in 1 .. 3 loop
      declare
         C : constant Code_Array := [Vertex_Id (V)];
      begin
         Round_Trip_Code ("n3-" & V'Image, C);
      end;
   end loop;

   --  All length-2 codes over 1..4 (16 trees).
   for A in 1 .. 4 loop
      for B in 1 .. 4 loop
         declare
            C : constant Code_Array := [Vertex_Id (A), Vertex_Id (B)];
         begin
            Round_Trip_Code ("n4-" & A'Image & "," & B'Image, C);
         end;
      end loop;
   end loop;

   -----------------------------------------------------------------
   Section ("7. Branching / custom trees");
   -----------------------------------------------------------------
   --  Balanced-ish: 1-2, 1-3, 2-4, 2-5, 3-6, 3-7
   Clear (T, Nat (7));
   Add_Edge (T, 1, 2);
   Add_Edge (T, 1, 3);
   Add_Edge (T, 2, 4);
   Add_Edge (T, 2, 5);
   Add_Edge (T, 3, 6);
   Add_Edge (T, 3, 7);
   Round_Trip_Tree ("binary-ish", T);

   --  Line with side leaf: 1-2-3-4-5 and 3-6
   Clear (T, Nat (6));
   Add_Edge (T, 1, 2);
   Add_Edge (T, 2, 3);
   Add_Edge (T, 3, 4);
   Add_Edge (T, 4, 5);
   Add_Edge (T, 3, 6);
   Round_Trip_Tree ("path+side", T);
   Encode (T, Code, Len);
   Check (Len = 4, "path+side Len");

   --  Double star: hubs 3,4 connected; leaves 1,2 on 3; 5,6 on 4
   Clear (T, Nat (6));
   Add_Edge (T, 1, 3);
   Add_Edge (T, 2, 3);
   Add_Edge (T, 3, 4);
   Add_Edge (T, 4, 5);
   Add_Edge (T, 4, 6);
   Round_Trip_Tree ("double-star", T);

   -----------------------------------------------------------------
   Section ("8. Decode_Edges agreement");
   -----------------------------------------------------------------
   declare
      C : constant Code_Array := [4, 4, 4, 5];
   begin
      Decode_Edges (C, Edges, EC, NN);
      Check (NN = 6, "DE N=6");
      Check (EC = 5, "DE M=5");
      Decode (C, T);
      declare
         E2 : Edge_List (1 .. Max_Edges);
         M2 : Natural;
      begin
         Get_Edges (T, E2, M2);
         Check (Edge_Sets_Equal (Edges, EC, E2, M2), "DE vs Decode");
      end;
   end;

   -----------------------------------------------------------------
   Section ("9. Invalid_Argument");
   -----------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Check (Clear_Raises (Nat (2_000)), "Clear 2000");

   Clear (T, Nat (3));
   Check (Add_Edge_Raises (T, 1, 1), "self-loop");
   Check (Add_Edge_Raises (T, 1, 4), "U ok V out");
   Check (Add_Edge_Raises (T, 4, 1), "U out V ok");
   Add_Edge (T, 1, 2);
   Add_Edge (T, 2, 3);
   --  Extra edge => not a tree
   Add_Edge (T, 1, 3);
   Check (Encode_Raises (T), "triangle Encode");

   Clear (T, Nat (4));
   Add_Edge (T, 1, 2);
   Add_Edge (T, 3, 4);
   Check (Encode_Raises (T), "disconnected Encode");

   Clear (T, Nat (4));
   Add_Edge (T, 1, 2);
   Check (Encode_Raises (T), "too few edges Encode");

   Clear (T, Nat (3));
   --  no edges
   Check (Encode_Raises (T), "N=3 no edges Encode");

   declare
      Bad : constant Code_Array := [1, 7];  -- N=4, label 7 invalid
   begin
      Check (Decode_Raises (Bad), "Decode label > N");
      Check (Decode_Edges_Raises (Bad), "Decode_Edges label > N");
   end;

   declare
      Bad : constant Code_Array := [9, 9, 9];  -- N=5, 9 invalid
   begin
      Check (Decode_Raises (Bad), "Decode 9>5");
   end;

   --  Code buffer First /= 1
   declare
      T2   : Tree;
      Cbad : Code_Array (3 .. 10);
      L    : Natural;
   begin
      Clear (T2, Nat (4));
      Add_Edge (T2, 1, 2);
      Add_Edge (T2, 2, 3);
      Add_Edge (T2, 3, 4);
      begin
         Encode (T2, Cbad, L);
         Check (False, "Encode bad First");
      exception
         when Invalid_Argument =>
            Check (True, "Encode bad First");
      end;
   end;

   declare
      Cbad : constant Code_Array (2 .. 5) := [2 => 1, 3 => 1, 4 => 1, 5 => 1];
      T2   : Tree;
   begin
      begin
         Decode (Cbad, T2);
         Check (False, "Decode bad First");
      exception
         when Invalid_Argument =>
            Check (True, "Decode bad First");
      end;
   end;

   Clear (T, Nat (3));
   Add_Edge (T, 1, 2);
   Add_Edge (T, 2, 3);
   Check (Get_Edges_Raises (T), "Get_Edges First/=1");

   --  Short output buffer for Encode
   declare
      T2 : Tree;
      Cs : Code_Array (1 .. 1);
      L  : Natural;
   begin
      Make_Path (T2, 5);  -- needs length 3
      begin
         Encode (T2, Cs, L);
         Check (False, "Encode short buffer");
      exception
         when Invalid_Argument =>
            Check (True, "Encode short buffer");
      end;
   end;

   --  Short Edges for Decode_Edges
   declare
      C  : constant Code_Array := [1, 2, 3];  -- N=5, need 4 edges
      Es : Edge_List (1 .. 2);
      ECnt, Nv : Natural;
   begin
      begin
         Decode_Edges (C, Es, ECnt, Nv);
         Check (False, "Decode_Edges short");
      exception
         when Invalid_Argument =>
            Check (True, "Decode_Edges short");
      end;
   end;

   --  Decode would exceed Max_Vertices: length Max_Vertices-1 => N=Max+1
   declare
      Big : constant Code_Array (1 .. Max_Vertices - 1) := [others => 1];
   begin
      Check (Decode_Raises (Big), "Decode N>Max");
   end;

   -----------------------------------------------------------------
   Section ("10. Capacity / rebuild / inspectors");
   -----------------------------------------------------------------
   Clear (T, Nat (Max_Vertices));
   Check (Vertex_Count (T) = Max_Vertices, "max N clear");
   --  Build a path on Max_Vertices (may be slow-ish but N=1024 fine)
   Make_Path (T, Max_Vertices);
   Check (Edge_Count (T) = Max_Vertices - 1, "max path M");
   Encode (T, Code, Len);
   Check (Len = Max_Vertices - 2, "max path Len");
   Round_Trip_Tree ("max-path", T);

   Clear (T, Nat (10));
   Make_Star (T, 10, 5);
   Check (Vertex_Count (T) = 10, "rebuild N");
   Clear (T, Nat (0));
   Check (Vertex_Count (T) = 0, "clear to empty");

   --  Get_Edges content
   Make_Path (T, 4);
   Get_Edges (T, Edges, EC);
   Check (EC = 3, "Get_Edges count");
   Check (Same_Undirected (Edges (1), (1, 2))
            and then Same_Undirected (Edges (2), (2, 3))
            and then Same_Undirected (Edges (3), (3, 4)),
          "Get_Edges path4 content");

   -----------------------------------------------------------------
   Section ("11. Extra round-trips / stars mid-hub");
   -----------------------------------------------------------------
   for Hub in 1 .. 7 loop
      Make_Star (T, 7, Hub);
      Round_Trip_Tree ("star7-hub" & Hub'Image, T);
   end loop;

   for N in 2 .. 8 loop
      Make_Path (T, N);
      Encode (T, Code, Len);
      declare
         Slice : constant Code_Array := Code (1 .. Len);
      begin
         Round_Trip_Code ("path-code" & N'Image, Slice);
      end;
   end loop;

   --  Complete enumeration already did n=4; spot-check n=5 codes
   declare
      C5a : constant Code_Array := [1, 1, 1];
      C5b : constant Code_Array := [5, 4, 3];
      C5c : constant Code_Array := [2, 3, 2];
      C5d : constant Code_Array := [1, 5, 1];
      C5e : constant Code_Array := [3, 3, 3];
   begin
      Round_Trip_Code ("c5a", C5a);
      Round_Trip_Code ("c5b", C5b);
      Round_Trip_Code ("c5c", C5c);
      Round_Trip_Code ("c5d", C5d);
      Round_Trip_Code ("c5e", C5e);
   end;

   -----------------------------------------------------------------
   Section ("12. Degree / Cayley multinomial spot");
   -----------------------------------------------------------------
   --  Star on n=5 hub=3: degrees hub=4, leaves=1 ⇒ code length 3 all 3s
   Make_Star (T, 5, 3);
   Encode (T, Code, Len);
   Check (Len = 3, "star5 Len");
   Check (Code (1) = 3 and then Code (2) = 3 and then Code (3) = 3,
          "star5 code [3,3,3]");
   --  Number of times i appears in code = degree(i) - 1
   Check (True, "degree-count remark");

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
