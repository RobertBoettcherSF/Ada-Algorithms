pragma Ada_2022;
--  Own checks for Path-Sum (V&V sweep, agent A3, 2026-10-09; see
--  tests/SOURCES.txt). The test keeps its own copy of each tree (values and
--  child links) and answers by recursion over it: a root-to-leaf path
--  (leaf = no children) has sum Wanted. The library walks with an explicit
--  stack instead. Inputs: 3,000 seeded random binary trees of 1 .. 15 nodes
--  on random node numbers, values mostly in -5 .. 5 (so sums repeat) and
--  sometimes in -100 .. 100; every used node is tried as the root; targets
--  are every leaf sum, its neighbours +-1 and random targets in
--  -1000 .. 1000; an unused root and root 0 must give False.
--  Seeded: Park-Miller minimal standard generator; default seed = FNV-1a
--  (32-bit) of the folder name folded into 1 .. 2 ** 31 - 2, printed;
--  AA_SEED=<n> overrides it.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Path_Sum; use Path_Sum;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Path-Sum";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   --  The test's own copy of a tree.
   type Int_Map is array (Node_Index) of Integer;
   type Link_Map is array (Node_Index) of Index;
   type Flag_Map is array (Node_Index) of Boolean;
   type Model is record
      Val         : Int_Map := [others => 0];
      Left, Right : Link_Map := [others => 0];
      Used        : Flag_Map := [others => False];
   end record;

   function Ref (M : Model; N : Node_Index; Wanted : Integer) return Boolean is
      Rest : constant Integer := Wanted - M.Val (N);
   begin
      if M.Left (N) = 0 and then M.Right (N) = 0 then
         return Rest = 0;
      end if;
      return (M.Left (N) /= 0 and then Ref (M, M.Left (N), Rest))
        or else (M.Right (N) /= 0 and then Ref (M, M.Right (N), Rest));
   end Ref;

   --  All leaf sums below N (at most 15 leaves).
   type Sum_List is array (1 .. 16) of Integer;
   procedure Sums (M : Model; N : Node_Index; Acc : Integer;
                   L : in out Sum_List; K : in out Natural) is
      S : constant Integer := Acc + M.Val (N);
   begin
      if M.Left (N) = 0 and then M.Right (N) = 0 then
         K := K + 1;
         L (K) := S;
      else
         if M.Left (N) /= 0 then Sums (M, M.Left (N), S, L, K); end if;
         if M.Right (N) /= 0 then Sums (M, M.Right (N), S, L, K); end if;
      end if;
   end Sums;
begin
   for Trial in 1 .. 3_000 loop
      declare
         M     : Model;
         T     : Tree := Empty;
         Ids   : array (1 .. 15) of Node_Index;
         Count : constant Positive := 1 + Next mod 15;
         Wide  : constant Boolean := Trial mod 4 = 0;
         Spare : Index := 0;
      begin
         --  random node numbers: shuffle 1 .. 15
         for I in Ids'Range loop
            Ids (I) := I;
         end loop;
         for I in reverse 2 .. Ids'Last loop
            declare
               J : constant Positive := 1 + Next mod I;
               X : constant Node_Index := Ids (I);
            begin
               Ids (I) := Ids (J);
               Ids (J) := X;
            end;
         end loop;
         for I in 1 .. Count loop
            M.Used (Ids (I)) := True;
            M.Val (Ids (I)) := (if Wide then Next mod 201 - 100 else Next mod 11 - 5);
            if I > 1 then
               --  attach to a random earlier node with a free slot
               loop
                  declare
                     P : constant Node_Index := Ids (1 + Next mod (I - 1));
                  begin
                     if Next mod 2 = 0 and then M.Left (P) = 0 then
                        M.Left (P) := Ids (I);
                        exit;
                     elsif M.Right (P) = 0 then
                        M.Right (P) := Ids (I);
                        exit;
                     elsif M.Left (P) = 0 then
                        M.Left (P) := Ids (I);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end loop;
         if Count < 15 then
            Spare := Ids (Count + 1);
         end if;
         --  Set the nodes children first (reverse attachment order) on odd
         --  trials, parents first on even ones.
         for J in 1 .. Count loop
            declare
               N : constant Node_Index :=
                 Ids (if Trial mod 2 = 1 then Count + 1 - J else J);
            begin
               Set_Node (T, N, M.Val (N), M.Left (N), M.Right (N));
            end;
         end loop;
         for I in 1 .. Count loop
            declare
               R : constant Node_Index := Ids (I);
               L : Sum_List;
               K : Natural := 0;
            begin
               Report (Left_Child (T, R) = M.Left (R) and then Right_Child (T, R) = M.Right (R),
                       "child links");
               Sums (M, R, 0, L, K);
               for J in 1 .. K loop
                  for D in -1 .. 1 loop
                     if L (J) + D in Target then
                        Report (Has_Path_Sum (T, R, L (J) + D) = Ref (M, R, L (J) + D),
                                "Has_Path_Sum root" & R'Image & " target" & Integer'Image (L (J) + D));
                     end if;
                  end loop;
               end loop;
               for J in 1 .. 3 loop
                  declare
                     W : constant Target := Next mod 2001 - 1000;
                  begin
                     Report (Has_Path_Sum (T, R, W) = Ref (M, R, W),
                             "Has_Path_Sum root" & R'Image & " random target" & W'Image);
                  end;
               end loop;
            end;
         end loop;
         Report (not Has_Path_Sum (T, 0, 0), "root 0");
         if Spare /= 0 then
            Report (not Has_Path_Sum (T, Spare, 0), "unused root");
         end if;
      end;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
