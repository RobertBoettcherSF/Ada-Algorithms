pragma Ada_2022;
--  Own tests for Backtracking (see tests/SOURCES.txt).
--  Every result is checked against an own exhaustive search: N-Queens counts over all permutations,
--  subset sums over all 2**n masks, colourings over all K**n assignments.
with Ada.Text_IO; use Ada.Text_IO;
with Backtracking; use Backtracking;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Q_Ok (P : Queen_Array; N : Positive) return Boolean is
   begin
      for I in 1 .. N loop
         if P (I) not in 1 .. N then return False; end if;
         for J in 1 .. I - 1 loop
            if P (I) = P (J) or else abs (P (I) - P (J)) = I - J then return False; end if;
         end loop;
      end loop;
      return True;
   end Q_Ok;
   function Brute_Queens (N : Positive) return Natural is
      P : Queen_Array (1 .. N);
      Used : array (1 .. N) of Boolean := [others => False];
      Count : Natural := 0;
      procedure Place (R : Positive) is   --  all permutations; the diagonal test happens only at the leaf
      begin
         if R > N then
            if Q_Ok (P, N) then Count := Count + 1; end if;
            return;
         end if;
         for C in 1 .. N loop
            if not Used (C) then Used (C) := True; P (R) := C; Place (R + 1); Used (C) := False; end if;
         end loop;
      end Place;
   begin
      Place (1);
      return Count;
   end Brute_Queens;
begin
   for N in 1 .. 9 loop
      declare
         Own : constant Natural := Brute_Queens (N);
         P : Queen_Array (1 .. N);
         Found : constant Boolean := Solve_N_Queens (N, P);
      begin
         Report (Count_N_Queens (N) = Own, "Count_N_Queens" & N'Image & " gave" & Count_N_Queens (N)'Image & ", own" & Own'Image);
         Report (Found = (Own > 0) and then (not Found or else (Q_Ok (P, N) and then Is_Safe_Placement (P, N))),
                 "Solve_N_Queens" & N'Image);
      end;
   end loop;
   for Run in 1 .. 5000 loop
      declare
         N : constant Positive := Next (1, 6);
         P : Queen_Array (1 .. N);
      begin
         for I in 1 .. N loop P (I) := Next (0, N + 1); end loop;
         Report (Is_Safe_Placement (P, N) = Q_Ok (P, N), "Is_Safe_Placement run" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 5000 loop
      declare
         N : constant Natural := Next (0, 12);
         A : Element_Array (1 .. N);
         Ch : Boolean_Array (1 .. N);
         T : constant Integer := Next (-60, 60);
         Own : Boolean := False;
         S : Integer;
         R : Boolean;
      begin
         for I in 1 .. N loop A (I) := Next (-20, 20); end loop;
         for Mask in 0 .. 2 ** N - 1 loop
            S := 0;
            for I in 1 .. N loop if (Mask / 2 ** (I - 1)) mod 2 = 1 then S := S + A (I); end if; end loop;
            if S = T then Own := True; end if;
         end loop;
         R := Subset_Sum (A, T, Ch);
         S := 0;
         for I in 1 .. N loop if Ch (I) then S := S + A (I); end if; end loop;
         Report (R = Own and then Subset_Sum_Exists (A, T) = Own
                 and then (if R then S = T else (for all C of Ch => not C)),
                 "Subset_Sum run" & Run'Image & " N =" & N'Image & " T =" & T'Image);
      end;
   end loop;
   for Run in 1 .. 3000 loop
      declare
         N : constant Positive := Next (1, 7);
         K : constant Positive := Next (1, 4);
         Adj : Adjacency_Matrix (1 .. N, 1 .. N) := [others => [others => False]];
         C, Try : Color_Array (1 .. N);
         Own : Boolean := False;
         R : Boolean;
         function Proper (X : Color_Array) return Boolean is
           (for all I in 1 .. N => X (I) in 1 .. K and then (for all J in 1 .. N => not Adj (I, J) or else X (I) /= X (J)));
      begin
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if Next (0, 99) < 45 then Adj (I, J) := True; Adj (J, I) := True; end if;
            end loop;
         end loop;
         for Code in 0 .. K ** N - 1 loop
            for I in 1 .. N loop Try (I) := (Code / K ** (I - 1)) mod K + 1; end loop;
            if Proper (Try) then Own := True; exit; end if;
         end loop;
         R := Color_Graph (Adj, K, C);
         Report (R = Own and then (if R then Proper (C) and then Is_Valid_Colouring (Adj, C, K) else (for all X of C => X = 0)),
                 "Color_Graph run" & Run'Image & " N =" & N'Image & " K =" & K'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
