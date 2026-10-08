pragma Ada_2022;
--  Own tests for Kruskals_Algorithm (see tests/SOURCES.txt).
--  On a connected graph Kruskal must return N - 1 edges of the graph forming a spanning
--  tree whose weight equals the minimum over all spanning trees (own brute force over edge subsets).
with Ada.Text_IO; use Ada.Text_IO;
with Kruskals_Algorithm; use Kruskals_Algorithm;

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
   type E_Rec is record U, V : Positive; W : Natural; end record;
   type E_Arr is array (1 .. 10) of E_Rec;
   function Spans (E : E_Arr; Mask : Natural; N : Positive) return Boolean is
      Comp : array (1 .. N) of Positive;
      Old : Positive;
   begin
      for I in Comp'Range loop Comp (I) := I; end loop;
      for K in E'Range loop
         if (Mask / 2 ** (K - 1)) mod 2 = 1 then
            if Comp (E (K).U) = Comp (E (K).V) then return False; end if;   --  cycle
            Old := Comp (E (K).V);
            for I in Comp'Range loop if Comp (I) = Old then Comp (I) := Comp (E (K).U); end if; end loop;
         end if;
      end loop;
      for I in Comp'Range loop if Comp (I) /= Comp (1) then return False; end if; end loop;
      return True;
   end Spans;
begin
   for Run in 1 .. 1500 loop
      declare
         N : constant Positive := Next (2, 5);
         M : constant Positive := Next (N - 1, 10);
         E : E_Arr;
         G : Graph;
         T : Edge_List (1 .. 10);
         TC : Natural;
         TW : Weight_Sum;
         Best : Natural := Natural'Last;
         S, Ones : Natural;
         Ok : Boolean := True;
      begin
         for K in 1 .. M loop
            E (K) := (U => Next (1, N), V => Next (1, N), W => Next (0, 20));
            if K < N then E (K).U := K; E (K).V := K + 1; end if;   --  a path keeps the graph connected
         end loop;
         Clear (G, N);
         for K in 1 .. M loop Add_Edge (G, Vertex_Id (E (K).U), Vertex_Id (E (K).V), E (K).W); end loop;
         for Mask in 0 .. 2 ** M - 1 loop
            Ones := 0; S := 0;
            for K in 1 .. M loop
               if (Mask / 2 ** (K - 1)) mod 2 = 1 then Ones := Ones + 1; S := S + E (K).W; end if;
            end loop;
            if Ones = N - 1 and then S < Best and then Spans (E, Mask, N) then Best := S; end if;
         end loop;
         Kruskal (G, T, TC, TW);
         --  the returned edges: N - 1 of them, existing in the graph, weights adding up to TW
         S := 0;
         for K in 1 .. TC loop
            S := S + Natural (T (K).Weight);
            declare Found : Boolean := False; begin
               for J in 1 .. M loop
                  if ((Positive (T (K).U) = E (J).U and then Positive (T (K).V) = E (J).V)
                      or else (Positive (T (K).U) = E (J).V and then Positive (T (K).V) = E (J).U))
                    and then Natural (T (K).Weight) = E (J).W then Found := True; end if;
               end loop;
               Ok := Ok and then Found;
            end;
         end loop;
         Report (Ok and then TC = N - 1 and then Natural (TW) = Best and then S = Best,
                 "run" & Integer'Image (Run) & " weight" & Weight_Sum'Image (TW) & " minimum" & Integer'Image (Best));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
