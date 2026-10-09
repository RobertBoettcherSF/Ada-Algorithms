--  Exhaustive tie-break search driver (sweep B, 2026-10-09; tools/vv/lh_tiebreak_run.sh runs it in chunks of 20,000 games because Big_Integer memory grows per process):
--  set a: all 3x3 games, payoffs in {0,1}; set b: all 2x3 and 3x2 games,
--  payoffs in -1 .. 1. Every starting label. Reports the first game whose
--  run does not end with Status = Found.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Lemke_Howson; use Lemke_Howson;
procedure Drive is
   Calls : Long_Long_Integer := 0;
   Bad   : Long_Long_Integer := 0;
   Max_P : Natural := 0;

   procedure Show (A, B : Payoff_Matrix; L : Positive; S : String) is
   begin
      Put ("FIRST-FAIL label" & L'Image & " status " & S & " A=");
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            Put (A (I, J)'Image);
         end loop;
         Put (" /");
      end loop;
      Put (" B=");
      for I in B'Range (1) loop
         for J in B'Range (2) loop
            Put (B (I, J)'Image);
         end loop;
         Put (" /");
      end loop;
      New_Line;
   end Show;

   From_Code, To_Code : Long_Long_Integer;

   procedure Run_Set (M, N : Positive; Lo, Hi : Integer; Name : String) is
      Base  : constant Long_Long_Integer := Long_Long_Integer (Hi - Lo + 1);
      Cells : constant Natural := 2 * M * N;
      Total : Long_Long_Integer := 1;
      A, B  : Payoff_Matrix (1 .. M, 1 .. N);
      C0, B0 : Long_Long_Integer := Calls;
   begin
      C0 := Calls; B0 := Bad;
      for K in 1 .. Cells loop
         Total := Total * Base;
      end loop;
      for Code in From_Code .. Long_Long_Integer'Min (To_Code, Total - 1) loop
         declare
            R : Long_Long_Integer := Code;
            K : Natural := 0;
         begin
            for I in 1 .. M loop
               for J in 1 .. N loop
                  A (I, J) := Lo + Integer (R mod Base); R := R / Base;
                  B (I, J) := Lo + Integer (R mod Base); R := R / Base;
                  K := K + 2;
               end loop;
            end loop;
         end;
         for L in 1 .. M + N loop
            declare
               E : constant Exact_Equilibrium := Find_Equilibrium (A, B, L);
            begin
               Calls := Calls + 1;
               if E.Pivots > Max_P then Max_P := E.Pivots; end if;
               if E.Status /= Found then
                  if Bad = B0 then
                     Put (Name & " "); Show (A, B, L, E.Status'Image);
                  end if;
                  Bad := Bad + 1;
               end if;
            end;
         end loop;
      end loop;
      Put_Line (Name & ": codes" & From_Code'Image & " .." & Long_Long_Integer'Min (To_Code, Total - 1)'Image & " of" & Total'Image & " calls" & Long_Long_Integer'Image (Calls - C0)
                & " not-found" & Long_Long_Integer'Image (Bad - B0) & " max-pivots" & Max_P'Image);
   end Run_Set;
   use Ada.Command_Line;
begin
   From_Code := Long_Long_Integer'Value (Argument (2));
   To_Code   := Long_Long_Integer'Value (Argument (3));
   if Argument (1) = "a" then
      Run_Set (3, 3, 0, 1, "a-3x3-01");
   elsif Argument (1) = "b23" then
      Run_Set (2, 3, -1, 1, "b-2x3-m1p1");
   else
      Run_Set (3, 2, -1, 1, "b-3x2-m1p1");
   end if;
   if Bad > 0 then
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Drive;
