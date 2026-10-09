pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Convert_Sorted_Array_To_BST; use Convert_Sorted_Array_To_BST;
--  Own checks (H124): Build_From (A) for a sorted A (1 .. N), N up to
--  Max_Nodes, must be a height-balanced BST whose in-order walk is A:
--  every node reached exactly once from the root, the in-order walk equals
--  A, every node's two subtree heights differ by at most 1, and the height
--  is the least possible, ceil (log2 (N + 1)). Exhaustive N = 0 .. 300 on
--  1 .. N, 500 random sorted arrays (duplicates allowed) with N up to
--  Max_Nodes (seed 20261009).
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   procedure Run (A : Value_List; Tag : String) is
      T    : constant Tree := Build_From (A);
      N    : constant Natural := A'Length;
      Seen : array (1 .. Max_Nodes) of Boolean := [others => False];
      Walk : array (1 .. Max_Nodes) of Value := [others => 0];
      W    : Natural := 0;
      Ok   : Boolean := True;

      function Height (K : Index) return Natural is
         HL, HR : Natural;
      begin
         if K = 0 then
            return 0;
         end if;
         if K > N or else Seen (K) then
            Ok := False;
            return 0;
         end if;
         Seen (K) := True;
         HL := Height (Left (T, K));
         W := W + 1;
         Walk (W) := Node_Value (T, K);
         HR := Height (Right (T, K));
         if abs (HL - HR) > 1 then
            Ok := False;
         end if;
         return 1 + Natural'Max (HL, HR);
      end Height;

      H, Best : Natural := 0;
   begin
      Check (Size (T) = N, "size" & Tag);
      Check ((Root (T) = 0) = (N = 0), "root" & Tag);
      H := Height (Root (T));
      Check (Ok, "reached once / balanced" & Tag);
      Check (W = N, "every node reached" & Tag);
      for I in 1 .. Natural'Min (W, N) loop
         if Walk (I) /= A (I) then
            Check (False, "in-order position" & I'Image & Tag);
            exit;
         end if;
      end loop;
      while 2 ** Best - 1 < N loop
         Best := Best + 1;
      end loop;
      Check (H = Best, "height" & H'Image & " least" & Best'Image & Tag);
   end Run;
begin
   for N in 0 .. 300 loop
      declare
         A : Value_List (1 .. N);
      begin
         for I in 1 .. N loop
            A (I) := I;
         end loop;
         Run (A, " N =" & N'Image);
      end;
   end loop;
   for T in 1 .. 500 loop
      declare
         N : constant Natural := Rand (Max_Nodes + 1);
         A : Value_List (1 .. N);
         V : Integer := Value'First + Rand (100);
      begin
         for I in 1 .. N loop
            V := Integer'Min (Value'Last, V + Rand (3));
            A (I) := V;
         end loop;
         Run (A, " random" & T'Image & " N =" & N'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Convert_Sorted_Array_To_BST own checks:" & Cases'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
